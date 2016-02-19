#!/bin/bash
##############################################################################
##
## Description  : Script to switch Enterprise Messaging HUB core applications
##                between UK4 DB and FR1 DB
##
## Author       : Sanjan Grero (sanjan.grero@sap.com)
##
##############################################################################



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
morouters_uk_main=(uk4morouter01 uk4morouter02)

# US2 MT Routers
mtrouters_us_main=(us2appstage006 us2appstage005)

# US2 Notifs
notifs_us_lvl1_main=(us2appstage007)
notifs_us_lvl2_main=(us2appstage001)

# US2 MO Routers
morouters_us_main=(us2appstage010)


# List of configuration files

mtconf="/opt/HUB/MTRouter/conf/mtrouter.properties"
dtwconf="/opt/HUB/dtw_spoolmanager/conf/spoolConfig.xml"
notifl1sockconf="/opt/HUB/etc/sock_mv-notif_lvl1.ini"
notifl2filterconf="/opt/HUB/ixng-a2pjmstools/etc/Notif_Filter.properties"
moconf="/opt/HUB/etc/asepwd.ini"

# List of log files
mtlog="/opt/HUB/log/mtrouter.log"
dtwlog="/opt/HUB/log/SpoolManager.log"

#list of MO processes
moproc_fr_main=(mosendsmsinterface-1 mosendsmsinterface-2 mosendsmsinterface-frenchrs mosendsmsinterface-terra mosendsmsinterface-snap)
moproc_fr_tss=(mosendsmsinterface-2)
moproc_uk_main=(mosendsmsinterface-1 mosendsmsinterface-2)
moproc_us_main=(mosendsmsinterface-2)

# Other properties
logdir=/opt/HUB/log
log=/opt/HUB/log/$(basename $0 .sh).log


#######################################################################
# -MT ROUTER SWITCH
# Globals:
#   None
# Arguments:
#   List of servers
#######################################################################

function f_switch {

local type=$1; shift
local dbswitch=$1; shift
local subscript=switch_db_mt.sh

if [[ "$type" == "MT" ]]
then
  echo -e "\n$(date +%F' '%T) Switching MT Routers ..." | tee -a "${log}"
  subscript=switch_db_mt.sh
elif [[ "$type" == "NOTIF" ]]
then
  echo -e "\n$(date +%F' '%T) Switching NOTIF Servers ..." | tee -a "${log}"
  subscript=switch_db_notif.sh
elif [[ "$type" == "MO" ]]
then
  echo -e "\n$(date +%F' '%T) Switching MO Routers ..." | tee -a "${log}"
  subscript=switch_db_mo.sh
fi

for host in "$@"
do
echo -e "$(date +%F' '%T) Switching $host to \"$dbswitch\" Database. Log: $logdir/$(basename $subscript .sh)_$host.log"  | tee -a "${log}"
$subscript $host $dbswitch &
done

}

#######################################################################
# Check current status of each server
# Globals:
#   list of servers
# Arguments:
#   none
#######################################################################

