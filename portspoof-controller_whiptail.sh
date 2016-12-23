#! /bin/bash -

set -x

## Locations
INIT="/etc/rc.d/init.d/portspoof";
ROTATE="/etc/logrotate.d/portspoof";
CONF="/etc/portspoof";

function gauge() {
	{
	for ((i = 0 ; i <= 100 ; i+=5)); do
		sleep 0.1
		echo $i
	done 2>&1
	} | whiptail --gauge " \
		Please wait...
		" 6 50 0
}

# Start|Restart|Stop Portspoof
function start() {
	{
	/etc/init.d/portspoof start;
	} | gauge;
}
function restart() {
	{
	/etc/init.d/portspoof restart;
	} | gauge;
}
function stop() {
	{
	/etc/init.d/portspoof stop;
	} | gauge;
}

function rotateinstall() {
	{
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
	}
}

function install() {
	{
	# SHA256 sums
	PACKAGESUM="2e05c8920b18179317c2f9a27c177e806b11a8e7a093792127f84681cef7a319";
	PACKAGESUMA="d104b9adca9a619d7ed8b7a7f64d1b4ccd446ec8472f02c9c340b8a915d8231e";
	# Platform check
	TYPE=$(uname -m | tail -c 3);
	# Package, URL and installation directory
	PACKAGE="portspoof-1.3-4.ipfire";
	PACKAGEA="portspoof_arm-1.3-4.tar.gz";
	URL="http://people.ipfire.org/~ummeegge/portspoof/portspoof-1.3%2b";
	INSTDIR="/opt/pakfire/tmp";

	if [[ ${TYPE} = "86" ]]; then
		cd /tmp || exit;
		# Check if package is already presant otherwise download it
		if [[ ! -e "${PACKAGE}" ]]; then
			curl -O ${URL}/${PACKAGE};
		fi
		# X86 package check
		CHECK=$(sha256sum ${PACKAGE} | awk '{print $1}');
		if [[ "${CHECK}" = "${PACKAGESUM}" ]]; then
			cp -vf ${PACKAGE} ${INSTDIR};
			cd ${INSTDIR} || exit 1;
			tar xvf ${PACKAGE};
			./install.sh 2>&1 | tee /tmp/portspoof_installer.log;
			rm -f /etc/portspoof.conf /etc/portspoof_signatures;
			whiptail --title "Portspoof Installation" \
				--msgbox "Has been installed, please select initscript and firewall integration." 8 78
			rotateinstall;
			sed -i 's|/var/log/portspoof.log|/var/log/portspoof/portspoof.log|' ${INIT};
		else
			whiptail --title "Portspoof Installation" \
				--msgbox "The SHA check do not match, wrong package. Need to quit." 8 78
			exit 1;
		fi
	else
		cd /tmp || exit 1;
		# Check if package is already presant otherwise download it
		if [[ ! -e "${PACKAGEA}" ]]; then
			curl -O ${URL}/${PACKAGEA};
		fi
		# ARM package check
		CHECK=$(sha256sum ${PACKAGEA} | awk '{print $1}');
		if [[ "${CHECK}" = "${PACKAGESUMA}" ]]; then
			cp -vf ${PACKAGEA} ${INSTDIR};
			cd ${INSTDIR} || exit 1;
			tar xvf ${PACKAGEA};
			./install.sh 2>&1 | tee /tmp/portspoof_installer.log;
			rm -f /etc/portspoof.conf /etc/portspoof_signatures;
			whiptail --title "Portspoof Installation" \
				--msgbox "Has been installed." 8 78
			rotateinstall;
			sed -i 's|/var/log/portspoof.log|/var/log/portspoof/portspoof.log|' ${INIT};
		else
			whiptail --title "Portspoof Installation" \
				--msgbox "The SHA check do not match, wrong package. Need to quit." 8 78
			exit 1;
		fi
	fi
	}
}

function initinstall() {
	{
	whiptail --title "Initscript and firewall installation" \
	--yesno "<Yes>: Integrates automatic FW detection into the initscript \n \
<No>: Copies an example firewall.local into tmp directory" 8 78
 
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
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

EOF
	else
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
	fi
	}
}

