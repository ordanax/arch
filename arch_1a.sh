#!/bin/bash
echo "ordanax-pc" > /etc/hostname
ln -svf /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime
echo '3.4 Добавляем русскую локаль системы'
read -p "Пауза 3 ceк." -t 3
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 
echo 'Обновим текущую локаль системы'
read -p "Пауза 3 ceк." -t 3
locale-gen
echo 'Указываем язык системы'
read -p "Пауза 3 ceк." -t 3
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo 'Вписываем KEYMAP=ru FONT=cyr-sun16'
read -p "Пауза 3 ceк." -t 3
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT=cyr-sun16' >> /etc/vconsole.conf
echo 'Создадим загрузочный RAM диск'
read -p "Пауза 3 ceк." -t 3
mkinitcpio -p linux
read -p "Пауза 3 ceк." -t 3
echo 'Создаем root пароль'
passwd
echo '3.5 Устанавливаем загрузчик'
read -p "Пауза 3 ceк." -t 3
pacman -S grub --noconfirm 
grub-install /dev/sda
echo 'Обновляем grub.cfg'
read -p "Пауза 3 ceк." -t 3
grub-mkconfig -o /boot/grub/grub.cfg
read -p "Пауза 3 ceк." -t 3
echo 'Ставим программу для Wi-fi'
pacman -S dialog wpa_supplicant --noconfirm
exit
umount /mnt/{boot,home,}
echo 'Перезагружаемся'
echo 'После перезагрузки запустите вторую часть скрипта для продолжения установки'
read -p "Пауза 3 ceк." -t 3
reboot
