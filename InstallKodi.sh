#!/bin/bash
yellow=$(tput setf 6) ; red=$(tput setf 4) ; green=$(tput setf 2) ; reset=$(tput sgr0)
cmdkey=0 ; ME=`basename $0` cd~ ; clear

BackupsFolder=~/Kodi_Backup


function Zagolovok {
echo -en "${yellow} \n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                             ║"
echo "║                $ZI Kodi Media Center и его зависимостей               ║"
echo "║                                                                             ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n ${reset}"
}
function GoToMenu {
  GoToMenuInfo="Чтобы продолжить, введите"
while :
	do
	clear ; CheckBackUp=0 ; BackupRecovery=0
	ZI=Установка && Zagolovok 
	echo -en "\n"
	echo "     ┌─ Выберите действие: ──────────────────────────────────────────────┐"
	echo "     │                                                                   │"
	echo -en "\n" 
	echo "           1 - Установка Kodi на чистой системе $InstallInfo"
	echo -en "\n"
	echo "           2 - Установка Kodi с полным удалением старой версии $ReinstallInfo"
	echo -en "\n"
	echo "           3 - Полное удаление Kodi с очисткой системы $UninstallInfo"
	echo -en "\n"
	echo "           0 - Завершение работы с самоудалением скрипта"
	echo -en "\n"
	echo "     │                                                                   │"
	echo "     └────────────────────────────────────────────── H - Вызов справки ──┘"
	echo -en "\n"
	echo -e "\a"
	echo "           $GoToMenuInfo номер пункта и нажмите на Enter"
	echo -e "\a"
	read item
	printf "\n"
	case "$item" in

		0) 	RremovalItself ;;

		1) 	ReinstallInfo="" ; InstallScript ;;

		2) 	cmdkey=1 ; UninstallScript ; cmdkey=0 ; InstallScript ;;

		3) 	ReinstallInfo="" ; UninstallScript ;;

		D|d) 	RremovalItself ;;

		H|h) 	print_help ;;

		*) 	clear && GoToMenuInfo="Попробуйте еще раз ввести" ;;

	esac
done
}




function СheckingInstalledPackage() {
InstalledPackageKey=0 ; echo -en "\n" ; echo "  # # Проверка на ранее установленную версию..."
if dpkg -l kodi &>/dev/null; then
	echo -en "\n" ; echo "     - В вашей системе уже установлен Kodi как системный пакет..."
	InstallInfo="${green}[уже установлен]${reset}"
	InstalledPackageKey=1
fi

if [ $InstalledPackageKey -eq 1 ]; then
	if [ $cmdkey -eq 1 ]; then
		echo -en "\n" ; echo -e "\a"
		read -p "${green}           Нажмите любую клавишу, чтобы завершить работу скрипта...${reset}"
		exit 0
	else
		echo -en "\n" ; echo -e "\a"
		read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
		GoToMenu
	fi
fi
}

function BackUpScript() {

[ ! -d $BackupsFolder ] && sudo mkdir -p $BackupsFolder && sudo chmod 777 $BackupsFolder

	HA_SOURCE=/home/pi/.kodi/userdata
	[ -d $HA_SOURCE ] && CheckBackUp=1 && sudo tar cfz $BackupsFolder/$(date +'%Y.%m.%d')-Kodi-Backup.tgz -C $HA_SOURCE . > /dev/null 2>&1

if [ $CheckBackUp -eq 1 ]; then
	echo -en "\n" ; echo "  # # Создание резервной копии конфигурационных файлов Kodi..."
fi
}




