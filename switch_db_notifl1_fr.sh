#!/bin/bash

# List of configuration files



host=$1

switchtodb=$2

type=$3

jms2filenotifl1_conf="/opt/HUB/ixng-a2pjmstools-1.3.0/etc/jms2file-notiflvl1.properties"

if [[ "${type}" == "CAMPAIGN" ]];then
jms2filenotifl1_conf="/opt/HUB/ixng-a2pjmstools-1.3.0/etc/jms2file-camp-notiflvl1.properties"
fi

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

function f_notiflvl1_switch2ukdb {

echo -e "\n$(date +%F' '%T) ==> START Switching JMS to File - Notif Level 1 in [$host] to UK4 Spool Directory\n" >> "${log}" 2>&1

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking JMS to File - Notif Level 1 ..."

nfsinkpathfr=\$(grep "orderid \^1.*updatemtnotif/" $jms2filenotifl1_conf | wc -l) 2>&1
restartnf=0
if [[ \$nfsinkpathfr -eq 1 ]]
then
  echo -e "\nUpdating JMS to File - Notif Level 1 sink spool directory to UK4\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif/@updatemtnotif_uk/@g' $jms2filenotifl1_conf 2>&1
  restartnf=1
else
 echo -e "\$(date +%F' '%T) JMS to File - Notif Level 1 already sending to UK4 spool directory"
fi

nfnotrunning=\$(lc nok | grep "jms2file.*notiflvl1" | wc -l)
if [[ \$nfnotrunning -ge 1 ]]
then
 echo -e "\$(date +%F' '%T) JMS to File - Notif Level 1 is NOT running"
 lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
 if [[ \$lockfile -eq 1 ]]
 then
    echo -e "\$(date +%F' '%T) Removing .lock file in JMS to File - Notif Level 1 inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
  fi
  
  if [[ ${type} == "CAMPAIGN" ]];then 
  lc restart jms2file-camp-notiflvl1
  else
  lc restart jms2file-notiflvl1
  fi
  
fi

if [[ \$restartnf -eq 1 ]]
then

if [[ ${type} == "CAMPAIGN" ]];then 
  nfpid=\$(pgrep -f jms2file-camp-notiflvl1)
  echo -e "\$(date +%F' '%T) Stopping JMS to File - Notif Level 1 (camp) and sleeping 10 seconds ..."
  lc stop jms2file-camp-notiflvl1
  sleep 10
  nfrunning=\$(pgrep -f jms2file-camp-notiflvl1 | wc -l)
    if [[ \$nfrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL JMS to File - Notif Level 1 (camp) with PID: \$nfpid ..."
        kill -9 \$nfpid
    fi
else
  nfpid=\$(pgrep -f jms2file-notiflvl1)
  echo -e "\$(date +%F' '%T) Stopping JMS to File - Notif Level 1 and sleeping 10 seconds ..."
  lc stop jms2file-notiflvl1
  sleep 10
  nfrunning=\$(pgrep -f jms2file-notiflvl1 | wc -l)
    if [[ \$nfrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL JMS to File - Notif Level 1 with PID: \$nfpid ..."
        kill -9 \$nfpid
    fi
fi

  lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
    if [[ \$lockfile -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Removing .lock file in JMS to File - Notif Level 1 inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
    fi
  
  if [[ ${type} == "CAMPAIGN" ]];then 
  echo -e "\$(date +%F' '%T) Restarting JMS to File - Notif Level 1 (camp) ..."
  lc restart jms2file-camp-notiflvl1
  else
  echo -e "\$(date +%F' '%T) Restarting JMS to File - Notif Level 1 ..."
  lc restart jms2file-notiflvl1
  fi
  
fi

lc reconf

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching JMS to File - Notif Level 1 in [$host] to UK4 Spool Directory\n" >> "${log}" 2>&1


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


function f_notiflvl1_switch2frdb {

echo -e "\n$(date +%F' '%T) ==> START Switching JMS to File - Notif Level 1 in [$host] to FR1 Spool Directory\n" >> "${log}" 2>&1

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking JMS to File - Notif Level 1 ..."

nfsinkpathuk=\$(grep "orderid \^1.*updatemtnotif_uk/" $jms2filenotifl1_conf | wc -l) 2>&1
restartnf=0
if [[ \$nfsinkpathuk -eq 1 ]]
then
  echo -e "\nUpdating JMS to File - Notif Level 1 sink spool directory to FR1\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif_uk/@updatemtnotif/@g' $jms2filenotifl1_conf 2>&1
  restartnf=1
else
 echo -e "\$(date +%F' '%T) JMS to File - Notif Level 1 already sending to FR1 spool directory"
fi

nfnotrunning=\$(lc nok | grep "jms2file.*notiflvl1" | wc -l)
if [[ \$nfnotrunning -ge 1 ]]
then
 echo -e "\$(date +%F' '%T) JMS to File - Notif Level 1 is NOT running"
 lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
 if [[ \$lockfile -eq 1 ]]
 then
    echo -e "\$(date +%F' '%T) Removing .lock file in JMS to File - Notif Level 1 inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
  fi
  
  if [[ ${type} == "CAMPAIGN" ]];then 
  lc restart jms2file-camp-notiflvl1
  else
  lc restart jms2file-notiflvl1
  fi
  
fi

if [[ \$restartnf -eq 1 ]]
then

if [[ ${type} == "CAMPAIGN" ]];then 
  nfpid=\$(pgrep -f jms2file-camp-notiflvl1)
  echo -e "\$(date +%F' '%T) Stopping JMS to File - Notif Level 1 (camp) and sleeping 10 seconds ..."
  lc stop jms2file-camp-notiflvl1
  sleep 10
  nfrunning=\$(pgrep -f jms2file-camp-notiflvl1 | wc -l)
    if [[ \$nfrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL JMS to File - Notif Level 1 (camp) with PID: \$nfpid ..."
        kill -9 \$nfpid
    fi
else
  nfpid=\$(pgrep -f jms2file-notiflvl1)
  echo -e "\$(date +%F' '%T) Stopping JMS to File - Notif Level 1 and sleeping 10 seconds ..."
  lc stop jms2file-notiflvl1
  sleep 10
  nfrunning=\$(pgrep -f jms2file-notiflvl1 | wc -l)
    if [[ \$nfrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL JMS to File - Notif Level 1 with PID: \$nfpid ..."
        kill -9 \$nfpid
    fi
fi

  lockfile=\$(find /opt/HUB/NOTIF/updatemtnotif/inputspool/ -type f -name ".lock" | wc -l)
    if [[ \$lockfile -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Removing .lock file in JMS to File - Notif Level 1 inputspool ..."
        rm -v /opt/HUB/NOTIF/updatemtnotif/inputspool/.lock
    fi
  
  if [[ ${type} == "CAMPAIGN" ]];then 
  echo -e "\$(date +%F' '%T) Restarting JMS to File - Notif Level 1 (camp) ..."
  lc restart jms2file-camp-notiflvl1
  else
  echo -e "\$(date +%F' '%T) Restarting JMS to File - Notif Level 1 ..."
  lc restart jms2file-notiflvl1
  fi
  
fi

lc reconf

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching JMS to File - Notif Level 1 in [$host] to FR1 Spool Directory\n" >> "${log}" 2>&1

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
  f_notiflvl1_switch2frdb
elif [[ "$switchtodb" == "UK" ]]
then
  f_notiflvl1_switch2ukdb
else
  echo -e "\nInvalid Database switch!\n"
  exit 1
fi
