#!/bin/bash

# List of configuration files
mtconf="/opt/HUB/MTRouter/conf/mtrouter.properties"
dtwconf="/opt/HUB/dtw_spoolmanager/conf/spoolConfig.xml"
notifl1sockconf="/opt/HUB/etc/sock_mv-notif_lvl1.ini"
notifl2filterconf="/opt/HUB/ixng-a2pjmstools/etc/Notif_Filter.properties"
moconf="/opt/HUB/etc/asepwd.ini"

# List of log files
mtlog="/opt/HUB/log/mtrouter.log"
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

echo -e "\$(date +%F' '%T) Checking JMTRouter ..."

mtdbfr=\$(grep "us2a2pasedb001.lab:5000/a2p_msgdb_fr1" $mtconf | wc -l)
mtcurdb=\$(grep "sybase:Tds:us2a2pasedb002.lab" $mtlog | tail -n1 | wc -l)
restartmt=0

if [[ \$mtdbfr -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating JMTRouter config to connect to UK4 DB"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@g' $mtconf 2>&1
  restartmt=1
elif [[ \$mtcurdb -eq 0 ]]
then
  restartmt=1
else
  echo -e "\$(date +%F' '%T) JMTRouter already connecting to UK4 DB"
fi


echo -e "\n\$(date +%F' '%T) Checking dtw_spoolmanager ..."

dtwdbfr=\$(grep "us2a2pasedb001.lab:5000/a2p_msgdb_fr1" $dtwconf | wc -l)
dtwcurdb=\$(grep "jdbc:sybase:Tds:us2a2pasedb002.lab:5000/a2p_msgdb_uk4" $dtwlog | tail -n1 | wc -l)
restartdtw=0

if [[ \$dtwdbfr -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating dtw_spoolmanager config to connect to UK4 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@g' $dtwconf 2>&1
  restartdtw=1
elif [[ \$dtwcurdb -eq 0 ]]
then
  restartdtw=1
else
  echo -e "\$(date +%F' '%T) dtw_spoolmanager already connecting to UK4 DB"
fi


echo -e "\n\$(date +%F' '%T) Checking Sock MV Client - Level 1 NOTIF ..."

sockmvfr=\$(grep "updatemtnotif/inputspool" $notifl1sockconf | wc -l)
restartsockmv=0

if [[ \$sockmvfr -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating Sock MV Client - Level 1 NOTIF config to UK4 spool\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif/inputspool@updatemtnotif_uk/inputspool@g' $notifl1sockconf 2>&1
  restartsockmv=1
else
  echo -e "\$(date +%F' '%T) Sock MV Client - Level 1 NOTIF already sending to UK4 spool"
fi



mtnotrunning=\$(lc nok | grep JMTRouter | wc -l)
if [[ \$mtnotrunning -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) JMTRouter is NOT running. Restarting now ..."
  lc restart JMTRouter
fi

dtwnotrunning=\$(lc nok | grep dtw_spoolmanager | wc -l)
if [[ \$dtwnotrunning -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) dtw_spoolmanager is NOT running. Restarting now ..."
  lc restart dtw_spoolmanager
fi

for smvprocess in \$(lc nok | grep "sock.*notif" | awk '{print \$1}');
do
  echo -e "\$(date +%F' '%T) \$smvprocess is NOT running. Restarting now ...\n" 
  lc restart \$smvprocess
done

if [[ \$restartmt -eq 1 ]]
then
  mtpid=\$(pgrep MTRouter -f)
  echo -e "\$(date +%F' '%T) Stopping JMTRouter and sleeping 10 seconds ..."
  lc stop JMTRouter
  sleep 10
  mtrunning=\$(pgrep MTRouter -f | wc -l)
    if [[ \$mtrunning -eq 1 ]]
    then
	echo -e "\$(date +%F' '%T) Force KILL JMTRouter with PID: \$mtpid ..."
    kill -9 \$mtpid
    fi
  echo -e "\$(date +%F' '%T) Restarting JMTRouter ..."
  lc restart JMTRouter
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

if [[ \$restartsockmv -eq 1 ]]
then
  for smvprocess in \$(lc status 2>/dev/null | grep "sock.*notif" | awk '{print \$1}')
  do
    smvpid=\$(lc status 2>/dev/null | grep \$smvprocess | awk '{print \$2}')
    echo -e "\$(date +%F' '%T) Stopping \$smvprocess and sleeping 5 seconds ..."
	lc stop \$smvprocess
	sleep 5
	smvrunning=\$(ps -p \$smvpid | sed 1d | wc -l)
      if [[ \$smvrunning -eq 1 ]]
      then
      echo -e "\$(date +%F' '%T) Force KILL \$smvprocess with PID: \$smvpid ..."
	  kill -9 \$smvpid
      fi
	echo -e "\$(date +%F' '%T) Restarting \$smvprocess ..."
	lc restart \$smvprocess
	done
fi

echo -e "\n\$(date +%F' '%T) Executing MT resend_db_error script ..."
/opt/HUB/scripts/resend_db_error.pl /opt/HUB/router/error/default /opt/HUB/router/inputspool >> /opt/HUB/log/resend_db_error.log 2>&1 &

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

echo -e "\$(date +%F' '%T) Checking JMTRouter ..."

mtdbuk=\$(grep "us2a2pasedb002.lab:5000/a2p_msgdb_uk4" $mtconf | wc -l)
mtcurdb=\$(grep "sybase:Tds:us2a2pasedb001.lab" $mtlog | tail -n1 | wc -l)
restartmt=0

if [[ \$mtdbuk -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating JMTRouter config to connect to FR1 DB"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@g' $mtconf 2>&1
  restartmt=1
elif [[ \$mtcurdb -eq 0 ]]
then
  restartmt=1
else
  echo -e "\$(date +%F' '%T) JMTRouter already connecting to FR1 DB"
fi


echo -e "\n\$(date +%F' '%T) Checking dtw_spoolmanager ..."

dtwdbuk=\$(grep "us2a2pasedb002.lab:5000/a2p_msgdb_uk4" $dtwconf | wc -l)
dtwcurdb=\$(grep "jdbc:sybase:Tds:us2a2pasedb001.lab:5000/a2p_msgdb_fr1" $dtwlog | tail -n1 | wc -l)
restartdtw=0

if [[ \$dtwdbuk -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating dtw_spoolmanager config to connect to FR1 DB\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@us2a2pasedb002.lab:5000/a2p_msgdb_uk4@us2a2pasedb001.lab:5000/a2p_msgdb_fr1@g' $dtwconf 2>&1
  restartdtw=1
elif [[ \$dtwcurdb -eq 0 ]]
then
  restartdtw=1
else
  echo -e "\$(date +%F' '%T) dtw_spoolmanager already connecting to FR1 DB"
fi


echo -e "\n\$(date +%F' '%T) Checking Sock MV Client - Level 1 NOTIF ..."

sockmvuk=\$(grep "updatemtnotif_uk/inputspool" $notifl1sockconf | wc -l)
restartsockmv=0

if [[ \$sockmvuk -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) Updating Sock MV Client - Level 1 NOTIF config to FR1 spool\n"
  sed -i.\$(date +%Y%m%d%H%M%S) 's@updatemtnotif_uk/inputspool@updatemtnotif/inputspool@g' $notifl1sockconf 2>&1
  restartsockmv=1
else
  echo -e "\$(date +%F' '%T) Sock MV Client - Level 1 NOTIF already sending to FR1 spool"
fi



mtnotrunning=\$(lc nok | grep JMTRouter | wc -l)
if [[ \$mtnotrunning -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) JMTRouter is NOT running. Restarting now ..."
  lc restart JMTRouter
fi

dtwnotrunning=\$(lc nok | grep dtw_spoolmanager | wc -l)
if [[ \$dtwnotrunning -eq 1 ]]
then
  echo -e "\$(date +%F' '%T) dtw_spoolmanager is NOT running. Restarting now ..."
  lc restart dtw_spoolmanager
fi

for smvprocess in \$(lc nok | grep "sock.*notif" | awk '{print \$1}');
do
  echo -e "\$(date +%F' '%T) \$smvprocess is NOT running. Restarting now ...\n" 
  lc restart \$smvprocess
done

if [[ \$restartmt -eq 1 ]]
then
  mtpid=\$(pgrep MTRouter -f)
  echo -e "\$(date +%F' '%T) Stopping JMTRouter and sleeping 10 seconds ..."
  lc stop JMTRouter
  sleep 10
  mtrunning=\$(pgrep MTRouter -f | wc -l)
    if [[ \$mtrunning -eq 1 ]]
    then
	echo -e "\$(date +%F' '%T) Force KILL JMTRouter with PID: \$mtpid ..."
    kill -9 \$mtpid
    fi
  echo -e "\$(date +%F' '%T) Restarting JMTRouter ..."
  lc restart JMTRouter
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

if [[ \$restartsockmv -eq 1 ]]
then
  for smvprocess in \$(lc status 2>/dev/null | grep "sock.*notif" | awk '{print \$1}')
  do
    smvpid=\$(lc status 2>/dev/null | grep \$smvprocess | awk '{print \$2}')
    echo -e "\$(date +%F' '%T) Stopping \$smvprocess and waiting 5 seconds ..."
	lc stop \$smvprocess
	sleep 5
	smvrunning=\$(ps -p \$smvpid | sed 1d | wc -l)
      if [[ \$smvrunning -eq 1 ]]
      then
      echo -e "\$(date +%F' '%T) Force KILL \$smvprocess with PID: \$smvpid ..."
	  kill -9 \$smvpid
      fi
	echo -e "\$(date +%F' '%T) Restarting \$smvprocess ..."
	lc restart \$smvprocess
	done
fi

echo -e "\n\$(date +%F' '%T) Executing MT resend_db_error script ..."
/opt/HUB/scripts/resend_db_error.pl /opt/HUB/router/error/default /opt/HUB/router/inputspool >> /opt/HUB/log/resend_db_error.log 2>&1 &

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

