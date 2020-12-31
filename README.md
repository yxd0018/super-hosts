# super-hosts

Super hosts file amalgamated from several sources to suit the needs of my network. Contains over 68,000 unique entries. The bulk of the hosts come from Steven Black's https://github.com/StevenBlack/hosts, which was also used to generate this host file. I put it here so that my DD-WRT enabled router can pull the hosts file on boot.

Copy script hostgen.sh into DD-WRT [Administration tab command window](https://wiki.dd-wrt.com/wiki/index.php/Startup_Scripts), then click SAVE FIREWALL. 

Then run script hostgen.sh in command window or in ssh session. It will generate temporary script /tmp/blocking_hosts.sh.  Host list (black and white) in folder /tmp/blocking_hosts while cron job in /tmp/crontab.

The script takes 1hr to run and you can see watch files growing in the folder /tmp/blocking_hosts. So be patient. 

You can save the commands in the "Commands" dialog box to /tmp/custom.sh. You can execute this custom script by typing `sh /tmp/custom.sh` (without quotation marks) in the Commands box and clicking on “Run Commands” at the bottom of the page. 