function f_check_status {



# check MT

echo -e "\nChecking MT Routers ..."

for mtrouter in "${mtrouters_us_main[@]}"
do
echo -e "\n==> $mtrouter"

ssh -T production1@$mtrouter /bin/bash <<EOF | tee -a ${log}

export PATH=\$PATH:/opt/HUB/bin

mtrunning=\$(lc status 2>/dev/null | grep JMTRouter | wc -l)
if [[ \$mtrunning -eq 1 ]]
then
  echo -en "JMTRouter - running " 
else
   echo -en "JMTRouter - NOT running " 
fi

mtdb=\$(grep "us2a2pasedb001.lab:5000/a2p_msgdb_fr1" $mtconf | wc -l)
if [[ \$mtdb -eq 1 ]]
then
  echo -e "- FR1 DB" 
else
   echo -e "- UK4 DB" 
fi

dtwrunning=\$(lc status 2>/dev/null | grep dtw_spoolmanager | wc -l)
if [[ \$dtwrunning -eq 1 ]]
then
  echo -en "dtw_spoolmanager - running " 
else
   echo -en "dtw_spoolmanager - NOT running " 
fi

dtwdb=\$(grep "us2a2pasedb001.lab:5000/a2p_msgdb_fr1" $dtwconf | wc -l)
if [[ \$dtwdb -eq 1 ]]
then
  echo -e "- FR1 DB" 
else
   echo -e "- UK4 DB" 
fi

sockmvrunning=\$(lc status 2>/dev/null | grep "sock.*notif" | wc -l)
if [[ \$sockmvrunning -ge 1 ]]
then
  echo -en "Sock MV Client Notif Level 1 - running " 
else
   echo -en "Sock MV Client Notif Level 1 - NOT running " 
fi

sockmvpath=\$(grep "updatemtnotif/inputspool" $notifl1sockconf | wc -l)

if [[ \$sockmvpath -eq 1 ]]
then
  echo -e "- FR1 spool" 
else
   echo -e "- UK4 spool" 
fi


EOF

done

# Check Notif 

echo -e "\nChecking Level 2/3  Notif Servers ..."

for notifserver in "${notifs_us_lvl2_main[@]}"
do
echo -e "\n==> $notifserver"

ssh -T production1@$notifserver /bin/bash <<EOF | tee -a ${log}

export PATH=\$PATH:/opt/HUB/bin

nfrunning=\$(lc status 2>/dev/null | grep Notif_Filter | wc -l)
if [[ \$nfrunning -eq 1 ]]
then
  echo -en "Notif_Filter - running "
else
  echo -en "Notif_Filter - NOT running "
fi

nfpath=\$(grep "^sink.spool.path = /opt/HUB/NOTIF/updatemtnotif\$" $notifl2filterconf | wc -l)
if [[ \$nfpath -eq 1 ]]
then
  echo -e "- FR1"
else
  echo -e "- UK4"
fi

EOF

done

# Check MO 
echo -e "\nChecking MO Routers ..."

for morouter in "${morouters_us_main[@]}"
do
echo -e "\n==> $morouter"

ssh -T production1@$morouter /bin/bash <<EOF | tee -a ${log}

export PATH=\$PATH:/opt/HUB/bin

for moproc in "${moproc_us_main[@]}"
do
morunning=\$(lc status 2>/dev/null | grep \$moproc | wc -l)
if [[ \$morunning -eq 1 ]]
then
  echo -e "\$moproc - running "
else
   echo -e "\$moproc - NOT running "
fi
done

modb=\$(grep "^HUBMO=DTSA2PFR2\$" $moconf | wc -l)
if [[ \$modb -eq 1 ]]
then
  echo -e "All MO - FR1 DB\n"
else
  echo -e "All MO - UK4 DB\n"
fi

EOF

done

}


# Functions for Sub-Menus

#######################################################################
# Show menu options for FR1 HUB
# Separate options for MAIN and TSS HUBs as well as MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_fr_hub {

echo -e "You have selected: FR1 Production HUB\n"

local options=("Set FR1 MAIN HUB MT/NOTIF Apps to UK4 DB" "Set FR1 MAIN HUB MO Apps to UK4 DB" 
			   "Set FR1 MAIN HUB MT/NOTIF Apps to FR1 DB" "Set FR1 MAIN HUB MO Apps to FR1 DB"
			   "Set FR1 TSS HUB MT/NOTIF Apps to UK4 DB" "Set FR1 TSS HUB MO Apps to UK4 DB" 
			   "Set FR1 TSS HUB MT/NOTIF Apps to FR1 DB" "Set FR1 TSS HUB MO Apps to FR1 DB"
			   "Restart UpdateMT Notif in FR1 HUB"
			   "Check Process Status in FR1 HUB"
			   "Exit")

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2ukdb "${mtrouters_fr_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_fr_lvl2_main[@]}"
		break ;;
	
	2)	f_morouter_switch2ukdb "${morouters_fr_main[@]}"
		break ;;
	
	
	3)	f_mtrouter_switch2frdb "${mtrouters_fr_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_fr_lvl2_main[@]}"
		break ;;
		
	4)	f_morouter_switch2frdb "${morouters_fr_main[@]}"
		break ;;
		
	5)	f_mtrouter_switch2ukdb "${mtrouters_fr_tss[@]}"
		f_notiflvl2_switch2ukdb "${notifs_fr_lvl2_tss[@]}"
		break ;;
		
	6)	f_morouter_switch2ukdb "${morouters_fr_tss[@]}"
		break ;;
	
	7)	f_mtrouter_switch2frdb "${mtrouters_fr_tss[@]}"
		f_notiflvl2_switch2frdb "${notifs_fr_lvl2_tss[@]}"
		break ;;
		
	8)	f_morouter_switch2frdb "${morouters_fr_tss[@]}"
		break ;;
		
	9)	f_restart_notif_apps "${notifs_fr_lvl1_main[@]}" "${notifs_fr_lvl2_main[@]}"
		break ;;
	
	10) f_check_status
		break ;;
		
	11)	echo -e "\nOperation Cancelled.\n"
		show_main_menu
		break ;;
	
	*) 	echo -e "\nInvalid Option - Try Again!\n"
		;;
	
