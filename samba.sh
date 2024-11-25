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

# 1. Устанавливаем Samba
if ! dpkg -l | grep -q samba; then
    echo -e "${YELLOW}Протокол samba не установлен. Устанавливаем его...${NC}"
    apt update && apt install -y samba
else
    echo -e "${GREEN}Протокол samba уже установлен.${NC}"
fi

# 2. Создаём каталог Public
echo -e "${YELLOW}Создаем каталог Public...${NC}"
mkdir /Public

# 3. Создаём в Public три каталога: Protection, Doc и Buh
echo -e "${YELLOW}Создаем подкаталоги в Public...${NC}"
mkdir /Public/Protection
mkdir /Public/Doc
mkdir /Public/Buh

# 4. Добавляем пользователей
echo -e "${YELLOW}Добавляем пользователей director, sysadms, glavbuh...${NC}"
USERNAME1="director"
USERNAME2="sysadms"
USERNAME3="glavbuh"

if id "$USERNAME1" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME1} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME1}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME1"
    # Добавляем пользователя в Samba и передаем пароль через стандартный ввод
    (echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a "$USERNAME1"
fi

if id "$USERNAME2" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME2} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME2}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME2"
    # Добавляем пользователя в Samba и передаем пароль через стандартный ввод
    (echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a "$USERNAME2"
fi

if id "$USERNAME3" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME3} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME3}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME3"
    # Добавляем пользователя в Samba и передаем пароль через стандартный ввод
    (echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a "$USERNAME3"
fi

# 5. Добавляем пользователей director и sysadms в группу best
echo -e "${YELLOW}Создаем группу best и добавляем пользователей...${NC}"

if ! getent group best > /dev/null; then
    echo -e "${YELLOW}Создаем группу best...${NC}"
    addgroup best
else
    echo -e "${GREEN}Группа best уже существует.${NC}"
fi

usermod -aG best $USERNAME1
usermod -aG best $USERNAME2

# 9. Настройка Samba
echo -e "${YELLOW}Настраиваем Samba...${NC}"

# Проверяем, существует ли секция [Public] в smb.conf
if ! grep -q "\[Public\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Public]
   browseable = no
   path = /Public
   guest ok = yes
   writable = yes
EOL
fi

# Проверяем, существует ли секция [Protection] в smb.conf
if ! grep -q "\[Protection\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Protection]
   browseable = yes
   path = /Public/Protection 
   guest ok = no
   writable = yes
   valid users = @best
   public = no
EOL
fi

# Проверяем, существует ли секция [Doc] в smb.conf
if ! grep -q "\[Doc\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Doc]
   browseable = yes
   path = /Public/Doc
   guest ok = yes
   writable = yes
EOL
fi

# Проверяем, существует ли секция [Buh] в smb.conf
if ! grep -q "\[Buh\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Buh]
   browseable = yes
   path = /Public/Buh
   guest ok = no
   writable = yes
   valid users = glavbuh, sysadms
   public = no
EOL
fi

# 10. Перезапускаем Samba
echo -e "${YELLOW}Перезапускаем Samba...${NC}"
systemctl restart smbd

# 11. Уведомление об успешном выполнении
echo -e "${GREEN}Скрипт выполнен успешно! Теперь вы можете подключиться к созданным каталогам из Windows 10.${NC}"

IP_ADDR=$(hostname -I | awk '{print $1}')  # Получаем первый IP-адрес
echo -e "${YELLOW}\\$IP_ADDR"${NC}
