#!/bin/bash

# List of configuration files
dtwconf="/opt/HUB/dtw_spoolmanager/conf/spoolConfig.xml"

# List of log files
dtwlog="/opt/HUB/log/SpoolManager.log"

# Other properties
host=$1
switchtodb=$2
log=/opt/HUB/log/$(basename $0 .sh)_"$host".log

# Functions for MT Routers

#######################################################################
# Update configuration in MT Router Apps to connect to UK4 Database
# - JMTRouter
# - dtw_spoolmanager
# - sock_mv client
# Globals:
#   Config file names
#   - JMTRouter - mtrouter.properties
#   - dtw_spoolmanager - SpoolConfig.xml
#   - sock_mv client - sock_mv-notif_lvl1.ini
# Arguments:
#   List of servers
#######################################################################

function f_mtrouter_switch2ukdb {

echo -e "\n$(date +%F' '%T) ==> START Switching MT applications in [$host] to UK4 DB\n" >> "${log}"

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking dtw_spoolmanager ..."

dtwdbfr=\$(grep "fr1a2pasedbvcs:5000/a2p_msgdb_fr1" $dtwconf | wc -l)
dtwcurdb=\$(grep "jdbc:sybase:Tds:uk4a2pasedbvcs:5000/a2p_msgdb_uk4" $dtwlog | tail -n1 | wc -l)
restartdtw=0

if [[ \$dtwdbfr -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating dtw_spoolmanager config to connect to UK4 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@g' $dtwconf 2>&1
  restartdtw=1
elif [[ \$dtwcurdb -eq 0 ]]
then
  restartdtw=1
else
  echo -e "\$(date +%F' '%T) dtw_spoolmanager already connecting to UK4 DB"
fi

dtwnotrunning=\$(lc nok | grep dtw_spoolmanager | wc -l)
if [[ \$dtwnotrunning -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) dtw_spoolmanager is NOT running. Restarting now ..."
  lc restart dtw_spoolmanager
fi

if [[ \$restartdtw -eq 1 ]]
then
  dtwpid=\$(pgrep SpoolManager -f)
  echo -e "\$(date +%F' '%T) Stopping dtw_spoolmanager and sleeping 10 seconds ..."
  lc stop dtw_spoolmanager
  sleep 10
  dtwrunning=\$(pgrep SpoolManager -f | wc -l)
    if [[ \$dtwrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL dtw_spoolmanager with PID: \$dtwpid ..."
        kill -9 \$dtwpid
    fi
  echo -e "\$(date +%F' '%T) Restarting dtw_spoolmanager ..."
  lc restart dtw_spoolmanager
fi

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching MT applications in [$host] to UK4 DB" >> "${log}"

}

#######################################################################
# Update configuration in MT Router Apps to connect to FR1 Database
# - JMTRouter
# - dtw_spoolmanager
# - sock_mv client
# Globals:
#   Config file names
#   - JMTRouter - mtrouter.properties
#   - dtw_spoolmanager - SpoolConfig.xml
#   - sock_mv client - sock_mv-notif_lvl1.ini
# Arguments:
#   List of servers
#######################################################################

function f_mtrouter_switch2frdb {

echo -e "\n$(date +%F' '%T) ==> START Switching MT applications in [$host] to FR1 DB\n" >> "${log}"

ssh -T production1@$host /bin/bash <<EOF >> "${log}" 2>&1

export PATH=\$PATH:/opt/HUB/bin

echo -e "\n\$(date +%F' '%T) Checking dtw_spoolmanager ..."

dtwdbuk=\$(grep "uk4a2pasedbvcs:5000/a2p_msgdb_uk4" $dtwconf | wc -l)
dtwcurdb=\$(grep "jdbc:sybase:Tds:fr1a2pasedbvcs:5000/a2p_msgdb_fr1" $dtwlog | tail -n1 | wc -l)
restartdtw=0

if [[ \$dtwdbuk -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating dtw_spoolmanager config to connect to FR1 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@uk4a2pasedbvcs:5000/a2p_msgdb_uk4@fr1a2pasedbvcs:5000/a2p_msgdb_fr1@g' $dtwconf 2>&1
  restartdtw=1
elif [[ \$dtwcurdb -eq 0 ]]
then
  restartdtw=1
else
  echo -e "\$(date +%F' '%T) dtw_spoolmanager already connecting to FR1 DB"
fi

dtwnotrunning=\$(lc nok | grep dtw_spoolmanager | wc -l)
if [[ \$dtwnotrunning -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) dtw_spoolmanager is NOT running. Restarting now ..."
  lc restart dtw_spoolmanager
fi

if [[ \$restartdtw -eq 1 ]]
then
  dtwpid=\$(pgrep SpoolManager -f)
  echo -e "\$(date +%F' '%T) Stopping dtw_spoolmanager and sleeping 10 seconds ..."
  lc stop dtw_spoolmanager
  sleep 10
  dtwrunning=\$(pgrep SpoolManager -f | wc -l)
    if [[ \$dtwrunning -eq 1 ]]
    then
    echo -e "\$(date +%F' '%T) Force KILL dtw_spoolmanager with PID: \$dtwpid ..."
        kill -9 \$dtwpid
    fi
  echo -e "\$(date +%F' '%T) Restarting dtw_spoolmanager ..."
  lc restart dtw_spoolmanager
fi

EOF

echo -e "\n$(date +%F' '%T) ==> COMPLETED Switching MT applications in [$host] to FR1 DB" >> "${log}"

}

function showusage {
echo
echo "Usage: $0 mtrouter_hostname db_to_switch_to"
echo "Eg: To switch fr1mtrouter001 to UK database : $0 fr1mtrouter001 UK"
echo
exit 1
}

if [[ $# -lt 2 ]];then
showusage
fi


if [[ "$switchtodb" == "FR" ]]
then
  f_mtrouter_switch2frdb
elif [[ "$switchtodb" == "UK" ]]
then
  f_mtrouter_switch2ukdb
else
  echo -e "\nInvalid Database switch!\n"
  exit 1
fi
