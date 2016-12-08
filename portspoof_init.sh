#!/bin/bash -

# Begin $rc_base/init.d/portspoof
# start|stop|restart|status script for Portspoof daemon.
# Portspoof options will be set.
# Sets firewall rules under /etc/sysconfig/firewall.local.
# Includes automatic WAN interface detection.
# Adds syslog entry for Portspoof activity.
# Search for open ports in *INPUT and *NAT chains
# and set the excluded ranges automatically in firewall.local into a for loop.
# If Portspoofs port is used by another program, you will be warned.
#
# $author: ummeegge ; $date: 2016-11.07 10:49:32
###############################################################################

. /etc/sysconfig/rc
. $rc_functions

## Iface searcher by Timmothy Wilson
ifstat | grep ppp0 2> /dev/null > /dev/null;
if [ "$?" != "0" ];then
   # no ppp0 interface assigned, it's safe to use red0
   WAN="red0";
else
   # found ppp0 interface, using it...
   WAN="ppp0";
fi;

## Locations
BIN="/usr/bin/portspoof";
CONF="/etc/portspoof";
LOG="/var/log/portspoof/portspoof.log";
FWL="/etc/sysconfig/firewall.local";
LIST="/tmp/.portlist";

#---------------------- Please define here your configuration options ---------------------------
# Portspoof should work out of the box but if you have some specific individual settings,
# you can change it in this section
## Options
# Portspoof options, default runs in daemon mode (-D) and disables syslogging (-d)
OPT="-D -d";
# Interface name will be for WAN side automatically detected.
# Change this onyl if you want to operate Portspoof in your LAN
# On which interface should Portspoof listen (IPFire name definitions are possible) ?
IFACE="${WAN}";
# On which port Portspoof should listen ?
PORT="4444";
#------------------------------------------------------------------------------------------------

## FW functions
# Searcher for start section
STARTFW=$(grep '## Portspoofs FW entries in start' ${FWL} | echo $?);

## Check for working services in *INPUT and *NAT chains
portcollect_funct() {
  # *INPUT chains check
  OP1=$(for i in INPUTFW OVPNINPUT TOR_INPUT IPSECINPUT IPTVINPUT CUSTOMINPUT; do
    iptables -nv -L "${i}" | awk '/dpt:/ { print $11 }' | cut -d':' -f2;
  done);
  # NAT chains check
  OP2=$(iptables -t nat -L -n -v | awk '/dpt:/ { print $11 }' | cut -d':' -f2);
  # Paste and sort ports into list
  USEDPORTS=$(echo "${OP1} ${OP2}");
  echo ${USEDPORTS} | tr ' ' '\n' | sort -n > ${LIST};
}
   
## Port check function
portcheck_funct () {
  # Check for port above 1024
  if [ ${PORT} -le 1024 ]; then
    echo;
    echo -e "\e[31mERROR: Portspoof could not be started. Please use a port above 1024... \e[0m";
    logger -t portspoof "ERROR: portspoof could not be started. Please use a port above 1024... ";
    echo;
    exit 1;
  fi
  # Check for already used ports
  for i in ${LIST}; do
    if [[ -n "$(grep -Fx ${PORT} ${i})" ]]; then
      echo;
      echo -e "\e[31mERROR: Portspoof could not be started. Port ${PORT} is used by another programm, please choose another one... \e[0m";
      logger -t portspoof "ERROR: portspoof could not be started. Port ${PORT} is used by another programm, please choose another one... ";
      echo;
      exit 1;
    fi
  done
}

