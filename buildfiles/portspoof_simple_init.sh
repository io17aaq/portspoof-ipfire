#!/bin/sh

# Begin $rc_base/init.d/portspoof
# Starts and stops Portspoof daemon
####################################
# From: ummeegge@ipfire.org
# $Date: 2015-13-04 14:41:19 -0500

. /etc/sysconfig/rc
. $rc_functions

BIN="/usr/bin/portspoof";
CONF="/etc/portspoof";
LOG="/var/log/portspoof.log";
# Options in ${OPT} are internal FUZZER_MODE (-1), run Portspoof in Daemon mode (-D) and disable syslog (-d) 
OPT="-1 -D -d";

case "$1" in
   start)
      boot_mesg "Starting Portspoofâ€¦"
      loadproc ${BIN} ${OPT} \
      -c ${CONF}/portspoof.conf \
      -s ${CONF}/portspoof_signatures \
      -l ${LOG};
      ;;

   stop)
      boot_mesg "Stopping Portspoof..."
      killproc ${BIN}
      ;;

   restart)
      $0 stop
      sleep 1
      $0 start
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
