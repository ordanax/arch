#!/bin/bash

# =============================================================================
# Arch Linux Fast Install v3.0.0 - Часть 3: Настройка и программы
# Запускать ПОСЛЕ первой перезагрузки и входа в систему
# =============================================================================

set -e

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     Arch Linux Fast Install v3.0.0 - Настройка системы             ║"
echo "║     Установка программ и конфигурация                             ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

mkdir -p ~/downloads
cd ~/downloads

# =============================================================================
# 1. УСТАНОВКА YAY (AUR helper)
# =============================================================================

echo "📦 Установка AUR helper (yay)..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

# Установка yay
if ! command -v yay &> /dev/null; then
    echo "⬇️  Скачивание и установка yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ~/downloads
    rm -rf /tmp/yay
    echo "✅ Yay установлен!"
else
    echo "✅ Yay уже установлен"
fi

# =============================================================================
# 2. СОЗДАНИЕ ДИРЕКТОРИЙ
# =============================================================================

echo "📁 Создание стандартных директорий..."
sudo pacman -S --noconfirm xdg-user-dirs
xdg-user-dirs-update

# =============================================================================
# 3. БАЗОВЫЕ ПРОГРАММЫ
# =============================================================================

echo "📦 Установка базовых программ..."
sudo pacman -S --noconfirm \
    reflector \
    firefox firefox-i18n-ru \
    ufw gufw \
    f2fs-tools dosfstools ntfs-3g \
    file-roller p7zip unrar \
    gvfs \
    aspell-ru \
    man-db man-pages texinfo

# =============================================================================
# 4. РЕКОМЕНДУЕМЫЕ ПРОГРАММЫ
# =============================================================================

echo ""
echo "Установить рекомендуемые программы?"
echo "  (LibreOffice, GIMP, VLC, Telegram, Discord, Obsidian и др.)"
read -p "1 - Да, 0 - Нет: " prog_set

if [[ $prog_set == "1" ]]; then
    echo "⬇️  Установка программ из официальных репозиториев..."
    sudo pacman -S --noconfirm \
        libreoffice-fresh libreoffice-fresh-ru \
        gimp inkscape \
        vlc mpv ffmpeg \
        thunderbird \
        telegram-desktop \
        qbittorrent \
        filezilla \
        obs-studio \
        veracrypt \
        flameshot \
        neofetch btop htop \
        galculator \
        viewnior \
        pcmanfm \
        gparted \
        ark
    
    echo "⬇️  Установка программ из AUR..."
    yay -S --noconfirm \
        sublime-text-4 \
        hunspell-ru \
        papirus-icon-theme \
        capitaine-cursors \
        ttf-clear-sans
        # Удалены: xflux (сервис закрыт), megasync (проблемы со сборкой)
    
    echo "✅ Программы установлены!"
else
    echo "⏭️  Установка программ пропущена"
fi

# =============================================================================
# 5. КОНФИГУРАЦИЯ XFCE
# =============================================================================

echo ""
echo "Скачать и установить конфиг и темы для XFCE?"
read -p "1 - Да, 0 - Нет: " xfce_set

