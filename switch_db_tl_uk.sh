#!/bin/bash

# Other properties
host=$1
switchtodb=$2
log=/opt/HUB/log/$(basename $0 .sh)_"$host".log

# Functions for Ticket Logger

#######################################################################
# Update configuration in Ticket Logger Apps to connect to UK4 Database
# Arguments:
#   List of servers
#
#######################################################################

function f_tlogger_switch2ukdb {

echo -e "\n$(date +%F' '%T) ==> START Switching Ticket Logger applications in [$host] to UK4 DB\n" >> "${log}"

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking ticket-logger ..."

tlconfigfiles=(\$(find /opt/HUB/ticket-logger/conf/ -type f -name "ticket*properties"))

for tlconfigfile in  \${tlconfigfiles[@]}
do
  echo -e "\$(date +%F' '%T) Updating \$tlconfigfile to connect to UK4 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@g' \$tlconfigfile 2>&1
done

for tlprocess in \$(grep "^\[ticketlogger" /opt/HUB/etc/lance.ini | sed 's/\(\[\|\]\)//g')
do
tlpid=\$(lc status 2>/dev/null | grep "\$tlprocess " | awk '{print \$2}')

if [[ ! -z "\$tlpid" ]]
then
echo -e "\$(date +%F' '%T) Stopping \$tlprocess and sleeping 5 seconds ..."
lc stop \$tlprocess
sleep 5
tlrunning=\$(ps -p \$tlpid | sed 1d | wc -l)
  if [[ \$tlrunning -eq 1 ]]
  then
  echo -e "\$(date +%F' '%T) Force KILL \$tlprocess with PID: \$tlpid ..."
  kill -9 \$tlpid
  fi
else
echo -e "\$(date +%F' '%T) Process: \$tlprocess is NOT running!"
fi
echo -e "\$(date +%F' '%T) Restarting \$tlprocess ..."
lc restart \$tlprocess
done

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching Ticket Logger applications in [$host] to UK4 DB" >> "${log}"

}

#######################################################################
# Update configuration in Ticket Logger Apps to connect to FR Database
# Arguments:
#   List of servers
#
#######################################################################

function f_tlogger_switch2frdb {

echo -e "\n$(date +%F' '%T) ==> START Switching Ticket Logger applications in [$host] to FR1 DB\n" >> "${log}"

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking ticket-logger ..."

tlconfigfiles=(\$(find /opt/HUB/ticket-logger/conf/ -type f -name "ticket*properties"))

for tlconfigfile in  \${tlconfigfiles[@]}
do
  echo -e "\$(date +%F' '%T) Updating \$tlconfigfile to connect to FR1 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@g' \$tlconfigfile 2>&1
done

for tlprocess in \$(grep "^\[ticketlogger" /opt/HUB/etc/lance.ini | sed 's/\(\[\|\]\)//g')
do
tlpid=\$(lc status 2>/dev/null | grep "\$tlprocess " | awk '{print \$2}')

if [[ ! -z "\$tlpid" ]]
then
echo -e "\$(date +%F' '%T) Stopping \$tlprocess and sleeping 5 seconds ..."
lc stop \$tlprocess
sleep 5
tlrunning=\$(ps -p \$tlpid | sed 1d | wc -l)
  if [[ \$tlrunning -eq 1 ]]
  then
  echo -e "\$(date +%F' '%T) Force KILL \$tlprocess with PID: \$tlpid ..."
  kill -9 \$tlpid
  fi
else
echo -e "\$(date +%F' '%T) Process: \$tlprocess is NOT running!"
fi
echo -e "\$(date +%F' '%T) Restarting \$tlprocess ..."
lc restart \$tlprocess

done

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching Ticket Logger applications in [$host] to FR1 DB" >> "${log}"

}

function showusage {
echo
echo "Usage: $0 ticketlogger_hostname db_to_switch_to"
echo "Eg: To switch fr1event001 to UK database : $0 fr1event001 UK"
echo
exit 1
}

if [[ $# -lt 2 ]];then
showusage
fi


if [[ "$switchtodb" == "FR" ]]
then
  f_tlogger_switch2frdb
elif [[ "$switchtodb" == "UK" ]]
then
  f_tlogger_switch2ukdb
else
  echo -e "\nInvalid Database switch!\n"
  exit 1
fi
