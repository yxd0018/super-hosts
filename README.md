# super-hosts
Super hosts file amalgamated from several sources to suit the needs of my network. Contains over 68,000 unique entries. The bulk of the hosts come from Steven Black's https://github.com/StevenBlack/hosts, which was also used to generate this host file. I put it here so that my DD-WRT enabled router can pull the hosts file on boot.
Below is the script I use on my router (in the Administration/Commands page). I got it from a ddwrt forum, but no longer have the source/author info to give proper credit.I leave the top (#commented) line when pasting into my router just so I have the instructions handy when sending it to other people to use.
Result are:
* script /tmp/blocking_hosts.sh
* host (black and white) in folder blocking_hosts
* cron job in /tmp/crontab.

copy script hostgen.sh into DD-WRT command window
