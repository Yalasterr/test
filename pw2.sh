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

# Добавляем пользователя student
USERNAME="student"

# Проверка на существование пользователя
if id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME} уже существует.${NC}"
    exit 1
fi

# Запрашиваем пароль у пользователя
echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME}:${NC}"
read -s PASSWORD

# Создаем пользователя с указанным паролем
useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"

# Проверка на наличие каталога 931Gruppa
if [ -d "/931Gruppa" ]; then
    echo -e "${RED}Каталог 931Gruppa уже существует.${NC}"
    exit 1
fi

# Создаём каталог 931Gruppa
mkdir 931Gruppa

# Проверка на наличие каталога Forever
if [ -d "/931Gruppa/Forever" ]; then
    echo -e "${RED}Каталог Forever уже существует.${NC}"
    exit 1
fi

# Переходим в каталог 931Gruppa и создаём папку Forever
cd 931Gruppa
mkdir Forever 

# Переходим в каталог Forever, создаём текстовый файл good.txt и пишем своё ФИО
cd Forever
touch good.txt

# Запрашиваем ФИО у пользователя
echo -e "${YELLOW}Введите ваше ФИО:${NC}"
read FULL_NAME

# Записываем ФИО в файл good.txt
echo "$FULL_NAME" | tee good.txt > /dev/null

# Переходим в корневой каталог и переименовываем папку 931Gruppa в GR931
cd /
mv 931Gruppa GR931

# Меняем время на 9:35
date -s "09:35:00"

# Определяем объём оперативной памяти компьютера
free -h

# Проверка на установленный net-tools
if ! command -v ifconfig &> /dev/null; then
    echo -e "${YELLOW}Пакет net-tools не установлен. Устанавливаем его...${NC}"
    apt update && apt install -y net-tools

fi

# Копируем файл good.txt в каталог GR931 
cp GR931/Forever/good.txt /GR931/

# Выводим информацию о сетевых устройствах
ifconfig

# Сообщение об успешном завершении
echo -e "${GREEN}Скрипт успешно выполнен!${NC}"
