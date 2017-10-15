#!/bin/bash -

#
# This installer integrates Portspoof into IPFire environment.
# It downloads portspoof-1.3-4.ipfire from http://people.ipfire.org/~ummeegge/portspoof/portspoof-1.3%2b/ .
# The portspoof package serves an log file, symlinks, a meta file, the binary and a config directory.
# The installer serves a possibility to integrate another initscript where FW rules will also be set.
# You can start and stop Portspoof over the installer, there is also a status and a logfile check integrated .
#
# $author: ummeegge ; $date: 07-11.2016
##############################################################################################################
#

# Package, URL and installation directory
PACKAGE="portspoof-1.3-4.ipfire";
PACKAGEA="portspoof_arm-1.3-4.tar.gz";
PACKAGEB="portspoof-1.2-2_64bit.ipfire";
URL="https://people.ipfire.org/~ummeegge/portspoof/portspoof-1.3%2b";
URLB="https://people.ipfire.org/~ummeegge/portspoof/64bit";
INSTDIR="/opt/pakfire/tmp";
LOGDIR="/var/log/portspoof";
LOG="${LOGDIR}/portspoof.log"
BIN="/usr/bin/portspoof";
INIT="/etc/rc.d/init.d/portspoof";
CONF="/etc/portspoof";
META="/opt/pakfire/db/installed/meta-portspoof";
ROTATE="/etc/logrotate.d/portspoof";

# SHA256 sums
PACKAGESUM="2e05c8920b18179317c2f9a27c177e806b11a8e7a093792127f84681cef7a319";
PACKAGESUMA="d104b9adca9a619d7ed8b7a7f64d1b4ccd446ec8472f02c9c340b8a915d8231e";
PACKAGESUMB="3a5f612a2d7eb88cfa365e1817d8bd3915be53ece7e6abc3234f46090137943f";