esac

done

}

#######################################################################
# Show menu options for UK4 HUB
# Separate options for MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_uk_hub {

echo -e "You have selected: UK4 Production HUB\n"

local options=("Set UK4 HUB MT/NOTIF Apps to UK4 DB" "Set UK4 HUB MO Apps to UK4 DB" 
			   "Set UK4 HUB MT/NOTIF Apps to FR1 DB" "Set UK4 HUB MO Apps to FR1 DB"
			   "Restart UpdateMT Notif in UK4 HUB"
			   "Check Process Status in UK4 HUB"
			   "Exit")

select action in "${options[@]}"
do

case $REPLY in

	1)	f_mtrouter_switch2ukdb "${mtrouters_uk_main[@]}"
		f_notiflvl2_switch2ukdb "${notifs_uk_lvl2_main[@]}"
		break ;;
	
	2)	f_morouter_switch2ukdb "${morouters_uk_main[@]}"
		break ;;
		
	3)	f_mtrouter_switch2frdb "${mtrouters_uk_main[@]}"
		f_notiflvl2_switch2frdb "${notifs_uk_lvl2_main[@]}"
		break ;;

	4)	f_morouter_switch2frdb "${morouters_uk_main[@]}"
		break ;;
		
	5)	f_restart_notif_apps "${notifs_uk_lvl1_main[@]}" "${notifs_uk_lvl2_main[@]}"
		break ;;
	
	6)  f_check_status
		break ;;
		
	7)	echo -e "\nOperation Cancelled.\n"
		break ;;
		
	*) 	echo -e "\nInvalid Option - Try Again!\n"
		;;
		
esac

done

}

#######################################################################
# Show menu options for US2 Staging HUB
# Separate options for MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_us_hub {

echo -e "==> US2 Staging HUB\n"

local options=("Set US2 Staging MT/NOTIF Apps to UK4 DB" "Set US2 Staging MO Apps to UK4 DB" 
			   "Set US2 Staging MT/NOTIF Apps to FR1 DB" "Set US2 Staging MO Apps to FR1 DB" 
			   "Check Process Status in US2 HUB"
			   "Exit")

select action in "${options[@]}"
do

case $REPLY in

	1)	f_switch "MT" "UK" "${mtrouters_us_main[@]}"
		f_switch "NOTIF" "UK" "${notifs_us_lvl2_main[@]}"
		show_main_menu
		break ;;
		
	2)	f_switch "MO" "UK" "${morouters_us_main[@]}"
		show_main_menu
		break ;;
		
	3)	f_switch "MT" "FR" "${mtrouters_us_main[@]}"
		f_switch "NOTIF" "FR" "${notifs_us_lvl2_main[@]}"
		show_main_menu
		break ;;
		
	4)	f_switch "MO" "FR" "${morouters_us_main[@]}"
		show_main_menu
		break ;;
	
	5)  f_check_status
		show_main_menu
		break ;;

	6)	echo -e "\nOperation Cancelled.\n"
		break ;;
	
	*) 	echo -e "\nInvalid Option - Try Again!\n"
		;;

esac

done

}

#######################################################################
# Show menu options for selection of messaging HUB
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function show_main_menu {
export COLUMNS=1
echo -e "\n===================================="
echo -e "| Switch DB Script ( FR1 <-> UK4 ) |"
echo -e "====================================\n"

PS3="Select Action: "

f_switch_us_hub

}

# Execute the main menu
echo -e "\n$(date +%F' '%T) ==> START execution of script by $(whoami) \n" | tee -a "${log}"
clear

show_main_menu;