if [[ $xfce_set == "1" ]]; then
    echo "🎨 Установка тем и конфигов XFCE..."
    
    # Темы из AUR
    yay -S --noconfirm arc-gtk-theme papirus-maia-icon-theme-git
    sudo pacman -S --noconfirm capitaine-cursors
    
    # Скачивание конфига (если URL актуален)
    echo "⬇️  Скачивание конфигурации XFCE..."
    if wget -q --spider https://github.com/ordanax/arch/raw/master/attach/config.tar.gz 2>/dev/null; then
        wget -q https://github.com/ordanax/arch/raw/master/attach/config.tar.gz
        sudo rm -rf ~/.config/xfce4/*
        tar -xzf config.tar.gz -C ~/
        echo "✅ Конфиг XFCE установлен"
    else
        echo "⚠️  URL конфига недоступен, пропускаем"
    fi
    
    # Лого Arch
    if wget -q --spider https://raw.githubusercontent.com/ordanax/arch/master/attach/arch_logo.png 2>/dev/null; then
        wget -q https://raw.githubusercontent.com/ordanax/arch/master/attach/arch_logo.png
        sudo mv -f arch_logo.png /usr/share/pixmaps/arch_logo.png
    fi
    
    # Удаление лишних пакетов XFCE (опционально)
    echo ""
    echo "Удалить неиспользуемые плагины XFCE?"
    read -p "1 - Да, 0 - Нет: " remove_xfce
    if [[ $remove_xfce == "1" ]]; then
        sudo pacman -Rs --noconfirm \
            xfburn orage parole mousepad \
            xfce4-appfinder xfce4-clipman-plugin \
            xfce4-timer-plugin xfce4-time-out-plugin \
            xfce4-artwork xfce4-taskmanager \
            2>/dev/null || true
    fi
    
    # Обои
    if wget -q --spider https://raw.githubusercontent.com/ordanax/arch/master/attach/bg.jpg 2>/dev/null; then
        wget -q https://raw.githubusercontent.com/ordanax/arch/master/attach/bg.jpg
        sudo rm -rf /usr/share/backgrounds/xfce/*
        sudo mv -f bg.jpg /usr/share/backgrounds/xfce/bg.jpg
    fi
    
    echo "✅ Настройка XFCE завершена!"
else
    echo "⏭️  Установка конфигов XFCE пропущена"
fi

# =============================================================================
# 6. I3WM (опционально)
# =============================================================================

echo ""
echo "Установить i3wm с настройками?"
read -p "1 - Да, 0 - Нет: " i3_choice

if [[ $i3_choice == "1" ]]; then
    echo "🪟 Установка i3wm..."
    sudo pacman -S --noconfirm \
        i3-wm i3status dmenu \
        pcmanfm \
        ttf-font-awesome \
        feh \
        udiskie \
        xorg-xbacklight \
        ristretto \
        tumbler \
        picom  # compton заменен на picom
    
    yay -S --noconfirm polybar ttf-weather-icons
    
    # Скачивание конфига i3
    if wget -q --spider https://github.com/ordanax/arch/raw/master/attach/config_i3wm.tar.gz 2>/dev/null; then
        wget -q https://github.com/ordanax/arch/raw/master/attach/config_i3wm.tar.gz
        rm -rf ~/.config/i3/* ~/.config/polybar/*
        tar -xzf config_i3wm.tar.gz -C ~/
        echo "✅ Конфиг i3wm установлен"
    else
        echo "⚠️  URL конфига i3 недоступен"
    fi
else
    echo "⏭️  Установка i3wm пропущена"
fi

# =============================================================================
# 7. CONKY
# =============================================================================

echo ""
echo "Установить Conky?"
read -p "1 - Да, 0 - Нет: " conky_set

if [[ $conky_set == "1" ]]; then
    sudo pacman -S --noconfirm conky conky-manager
    
    if wget -q --spider https://raw.githubusercontent.com/ordanax/arch/master/attach/conky.tar.gz 2>/dev/null; then
        wget -q https://raw.githubusercontent.com/ordanax/arch/master/attach/conky.tar.gz
        tar -xzf conky.tar.gz -C ~/
    fi
fi

# =============================================================================
# 8. ZRAM
# =============================================================================

echo ""
echo "Включить zram (сжатие RAM)?"
read -p "1 - Да, 0 - Нет: " zram_choice

if [[ $zram_choice == "1" ]]; then
    yay -S --noconfirm zram-generator
    sudo systemctl enable systemd-zram-setup@zram0.service
fi

# =============================================================================
# 9. ФАЙРВОЛ
# =============================================================================

echo "🔥 Включение файрвола UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw

# =============================================================================
# 10. АВТОВХОД БЕЗ DM (опционально)
# =============================================================================

echo ""
echo "Настроить автовход без менеджера входа (LightDM)?"
echo "⚠️  Только если вы знаете что делаете!"
read -p "1 - Да, 0 - Нет: " node_set

if [[ $node_set == "1" ]]; then
    echo "🔧 Настройка автовхода..."
    
    # Отключаем LightDM
    sudo systemctl disable lightdm
    sudo pacman -R --noconfirm lightdm lightdm-gtk-greeter
    
    # Устанавливаем xinit
    sudo pacman -S --noconfirm xorg-xinit
    
    # Создаем .xinitrc
    cat > ~/.xinitrc << 'XEOF'
#!/bin/sh
# Xfce по умолчанию
session=${1:-xfce}

case $session in
    xfce|xfce4) exec startxfce4 ;;
    i3|i3wm) exec i3 ;;
    *) exec $1 ;;
esac
XEOF
    chmod +x ~/.xinitrc
    
    # Настраиваем автовход
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
    sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
    
    # Добавляем автозапуск X в .bash_profile
    if ! grep -q "exec startx" ~/.bash_profile 2>/dev/null; then
        echo '
# Автозапуск X при входе на tty1
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec startx
fi' >> ~/.bash_profile
    fi
    
    echo "✅ Автовход настроен!"
    echo "⚠️  Перезагрузитесь для применения изменений"
fi

# =============================================================================
# 11. ОЧИСТКА
# =============================================================================

echo "🧹 Очистка временных файлов..."
cd ~
rm -rf ~/downloads

# =============================================================================
# ЗАВЕРШЕНИЕ
# =============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     ✅ УСТАНОВКА ЗАВЕРШЕНА!                                        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Установлено:"
echo "  • Базовые программы"
if [[ $prog_set == "1" ]]; then
    echo "  • Офис, мультимедиа, интернет-программы"
fi
if [[ $xfce_set == "1" ]]; then
    echo "  • Темы и конфиги XFCE"
fi
if [[ $i3_choice == "1" ]]; then
    echo "  • i3wm"
fi
if [[ $conky_set == "1" ]]; then
    echo "  • Conky"
fi
echo "  • Файрвол UFW"
echo ""
echo "Полезные команды:"
echo "  yay -Syu           # Обновление системы"
echo "  reflector ...      # Обновление зеркал"
echo "  sudo ufw status    # Статус файрвола"
echo ""
echo "Группа Arch Linux: https://vk.com/arch4u"
echo "Telegram: https://t.me/linux4at"
echo ""