# Formatting and Colors
COLUMNS="$(tput cols)";
R=$(tput setaf 1);
G=$(tput setaf 2);
B=$(tput setaf 6);
b=$(tput bold);
N=$(tput sgr0);
seperatorA(){ printf -v _hr "%*s" ${COLUMNS} && echo ${_hr// /${1-_}}; }
seperatorB(){ printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -; }

# Platform check
TYPE=$(uname -m | tail -c 3)

# Delete old Portspoof installations
del_funct() {
  # Symlink searcher
  SYM=$(find /etc/rc.d/rc*.d -name "*portspoof")
  if [[ -e "${CONF}" || "${LOGDIR}" || "${INIT}" || "${BIN}" ]]; then
    if [ -e "${INIT}" ]; then
      ${INIT} stop
    fi
    rm -rvf "${CONF}"* "${BIN}" "${LOGDIR}" "${META}" "${INIT}" "${ROTATE}" ${SYM};
  fi
}

# Check SHA256 sum
down_funct() {
  if [[ ${TYPE} = "86" ]]; then
    cd /tmp || exit;
    # Check if package is already presant otherwise download it
    if [[ ! -e "${PACKAGE}" ]]; then
      echo;
      curl -O ${URL}/${PACKAGE};
    fi
    # X86 package check
    CHECK=$(sha256sum ${PACKAGE} | awk '{print $1}');
    if [[ "${CHECK}" = "${PACKAGESUM}" ]]; then
      echo;
      echo -e "SHA2 sum should be ${B}${PACKAGESUM}${N}";
      echo -e "SHA2 sum is        ${G}${CHECK}${N} and is correct… ";
      echo;
      echo "will go for further processing :-) ...";
      echo;
      sleep 3;
      cp -vf ${PACKAGE} ${INSTDIR};
      cd ${INSTDIR} || exit 1;
      tar xvf ${PACKAGE};
      ./install.sh 2>&1 | tee /tmp/portspoof_installer.log;
      rm -f /etc/portspoof.conf /etc/portspoof_signatures;
    else
      echo;
      echo -e "SHA2 sum should be ${B}${PACKAGESUM}${N}";
      echo -e "SHA2 sum is        ${R}${CHECK}${N} and is not correct… ";
      echo;
      echo -e "\033[1;31mShit happens :-( the SHA2 sum is incorrect, please report this here\033[0m";
      echo "--> https://forum.ipfire.org/viewtopic.php?f=41&t=12399";
      echo;
      exit 1;
    fi
  elif [[ ${TYPE} = "64" ]]; then
    cd /tmp || exit;
    # Check if package is already presant otherwise download it
    if [[ ! -e "${PACKAGEB}" ]]; then
      echo;
      curl -O ${URLB}/${PACKAGEB};
    fi
    # X86 package check
    CHECK=$(sha256sum ${PACKAGEB} | awk '{print $1}');
    if [[ "${CHECK}" = "${PACKAGESUMB}" ]]; then
      echo;
      echo -e "SHA2 sum should be ${B}${PACKAGESUMB}${N}";
      echo -e "SHA2 sum is        ${G}${CHECK}${N} and is correct… ";
      echo;
      echo "will go for further processing :-) ...";
      echo;
      sleep 3;
      cp -vf ${PACKAGEB} ${INSTDIR};
      cd ${INSTDIR} || exit 1;
      tar xvf ${PACKAGEB};
      ./install.sh 2>&1 | tee /tmp/portspoof_installer.log;
      rm -f /etc/portspoof.conf /etc/portspoof_signatures;
    else
      echo;
      echo -e "SHA2 sum should be ${B}${PACKAGESUMB}${N}";
      echo -e "SHA2 sum is        ${R}${CHECK}${N} and is not correct… ";
      echo;
      echo -e "\033[1;31mShit happens :-( the SHA2 sum is incorrect, please report this here\033[0m";
      echo "--> https://forum.ipfire.org/viewtopic.php?f=41&t=12399";
      echo;
      exit 1;
    fi
  else
    cd /tmp || exit 1;
    # Check if package is already presant otherwise download it
    if [[ ! -e "${PACKAGEA}" ]]; then
      echo;
      curl -O ${URL}/${PACKAGEA};
    fi
    # ARM package check
    CHECK=$(sha256sum ${PACKAGEA} | awk '{print $1}');
    if [[ "${CHECK}" = "${PACKAGESUMA}" ]]; then
      echo;
      echo -e "SHA2 sum should be ${B}${PACKAGESUMA}${N}";
      echo -e "SHA2 sum is        ${G}${CHECK}${N} and is correct… ";
      echo;
      echo "will go for further processing :-) ...";
      echo;
      sleep 3;
      cp -vf ${PACKAGEA} ${INSTDIR};
      cd ${INSTDIR} || exit 1;
      tar xvf ${PACKAGEA};
      ./install.sh 2>&1 | tee /tmp/portspoof_installer.log;
      rm -f /etc/portspoof.conf /etc/portspoof_signatures;
    else
      echo;
      echo -e "SHA2 sum should be ${B}${PACKAGESUMA}${N}";
      echo -e "SHA2 sum is        ${R}{CHECK}${N} and is not correct… ";
      echo;
      echo -e "\033[1;31mShit happens :-( the SHA2 sum is incorrect, please report this here\033[0m";
      echo "--> https://forum.ipfire.org/viewtopic.php?f=41&t=12399";
      echo;
      exit 1;
    fi
  fi
}

state_funct() {
  clear;
  echo -e "${B}Portspoofs 'list of open files':${N}";
  lsof | grep portspoof;
  echo;
  echo -e "${B}Portspoofs 'progress state':${N}";
  ps aux | grep portspoof | grep daemon;
  echo;
  echo -e "${B}Portspoofs 'netstat':${N}";
  netstat -tlpn | grep portspoof | tail -1;
  echo;
  echo -e "${B}Overview of changed 'CUSTOMINPUT' chain:${N}";
  iptables -n -vL CUSTOMINPUT;
  echo;
  echo -e "${B}Overview of changed 'CUSTOMPREROUTING' chain:${N}";
  iptables -t nat -n -vL CUSTOMPREROUTING;
  echo;
  /etc/init.d/portspoof status;
  read -p "To checkout your firewall.local entries press [ENTER] ... ";
  cat /etc/sysconfig/firewall.local;
}

# Installer Menu
while true; do
  # Choose installation
  clear;
  echo "${N}";
  echo "+------------------------------------------------------------------------+";
  echo "|              Welcome to Portspoof on IPFire installation               |";
  echo "+------------------------------------------------------------------------+";
  echo;
  echo -e "       If you want to install Portspoof press      ${B}${b}'i'${N} and [ENTER]";
  echo -e "       If you want to configure Portspoof press    ${B}${b}'c'${N} and [ENTER]";
  echo -e "       If you want to uninstall Portspoof press    ${B}${b}'u'${N} and [ENTER]";
  echo;
  echo  "+-----------------------------------------------------------------------+";
  echo;
  echo -e "       To check Portspoofs state press             ${B}${b}'p'${N} and [ENTER]";
  echo -e "       To check Portspoofs logs press              ${B}${b}'l'${N} and [ENTER]";
  echo -e "       To start Portspoof press                    ${B}${b}'s'${N} and [ENTER]";
  echo -e "       To stop Portspoofs press                    ${B}${b}'d'${N} and [ENTER]";
  echo -e "       To check the firewall.local entries press   ${B}${b}'f'${N} and [ENTER]";
  echo;
  echo  "+-----------------------------------------------------------------------+";
  echo -e "       If you want to quit this installation press ${B}${b}'q'${N} and [ENTER]";
  echo  "+-----------------------------------------------------------------------+";
  echo;
  read -r choice
  clear;
  # Install section
  case $choice in
    i*|I*)
    clear;
    read -p "To install Portspoof now press [ENTER] , to quit use [CTRL-c]... ";
    if [[ -d "${CONF}" ]]; then
      echo "Portspoof is already installed on this system... ";
      sleep 3;
      echo;
    else
      # Delete old installation and unpack and install package
      del_funct;
      # Download and install new package
      down_funct;
      touch ${META};
      # Integration of firewall rules
      clear;
      seperatorA;
      echo;
      echo "There are two possibilities to integrate the needed firewall rules for Portspoof:"
      seperatorB;
      echo;
      echo -e "${R}A)${N} ${B}Integrates the FW rules over the initscript automatically";
      echo -e "${R}B)${N} ${B}Copy an example_firewall.local file to '/tmp'. The firewall configuration needs to be done by your own.${N}"
      seperatorB;
      echo;
      printf "%b" "For automatic FW detection press ${R}'A'${N} - For an example under /tmp press ${R}'B'${N}: ";
      read what;
      echo;
      case "$what" in
        a*|A*)
          echo "Will set the FW rules into the initscript... ";
          echo;
          sleep 3;
          cat > "${INIT}" << "EOF"
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
###############################################################################
# From: ummeegge@ipfire.org
# $Date: 2016-11.07 10:49:32 -0500

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
# Searcher for stop section

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
STOPFW=$(grep '\${PORTSPOOF} -t nat -F CUSTOMPREROUTING' ${FWL} | echo $?);
# FW add function
fwadd_main_funct() {
    sed -i '/# Used for private firewall rules/ a\PORTSPOOF="\/sbin\/iptables"' ${FWL}
    sed -i "/start)/ a\ \
       # Portspoof ### This block is automatically generated by \/etc\/rc.d\/init.d\/portspoof ### PLEASE DO NOT CHANGE IT HERE \n \
       # Portspoof log activity to syslog \n \
       \${PORTSPOOF} -A CUSTOMINPUT -i ${IFACE} -p tcp --dport ${PORT} -m limit --limit 2/m -j LOG --log-prefix=\"portspoof: Activity log \" --log-level 1\n \
       # Portspoof open external access \n \
       \${PORTSPOOF} -A CUSTOMINPUT -i ${IFACE} -p tcp --dport ${PORT} -j ACCEPT\n \
       # Portspoof will redirect the ports ${SPORTS} to port ${PORT} TCP\n \
       for PORTSPOOFRANGES in ${SPORTS}; do\n \
           \${PORTSPOOF} -t nat -A CUSTOMPREROUTING -i ${IFACE} -p tcp -m tcp --dport \${PORTSPOOFRANGES} -j REDIRECT --to-ports ${PORT}; done\n \
       # Portspoof ### End automatic generated block" ${FWL};
       # Add stop rules
       sed -i "/stop)/ a\ \
       # Portspoof ### This block is automatically generated by \/etc\/rc.d\/init.d\/portspoof ### PLEASE DO NOT CHANGE IT HERE \n \
       # Portspoof flushing related chains\n \
       \${PORTSPOOF} -F CUSTOMINPUT\n \
       \${PORTSPOOF} -t nat -F CUSTOMPREROUTING\n \
       # Portspoof ### End automatic generated block" ${FWL};
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

EOF
        clear;
        seperatorA;
        echo;
        echo "Please check the existing Portspoof initscript if you chose the FW integration.";
        seperatorB;
        echo;
        echo -e "${B}You can change Portspoofs behavior under ${R}'${INIT}'${N}." 
        echo -e "${B}The installer provides also a configuration possibility over point ${R}${b}'C'${N} .";
        echo;
        seperatorB;
        echo;
        read -p "For further processing press [ENTER]... "
      ;;

      b*|B*)
        echo "Will paste an example named 'example_firewall.local under /tmp... ";
        sleep 3;
        cat > /tmp/example_firewall.local << "EOF"
