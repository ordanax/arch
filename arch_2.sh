#!/bin/bash
loadkeys ru
setfont cyr-sun16
echo 'Скрипт сделан на основе чеклиста Бойко Алексея по Установке ArchLinux'
echo 'Ссылка на чек лист есть в группе vk.com/arch4u'
echo 'Ускоренная установка ArhLinux + XFCE. Часть 2'
read -p "Пауза 3 ceк." -t 3
echo 'Добавляем пользователя'
useradd -m -g users -G wheel -s /bin/bash ordanax
echo 'Устанавливаем пароль пользователя'
passwd ordanax
echo 'Устанавливаем SUDO'
read -p "Пауза 3 ceк." -t 3
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
echo 'Раскомментируем репозиторий multilib Для работы 32-битных приложений в 64-битной системе.'
read -p "Пауза 3 ceк." -t 3
echo '[multilib]' >> /etc/pacman.d/mirrorlist
echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.d/mirrorlist
pacman -Syy
echo 'Ставим иксы и драйвера'
read -p "Пауза 3 ceк." -t 3
pacman -S xorg-server xorg-drivers
echo 'Ставим Xfce, LXDM и сеть'
read -p "Пауза 3 ceк." -t 3
pacman -S --noconfirm xfce4 xfce4-goodies lxdm networkmanager network-manager-applet ppp
echo 'Подключаем автозагрузку менеджера входа и интернет'
read -p "Пауза 3 ceк." -t 3
systemctl enable lxdm NetworkManager
echo 'Установка AUR'
read -p "Пауза 3 ceк." -t 3
pacman -Syy
echo '[archlinuxfr]' >> /etc/pacman.conf
echo 'SigLevel = Never' >> /etc/pacman.conf
echo 'Server = http://repo.archlinux.fr/$arch' >> /etc/pacman.conf
pacman -Syu
pacman -Sy yaourt
echo 'Установка программ'
read -p "Пауза 3 ceк." -t 3
sudo pacman -S firefox libreoffice libreoffice-fresh-ru screenfetch vlc qt4 qbittorrent ufw gparted f2fs-tools dosfstools ntfs-3g alsa-lib alsa-utils gnome-calculator file-roller p7zip unrar gvfs aspell-ru pulseaudio
yaourt -S dropbox timeshift google-talkplugin hunspell-ru
echo 'Установка тем'
read -p "Пауза 3 ceк." -t 3
yaourt -S vertex-themes
echo 'Включаем звук'
read -p "Пауза 3 ceк." -t 3
amixer sset Master unmut
echo 'Включаем сетевой экран'
read -p "Пауза 3 ceк." -t 3
ufw enable
echo 'Установка завершена! Перезагружаемся.'
read -p "Пауза 3 ceк." -t 3
reboot