# The fw* functions investigates open ports by it´s own and set them into firewall.local via a for loop.
# Searcher for stop section
STOPFW=$(grep '\${PORTSPOOF} -t nat -F CUSTOMPREROUTING' ${FWL} | echo $?);
# FW add function
fwadd_main_funct() {
    sed -i '/# Used for private firewall rules/ a\PORTSPOOF="\/sbin\/iptables"' ${FWL}
    sed -i "/## add your 'start' rules here/ a\ \
       # Portspoof log activity to syslog \n \
       \${PORTSPOOF} -A CUSTOMINPUT -i ${IFACE} -p tcp --dport ${PORT} -m limit --limit 2/m -j LOG --log-prefix=\"portspoof: Activity log \" --log-level 1\n \
       # Portspoof open external access \n \
       \${PORTSPOOF} -A CUSTOMINPUT -i ${IFACE} -p tcp --dport ${PORT} -j ACCEPT\n \
       # Portspoof will redirect the ports ${SPORTS} to port ${PORT} TCP\n \
       for PORTSPOOFRANGES in ${SPORTS}; do\n \
           \${PORTSPOOF} -t nat -A CUSTOMPREROUTING -i ${IFACE} -p tcp -m tcp --dport \${PORTSPOOFRANGES} -j REDIRECT --to-ports ${PORT}; done" ${FWL};
       # Add stop rules
       sed -i "/## add your 'stop' rules here/ a\ \
       # Portspoof flushing related chains\n \
       \${PORTSPOOF} -F CUSTOMINPUT\n \
       \${PORTSPOOF} -t nat -F CUSTOMPREROUTING" ${FWL};
}

fwadd_funct() {
    if [ "${STARTFW}" -eq 0 ]; then
      if [ -z "$(cat ${LIST})" ]; then
        #------------------------------------------------------------------------------------------------------------
        # Set whole portrange in FW rules cause no ports are opened
        SETPORTS="1:65535";
        SPORTS="${SETPORTS}";
        fwadd_main_funct;
      else
        #------------------------------------------------------------------------------------------------------------
        # Set automatic FW rules investigated by portcheck
        SETPORTS=$(echo '65536' >> ${LIST} | sort -nu ${LIST} | awk '$1!=p+1{print p+1":"$1-1}{p=$1}' | tr '\n' ' ');
        SPORTS="${SETPORTS}";
        #------------------------------------------------------------------------------------------------------------
        fwadd_main_funct;
      fi
    fi
}

# FW delete function
fwdel_funct() {
    if [ "${STOPFW}" -eq 0 ]; then
        # Delete IPTables var, start and stop section entries
        sed -i -e '/PORTSPOOF="\/sbin\/iptables"/d' -e "/for PORTSPOOFRANGES in.*/d" \
        -e "/\${PORTSPOOF}.*/d" -e "/# Portspoof.*/d" ${FWL};
    fi
}

# Check for unregular remaining entries in firewall.local causing e.g. an system/portspoof crash
clean_funct() {
   if [ -n "$(grep 'PORTSPOOF' ${FWL})" ]; then
        killproc ${BIN};
        ${FWL} stop;
        fwdel_funct;
        ${FWL} start;
        logger -t portspoof "portspoof has been stopped causing a unregular behavior, try to start it again... ";
   fi
}

case "$1" in
   start)
       if [ -z "$(pidof portspoof)" ]; then
            clean_funct;
            portcollect_funct;
            portcheck_funct;
            boot_mesg "Starting Portspoof... ";
            loadproc ${BIN} "${OPT}" \
            -p ${PORT} \
            -c ${CONF}/portspoof.conf \
            -s ${CONF}/portspoof_signatures \
            -l ${LOG};
            ${FWL} stop;
            echo "Stopped firewall.local... ";
            fwadd_funct;
            echo "Added Portspoofs FW rules in firewall.local... ";
            ${FWL} start;
            echo "Start firewall.local... ";
            logger -t portspoof "portspoof has been started... ";
            rm -f ${LIST};
       else
            echo "Portspoof is already running... ";
       fi
    ;;

   stop)
      if [ -z "$(pidof portspoof)" ]; then
           echo "Portspoof is already stopped... ";
      else
           boot_mesg "Stopping Portspoof...";
           killproc ${BIN};
           ${FWL} stop;
           echo "Stopped firewall.local... ";
           fwdel_funct;
           echo "Deleted Portspoofs FW rules in firewall.local... ";
           ${FWL} start;
           echo "Started firewall.local again... ";
           logger -t portspoof "portspoof has been stopped... ";
      fi
    ;;

   restart)
      ${0} stop
      sleep 1
      ${0} start
    ;;

   status)
      statusproc ${BIN}
    ;;

   *)
      echo "Usage: $0 {start|stop|restart|status}"
      exit 1
    ;;
esac

# End $rc_base/init.d/portspoof