#!/bin/sh
# Used for private firewall rules


## Portspoofs IPTables rule variable
# If you delete or stop Portspoof, please delete this rules.
# To bring this changes to work, use '/etc/init.d/firewall restart' in the command line.

# Portspoofs default port which is also defined in Portspoofs Initskript.
PORT="4444";
# Exclude your services (if you provide some) in the following 'SPORTS' line by separate them with an empty space and separate ranges with an ':'.
# You can use more then 15 port ranges cause the rule works with an for loop.
# If you want to exclude services on IPFire or behind IPFire, the following line gives an example for port 222 and 443 TCP.
# SPORTS="1:221 223:442 444:65535";
# Currently all Ports are spoofed by Portspoof as you can see in the following line, which one you need to change if you want an other behavior.
SPORTS="1:65535";

# See how we were called.
case "$1" in
  start)
        ## add your 'start' rules here
   # External access for Portspoof port 4444 TCP
   /sbin/iptables -A CUSTOMINPUT -i red0 -p tcp --dport ${PORT} -j ACCEPT;
   # Redirect all above define SPORTS to Portspoof 4444 TCP.
   for RANGES in ${SPORTS}; do
       /sbin/iptables -t nat -A CUSTOMPREROUTING -i red0 -p tcp -m tcp --dport ${RANGES} -j REDIRECT --to-ports ${PORT};
   done
        ;;
  stop)
        ## add your 'stop' rules here
   # Flush the used chains
   /sbin/iptables -F CUSTOMINPUT
   /sbin/iptables -t nat -F CUSTOMPREROUTING
        ;;
  reload)
        $0 stop
        $0 start
        ## add your 'reload' rules here
        ;;
  *)
        echo "Usage: $0 {start|stop|reload}"
        ;;
