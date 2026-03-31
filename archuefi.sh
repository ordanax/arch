#!/bin/bash

# =============================================================================
# Arch Linux Fast Install v3.2.0 (Актуализирован 2024-2025)
# Быстрая установка Arch Linux с XFCE/LightDM + Опциональное LUKS шифрование
# Автор: Алексей Бойко t.me/ordanax
# =============================================================================
# Часть 3 (настройка) запускается отдельно после перезагрузки
# =============================================================================

set -e  # Прервать выполнение при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     Arch Linux Fast Install v3.2.0 (UEFI) - 2025-2026              ║"
echo "║     Базовая установка системы с опциональным LUKS шифрованием     ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# 0. ВЫБОР РЕЖИМА ШИФРОВАНИЯ
# =============================================================================

echo "🔐 Выберите режим установки:"
echo "  1) Обычная установка (без шифрования) - быстрее, проще"
echo "  2) Установка с LUKS шифрованием (LVM on LUKS) - безопаснее"
echo ""
read -p "Ваш выбор (1/2): " install_mode

if [[ $install_mode == "2" ]]; then
    USE_ENCRYPTION=true
    log_warn "Выбрано шифрование LUKS. Потребуется ввод пароля при каждой загрузке."
else
    USE_ENCRYPTION=false
    log_info "Выбрана обычная установка без шифрования."
fi

echo ""

# =============================================================================
# 1. ПОДГОТОВКА
# =============================================================================

echo "📋 Настройка клавиатуры и шрифта..."
loadkeys ru
setfont cyr-sun16

echo "⏰ Синхронизация системных часов..."
timedatectl set-ntp true
hwclock --systohc

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  ⚠️  ВНИМАНИЕ! СКРИПТ ЗАТРЕТ ДИСК /dev/sda                         ║"
echo "║     Если у вас ценные данные - СОХРАНИТЕ ИХ!                       ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
read -p "Продолжить установку? (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    echo "Установка отменена."
    exit 1
fi

# =============================================================================
# 2. РАЗМЕТКА ДИСКА (GPT/UEFI)
# =============================================================================

if $USE_ENCRYPTION; then
    # РАЗМЕТКА С ШИФРОВАНИЕМ (LVM on LUKS)
    echo "💾 Создание разделов для шифрования..."
    echo "  Разметка: EFI (512M) | LUKS+LVM (всё остальное)"
    echo "  LVM volumes: swap (4G) | root (30G) | home (остальное)"
    (
        echo g;      # Создать GPT таблицу

        echo n;      # Раздел 1: EFI
        echo;
        echo;
        echo +512M;
        echo t;
        echo 1;      # Тип: EFI System

        echo n;      # Раздел 2: LUKS контейнер (всё остальное)
        echo;
        echo;
        echo;
        echo t;
        echo 2;
        echo 30;     # Тип: Linux LVM (или 8309 для LUKS)

        echo w;      # Записать изменения
    ) | fdisk /dev/sda

    echo "📋 Ваша разметка диска:"
    fdisk -l /dev/sda
    echo ""

    # =============================================================================
    # 3. НАСТРОЙКА LUKS И LVM
    # =============================================================================

    echo "🔐 Настройка LUKS шифрования..."
    log_warn "Введите пароль для шифрования диска (минимум 8 символов):"
    
    # Создаём LUKS контейнер с pbkdf2 для совместимости с GRUB
    # Используем LUKS2 с pbkdf2 (GRUB поддерживает)
    cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 --cipher aes-xts-plain64 --key-size 512 --hash sha512 /dev/sda2
    
    log_success "LUKS контейнер создан."
    
    # Открываем контейнер
    echo "🔓 Открытие LUKS контейнера..."
    cryptsetup open /dev/sda2 cryptlvm
    log_success "Контейнер открыт как /dev/mapper/cryptlvm"

    # Создаём LVM
    echo "💾 Создание LVM структуры..."
    pvcreate /dev/mapper/cryptlvm
    vgcreate vg0 /dev/mapper/cryptlvm
    
    # Создаём logical volumes
    lvcreate -L 4G vg0 -n swap
    lvcreate -L 30G vg0 -n root
    lvcreate -l 100%FREE vg0 -n home
    
    log_success "LVM создан: swap (4G), root (30G), home (остальное)"

    # Форматирование
    echo "🗂️  Форматирование разделов..."
    mkfs.fat -F32 /dev/sda1
    mkswap /dev/vg0/swap -L swap
    mkfs.ext4 /dev/vg0/root -L root
    mkfs.ext4 /dev/vg0/home -L home
    
    log_success "Разделы отформатированы."

    # Монтирование
    echo "📂 Монтирование разделов..."
    mount /dev/vg0/root /mnt
    mkdir -p /mnt/boot/efi /mnt/home
    mount /dev/sda1 /mnt/boot/efi
    mount /dev/vg0/home /mnt/home
    swapon /dev/vg0/swap

