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

# 1. Добавляем пользователя student931
USERNAME="student931"
if id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Пользователь ${USERNAME} уже существует.${NC}"
else
    echo -e "${YELLOW}Введите пароль для пользователя ${USERNAME}:${NC}"
    read -s PASSWORD
    useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME"
fi

# 2. Создаём группу пользователей collage
GROUPNAME="collage"
if getent group "$GROUPNAME" > /dev/null; then
    echo -e "${RED}Группа ${GROUPNAME} уже существует.${NC}"
else
    groupadd "$GROUPNAME"
fi

# 3. Добавляем пользователя student931 в группу пользователей collage
usermod -aG "$GROUPNAME" "$USERNAME"

# 4. Переходим в каталог home и создаём каталог МДК02
MDK_DIR="/home/МДК02"
if [ -d "$MDK_DIR" ]; then
    echo -e "${RED}Каталог ${MDK_DIR} уже существует.${NC}"
else
    mkdir "$MDK_DIR"
fi

# 5. Создаём в каталоге МДК02 текстовый файл lvm.txt и пишем назначение lvm диска
LVM_FILE="$MDK_DIR/lvm.txt"
if [ -f "$LVM_FILE" ]; then
    echo -e "${RED}Файл ${LVM_FILE} уже существует.${NC}"
else
    touch "$LVM_FILE"
    echo 'Назначение LVM (Logical Volume Manager) — управление логическими томами в операционных системах Linux.' > "$LVM_FILE"
fi

# 6. Подсчитываем количество строк и слов в текстовом файле lvm.txt 
echo -e "${YELLOW}Количество строк и слов в файле lvm.txt:${NC}"
wc "$LVM_FILE"

# 7. Создаём в каталоге МДК02 каталог ПМ02 и переносим в его текстовый файл lvm.txt
PM_DIR="$MDK_DIR/ПМ02"
if [ -d "$PM_DIR" ]; then
    echo -e "${RED}Каталог ${PM_DIR} уже существует.${NC}"
else
    mkdir "$PM_DIR"
    mv "$LVM_FILE" "$PM_DIR/"
    echo -e "${GREEN}Файл lvm.txt перемещен в каталог ПМ02.${NC}"
fi

# 8. Определяем ip-адрес своего компьютера
echo -e "${YELLOW}IP-адрес вашего компьютера:${NC}"
ifconfig

# 9. Определяем количество разделов жёсткого диска на компьютере 
echo -e "${YELLOW}Количество разделов жёсткого диска:${NC}"
fdisk -l

# Сообщение об успешном завершении
echo -e "${GREEN}Скрипт успешно выполнен!${NC}"
