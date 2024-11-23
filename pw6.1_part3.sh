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

# 11. Создаем каталог Good в SSH931
echo -e "${YELLOW}Создаем каталог Good в /home/SSH931...${NC}"
sudo mkdir -p /home/SSH931/Good

# 12. Открываем доступ к каталогу Good только создателю
echo -e "${YELLOW}Открываем доступ к каталогу Good только создателю...${NC}"
sudo chmod 755 /home/SSH931/Good