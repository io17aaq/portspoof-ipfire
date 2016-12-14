#!/bin/bash -

#
# - Script will proof via a SHA1 checksum if the Portspoof related FW chains has been changed,
# if so, it will restart Portspoof so new ports can be excluded in Portspoofs
# for loop in firewall.local.
#
# $author: ummeegge ; $date: 2016-06.11 09:35:19 -0500
##############################################################################################

## Locations
# Bin location
INIT="/etc/init.d/portspoof";
INITCHECK="210"
IPTABLES="/sbin/iptables";
# File location
SHAFILE="/etc/portspoof/.fwshachecksum";

if [ "$(cat ${INIT} | wc -l)" = "${INITCHECK}" ]; then
   ## Main part
   # Portcheck for sha1 checksum.
   shacheck_funct() {
      OP1=$(for i in INPUTFW OVPNINPUT TOR_INPUT IPSECINPUT IPTVINPUT CUSTOMINPUT; do
      ${IPTABLES} -nv -L "${i}" | awk '/dpt:/ { print $11 }' | cut -d':' -f2;
      done);
      OP2=$(${IPTABLES} -t nat -L -n -v | awk '/dpt:/ { print $11 }' | cut -d':' -f2);
      USEDPORTS=$(echo "${OP1} ${OP2}");
      SHASUM=$(echo ${USEDPORTS} | tr ' ' '\n' | sort -nu);
      echo ${SHASUM} | sha1sum;
   }

   # Check if SHAsum exist, otherwise create it
   if [ -z "${SHAFILE}" ]; then
      shacheck_funct > "${SHAFILE}";
   fi  > /dev/null 2>&1

   # Proof for FW changes
   if [ "$(shacheck_funct)" != "$(cat ${SHAFILE})" ]; then
      ${INIT} restart;
      shacheck_funct > "${SHAFILE}";
      logger -t portspoof: "Portspoofs FW entries in firewall.local has been updated... ";
   fi > /dev/null 2>&1
else
   echo "There are two potential problems. 1) You use the wrong Portspoof initscript or 2) There is no Portspoof Initscript. Need to quit... ";
   exit 1;
fi

# End script

