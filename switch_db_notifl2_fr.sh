#!/bin/bash

# List of configuration files

notifl2filterconf="/opt/HUB/ixng-a2pjmstools/etc/Notif_Filter.properties"


host=$1

switchtodb=$2

log=/opt/HUB/log/$(basename $0 .sh)_"$host".log

# Functions for Notifs

#######################################################################
# Update configuration in Notif Level 2/3 Server Notif Filter
# to switch output path to input spool of updatemtnotif processes
# connecting to UK4 Database
# Globals:
#   Config file name of Notif Filter
# Arguments:
#   List of servers
#######################################################################

function f_notiflvl2_switch2ukdb {

echo -e "\n$(date +%F' '%T) ==> START Switching Level 2/3 Notif Filter in [$host] to UK4 Spool Directory\n" >> "${log}" 2>&1

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking Level 2/3 Notif Filter ..."

nfsinkpathfr=\$(grep "^sink.spool.path = /opt/HUB/NOTIF/updatemtnotif\$" $notifl2filterconf | wc -l) 2>&1
restartnf=0
if [[ \$nfsinkpathfr -eq 1 ]]
then
  echo -e "\nUpdating Notif_Filter sink spool directory to UK4\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@path = /opt/HUB/NOTIF/updatemtnotif\$@path = /opt/HUB/NOTIF/updatemtnotif_uk@g' $notifl2filterconf 2>&1
  restartnf=1
else
 echo -e "\$(date +%F' '%T) Level 2/3 Notif_Filter already sending to UK4 spool directory"
fi

nfnotrunning=\$(lc nok | grep Notif_Filter | wc -l)
if [[ \$nfnotrunning -eq 1 ]]
then
 echo -e "\$(date +%F' '%T) Notif_Filter is NOT running"
 lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
 if [[ \$lockfile -eq 1 ]]
 then
    echo -e "\$(date +%F' '%T) Removing .lock file in Notif_Filter inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
  fi
  lc restart Notif_Filter
fi

if [[ \$restartnf -eq 1 ]]
then
  nfpid=\$(pgrep Notif_Filter -f)
  echo -e "\$(date +%F' '%T) Stopping Notif_Filter and sleeping 10 seconds ..."
  lc stop Notif_Filter
  sleep 10
  nfrunning=\$(pgrep Notif_Filter -f | wc -l)
    if [[ \$nfrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL Notif_Filter with PID: \$nfpid ..."
        kill -9 \$nfpid
    fi

  lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
    if [[ \$lockfile -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Removing .lock file in Notif_Filter inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
    fi

  echo -e "\$(date +%F' '%T) Restarting Notif_Filter ..."
  lc restart Notif_Filter

fi

lc reconf

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching Level 2/3 Notif Filter in [$host] to UK4 Spool Directory\n" >> "${log}" 2>&1


}

#######################################################################
# Update configuration in Notif Level 2/3 Server Notif Filter
# to switch output path to input spool of updatemtnotif processes
# connecting to FR1 Database
# Globals:
#   Config file name of Notif Filter
# Arguments:
#   List of servers
#######################################################################


function f_notiflvl2_switch2frdb {

echo -e "\n$(date +%F' '%T) ==> START Switching Level 2/3 Notif Filter in [$host] to FR1 Spool Directory\n" >> "${log}" 2>&1

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking Level 2/3 Notif Filter ..."

nfsinkpathuk=\$(grep "^sink.spool.path = /opt/HUB/NOTIF/updatemtnotif_uk\$" $notifl2filterconf | wc -l) 2>&1
restartnf=0
if [[ \$nfsinkpathuk -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating Notif_Filter sink spool directory to FR1\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@path = /opt/HUB/NOTIF/updatemtnotif_uk\$@path = /opt/HUB/NOTIF/updatemtnotif@g' $notifl2filterconf 2>&1
  restartnf=1
else
  echo -e "\$(date +%F' '%T) Notif_Filter already sending to FR1 spool directory"
fi

nfnotrunning=\$(lc nok | grep Notif_Filter | wc -l)
if [[ \$nfnotrunning -eq 1 ]]
then
 echo -e "\$(date +%F' '%T) Notif_Filter is NOT running"
 lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
 if [[ \$lockfile -eq 1 ]]
 then
    echo -e "\$(date +%F' '%T) Removing .lock file in Notif_Filter inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
  fi
  lc restart Notif_Filter
fi

if [[ \$restartnf -eq 1 ]]
then
  nfpid=\$(pgrep Notif_Filter -f)
  echo -e "\$(date +%F' '%T) Stopping Notif_Filter and sleeping 10 seconds ..."
  lc stop Notif_Filter
  sleep 10
  nfrunning=\$(pgrep Notif_Filter -f | wc -l)
    if [[ \$nfrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL Notif_Filter with PID: \$nfpid ..."
        kill -9 \$nfpid
    fi

  lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
    if [[ \$lockfile -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Removing .lock file in Notif_Filter inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
    fi

  echo -e "\$(date +%F' '%T) Restarting Notif_Filter ..."
  lc restart Notif_Filter
fi

lc reconf

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching Level 2/3 Notif Filter in [$host] to FR1 Spool Directory\n" >> "${log}" 2>&1

}


function showusage {
echo
echo "Usage: $0 notifserver_hostname db_to_switch_to"
echo "Eg: To switch fr1notif005 to UK database : $0 fr1notif005 uk"
echo
exit 1
}

if [[ $# -lt 2 ]];then
showusage
fi


if [[ "$switchtodb" == "FR" ]]
then
  f_notiflvl2_switch2frdb
elif [[ "$switchtodb" == "UK" ]]
then
  f_notiflvl2_switch2ukdb
else
  echo -e "\nInvalid Database switch!\n"
  exit 1
fi
