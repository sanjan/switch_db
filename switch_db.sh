#!/bin/bash
##
## Author		: Sanjan Grero (sanjan.grero@sap.com)
## Description	: Script to switch Enterprise Messaging HUB core applications 
## 				  between UK4 DB and FR1 DB
##


log=/opt/HUB/log/$(basename $0 .sh).log

# List of hosts

# FR1 MT Routers
mtrouters_fr_main=(fr1mtrouter001 fr1mtrouter002 fr1mtrouter003 fr1mtrouter004 fr1mtrouter005 fr1mtrouter006 fr1mtrouter007 fr1mtrouter008)
mtrouters_fr_tss=(fr1mtrouter101 fr1mtrouter102)

# FR1 Notifs
notifs_fr_lvl1_main=(fr1notif001 fr1notif002 fr1notif003 fr1notif004)
notifs_fr_lvl2_main=(fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010)
notifs_fr_lvl1_tss=(fr1notif101 fr1notif102)
notifs_fr_lvl2_tss=(fr1notif103 fr1notif104)

# FR1 MO Routers
morouters_fr_main=(fr1morouter001 fr1morouter002)
morouters_fr_tss=(fr1morouter101 fr1morouter102)

# UK4 MT Routers
mtrouters_uk_main=(uk4mtrouter01 uk4mtrouter02 uk4mtrouter003 uk4mtrouter004 uk4mtrouter005 uk4mtrouter006)

# UK4 Notifs
notifs_uk_lvl1_main=(uk4notifa01 uk4notifa02)
notifs_uk_lvl2_main=(uk4notifb01 uk4notifb02)

# UK4 MO Routers
morouters_uk_main=(fr1morouter001 fr1morouter002)

# US2 MT Routers
mtrouters_us_main=(us2appstage005 us2appstage006)

# US2 Notifs
notifs_us_lvl2_main=(us2appstage001 us2appstage007)

# US2 MO Routers
morouters_us_main=(us2appstage010)


# List of configuration files

mtconf="/opt/HUB/MTRouter/conf/mtrouter.properties"
dtwconf="/opt/HUB/dtw_spoolmanager/conf/spoolConfig.xml"
notifl1sockconf="/opt/HUB/etc/sock_mv-notif_lvl1.ini"

# Functions for MT Routers

function f_restart_mtrouter_apps {

for host in "$@"
do

echo "$(date +%F' '%T) ==> Restarting applications in [$host]" | tee -a "${log}"

ssh -T production1@$host <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin

lc restart JMTRouter 2>&1
lc restart dtw_spoolmanager 2>&1
for smvproc in $(lc status 2>/dev/null | grep "sock.*notif" | awk '{echo -e $1}');do lc restart \$smvproc;done 2>&1

EOF

done

}

function f_mtrouter_switch2ukdb {



for host in "$@"
do

echo "$(date +%F' '%T) ==> Switching applications in [$host] to UK4 DB" | tee -a "${log}"

ssh -T production1@$host <<EOF | tee -a ${log}


echo "Updating mtrouter config in \$(hostname)" 
if [[ \$(hostname) =~ "us2*" ]]
then
echo US2 server detected
sed -e 's@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@g' $mtconf 2>&1} 

sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@g' $mtconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@g' $mtconf 2>&1
fi

