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
mtrouters_fr_5fgr=(fr1mtrouter009 fr1mtrouter010 fr1mtrouter011 fr1mtrouter012)
mtrouters_fr_fb=(fr1mtrouter013 fr1mtrouter014)

# FR1 Notifs
notifs_fr_lvl2_main=(fr1notif005 fr1notif006 fr1notif007 fr1notif008 fr1notif009 fr1notif010 fr1notif011 fr1notif012)
notifs_fr_lvl2_tss=(fr1notif103 fr1notif104)

# FR1 MO Routers
morouters_fr_main=(fr1morouter001 fr1morouter002)
morouters_fr_tss=(fr1morouter101 fr1morouter102)


# List of configuration files

mtconf="/opt/HUB/MTRouter/conf/mtrouter.properties"
dtwconf="/opt/HUB/dtw_spoolmanager/conf/spoolConfig.xml"
notifl1sockconf="/opt/HUB/etc/sock_mv-notif_lvl1.ini"
notifl2filterconf="/opt/HUB/ixng-a2pjmstools/etc/Notif_Filter.properties"
moconf="/opt/HUB/etc/asepwd.ini"

# Other properties
logdir=/opt/HUB/log
log=/opt/HUB/log/$(basename $0 .sh).log


#######################################################################
# FUNCTION PRESS ANY KEY
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function f_anykey {

read -rsp $'Press any key to continue...' -n1 key
echo
show_main_menu

}

#######################################################################
# -Application Switch
# Globals:
#   None
# Arguments:
#   Type of server , DB to switch to , list of servers
#######################################################################

function f_switch {

local type=$1; shift
local dbswitch=$1; shift
local subscript=/opt/HUB/scripts/switch_db_mt_fr.sh

echo -e "\n$(date +%F' '%T) Switching $type ..." | tee -a "${log}"

if [[ "$type" == "MT" ]]
then
  subscript=/opt/HUB/scripts/switch_db_mt_fr.sh
elif [[ "$type" == "NOTIF" ]]
then
  subscript=/opt/HUB/scripts/switch_db_notif_fr.sh
elif [[ "$type" == "MO" ]]
then
  subscript=/opt/HUB/scripts/switch_db_mo_fr.sh
fi

for host in "$@"
do
echo -e "$(date +%F' '%T) Switching $host to \"$dbswitch\" Database. Log: $logdir/$(basename $subscript .sh)_$host.log"  | tee -a "${log}"
$subscript $host $dbswitch &
done

}

#######################################################################
# Switch selected MT Routers
# Globals:
#   None
# Arguments:
#   Type of server , DB to switch to , list of servers
#######################################################################

function f_switch_selected_mt {

local dbswitch=$1

local selected=$(whiptail --title "Select MT Routers" \
--checklist "Press:\n<SPACE> to select/de-select\n<UP/DOWN> to scroll through items\n<TAB> to navigate components" 22 50 16 \
fr1mtrouter001 MainHub off \
fr1mtrouter002 MainHub off \
fr1mtrouter003 MainHub off \
fr1mtrouter004 MainHub off \
fr1mtrouter005 MainHub off \
fr1mtrouter006 MainHub off \
fr1mtrouter007 MainHub off \
fr1mtrouter008 MainHub off \
fr1mtrouter009 5thFinger off \
fr1mtrouter010 5thFinger off \
fr1mtrouter011 5thFinger off \
fr1mtrouter012 5thFinger off \
fr1mtrouter013 Facebook off \
fr1mtrouter014 Facebook off \
fr1mtrouter101 TSSHub off \
fr1mtrouter102 TSSHub off \
3>&1 1>&2 2>&3)

if [[ "$selected" == "" ]]
then
  echo "No MT Router was selected. Operation Cancelled."
else
  local selected_routers=($(echo $selected | sed 's/\"//g' ))
  echo -e "\nReady to Switch Routers:"
  for router in ${selected_routers[@]}
  do
    echo "- $router"
  done
  echo -en "\nProceed with switching? (yes/no): "
  read choice
  if [[ "$choice" == "yes" ]]
  then
    f_switch "MT" "$dbswitch" "${selected_routers[@]}"
  fi
fi

}

#######################################################################
# Switch selected Notif
# Globals:
#   None
# Arguments:
#   DB to switch to
#######################################################################

