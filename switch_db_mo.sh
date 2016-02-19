#!/bin/bash

# List of configuration files
moconf="/opt/HUB/etc/asepwd.ini"

# Other properties
host=$1
switchtodb=$2
log=/opt/HUB/log/$(basename $0 .sh)_"$host".log

# Functions for MO Routers

#######################################################################
# Update configuration in MO Routers to connect to UK4 Database
# Globals:
#   Name of ASE password file used by mosendsmsinterface processes
# Arguments:
#   List of servers
#######################################################################

function f_morouter_switch2ukdb {

echo -e "\n$(date +%F' '%T) ==> START Switching MO applications in [$host] to UK4 DB"  >> "${log}" 2>&1

ssh -T production1@$host /bin/bash <<EOF  >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin:/opt/HUB/lance

echo -e "\n\$(date +%F' '%T) Checking MO Router ..."

modbfr=\$(grep "^HUBMO=DTSA2PFR2\$" $moconf | wc -l) 2>&1
restartmo=0
if [[ \$modbfr -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating MO Router config to connect to UK4 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@^HUBMO=DTSA2PFR2\$@HUBMO=DTSA2PUK2@g' $moconf 2>&1
  restartmo=1
else
  echo -e "\$(date +%F' '%T) MO Router already connecting to FR1 DB"
fi

for moprocess in \$(lc nok 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}');
do
  echo -e "\$(date +%F' '%T) \$moprocess is NOT running. Restarting now ..."
  lc restart \$moprocess
done

if [[ \$restartmo -eq 1 ]]
then
  for moprocess in \$(lc status 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}')
  do
    mopid=\$(lc status 2>/dev/null | grep \$moprocess | awk '{print \$2}')
    echo -e "\$(date +%F' '%T) Stopping \$moprocess and waiting 5 seconds ..."
	lc stop \$moprocess
	sleep 5
	morunning=\$(ps -p \$mopid | sed 1d | wc -l)
      if [[ \$morunning -eq 1 ]]
      then
      echo -e "\$(date +%F' '%T) Force KILL \$moprocess with PID: \$mopid ..."
	  kill -9 \$mopid
      fi
	echo -e "\$(date +%F' '%T) Restarting \$moprocess ..."
	lc restart \$moprocess
	done
fi  
  
echo -e "\n\$(date +%F' '%T) Executing MO DB error re-process script ..."
/opt/HUB/scripts/dberror_reprocess_cron.sh >> /opt/mobileway/log/dberror_reprocess_cron.log 2>&1 &

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching MO applications in [$host] to UK4 DB"  >> "${log}" 2>&1

}

#######################################################################
# Update configuration in MO Routers to connect to FR1 Database
# Globals:
#   Name of ASE password file used by mosendsmsinterface processes
# Arguments:
#   List of servers
#######################################################################

function f_morouter_switch2frdb {

echo -e "\n$(date +%F' '%T) ==> START Switching MO applications in [$host] to FR1 DB"  >> "${log}" 2>&1

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin:/opt/HUB/lance

echo -e "\n\$(date +%F' '%T) Checking MO Router ..."

modbuk=\$(grep "^HUBMO=DTSA2PUK2\$" $moconf | wc -l) 2>&1
restartmo=0
if [[ \$modbuk -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating MO Router config to connect to FR1 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@^HUBMO=DTSA2PUK2\$@HUBMO=DTSA2PFR2@g' $moconf 2>&1
  restartmo=1
else
  echo -e "\$(date +%F' '%T) MO Router already connecting to UK4 DB"
fi

for moprocess in \$(lc nok 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}');
do
  echo -e "\$(date +%F' '%T) \$moprocess is NOT running. Restarting now ..."
  lc restart \$moprocess
done

if [[ \$restartmo -eq 1 ]]
then
  for moprocess in \$(lc status 2>/dev/null | grep "mosendsmsinterface" | awk '{print \$1}')
  do
    mopid=\$(lc status 2>/dev/null | grep \$moprocess | awk '{print \$2}')
    echo -e "\$(date +%F' '%T) Stopping \$moprocess and waiting 5 seconds ..."
	lc stop \$moprocess
	sleep 5
	morunning=\$(ps -p \$mopid | sed 1d | wc -l)
      if [[ \$morunning -eq 1 ]]
      then
      echo -e "\$(date +%F' '%T) Force KILL \$moprocess with PID: \$mopid ..."
	  kill -9 \$mopid
      fi
	echo -e "\$(date +%F' '%T) Restarting \$moprocess ..."
	lc restart \$moprocess
	done
fi  
  
echo -e "\n\$(date +%F' '%T) Executing MO DB error re-process script ..."
/opt/HUB/scripts/dberror_reprocess_cron.sh >> /opt/mobileway/log/dberror_reprocess_cron.log 2>&1 &

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching MO applications in [$host] to FR1 DB"  >> "${log}" 2>&1

}

function showusage {
echo
echo "Usage: $0 morouter_hostname db_to_switch_to"
echo "Eg: To switch fr1morouter001 to UK database : $0 fr1morouter001 UK"
echo
exit 1
}

if [[ $# -lt 2 ]];then
showusage
fi


if [[ "$switchtodb" == "FR" ]]
then
  f_morouter_switch2frdb
elif [[ "$switchtodb" == "UK" ]]
then
  f_morouter_switch2ukdb
else
  echo -e "\nInvalid Database switch!\n"
  exit 1
fi
