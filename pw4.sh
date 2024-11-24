#!/bin/bash

# Определение цветовых кодов
RED='\033[0;31m'    # Красный
GREEN='\033[0;32m'  # Зеленый
YELLOW='\033[0;33m' # Желтый
NC='\033[0m'        # Сброс цвета

# Проверка на выполнение от имени root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Пожалуйста, запустите этот скрипт с правами суперпользователя (root).${NC}" 
    exit 1
fi

# Получаем номер команды, чтобы удалить его позже
history -d $(history | tail -n 1 | awk '{print $1}')

# 1. Проверяем IP-адрес
echo -e "${YELLOW}Текущий IP-адрес:${NC}"
ip addr

# 2. Изменяем имя компьютера
echo -e "${YELLOW}Введите новое имя компьютера:${NC}"
read NEW_HOSTNAME
hostnamectl set-hostname "$NEW_HOSTNAME"
echo -e "${GREEN}Имя компьютера изменено на $NEW_HOSTNAME.${NC}"

# 3. Проверяем, установлен ли bind9
if ! dpkg -l | grep -q bind9; then
    echo -e "${YELLOW}Сервис bind9 не установлен. Устанавливаем его...${NC}"
    apt update && apt install -y bind9
else
    echo -e "${GREEN}Сервис bind9 уже установлен.${NC}"
fi

# 4. Настраиваем named.conf.options
IP_ADDR=$(hostname -I | awk '{print $1}')  # Получаем первый IP-адрес
echo -e "${YELLOW}Настраиваем named.conf.options...${NC}"
cat <<EOL > /etc/bind/named.conf.options
options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable 
	// nameservers, you probably want to use them as forwarders.  
	// Uncomment the following block, and insert the addresses replacing 
	// the all-0's placeholder.

	 forwarders {
	 	8.8.8.8;
	 };

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	dnssec-validation auto;

	listen-on-v6 { any; };

	listen-on {
	127.0.0.1;
	$IP_ADDR;
};
};

EOL

# 5. Настраиваем файл named.conf.local
echo -e "${YELLOW}Введите название зоны прямого просмотра (например, vumk.lov):${NC}"
read ZONE_NAME

# Извлекаем первые три части IP-адреса для использования в конфигурации
IP_PREFIX=$(echo $IP_ADDR | awk -F. '{print $1"."$2"."$3}')
LAST_OCTET=$(echo $IP_ADDR | awk -F. '{print $4}')

# Формируем обратный порядок для зоны обратного просмотра
REVERSED_IP=$(echo $IP_PREFIX | awk -F. '{print $3"."$2"."$1}')

echo -e "${YELLOW}Настраиваем named.conf.local...${NC}"
cat <<EOL > /etc/bind/named.conf.local
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "$ZONE_NAME" {
type master;
file "/etc/bind/db.$ZONE_NAME";
};

zone "$REVERSED_IP. in-addr.apra" {
type master;
file "/etc/bind/db.$IP_PREFIX";
};
EOL

# 6. Создаём файл db.$ZONE_NAME
echo -e "${YELLOW}Создаем файл db.$ZONE_NAME...${NC}"
cp /etc/bind/db.local /etc/bind/db.$ZONE_NAME
cat <<EOL > /etc/bind/db.$ZONE_NAME
;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	$NEW_HOSTNAME.$ZONE_NAME. root.$NEW_HOSTNAME.$ZONE_NAME. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	$NEW_HOSTNAME.$ZONE_NAME.
@	IN	A	127.0.0.1
@	IN	AAAA	::1
$NEW_HOSTNAME	IN	A	$IP_ADDR
EOL

# 7. Создаём файл db.$IP_PREFIX
echo -e "${YELLOW}Создаем файл db.$IP_PREFIX...${NC}"
cp /etc/bind/db.local /etc/bind/db.$IP_PREFIX
cat <<EOL > /etc/bind/db.$IP_PREFIX
;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	$NEW_HOSTNAME.$ZONE_NAME. root.$NEW_HOSTNAME.$ZONE_NAME. (
			      3		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	$NEW_HOSTNAME.$ZONE_NAME.
$LAST_OCTET	IN	PTR	$NEW_HOSTNAME.$ZONE_NAME.
EOL

# 8. Устанавливаем обновления Ubuntu Server
echo -e "${YELLOW}Устанавливаем обновления Ubuntu Server...${NC}"
apt update && apt upgrade -y

# 9. Пропинговываем компьютер с внешними IP-адресами Google, Yandex
echo -e "${YELLOW}Проверяем DNS-записи...${NC}"
echo "nslookup 8.8.8.8"
nslookup 8.8.8.8
echo "nslookup 8.8.4.4"
nslookup 8.8.4.4
echo "nslookup google.ru"
nslookup google.ru
echo "nslookup 77.88.44.55"
nslookup 77.88.44.55
echo "nslookup yandex.ru"
nslookup yandex.ru

echo -e "${GREEN}Скрипт успешно выполнен!${NC}"

# Очистка истории команд
echo -e "${YELLOW}Очищаем историю команд...${NC}"
cat /dev/null > ~/.bash_history
echo -e "${GREEN}История команд очищена.${NC}"

# Перезагрузка через 30 секунд
echo -e "${YELLOW}Система будет перезагружена через 30 секунд...${NC}"
sleep 30
reboot