echo "Updating dtw_spoolmanager config in \$(hostname)"
if [[ "\$(hostname)" =~ "us2*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@g' $dtwconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@g' $dtwconf 2>&1
fi

echo "Updating notif lvl1 sock mv config in \$(hostname)"
sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif/inputspool@updatemtnotif_uk/inputspool@g' $notifl1sockconf 2>&1

EOF

done

f_restart_mtrouter_apps "$@"

}


function f_mtrouter_switch2frdb {

for host in "$@"
do

echo "$(date +%F' '%T) ==> Switching applications in [$host] to FR1 DB" | tee -a "${log}"

ssh -T production1@$host <<EOF | tee -a ${log}

echo "Updating mtrouter config in \$(hostname)" 
if [[ "\$(hostname)" =~ "us2*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@g' $mtconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@g' $mtconf 2>&1
fi

echo "Updating dtw_spoolmanager config in \$(hostname)"
if [[ "\$(hostname)" =~ "us2*" ]]
then
sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@g' $dtwconf 2>&1
else
sed -i.\$(date +%Y%m%d%H%M%S) 's@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@g' $dtwconf 2>&1
fi
echo "Updating notif lvl1 sock mv config in \$(hostname)"
sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif_uk/inputspool@updatemtnotif/inputspool@g' $notifl1sockconf 2>&1

EOF

done

f_restart_mtrouter_apps "$@"

}

# Functions for Notifs

function f_notiflvl2_switch2ukdb {
true
}

function f_notiflvl2_switch2frdb {
true
}

# Functions for MO Routers

function f_morouter_switch2ukdb {
true
}

function f_morouter_switch2frdb {
true
}

# Functions for Sub-Menus

function  f_switch_fr_hub {

echo -e "\nYou have selected: FR1 Production HUB\n"

local options=("Set FR1 MAIN HUB Apps to UK4 DB" "Set FR1 MAIN HUB Apps to FR1 DB" "Set FR1 TSS HUB Apps to UK4 DB" "Set FR1 TSS HUB Apps to FR1 DB" "Cancel")

local PS3="Select Action: "

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2ukdb "${mtrouters_fr_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_fr_lvl2_main[@]}"
		f_morouter_switch2ukdb "${morouters_fr_main[@]}"
		break ;;
	
	2)	f_mtrouter_switch2frdb "${mtrouters_fr_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_fr_lvl2_main[@]}"
		f_morouter_switch2frdb "${morouters_fr_main[@]}"
		break ;;
		
	3)	f_mtrouter_switch2ukdb "${mtrouters_fr_tss[@]}"
		f_notiflvl2_switch2ukdb "${notifs_fr_lvl2_tss[@]}"
		f_morouter_switch2ukdb "${morouters_fr_tss[@]}"
		break ;;
	
	4)	f_mtrouter_switch2frdb "${mtrouters_fr_tss[@]}"
		f_notiflvl2_switch2frdb "${notifs_fr_lvl2_tss[@]}"
		f_morouter_switch2frdb "${morouters_fr_tss[@]}"
		break ;;
		
	5)	echo -e "\nOperation Cancelled.\n"
		break ;;
esac

done

}

function  f_switch_uk_hub {

echo -e "\nYou have selected: UK4 Production HUB\n"

local options=("Set UK4 HUB Apps to FR1 DB" "Set UK4 HUB Apps to UK4 DB" "Cancel")
local PS3="Select Action: "

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2frdb "${mtrouters_uk_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_uk_lvl2_main[@]}"
		f_morouter_switch2frdb "${morouters_uk_main[@]}"
		break ;;

	2)	f_mtrouter_switch2ukdb "${mtrouters_uk_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_uk_lvl2_main[@]}"
		f_morouter_switch2ukdb "${morouters_uk_main[@]}"
		break ;;
			
	3)	echo -e "\nOperation Cancelled.\n"
		break ;;
esac

done

}

function  f_switch_us_hub {

echo -e "\nYou have selected: US2 Staging HUB\n"

local options=("Set US2 Staging to FR1 DB" "Set US2 Staging to UK4 DB" "Cancel")
local PS3="Select Action: "

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2frdb "${mtrouters_us_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_us_lvl2_main[@]}"
		f_morouter_switch2frdb "${morouters_us_main[@]}"
		break ;;

	2)	f_mtrouter_switch2ukdb "${mtrouters_us_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_us_lvl2_main[@]}"
		f_morouter_switch2ukdb "${morouters_us_main[@]}"
		break ;;
			
	3)	echo -e "\nOperation Cancelled.\n"
		break ;;
esac

done

}

# Main
clear
echo ""
echo "======================="
echo "| Switch DB Script    |"
echo "======================="
echo ""


msghubs=("FR1 HUB" "UK4 HUB" "US2 Staging HUB" "Quit")
PS3="Select Messaging HUB: "
echo ""

select hub in "${msghubs[@]}"
do
case $hub in
	
	"FR1 HUB") f_switch_fr_hub
	break ;;	
	
	"UK4 HUB") f_switch_uk_hub
	break ;;

	"US2 Staging HUB") f_switch_us_hub
	break ;;
	
	"Quit") echo -e "\nGoodbye!\n"
	break ;;
	
	*) echo -e "\nInvalid Entry - Try Again!\n"
	;;

esac

echo ""
done