else
    # ОБЫЧНАЯ РАЗМЕТКА (без шифрования)
    echo "💾 Создание разделов..."
(
    echo g;      # Создать GPT таблицу

    echo n;      # Раздел 1: EFI
    echo;
    echo;
    echo +512M;
    echo t;
    echo 1;      # Тип: EFI System

    echo n;      # Раздел 2: root
    echo;
    echo;
    echo +30G;

    echo n;      # Раздел 3: swap
    echo;
    echo;
    echo +4G;
    echo t;
    echo 3;
    echo 19;     # Тип: Linux swap

    echo n;      # Раздел 4: home
    echo;
    echo;
    echo;

    echo w;      # Записать изменения
) | fdisk /dev/sda

echo "📋 Ваша разметка диска:"
fdisk -l /dev/sda
echo ""

# =============================================================================
# 3. ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ
# =============================================================================

echo "🗂️  Форматирование разделов..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2 -L root
mkswap /dev/sda3 -L swap
mkfs.ext4 /dev/sda4 -L home

echo "📂 Монтирование разделов..."
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi /mnt/home
mount /dev/sda1 /mnt/boot/efi
mount /dev/sda4 /mnt/home
swapon /dev/sda3

fi  # Закрываем if $USE_ENCRYPTION

# =============================================================================
# 4. ВЫБОР ЗЕРКАЛ
# =============================================================================

echo "🌍 Настройка зеркал..."
if command -v reflector &> /dev/null; then
    reflector --country Russia,Germany --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
else
    # Если reflector нет, используем ручную настройку
    cat > /etc/pacman.d/mirrorlist << 'EOF'
## Russia
Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch
Server = https://mirror.dotsrc.org/archlinux/$repo/os/$arch
EOF
fi

# =============================================================================
# 5. УСТАНОВКА БАЗОВОЙ СИСТЕМЫ
# =============================================================================

echo "📦 Установка базовой системы..."
echo "⚠️  Выберите тип процессора:"
echo "  1) Intel (установится intel-ucode)"
echo "  2) AMD (установится amd-ucode)"
read -p "Ваш выбор (1/2): " cpu_type

if [[ $cpu_type == "1" ]]; then
    UCODE="intel-ucode"
elif [[ $cpu_type == "2" ]]; then
    UCODE="amd-ucode"
else
    echo "Неверный выбор, пропускаем микрокод."
    UCODE=""
fi

echo "⬇️  Загрузка и установка пакетов (это займет время)..."

if $USE_ENCRYPTION; then
    # Добавляем пакеты для шифрования и LVM
    pacstrap -K /mnt base base-devel linux linux-firmware $UCODE nano vim \
        networkmanager iwd grub efibootmgr lvm2 cryptsetup
else
    pacstrap -K /mnt base base-devel linux linux-firmware $UCODE nano vim \
        networkmanager iwd grub efibootmgr