function InstallScript() {
clear
Zagolovok
СheckingInstalledPackage
BackUpScript

echo -en "\n" ; echo "  # # Устранение проблеммы с черной рамкой по периметру..."
sudo raspi-config nonint do_overscan 0

echo -en "\n" ; echo "  # # Выделение по умолчанию для графической подсистемы 192 Мб..."
sudo raspi-config nonint do_memory_split 192

echo -en "\n" ; echo "  # # Обновление кеша данных и индексов репозиторий..."
sudo rm -Rf /var/lib/apt/lists
sudo apt update -y > /dev/null 2>&1
sudo apt upgrade -y > /dev/null 2>&1

#echo -en "\n" ; echo "  # # Установка необходимых зависимостей"
#echo -en "\n" ; echo "  # # Устранение ранее известных проблем..."

echo -en "\n" ; echo "  # # Установка Kodi..."
sudo apt install -y kodi kodi-eventclients-kodi-send > /dev/null 2>&1

echo -en "\n" ; echo "  # # Установка плагина IPTV Simple PVR..."
sudo apt install -y kodi-pvr-iptvsimple

echo -en "\n" ; echo "  # # Поддержка сжатых файлов Kodi-vfs-nfs..."
sudo apt install -y kodi-vfs-libarchive 

#echo -en "\n" ; echo "  # # Установка других плагинов при..."
#sudo apt install -y kodi-peripheral-joystick kodi-inputstream-adaptive kodi-inputstream-rtmp


echo -en "\n" ; echo "  # # Настройка плагина pvr.iptvsimple..."
#Проверка и создание необходимых каталогов c применение прав доступа
[ ! -d /home/pi/.kodi/userdata/addon_data/pvr.iptvsimple ] && sudo mkdir -v -m755 /home/pi/.kodi/userdata/addon_data/pvr.iptvsimple && sudo chown -v pi:pi /home/pi/.kodi/userdata/addon_data/pvr.iptvsimple
#Удаление ранее созданных настроек
sudo rm -rf /home/pi/.kodi/userdata/addon_data/pvr.iptvsimple/settings.xml*
#Создание готового файла настроек для плагина pvr.iptvsimple и применение необходимых прав
sudo tee -a /home/pi/.kodi/userdata/addon_data/pvr.iptvsimple/settings.xml <<_EOF_
<settings version="2">
    <setting id="epgCache">true</setting>
    <setting id="epgPath" default="true"></setting>
    <setting id="epgPathType" default="true">1</setting>
    <setting id="epgTimeShift" default="true">0</setting>
    <setting id="epgTSOverride" default="true">false</setting>
    <setting id="epgUrl">http://epg.it999.ru/edem.xml.gz</setting>
    <setting id="logoBaseUrl">http://epg.it999.ru/edem.xml.gz</setting>
    <setting id="logoFromEpg">2</setting>
    <setting id="logoPath" default="true"><-/setting>
    <setting id="logoPathType" default="true">1</setting>
    <setting id="m3uCache">true</setting>
    <setting id="m3uPath">/home/pi/.kodi/edem_playlist.m3u8</setting>
    <setting id="m3uPathType">1</setting>
    <setting id="m3uUrl">https://#PLAYLIST_URL#</setting>
    <setting id="startNum">1</setting>
</settings>
_EOF_
sudo chown -v pi:pi /home/pi/.kodi/userdata/addon_data/pvr.iptvsimple/settings.xml
sudo chmod 755 /home/pi/.kodi/userdata/addon_data/pvr.iptvsimple/settings.xml

echo -en "\n" ; echo "  # # Предварительная настройка Kodi..."
#Проверка и создание необходимых каталогов c применение прав доступа
[ ! -d /usr/share/kodi ] && sudo mkdir -v -m755 /usr/share/kodi && sudo chown -v root:root /usr/share/kodi
[ ! -d /usr/share/kodi/system ] && sudo mkdir -v -m755 /usr/share/kodi/system && sudo chown -v root:root /usr/share/kodi/system
#Удаление ранее созданных настроек
sudo rm -rf /usr/share/kodi/system/advancedsettings.xml*
#Создание готового файла настроек для Kodi и применение необходимых прав
sudo tee -a /usr/share/kodi/system/advancedsettings.xml <<_EOF_
<?xml version="1.0" encoding="UTF-8"?>
<advancedsettings>
  <cache> 
    <buffermode>1</buffermode>
    <memorysize>104857600</memorysize>
    <readfactor>10</readfactor>
  </cache>

  <gputempcommand>/opt/vc/bin/vcgencmd measure_temp | sed -e "s/temp=//" -e "s/\..*'/ /"</gputempcommand>
</advancedsettings>
_EOF_
sudo chown -v root:root /usr/share/kodi/system/advancedsettings.xml
sudo chmod 644 /usr/share/kodi/system/advancedsettings.xml

echo -en "\n" ; echo "  # # Создание службы для автозапуска Kodi"
sudo rm -rf /etc/systemd/system/kodi.service
sudo tee -a /etc/systemd/system/kodi.service > /dev/null <<_EOF_
[Unit]
Description = Kodi Media Center
After = remote-fs.target network-online.target
Wants = network-online.target

[Service]
User = pi
Group = pi
Type = simple
ExecStart = /usr/bin/kodi-standalone
Restart = on-abort
RestartSec = 5

[Install]
WantedBy = multi-user.target
_EOF_


# Восстанавление резервной копии
if [ -f $BackupsFolder/* ]; then

	BackupRecovery=1 && echo -en "\n" && echo "  # # Восстанавление резервной копии Home Assistant в папку backup..."

	if [ ! -d /home/pi/.kodi/backup ] ; then 
		sudo mkdir -p /home/pi/.kodi/backup/ && sudo chown 777 /home/pi/.kodi/backup/
	fi
	sudo mv -f $BackupsFolder/* /home/pi/.kodi/backup/
	sudo rm -rf $BackupsFolder
fi



echo -en "\n" ; echo "  # # Создание автозагрузки и запуск служб..."
sudo systemctl -q daemon-reload
sudo systemctl enable kodi.service
sudo systemctl start kodi.service


echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "║                 ${green}Установки Kodi и его зависимостей завершена${reset}                 ║"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -en "\n"
echo "    ┌──────────── Полезная информация для работы с Kodi ────────────┐"
echo "    │                                                                     │"
echo "    │                    Доступ к Kodi по адресу                    │"
echo "    │                      ${green}http://$(hostname -I | tr -d ' ')${reset}                      │"
echo "    │                                                                     │"
echo "    │                  Редактирование файла конфигурации                  │"
echo "    │              ${green}sudo nano /home/pi/.kodi/userdata/profiles.xml${reset}              │"
echo "    │                                                                     │"
if [ $CheckBackUp -eq 1 ]; then
echo "    │               Путь к восстанавленым резервным копиям:               │"
echo "    │             ${green}/home/pi/.kodi/backup/${reset}              │"
echo "    │                                                                     │"
fi
echo "    │               Путь хранения - ${green}/home/pi/.kodi${reset}                   │"
echo "    │                Путь плагина - ${green}/home/pi/.kodi/node_modules${reset}      │"
echo "    │                                                                     │"
echo "    │                       Перезагрузка Kodi                       │"
echo "    │     ${green}sudo systemctl restart kodi.service${reset}      │"
echo "    │                                                                     │"
echo "    │                    Запустит Kodi - ${green}sudo systemctl start kodi.service${reset}              │"
echo "    │                  Остановить Kodi - ${green}sudo systemctl stop kodi.service${reset}               │"
echo "    │                                                                     │"
echo "    │              Просмотр журналов - ${green} ${reset}               │"
echo "    │                                                                     │"
echo "    │                    Установка и удаление плагинов                    │"
echo "    │               ${green} ${reset}                │"
echo "    │               ${green} ${reset}             │"
echo "    │                                                                     │"
echo "    └─────────────────────────────────────────────────────────────────────┘"
echo -e "\a"

InstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	sleep 5
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function UninstallScript() {
clear
ZI=" Удаление" && Zagolovok

echo -en "\n" ; echo "  # # Остановка и завершение процесса Kodi..."
sudo kodi-send --action=Quit > /dev/null 2>&1
sleep 3
sudo systemctl stop kodi > /dev/null 2>&1
sudo service kodi stop > /dev/null 2>&1
sudo killall -w -s 9 -u kodi > /dev/null 2>&1

BackUpScript

echo -en "\n" ; echo "  # # Деинсталляция Kodi..."
sudo apt remove kodi -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Деинсталляция всех плагинов и конфигурацию Kodi..."
sudo apt purge kodi -y > /dev/null 2>&1

echo -en "\n" ; echo "  # # Удаление служб из списока автозагрузки..."
sudo update-rc.d kodi remove > /dev/null 2>&1
sudo rm -rf /etc/init.d/kodi
sudo rm -rf /etc/systemd/system/kodi*
sudo rm -rf /etc/systemd/system/multi-user.target.wants/kodi*
sudo systemctl --system daemon-reload > /dev/null

echo -en "\n" ; echo "  # # Удаление хвостов, для возможности последующей нормальной установки..."
sudo rm -rf /usr/bin/kodi*
sudo rm -rf /etc/default/kodi*
sudo rm -rf /var/lib/kodi*
sudo rm -rf /home/pi/.kodi*
sudo rm -rf /home/kodi*
sudo rm -rf ~/.kodi*
sudo rm -rf /home/pi/kodi_crashlog*


#echo -en "\n" ; echo "  # # Удаление хвостов от плагинов..."


echo -en "\n"
echo -en "\n"
echo "╔═════════════════════════════════════════════════════════════════════════════╗"
echo "      ${green}Удаление Kodi, а так же всех его плагинов с конфигурациями завершена${reset}"
echo "╚═════════════════════════════════════════════════════════════════════════════╝"
echo -e "\a"

UninstallInfo="${green}[OK]${reset}"

if [ $cmdkey -eq 1 ]; then
	sleep 5
	return
fi

read -p "${green}           Нажмите любую клавишу, чтобы вернуться в главное меню...${reset}"
sleep 1
GoToMenu
}





function RremovalItself() {
clear ; echo -en "\n" ; echo "                   Самоудаление папки со скриптом установки...  " ; cd
sudo rm -rf ~/HomebBridge-Install-Script
if [ $? -eq 0 ]; then
	echo "                ${green}[Успешно удалено]${reset} - ${red}Завершение работы скрипта...${reset}" ; echo -en "\n"
else
	echo "            ${red}[Удаление не удалось] - Завершение работы скрипта...${reset}" ; echo -en "\n"
fi
sleep 1
exit 0
}



function print_help() {
	echo -en "\n"
	echo "  ${yellow}Справка по работе скрипта $ME из командной строки${reset}"
	echo -en "\n"
	echo "    Использование: $ME [-i] [-u] [-r] [-d] [-h] "
	echo -en "\n"
	echo "        Параметры:"
	echo "            -i        Установка Kodi на чистой системе."
	echo "            -u        Полное удаление Kodi с очисткой системы."
	echo "            -r        Установка Kodi с полным удалением старой версии."
	echo "            -d        Самоудаление папки со скриптом установки."
	echo -en "\n"
	echo "            -h        Вызов справки."
	echo -en "\n"
exit 0
}





# Если скрипт запущен без аргументов, открываем справку.
if [ $# = 0 ]; then
	GoToMenu
fi

while getopts ":uUiIrRhHdD" Option
	do

	cmdkey=1
 
	case $Option in

		I|i) 	InstallScript ;;

		U|u) 	UninstallScript ;;

		R|r) 	UninstallScript ; InstallScript ;;

		D|d) 	RremovalItself ;;

		H|h) 	print_help ;;

		*) 	echo -en "\n" ; echo -en "\n"
			echo "${red}           Неправильный параметр!${reset}"
			print_help ; exit 1 ;;
	esac
done

shift $(($OPTIND - 1))

exit 0