function f_switch_selected_notif {

local dbswitch=$1

local selected=$(whiptail --title "Select Notif Routers" --noitem \
--radiolist "Press:\n<SPACE> to select/de-select\n<UP/DOWN> to scroll through items\n<TAB> to navigate components" 20 80 10 \
MAINHUB off \
TSSHUB off \
BOTH off \
3>&1 1>&2 2>&3)

local selected_routers=()

if [[ "$selected" == "MAINHUB" ]]
then
  selected_routers=("${notifs_fr_lvl2_main[@]}")
elif [[ "$selected" == "TSSHUB" ]]
then
  selected_routers=("${notifs_fr_lvl2_tss[@]}")
elif [[ "$selected" == "BOTH" ]]
then
selected_routers=("${notifs_fr_lvl2_main[@]}" "${notifs_fr_lvl2_tss[@]}")
fi

if [[ "$selected" == "" ]]
then
  echo "No Notif server was selected. Operation Cancelled."
else
  echo -e "\nReady to Switch Notif Servers:"
  for router in ${selected_routers[@]}
  do
    echo "- $router"
  done

  echo -en "\nProceed with switching? (yes/no): "
  read choice
  if [[ "$choice" == "yes" ]]
  then
  f_switch "NOTIF" "$dbswitch" "${selected_routers[@]}"
  fi
fi

}

#######################################################################
# Check current status of each server
# Globals:
#   list of servers
# Arguments:
#   none
#######################################################################

function f_check_status {

echo -e "\n$(date +%F' '%T) START Status check ..."  | tee -a "${log}"

# check MT

echo -e "\n$(date +%F' '%T) Checking MT Routers ..." | tee -a "${log}"

mtlist=( ${mtrouters_fr_main[@]} ${mtrouters_fr_5fgr[@]} ${mtrouters_fr_fb[@]} ${mtrouters_fr_tss[@]} )

for mtrouter in "${mtlist[@]}"
do

echo -e "\n$(date +%F' '%T) HOST: $mtrouter" | tee -a "${log}"

ssh -T production1@$mtrouter /bin/bash <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin

mtrunning=\$(lc status 2>/dev/null | grep JMTRouter | wc -l)
if [[ \$mtrunning -eq 1 ]]
then
  echo -en "JMTRouter - Running "
else
   echo -en "JMTRouter - NOT RUNNING! "
fi

mtlsof=\$(pgrep MTRouter -f | xargs -i /usr/sbin/lsof -p {} -a -i -P | grep 5000 | head -n1 | awk '{print \$8" "\$9" "\$10}')

mtdb=\$(grep "fr1a2pasedbvcs:5000/a2p_msgdb_fr1" $mtconf 2>/dev/null  | wc -l)
if [[ \$mtdb -eq 1 ]]
then
  echo -e "==> Connects to: FR1 DB , \$mtlsof"
else
   echo -e "==> Connects to: UK4 DB , \$mtlsof"
fi

dtwrunning=\$(lc status 2>/dev/null | grep dtw_spoolmanager | wc -l)
if [[ \$dtwrunning -eq 1 ]]
then
  echo -en "dtw_spoolmanager - Running "
else
   echo -en "dtw_spoolmanager - NOT RUNNING! "
fi

dtwlsof=\$(pgrep SpoolManager -f | xargs -i /usr/sbin/lsof -p {} -a -i -P | grep 5000 | head -n1 | awk '{print \$8" "\$9" "\$10}')

dtwdb=\$(grep "fr1a2pasedbvcs:5000/a2p_msgdb_fr1" $dtwconf 2>/dev/null | wc -l)
if [[ \$dtwdb -eq 1 ]]
then
  echo -e "==> Connects to: FR1 DB , \$dtwlsof"
else
   echo -e "==> Connects to: UK4 DB  , \$dtwlsof"
fi

sockmvrunning=\$(lc status 2>/dev/null | grep "sock.*notif" | wc -l)
if [[ \$sockmvrunning -ge 1 ]]
then
  echo -en "Sock MV Client Notif Level 1 - Running "
else
   echo -en "Sock MV Client Notif Level 1 - NOT RUNNING! "
fi

sockmvpath=\$(grep "updatemtnotif/inputspool" $notifl1sockconf | wc -l)

if [[ \$sockmvpath -eq 1 ]]
then
  echo -e "==> Sends to: FR1 spool"
else
   echo -e "==> Sends to: UK4 spool"
fi

EOF

done

# Check Notif

echo -e "\n$(date +%F' '%T) Checking Level 2/3  Notif Servers ..." | tee -a "${log}"

notiflist=( ${notifs_fr_lvl2_main[@]} ${notifs_fr_lvl2_tss[@]} )

for notifserver in "${notiflist[@]}"
do

echo -e "\n$(date +%F' '%T) HOST: $notifserver" | tee -a "${log}"

ssh -T production1@$notifserver /bin/bash <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin

nfrunning=\$(lc status 2>/dev/null | grep Notif_Filter | wc -l)
if [[ \$nfrunning -eq 1 ]]
then
  echo -en "Notif_Filter - Running "
else
  echo -en "Notif_Filter - NOT RUNNING! "
fi

nfpath=\$(grep "^sink.spool.path = /opt/HUB/NOTIF/updatemtnotif\$" $notifl2filterconf | wc -l)
if [[ \$nfpath -eq 1 ]]
then
  echo -e "==> Sends to: FR1 spool"
else
  echo -e "==> Sends to: UK4 spool"
fi

EOF

done

# Check MO
echo -e "\n$(date +%F' '%T) Checking MO Routers ..." | tee -a "${log}"

molist=( ${morouters_fr_main[@]} ${morouters_fr_tss[@]} )

for morouter in "${molist[@]}"
do

echo -e "\n$(date +%F' '%T) HOST: $morouter" | tee -a "${log}"

ssh -T production1@$morouter /bin/bash <<EOF | tee -a ${log}

export PATH=\$PATH:/opt/HUB/bin:/opt/HUB/lance

modb=\$(grep "^HUBMO=PDSA2PFR5\$" $moconf 2>/dev/null | wc -l)
modbstatus=""
if [[ \$modb -eq 1 ]]
then
  modbstatus="Connects to: FR1 DB"
else
  modbstatus="Connects to: UK4 DB"
fi


morunninglist=\$(lc status 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}')
for moproc in \${morunninglist[@]}
do
  echo -e "\$moproc - Running ==> \$modbstatus"
done

modownlist=\$(lc nok 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}')
for moproc in \${modownlist[@]}
do
   echo -e "\$moproc - NOT RUNNING! ==> \$modbstatus"
done

EOF

done

echo -e "\n$(date +%F' '%T) COMPLETED Status check.\n"  | tee -a "${log}"

}