fi

echo "✅ Базовая система установлена"

# =============================================================================
# 6. НАСТРОЙКА СИСТЕМЫ (FSTAB)
# =============================================================================

echo "📝 Генерация fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Для шифрования добавляем crypttab
if $USE_ENCRYPTION; then
    echo "🔐 Настройка crypttab..."
    # Получаем UUID зашифрованного раздела
    CRYPT_UUID=$(blkid -s UUID -o value /dev/sda2)
    echo "cryptlvm UUID=$CRYPT_UUID none luks" >> /mnt/etc/crypttab
    log_success "crypttab настроен"
fi

# Проверяем fstab
cat /mnt/etc/fstab

# =============================================================================
# 7. CHROOT И НАСТРОЙКА СИСТЕМЫ
# =============================================================================

echo "🔧 Переходим к настройке системы внутри chroot..."
echo ""

# Запрашиваем данные заранее
read -p "Введите имя компьютера (hostname): " hostname
read -p "Введите имя пользователя: " username
echo ""

# Определяем параметры для mkinitcpio
if $USE_ENCRYPTION; then
    # Для шифрования используем encrypt и lvm2 hooks
    MKINITCPIO_HOOKS="base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck"
    CRYPT_UUID=$(blkid -s UUID -o value /dev/sda2)
    GRUB_CMDLINE="cryptdevice=UUID=$CRYPT_UUID:cryptlvm root=/dev/vg0/root"
else
    MKINITCPIO_HOOKS="base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck"
    GRUB_CMDLINE=""
fi

# Создаем скрипт для выполнения внутри chroot
cat > /mnt/install_chroot.sh << EOF
#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     Настройка системы внутри chroot                               ║"
echo "╚════════════════════════════════════════════════════════════════════╝"

# --- Имя компьютера ---
echo "🖥️  Установка имени компьютера: $hostname"
echo "$hostname" > /etc/hostname

# --- Часовой пояс ---
echo "🌍 Выберите часовой пояс:"
echo "  1) Москва (Europe/Moscow)"
echo "  2) Екатеринбург (Asia/Yekaterinburg)"
echo "  3) Другой (введите вручную)"
read -p "Ваш выбор (1/2/3): " tz_choice

if [[ \$tz_choice == "1" ]]; then
    ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
elif [[ \$tz_choice == "2" ]]; then
    ln -sf /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime
else
    read -p "Введите часовой пояс (например Europe/London): " tz_manual
    ln -sf /usr/share/zoneinfo/\$tz_manual /etc/localtime
fi
hwclock --systohc

# --- Локализация ---
echo "🌐 Настройка локализации..."
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo 'KEYMAP=ru' > /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf

# --- Настройка mkinitcpio для шифрования ---
if $USE_ENCRYPTION; then
    echo "🔐 Настройка mkinitcpio для LUKS+LVM..."
    # Устанавливаем lvm2
    pacman -S lvm2 --noconfirm --needed
    
    # Модифицируем mkinitcpio.conf
    sed -i 's/^HOOKS=.*/HOOKS=($MKINITCPIO_HOOKS)/' /etc/mkinitcpio.conf
    echo "mkinitcpio hooks настроены: $MKINITCPIO_HOOKS"
fi

# --- RAM диск ---
echo "💾 Создание загрузочного RAM диска..."
mkinitcpio -P

# --- Загрузчик GRUB ---
echo "🥾 Установка GRUB..."
pacman -Syy

if $USE_ENCRYPTION; then
    # Для шифрования устанавливаем GRUB с поддержкой cryptodisk
    pacman -S grub efibootmgr --noconfirm
    
    # Включаем поддержку шифрования в GRUB
    sed -i 's/^#GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /etc/default/grub
    sed -i 's/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /etc/default/grub
    
    # Добавляем параметры ядра для расшифровки
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_CMDLINE quiet\"|" /etc/default/grub
    sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE\"|" /etc/default/grub
    
    echo "GRUB настроен для шифрования"
