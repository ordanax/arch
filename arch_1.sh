#!/bin/bash
loadkeys ru
setfont cyr-sun16
echo 'Скрипт сделан на основе чеклиста Бойко Алексея по Установке ArchLinux'
echo 'Ссылка на чек лист есть в группе vk.com/arch4u'
echo 'Ускоренная установка ArhLinux + XFCE. Часть 1.'
read -p "Пауза 3 ceк." -t 3
echo '2.4.2 Форматирование дисков'
mkfs.ext2  /dev/sda1 -L boot
mkfs.ext4  /dev/sda2 -L root
mkswap /dev/sda3 -L swap
mkfs.ext4  /dev/sda4 -L home
echo '2.4.3 Монтирование дисков'
read -p "Пауза 3 ceк." -t 3
mount /dev/sda2 /mnt
mkdir /mnt/{boot,home}
mount /dev/sda1 /mnt/boot
swapon /dev/sda3
mount /dev/sda4 /mnt/home
echo '3.1 Выбор зеркал для загрузки. Используем программу Reflector'
read -p "Пауза 3 ceк." -t 3
pacman -Sy --noconfirm --noprogressbar --quiet reflector
pacman -S --noconfirm --needed --noprogressbar --quiet reflector
reflector -l 3 --sort rate --save /etc/pacman.d/mirrorlist
echo '3.2 Установка основных пакетов'
read -p "Пауза 3 ceк." -t 3
pacstrap /mnt base base-devel
echo '3.3 Настройка системы'
read -p "Пауза 3 ceк." -t 3
genfstab -pU /mnt >> /mnt/etc/fstab
echo 'Переходим в установлнную систему'
read -p "Пауза 3 ceк." -t 3
mount -o bind /dev /mnt/dev
mount -t proc none /mnt/proc
pacman -S wget --noconfirm
wget ordanax.ru/arch_1a.sh
sh arch_1a.sh