# Functions for Sub-Menus

#######################################################################
# Show menu options for FR1 PRODUCTION HUB
# Separate options for MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_fr_hub {

echo -e "==> FR1 PRODUCTION HUB\n"

local options=("Set MAIN HUB - MT/NOTIF ==> to UK4 DB"
                           "Set MAIN HUB - MO ==> to UK4 DB"
                           "Set MAIN HUB - MT/NOTIF ==> to FR1 DB"
                           "Set MAIN HUB - MO ==> to FR1 DB"
                           "Set TSS HUB - MT/NOTIF ==> to UK4 DB"
                           "Set TSS HUB - MO ==> to UK4 DB"
                           "Set TSS HUB - MT/NOTIF ==> to FR1 DB"
                           "Set TSS HUB - MO ==> to FR1 DB"
                           "Set SELECTED MT Routers ==> to UK4 DB"
                           "Set SELECTED MT Routers ==> to FR1 DB"
                           "Set Level 2/3 NOTIF ==> to UK4 DB"
                           "Set Level 2/3 NOTIF ==> to FR1 DB"
                           "Check Process Status"
                           "Exit")

select action in "${options[@]}"
do

case $REPLY in

        1)      f_switch "MT" "UK" "${mtrouters_fr_main[@]}"
                f_switch "NOTIF" "UK" "${notifs_fr_lvl2_main[@]}"
                f_anykey
                break ;;

        2)      f_switch "MO" "UK" "${morouters_fr_main[@]}"
                f_anykey
                break ;;

        3)      f_switch "MT" "FR" "${mtrouters_fr_main[@]}"
                f_switch "NOTIF" "FR" "${notifs_fr_lvl2_main[@]}"
                f_anykey
                break ;;

        4)      f_switch "MO" "FR" "${morouters_fr_main[@]}"
                f_anykey
                break ;;

        5)      f_switch "MT" "UK" "${mtrouters_fr_tss[@]}"
                f_switch "NOTIF" "UK" "${notifs_fr_lvl2_tss[@]}"
                f_anykey
                break ;;

        6)      f_switch "MO" "UK" "${morouters_fr_tss[@]}"
                f_anykey
                break ;;

        7)      f_switch "MT" "FR" "${mtrouters_fr_tss[@]}"
                f_switch "NOTIF" "FR" "${notifs_fr_lvl2_tss[@]}"
                f_anykey
                break ;;

        8)      f_switch "MO" "FR" "${morouters_fr_tss[@]}"
                f_anykey
                break ;;

        9)      f_switch_selected_mt "UK"
                f_anykey
                break ;;

        10)     f_switch_selected_mt "FR"
                f_anykey
                break ;;

        11)     f_switch_selected_notif "UK"
                f_anykey
                break ;;

        12)     f_switch_selected_notif "FR"
                f_anykey
                break ;;

        13)     f_check_status
                f_anykey
                break ;;

        14)     echo -e "\n$(date +%F' '%T) ==> END execution of script by $(whoami) \n" | tee -a "${log}"
                                clear
                break ;;

        *)      echo -e "\nInvalid Option - Try Again!\n"
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

f_switch_fr_hub

}

# Execute the main menu
echo -e "\n$(date +%F' '%T) ==> START execution of script by $(whoami) \n" | tee -a "${log}"
clear

show_main_menu;
