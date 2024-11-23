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

if ! command -v samba &> /dev/null; then
    echo -e "${YELLOW}samba не установлен. Устанавливаем его...${NC}"
    apt update && apt install -y samba
else
    echo -e "${GREEN}samba уже установлен.${NC}"
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

USERNAMESMB1="director"
USERNAMESMB2="sysadms"
USERNAMESMB3="glavbuh"

if id "$USERNAME1" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME1} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME1}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME1"
fi

if id "$USERNAME2" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME2} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME2}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME2"
fi

if id "$USERNAME3" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME3} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME3}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME3"
fi


# ?. Добавляем пользователей в Samba
echo -e "${YELLOW}Добавляем пользователей в Samba...${NC}"

#if id "$USERNAMESMB1" &>/dev/null; then
#    echo -e "${RED}Пользователь ${USERNAMESMB1} уже существует.${NC}"
#else
#   echo -e "${YELLOW}Введите пароль для пользователя ${USERNAMESMB1}:${NC}"
#   read -s PASSWORD
#   smbpasswd -a $USERNAMESMB1 $PASSWORD
#fi

#if id "$USERNAMESMB2" &>/dev/null; then
#    echo -e "${RED}Пользователь ${USERNAMESMB2} уже существует.${NC}"
#else
#    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAMESMB2}:${NC}"
#    read -s PASSWORD
#    smbpasswd -a $USERNAMESMB2 $PASSWORD
#fi

#if id "$USERNAMESMB3" &>/dev/null; then
#    echo -e "${RED}Пользователь ${USERNAMESMB3} уже существует.${NC}"
#else
#    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAMESMB3}:${NC}"
#    read -s PASSWORD
#    smbpasswd -a $USERNAMESMB3 $PASSWORD
#fi
echo -e "${YELLOW}Введите пароль для пользователя ${USERNAMESMB1}:${NC}"
read -s PASSWORD

# Добавляем пользователя в Samba и передаем пароль через стандартный ввод
(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a "$USERNAMESMB1"

echo -e "${YELLOW}Введите пароль для пользователя ${USERNAMESMB2}:${NC}"
read -s PASSWORD

# Добавляем пользователя в Samba и передаем пароль через стандартный ввод
(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a "$USERNAMESMB2"

echo -e "${YELLOW}Введите пароль для пользователя ${USERNAMESMB3}:${NC}"
read -s PASSWORD

# Добавляем пользователя в Samba и передаем пароль через стандартный ввод
(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a "$USERNAMESMB3"

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

## 6. Для каталога Protection разрешаем доступ только пользователям группы best
#echo -e "${YELLOW}Настраиваем права доступа для каталога Protection...${NC}"
#chown :best /Public/Protection
#chmod 770 /Public/Protection

## 7. Для каталога Doc установить доступ всем пользователям на чтение и запись
#echo -e "${YELLOW}Настраиваем права доступа для каталога Doc...${NC}"
#chmod 777 /Public/Doc

## 8. Для каталога Buh установить доступ пользователям glavbuh и sysadms
#echo -e "${YELLOW}Настраиваем права доступа для каталога Buh...${NC}"
#chown :sysadms /Public/Buh
#chmod 770 /Public/Buh
#usermod -aG sysadms glavbuh

# 9. Настройка Samba
echo -e "${YELLOW}Настраиваем Samba...${NC}"

# Проверяем, существует ли секция [Public] в smb.conf
if ! grep -q "\[Public\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Public]
   path = /Public
   writable = yes
   browseable = yes
   guest ok = yes
EOL
fi

# Проверяем, существует ли секция [Protection] в smb.conf
if ! grep -q "\[Protection\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Protection]
   path = /Public/Protection
   valid users = @best
   writable = yes
   browseable = yes
   guest ok = no
EOL
fi

# Проверяем, существует ли секция [Doc] в smb.conf
if ! grep -q "\[Doc\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Doc]
   path = /Public/Doc
   writable = yes
   browseable = yes
   guest ok = yes
EOL
fi

# Проверяем, существует ли секция [Buh] в smb.conf
if ! grep -q "\[Buh\]" /etc/samba/smb.conf; then
    cat <<EOL >> /etc/samba/smb.conf

[Buh]
   path = /Public/Buh
   valid users = glavbuh, sysadms
   writable = yes
   browseable = yes
   guest ok = no
EOL
fi

# 10. Перезапускаем Samba
echo -e "${YELLOW}Перезапускаем Samba...${NC}"
systemctl restart smbd

# 11. Уведомление об успешном выполнении
echo -e "${GREEN}Скрипт выполнен успешно! Теперь вы можете подключиться к созданным каталогам из Windows 10.${NC}"