else
    pacman -S grub efibootmgr --noconfirm
fi

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# Проверка на несколько ОС
echo ""
echo "Установить os-prober для обнаружения других ОС?"
read -p "1 - Да, 0 - Нет: " osprober_choice
if [[ \$osprober_choice == "1" ]]; then
    pacman -S os-prober --noconfirm
    # Раскомментируем в /etc/default/grub
    sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
fi

grub-mkconfig -o /boot/grub/grub.cfg

# --- Пользователь ---
echo "👤 Создание пользователя: $username"
useradd -m -g users -G wheel,power,storage,audio,video,input -s /bin/bash "$username"

echo "🔐 Установите пароль для ROOT:"
passwd

echo "🔐 Установите пароль для пользователя $username:"
passwd "$username"

# --- Sudo ---
echo "🔓 Настройка sudo..."
echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

# --- Multilib ---
echo "📦 Включение репозитория multilib..."
echo '[multilib]' >> /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
pacman -Syy

# --- Сеть ---
echo "🌐 Включение NetworkManager..."
systemctl enable NetworkManager

# --- Xorg ---
echo "🖥️  Установка Xorg..."
echo "Это виртуальная машина?"
read -p "1 - Да (добавятся guest-utils), 0 - Нет: " vm_choice

if [[ \$vm_choice == "1" ]]; then
    pacman -S xorg-server xorg-xinit xorg-drivers virtualbox-guest-utils --noconfirm
    systemctl enable vboxservice
else
    pacman -S xorg-server xorg-xinit xorg-drivers --noconfirm
fi

# --- XFCE ---
echo "🎨 Установка XFCE..."
pacman -S xfce4 xfce4-goodies --noconfirm

# --- LightDM (вместо устаревшего LXDM) ---
echo "🚪 Установка LightDM..."
pacman -S lightdm lightdm-gtk-greeter --noconfirm
systemctl enable lightdm

# --- Шрифты ---
echo "🔤 Установка шрифтов..."
pacman -S ttf-liberation ttf-dejavu noto-fonts noto-fonts-cjk --noconfirm

# --- PipeWire (вместо устаревшего PulseAudio) ---
echo "🔊 Установка PipeWire (звук)..."
pacman -S pipewire pipewire-pulse pipewire-alsa pavucontrol wireplumber --noconfirm
systemctl --global enable pipewire pipewire-pulse

# --- Завершение ---
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     ✅ Базовая установка завершена!                               ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

if $USE_ENCRYPTION; then
    echo "🔐 ВАЖНО: При загрузке введите пароль от LUKS для расшифровки диска."
    echo ""
fi

echo "Следующие шаги:"
echo "  1. Выйдите из chroot: exit"
echo "  2. Размонтируйте диски: umount -R /mnt"

if $USE_ENCRYPTION; then
    echo "  3. Закройте LUKS: cryptsetup close cryptlvm"
fi

echo "  4. Перезагрузитесь: reboot"
echo ""
echo "После входа в систему установите дополнительные программы:"
echo "  wget git.io/archuefi3.sh && sh archuefi3.sh"
echo ""

rm /install_chroot.sh
EOF

chmod +x /mnt/install_chroot.sh

# Запускаем chroot с нашим скриптом
arch-chroot /mnt /bin/bash /install_chroot.sh

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     ✅ Установка базовой системы завершена!                       ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

if $USE_ENCRYPTION; then
    echo "🔐 Шифрование активировано!"
    echo ""
fi

echo "Теперь выполните:"
echo "  umount -R /mnt"

if $USE_ENCRYPTION; then
    echo "  cryptsetup close cryptlvm"
fi

echo "  reboot"
echo ""
echo "После первого входа в систему установите дополнительные программы:"
echo "  wget git.io/archuefi3.sh && sh archuefi3.sh"
echo ""
