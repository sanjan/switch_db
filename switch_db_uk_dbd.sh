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

# UK4 MT Routers
mtrouters_uk_main=(uk4mtrouter01 uk4mtrouter02 uk4mtrouter003 uk4mtrouter005 uk4mtrouter006)

# UK4 Event (Ticket Logger)
tloggers_uk_main=(uk4event001 uk4event002)

# UK4 Notifs
notifs_uk_lvl2_main=(uk4notifb01 uk4notifb02)

# UK4 MO Routers
morouters_uk_main=(uk4morouter01 uk4morouter02)

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
# -MT ROUTER SWITCH
# Globals:
#   None
# Arguments:
#   List of servers
#######################################################################

function f_switch {

local type=$1; shift
local dbswitch=$1; shift
local subscript=/opt/HUB/scripts/switch_db_mt_uk.sh

echo -e "\n$(date +%F' '%T) Switching $type ..." | tee -a "${log}"

if [[ "$type" == "MT" ]]
then
  subscript=/opt/HUB/scripts/switch_db_mt_uk.sh
  elif [[ "$type" == "TL" ]]
then
  subscript=/opt/HUB/scripts/switch_db_tl_uk.sh
  elif [[ "$type" == "NOTIF" ]]
then
  subscript=/opt/HUB/scripts/switch_db_notif_uk.sh
elif [[ "$type" == "MO" ]]
then
  subscript=/opt/HUB/scripts/switch_db_mo_uk.sh
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

local selected=$(whiptail --title "Select MT Routers" --noitem \
--checklist "Press:\n<SPACE> to select/de-select\n<UP/DOWN> to scroll through items\n<TAB> to navigate components" 20 80 10 \
uk4mtrouter01 off \
uk4mtrouter02 off \
uk4mtrouter003 off \
uk4mtrouter005 off \
uk4mtrouter006 off \
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
# Switch selected Ticket loggers
# Globals:
#   None
# Arguments:
#   Type of server , DB to switch to , list of servers
#######################################################################

function f_switch_selected_tl {

local dbswitch=$1

local selected=$(whiptail --title "Select Ticket Loggers" \
--checklist "Press:\n<SPACE> to select/de-select\n<UP/DOWN> to scroll through items\n<TAB> to navigate components" 22 50 16 \
uk4event001 MainHub off \
uk4event002 MainHub off \
3>&1 1>&2 2>&3)

if [[ "$selected" == "" ]]
then
  echo "No ticket logger was selected. Operation cancelled."
else
  local selected_routers=($(echo $selected | sed 's/\"//g' ))
  echo -e "\nReady to Switch Ticket loggers:"
  for router in ${selected_routers[@]}
  do
    echo "- $router"
  done
  echo -en "\nProceed with switching? (yes/no): "
  read choice
  if [[ "$choice" == "yes" ]]
  then
    f_switch "TL" "$dbswitch" "${selected_routers[@]}"
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

for mtrouter in "${mtrouters_uk_main[@]}"
do

echo -e "\n$(date +%F' '%T) HOST: $mtrouter" | tee -a "${log}"

ssh -T production1@$mtrouter /bin/bash <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin

dtwrunning=\$(lc status 2>/dev/null | grep dtw_spoolmanager | wc -l)
if [[ \$dtwrunning -eq 1 ]]
then
  echo -en "dtw_spoolmanager - Running "
else
   echo -en "dtw_spoolmanager - NOT RUNNING! "
fi

dtwlsof=\$(pgrep SpoolManager -f | xargs -i /usr/sbin/lsof -p {} -a -i -P | grep 5000 | head -n1 | awk '{print \$8" "\$9" "\$10}')

dtwdb=\$(grep "fr1a2pasedbvcs:5000/a2p_msgdb_fr1" $dtwconf | wc -l)
if [[ \$dtwdb -eq 1 ]]
then
  echo -e "==> Connects to: FR1 DB , \$dtwlsof"
else
   echo -e "==> Connects to: UK4 DB , \$dtwlsof"
fi

EOF

done

# check TL

echo -e "\n$(date +%F' '%T) Checking Event (Ticket Logger) Servers ..." | tee -a "${log}"

for tlogger in "${tloggers_uk_main[@]}"
do

echo -e "\n$(date +%F' '%T) HOST: $tlogger" | tee -a "${log}"

ssh -T production1@$tlogger /bin/bash <<EOF | tee -a "${log}"

export PATH=\$PATH:/opt/HUB/bin

for tlprocess in \$(grep "^\[ticketlogger" /opt/HUB/etc/lance.ini | sed 's/\(\[\|\]\)//g')
do

tlrunning=\$(lc status 2>/dev/null | grep \$tlprocess | wc -l)
if [[ \$tlrunning -eq 1 ]]
then
  echo -e "\$tlprocess - Running "
else
   echo -e "\$tlprocess - NOT RUNNING! "
fi

done

tlconfigfiles=(\$(find /opt/HUB/ticket-logger/conf/ -type f -name "ticket*properties"))

for tlconfigfile in  \${tlconfigfiles[@]}
do

tldb=\$(grep "fr1a2pasedbvcs:5000/a2p_msgdb_fr1" \$tlconfigfile | wc -l)
if [[ \$tldb -eq 1 ]]
then
  echo -e "\$tlconfigfile ==> Connects to: FR1 DB"
else
   echo -e "\$tlconfigfile  ==> Connects to: UK4 DB"
fi

done
EOF

done

# Check Notif

echo -e "\n$(date +%F' '%T) Checking Level 2/3  Notif Servers ..." | tee -a "${log}"

for notifserver in "${notifs_uk_lvl2_main[@]}"
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
  echo -e "==> Sends to: UK4 spool"
else
  echo -e "==> Sends to: FR1 spool"
fi

EOF

done

# Check MO
echo -e "\n$(date +%F' '%T) Checking MO Routers ..." | tee -a "${log}"

for morouter in "${morouters_uk_main[@]}"
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
# Show menu options for UK4 PRODUCTION HUB
# Separate options for MT/Notif and MO
# Globals:
#   None
# Arguments:
#   None
#######################################################################

function  f_switch_uk_hub {

echo -e "==> UK4 PRODUCTION HUB\n"

local options=("Set MT (DTW,TL) & NOTIF-1-2-3 ==> to UK4 DB"
               "Set MT (DTW,TL) & NOTIF-1-2-3 ==> to FR1 DB"
			   
			   "Set MO ==> to UK4 DB"
               "Set MO ==> to FR1 DB"

               "Set SELECTED Ticket Logger (TL) ==> to UK4 DB"
               "Set SELECTED Ticket Logger (TL) ==> to FR1 DB"
						   
               "Set Level 2-3 NOTIF ==> to UK4 DB"
               "Set Level 2-3 NOTIF ==> to FR1 DB"

               "CHECK PROCESS STATUS"

               "EXIT")

select action in "${options[@]}"
do

case $REPLY in

        1)      f_switch "MT" "UK" "${mtrouters_uk_main[@]}"
				f_switch "TL" "UK" "${tloggers_uk_main[@]}"         
				f_switch "NOTIF" "UK" "${notifs_uk_lvl2_main[@]}"
                f_anykey
                break ;;

        2)      f_switch "MT" "FR" "${mtrouters_uk_main[@]}"
				f_switch "TL" "FR" "${tloggers_uk_main[@]}"         
				f_switch "NOTIF" "FR" "${notifs_uk_lvl2_main[@]}"
                f_anykey
                break ;;

        3)      f_switch "MO" "UK" "${morouters_uk_main[@]}"
                f_anykey
                break ;;

		4)      f_switch "MO" "FR" "${morouters_uk_main[@]}"
                f_anykey
                break ;;

        5)      f_switch_selected_tl "UK"
                f_anykey
                break ;;

        6)      f_switch_selected_tl "FR"
                f_anykey
                break ;;

        7)      f_switch "NOTIF" "UK" "${notifs_uk_lvl2_main[@]}"
                f_anykey
                break ;;

        8)      f_switch "NOTIF" "FR" "${notifs_uk_lvl2_main[@]}"
                f_anykey
                break ;;

        9)      f_check_status
                f_anykey
                break ;;

       10)      echo -e "\nOperation Cancelled.\n"
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

f_switch_uk_hub

}

# Execute the main menu
echo -e "\n$(date +%F' '%T) ==> START execution of script by $(whoami) \n" | tee -a "${log}"
clear

show_main_menu;
