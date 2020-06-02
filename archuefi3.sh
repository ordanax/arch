#!/bin/bash
mkdir ~/downloads
cd ~/downloads

echo 'Установка AUR (yay)'
sudo pacman -Syu
sudo pacman -S wget --noconfirm
wget git.io/yay-install.sh && sh yay-install.sh --noconfirm

echo 'Создаем нужные директории'
sudo pacman -S xdg-user-dirs --noconfirm
xdg-user-dirs-update

echo 'Установка базовых программ и пакетов'
sudo pacman -S reflector firefox firefox-i18n-ru ufw f2fs-tools dosfstools ntfs-3g alsa-lib alsa-utils file-roller p7zip unrar gvfs aspell-ru pulseaudio pavucontrol --noconfirm

echo 'Установить рекомендумые программы?'
read -p "1 - Да, 0 - Нет: " prog_set
if [[ $prog_set == 1 ]]; then
  #Можно заменить на pacman -Qqm > ~/.pacmanlist.txt
  sudo pacman -S recoll chromium obs-studio veracrypt vlc freemind filezilla gimp libreoffice libreoffice-fresh-ru kdenlive neofetch vlc qbittorrent galculator telegram-desktop --noconfirm
  wget https://raw.githubusercontent.com/ordanax/arch/master/attach/.aurlist.txt
  yay -Syy
  yay -S --noconfirm - < .aurlist.txt
  rm -rf ~/.aurlist.txt
elif [[ $prog_set == 0 ]]; then
  echo 'Установка программ пропущена.'
fi

echo 'Скачать и установить конфиг и темы для XFCE?'
read -p "1 - Да, 0 - Нет: " xfce_set
if [[ $xfce_set == 1 ]]; then
  echo 'Качаем и устанавливаем настройки Xfce'
  # Чтобы сделать копию ваших настоек перейдите в домашнюю директорию ~/username 
  # открйте в этой категории терминал и выполните команду ниже
  # Предварительно можно очистить конфиг от всего лишнего
  # tar -czf config.tar.gz .config
  # Выгрузите архив в интернет и скорректируйте ссылку на свою.
  wget https://github.com/ordanax/arch/raw/master/attach/config.tar.gz
  sudo rm -rf ~/.config/xfce4
  sudo tar -xzf config.tar.gz -C ~/
  echo 'Удаление тем по умолчанию'
  sudo rm -rf /usr/share/themes/*
  echo 'Установка тем'
  yay -S x-arc-shadow papirus-maia-icon-theme-git breeze-default-cursor-theme --noconfirm
  sudo pacman -S capitaine-cursors --noconfirm
  
  echo 'Ставим лого ArchLinux в меню'
  wget git.io/arch_logo.png
  sudo mv -f ~/downloads/arch_logo.png /usr/share/pixmaps/arch_logo.png
  
  echo 'Удаляем лишнее из xfce4'
  sudo pacman -Rs mousepad xfce4-clipman-plugin xfce4-timer-plugin xfce4-time-out-plugin xfce4-artwork xfce4-taskmanager xfce4-smartbookmark-plugin xfce4-sensors-plugin xfce4-screenshooter xfce4-notes-plugin xfce4-netload-plugin xfce4-mpc-plugin xfce4-mount-plugin xfce4-mailwatch-plugin xfce4-genmon-plugin xfce4-fsguard-plugin xfce4-eyes-plugin xfce4-diskperf-plugin xfce4-dict xfce4-cpugraph-plugin xfce4-cpufreq-plugin

  echo 'Ставим обои на рабочий стол'
  wget git.io/bg.jpg
  sudo rm -rf /usr/share/backgrounds/xfce/* #Удаляем стандартные обои
  sudo mv -f ~/downloads/bg.jpg /usr/share/backgrounds/xfce/bg.jpg
elif [[ $xfce_set == 0 ]]; then
  echo 'Установка конфигов XFCE пропущена.'
fi 

#echo "Ставим i3 с моими настройками?"
#read -p "1 - Да, 2 - Нет: " vm_setting
#if [[ $vm_setting == 1 ]]; then
#    pacman -S i3-wm i3-gaps i3status sbxkb dmenu pcmanfm ttf-font-awesome feh lxappearance thunar gvfs udiskie xorg-xbacklight ristretto tumbler compton --noconfirm
#    yay -S polybar
#    wget https://github.com/ordanax/dots/raw/master/i3wm_v_2/i3wm_config.tar.gz
#    sudo rm -rf ~/.config/i3/*
#    sudo rm -rf ~/.config/polybar/*
#    sudo tar -xzf i3wm_config.tar.gz -C ~/
#elif [[ $vm_setting == 2 ]]; then
#  echo 'Пропускаем.'
#fi

echo 'Установить conky?'
read -p "1 - Да, 0 - Нет: " conky_set
if [[ $conky_set == 1 ]]; then
  sudo pacman -S conky conky-manager --noconfirm
  wget git.io/conky.tar.gz
  tar -xzf conky.tar.gz -C ~/
elif [[ $conky_set == 0 ]]; then
  echo 'Установка conky пропущена.'
fi

echo 'Делаем авто вход без DE?'
read -p "1 - Да, 0 - Нет: " node_set
if [[ $node_set == 1 ]]; then
sudo systemctl disable lxdm
sudo pacman -R lxdm
sudo pacman -S xorg-xinit --noconfirm
cp /etc/X11/xinit/xserverrc ~/.xserverrc
wget https://raw.githubusercontent.com/ordanax/arch/master/attach/.xinitrc
sudo mv -f .xinitrc ~/.xinitrc
wget https://raw.githubusercontent.com/ordanax/arch/master/attach/.bashrc
rm ~/.bashrc
sudo mv -f .bashrc ~/.bashrc
wget https://raw.githubusercontent.com/ordanax/arch/master/attach/grub
sudo mv -f grub /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
read -p "Введите имя пользователя: " username
sudo echo -e '[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --autologin' "$username" '--noclear %I $TERM' > override.conf
sudo mv -f override.conf /etc/systemd/system/getty@tty1.service.d/override.conf
elif [[ $node_set == 0 ]]; then
  echo 'Пропускаем.'
fi

echo 'Включаем сетевой экран'
sudo ufw enable

echo 'Добавляем в автозагрузку:'
sudo systemctl enable ufw

# Очистка
rm -R ~/downloads/
rm -rf ~/archuefi3.sh

echo 'Установка завершена!'