esac

EOF

          # Fixed wrong log path from default initscript
          sed -i 's|/var/log/portspoof.log|/var/log/portspoof/portspoof.log|' ${INIT};
    ;;

    *)
      echo "This option does not exist... ";
    ;;

    esac

      echo -e "\033[1;31mYou need to set your own firewall rules.\033[0m ";
      echo;
      echo "but you can find an firewall.local example how to set your own FW rules for Portspoof under /tmp... ";
      echo;
      echo "Installation is finish now. You can find an reduced installer.log under /tmp... ";
      echo;
      clear;
      seperatorA;
      echo;
      echo "You can start Portspoof over the configuration menu from this installer, ";
      seperatorB;
      echo -e "${B}but you can use also an '/etc/init.d/portspoof start' over the command line${N}";
      seperatorA;
      echo;
      read -p "To finish now the installation press [ENTER]. Enjoy your testings.";
      # Install logrotate.d again until package update cause the package version uses wrong path
      cat > "${ROTATE}" << "EOF"
/var/log/portspoof/*.log {
        weekly
        missingok
        rotate 52
        compress
        delaycompress
        notifempty
        create 0640 daemon daemon
        sharedscripts
        postrotate
   if [ -n "$(pidof portspoof) ]; then
            /etc/init.d/portspoof restart > /dev/null
        fi
        endscript
}
EOF

      # CleanUP pakfire /tmp
      rm -rvf "${INSTDIR:?}/"*;
    fi
  ;;

    # Configure section
    c*|C*)
      clear;
      # Configure portspoof.conf
      if [[ -e "${CONF}" ]]; then
        seperatorA;
        echo;
        echo -e "${B}The configuration in this installer uses the editor vim... ${N}";
        seperatorB;
        echo;
        printf "%b" "if you´d like to configure portspoof.conf press ${R}'A'${N}[ENTER] - To skip it press ${R}'B'${N}[ENTER]: ";
        echo
        read what;
        case "$what" in
          a*|A*)
            vim ${CONF}/portspoof.conf;
            /etc/init.d/portspoof restart;
            sleep 3;
            echo;
          ;;
        esac
      else
        echo "Have found no Portspoof installation on this system... ";
        echo;
        sleep 3;
      fi
      # Configure start parameters and firewall rules
      if [[ -e "${INIT}" ]]; then
        clear;
        seperatorA;
        echo;
        echo -e "${B}All Portspoof starting parameters are defined in the Portspoof initscript${N}";
        seperatorB;
        echo;
        printf "%b" "if you´d like to configure Portspoofs initscript press ${R}'A'${N}[ENTER] - To skip it press ${R}'B'${N}[ENTER]: ";
        read what;
        case "$what" in
          a*|A*)
            /etc/init.d/portspoof stop;
            vim +45 ${INIT};
            /etc/init.d/portspoof start;
          ;;
          b*|B*)
            echo;
            echo "Won´t change anything... ";
            echo;
            sleep 2;
          ;;
        esac
      else
        echo "Have found no Portspoof initscript on this machine... ";
        echo;
        exit 1;
      fi
      echo "Configuration is done... ";
      echo;
      echo -e "${R}If you got some problems, come to https://forum.ipfire.org/viewtopic.php?f=41&t=12399 will try then to help you... ${N}";
      echo;
      echo "Goodbye";
      echo;
      read -p "To go back to installer menu press [ENTER]... ";
    ;;

    # Display portspoofs state
    p*|P*)
      state_funct;
      echo;
      read -p "To go back to installer menu press [ENTER] ... ";
      echo;
    ;;

    # Display portspoofs log entries
    l*|L*)
      if [ -s "${LOG}" ]; then
        awk '{ printf strftime("%c", $1); for (i=2; i<NF; i++) printf $i " "; print $NF }' ${LOG};
        echo;
        read -p "To change back to main menu press [ENTER]... ";
        echo;
      else
        echo "There are currently no entries in Portspoofs log... ";
        sleep 3;
      fi
    ;;

    # Starting portspoof
    s*|S*)
      if [ -z "$(pidof portspoof)" ]; then
        /etc/init.d/portspoof start;
        sleep 2;
        echo "Show you now Portspoofs progress state... ";
        sleep 2;
        echo;
        state_funct;
        echo;
        read -p "To go back to installer menu press [ENTER]... ";
      else
        echo -e "${R}Portspoof is already running... ${N}";
        sleep 2;
      fi
    ;;

    # Stopping portspoof
    d*|D*)
      if [ -z "$(pidof portspoof)" ]; then
        echo -e "${R}Portspoof is already stopped... ${N}";
        sleep 2;
      else
        /etc/init.d/portspoof stop;
        echo "Show you now Portspoofs progress state... ";
        sleep 2;
        echo;
        state_funct;
        echo;
        read -p "To go back to installer menu press [ENTER]... ";
      fi
    ;;

    # Uninstall portspoof
    u*|U*)
      clear;
      if [[ ! -d "${CONF}" ]]; then
        echo "Portspoof is currently not installed on this system... ";
        echo;
        read -p "To go back to installer menu press [ENTER]... "
      else
        read -p "To uninstall the Portspoof installation press [ENTER] , to quit use [CTRL-c]... ";
        del_funct 2>&1 | tee /tmp/portspoof_uninstaller.log;
        echo;
        echo -e "${B}Portspoof has been uninstalled, the uninstaller is finished now. You can find also an uninstaller.log under /tmp...${N}"
        echo;
        echo "Thanks for testing.";
        echo;
        echo "Goodbye."
        echo;
        exit 0;
      fi
    ;;

    # Check FW entries
    f*|F*)
      clear;
      cat /etc/sysconfig/firewall.local;
      echo;
      read -p "To go back to installation menu, press [ENTER] ... ";
      echo;
    ;;

    # Quit installer
    q*|Q*)
      exit 0
    ;;

    # Installer usage explanation
    *)
      echo;
      echo -e "     ${R}Ooops, there went something wrong 8-\ - for explanation again${N}";
      echo "+-----------------------------------------------------------------------+";
      echo "|            Welcome to Portspoof on IPFire installation                |";
      echo "+-----------------------------------------------------------------------+";
      echo;
      echo -e "       If you want to install Portspoof press      ${B}${b}'i'${N} and [ENTER]";
      echo -e "       If you want to configure Portspoof press    ${B}${b}'c'${N} and [ENTER]";
      echo -e "       If you want to uninstall Portspoof press    ${B}${b}'u'${N} and [ENTER]";
      echo;
      echo    "+-----------------------------------------------------------------------+";
      echo;
      echo -e "       To check Portspoofs state press             ${B}${b}'p'${N} and [ENTER]";
      echo -e "       To check Portspoofs logs press              ${B}${b}'l'${N} and [ENTER]";
      echo -e "       To start Portspoof press                    ${B}${b}'s'${N} and [ENTER]";
      echo -e "       To stop Portspoofs press                    ${B}${b}'d'${N} and [ENTER]";
      echo -e "       To check the firewall.local entries press   ${B}${b}'f'${N} and [ENTER]";
      echo;
      echo    "+-----------------------------------------------------------------------+";
      echo -e "       If you want to quit this installation press ${B}${b}'q'${N} and [ENTER]";
      echo    "+-----------------------------------------------------------------------+";
      echo;
      read -p " To start the installer again press [ENTER] , to quit use [CTRL-c]";
      echo;
    ;;

  esac

done

## End Portspoof installerscript
