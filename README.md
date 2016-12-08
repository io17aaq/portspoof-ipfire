# portspoof-ipfire
##################
Scripts should deliver a possibility to integrate 
Portspoof --> https://github.com/drk1wi/portspoof into 
IPFire --> https://github.com/ipfire environment.
The scripts needs a working IPFire environment but also an compiled Portspoof binary including an configuration directory under /etc/portspoof.

The repo contains currently:

- An installerscript for IPFire platforms which provides
	- Portspoof installation on IPFire platforms.
	- Portspoof uninstallation on IPFire platforms.
	- progress overview for firewall, lsof, ps and init status.
	- different installerscripts (A and B)


- An initscript ( portspoof_init.sh ) which provides
	- automatic external interface detection for ppp0 or red0 (IPFire specific terms).
	- automatic port detection of IPTables *INPUT and *NAT chains.
	- automatic integration of the firewall rules investigated by port detection.
	- start|stop|restart|status sequences.
	- Check for system crash if there are IPTable entries leftover in firewall.local. If so, it will clean it up.

portspoof_init.sh is located under /etc/rc.d/init.d/

- An script ( checkFWchange.sh ) which checks 
	- in intervals for changes in the IPTable chains. 
	- if changes appears, it will restart the initscript which starts again to exlude the port ranges in the firewall.local so no user interaction should be needed.
	- initscript will be identified via line count cause both needs another.

checkFWchange.sh is located under /etc/fcron.minutely
