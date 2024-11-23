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

# 1. Устанавливаем службу SSH
echo -e "${YELLOW}Устанавливаем службу SSH...${NC}"
apt update && apt install -y openssh-server

# 2. Добавляем пользователя с фамилией, введенной пользователем
echo -e "${YELLOW}Введите вашу фамилию для создания пользователя:${NC}"
read USERNAME

if id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"
fi


# 3. Настраиваем конфигурационный файл SSH
echo -e "${YELLOW}Настраиваем конфигурационный файл SSH...${NC}"
# Раскомментируем строки Port и PasswordAuthentication
sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Перезапускаем службу SSH для применения изменений
systemctl restart ssh

# 4. Подключаемся с клиентского компьютера Windows (инструкция для пользователя)

echo -e "${GREEN}Вы можете подключиться к серверу с клиентского компьютера Windows под созданным пользователем:${NC}"
echo "ssh $USERNAME@<IP-адрес-сервера>"

# 9. Создаем пользователя со своим именем
echo -e "${YELLOW}Введите ваше имя для создания пользователя:${NC}"
read USERNAME2

if id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"
fi

# 10. Соединяемся с сервером с ноутбука (инструкция для пользователя)
echo -e "${GREEN}Вы можете подключиться к серверу с ноутбука под пользователем $USERNAME2:${NC}"
echo "ssh $USERNAME2@<IP-адрес-сервера>"