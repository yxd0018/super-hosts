## super-hosts

Super hosts file amalgamated from several sources to suit the needs of my network. Contains over 68,000 unique entries. The bulk of the hosts come from Steven Black's https://github.com/StevenBlack/hosts, which was also used to generate this host file. I put it here so that my DD-WRT enabled router can pull the hosts file on boot.

Copy script hostgen.sh into DD-WRT [Administration tab command window](https://wiki.dd-wrt.com/wiki/index.php/Startup_Scripts). The firewall is executed every time that the WAN comes up and this happens several times during boot. However, all of the tables are flushed before the firewall script is ran. 

Click button "SAVE FIREWALL" to wipe out firewall setting and execute script. If you want to write less often, make a script and execute as root.

The script will generate temporary script /tmp/blocking_hosts.sh.  Host list (black and white) in folder /tmp/blocking_hosts while cron job in /tmp/crontab.

The script takes 1hr to run and you can see watch files growing in the folder /tmp/blocking_hosts. So be patient. 

You can save the commands in the "Commands" dialog box to /tmp/custom.sh. You can execute this custom script by typing `sh /tmp/custom.sh` (without quotation marks) in the Commands box and clicking on “Run Commands” at the bottom of the page. 

List firewall setting
  ```iptables -vnL```

Below script to bounce firewall. 
```shell
#!/bin/sh
stopservice firewall && startservice firewall
sleep 20
firewall_script.sh
```

## wireguard fast VPN tunneling

[set up wireguard on DD-WRT](https://wiki.dd-wrt.com/wiki/index.php/The_Easiest_Tunnel_Ever)

[open VPN configuration generator](https://github.com/thesparklabs/openvpn-configuration-generator)

DD-WRT Setup menu -> Tunnels submenu. From the Protocol Type drop-down menu, choose WireGuard. Generate Key and enter IP Address (this will be oet1 interface ip and must be out of your local lan range, on a separate network. E.g. if your router LAN IP is 192.168.2.1, for an IP address of oet1 put 10.10.0.1.

Note: You cannot use allowed ips of 0.0.0.0/0 for multiple peers. This causes a collision. What works is setting of 10.10.0.2/32 and 10.10.0.3/32. The allowed ip's feature is for crypto routing. The key is valid for the allowed ip space. So, one single key is valid for the whole space.

# DD-WRT useful scripts

[Useful Scripts](https://wiki.dd-wrt.com/wiki/index.php/Useful_Scripts)