function uninstall() {
	{
	LOGDIR="/var/log/portspoof";
	BIN="/usr/bin/portspoof";
	INIT="/etc/rc.d/init.d/portspoof";
	CONF="/etc/portspoof";
	SYM=$(find /etc/rc.d/rc*.d -name "*portspoof")
	if [[ -e "${CONF}" || "${LOGDIR}" || "${INIT}" || "${BIN}" ]]; then
		if [ -e "${INIT}" ]; then
			${INIT} stop
		fi
		rm -rvf "${CONF}"* "${BIN}" "${LOGDIR}" "${META}" "${INIT}" "${ROTATE}" ${SYM};
	fi
	whiptail --title "Portspoof Installation" --msgbox "Has been uninstalled." 8 78
	}
}

function state() {
	echo "Portspoofs 'list of open files':";
	echo;
	lsof | grep portspoof;
	echo;
	echo "Portspoofs 'progress state':";
	echo;
	ps aux | grep portspoof | grep daemon;
	echo;
	echo "Portspoofs 'netstat':";
	echo;
	netstat -tlpn | grep portspoof | tail -1;
	echo;
	echo "Overview of changed 'CUSTOMINPUT' chain:";
	echo;
	iptables -n -vL CUSTOMINPUT;
	echo;
	echo "Overview of changed 'CUSTOMPREROUTING' chain:";
	echo;
	iptables -t nat -n -vL CUSTOMPREROUTING;
	echo;
	echo "Portspoofs init status:";
	echo;
	/etc/init.d/portspoof status;
	echo "Firewall.local overview:";
	echo;
	cat /etc/sysconfig/firewall.local;
	echo;
	echo;
	echo "Use right arrow and [RETURN] to finish the overview... ";
	echo;
	echo;
} > /tmp/.state;

# Change port
function port_change() {
	{
  	whiptail --msgbox "
	Portspoof operates per default with 4444 TCP. \n \
  	To change this enter a new port.
	" 20 70 1
  	CURRENT_PORT=$(awk -F'"' '/PORT=/ { print $2 }' ${INIT});
  	NEW_PORT=$(whiptail --inputbox "Please enter a port if you want to change it" 20 60 "$CURRENT_PORT" 3>&1 1>&2 2>&3);
  	if [ $? -eq 0 ]; then
    	sed -i "s/$CURRENT_PORT/$NEW_PORT/" ${INIT};
  	fi
  	restart;
	}
}

## Menu
while true
do
CHOICE=$(
whiptail --title "Portspoof Controller" --menu "Make your choice" 16 100 9 	\
	"A)" "Install Portspoof"   												\
	"B)" "Uninstall Portspoof"   											\
	"1)" "Change Portspoofs port"   										\
	"2)" "Restart Portspoof" 												\
	"3)" "Start Portspoof" 													\
	"4)" "Stop Portspoof" 													\
	"5)" "Portspoofs progression state" 									\
	"9)" "End script"  3>&2 2>&1 1>&3	
)


	case $CHOICE in
		"A)")
			if [ -d "${CONF}" ]; then
				whiptail --title "Portspoof Installation" --msgbox "Portspoof is already installed on this system. Please uninstall it first... " 8 78
			else
				install;
				initinstall;
				/etc/init.d/portspoof start;
			fi
		;;

		"B)")
			if [ -d "${CONF}" ]; then
				uninstall;
			else
				whiptail --title "Portspoof Installation" --msgbox "Portspoof is currently not installed on this system... " 8 78
			fi
		;;

		"1)")
			port_change;
		;;

		"2)")   
			restart;
		;;

		"3)")
			if [ -z "$(pidof portspoof)" ]; then
				start;
			else
				whiptail --title "Portspoof Installation" --msgbox "Portspoof is already started... " 8 78
			fi
		;;

		"4)")
			if [ -z "$(pidof portspoof)" ]; then
				whiptail --title "Portspoof Installation" --msgbox "Portspoof is already stopped... " 8 78
			else
				stop;
			fi
		;;

		"5)")
			state;   
			whiptail --textbox --scrolltext /tmp/.state 40 80;
			rm -f /tmp/state;
		;;

		"9)") 
			exit
		;;
	esac

	#whiptail --msgbox "Thanks for testing. Goodbye... " 20 78
done

exit

# End script