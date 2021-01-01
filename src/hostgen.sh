# script to download host files from github repo into /tmp/blocking_hosts and clean them by whitelist setting.
# Then create DNSMASQ setting.

# --- COPY THE TEXT BELOW TO DD-WRT / ADMINISTRATION / COMMANDS then click SAVE FIREWALL ---
BH_SCRIPT="/tmp/blocking_hosts.sh"
BH_WHITELIST="/tmp/blocking_hosts.whitelist"
SKIP_DOWNLOAD=0
logger "Download blocking hosts file and restart dnsmasq ..."

# Create download script.
cat > "$BH_SCRIPT" <<EOF
#!/bin/sh

# Function: wait_for_connection
wait_for_connection() {
  # Wait for an Internet connection.
  # This possibly could take a long time.
  while :; do
    ping -c 1 -w 10 www.freebsd.org > /dev/null 2>&1 && break
    sleep 10
  done
}

# Function: clean_hosts_file [file ...]
clean_hosts_file() {
  # The sed script cleans up the file.
  # The awk script groups the hosts by ten items.
  sed -e '/^127.0.0.1/b replace;
          /^0.0.0.0/b replace;
          :drop;
            d; b;
          :replace;
            s/^0.0.0.0[[:space:]]*//;
            s/^127.0.0.1[[:space:]]*//;
            s/[[:space:]]*#.*\$//;
            s/[[:space:]]*\$//;
            s/[[:space:]][[:space:]]*/ /;
            /^localhost\$/b drop;
            /^[[:space:]]*\$/b drop;' \$* | \\
  awk 'BEGIN {
         # Read whitelist file.
         n_whitelist = 0
         while ( getline < "${BH_WHITELIST}" ) {
           if ( \$0 == "" ) {
             break
           }
           else {
             a_whitelist[++n_whitelist] = \$0
           }
         }
         close("${BH_WHITELIST}")
         # Setup record sparator.
         RS=" +"
         c = 0
       }
       {
         for ( n = 1; \$n != ""; n++ ) {
           # Check whitelist.
           whitelist_flag = 0
           for ( w = 1; w <= n_whitelist; w++ ) {
             if ( \$n ~ ( "^" a_whitelist[w] "\$" ) ) {
               whitelist_flag = 1
               break
             }
           }
           if ( whitelist_flag == 0 ) {
             hosts[++c] = \$n
             if ( c == 10 ) {
               s_hosts = "0.0.0.0"
               for ( i = 1; i <= c; i++ ) {
                 s_hosts = s_hosts " " hosts[i]
               }
               print s_hosts
               c = 0
             }
           }
         }
       }
       END {
        if ( c > 0 ) {
           s_hosts = "0.0.0.0"
           for ( i = 1; i <= c; i++ ) {
             s_hosts = s_hosts = s_hosts " " hosts[i]
           }
           print s_hosts
         }
       }'
}

# Function to download
download_file() {
  url=\$1
  targetName=\$2
  cleanFlag=\$3
  logger "Downloading \${url} to \${targetName} with cleanFlag \${cleanFlag} ..."
  REPEAT=1
  while :; do
    # Wait for internet connection.
    wait_for_connection
    START_TIME=\`date +%s\`
    # Create process to download a hosts file.
    logger "wget -O - \${url} 2> /dev/null > \${targetName}.tmp"
    wget -O - "\${url}" 2> /dev/null > "\${targetName}.tmp" &
    WGET_PID=\$!
    WAIT_TIME=\$((\$REPEAT * 10 + 20))
    # Create timeout process.
    ( sleep \$WAIT_TIME; kill -TERM \$WGET_PID ) &
    TIMEOUT_PID=\$!
    wait \$WGET_PID
    CURRENT_RC=\$?
    kill -KILL \$TIMEOUT_PID
    STOP_TIME=\`date +%s\`
    if [ \$CURRENT_RC = 0 ]; then
      if [ \${cleanFlag} = 1 ]; then
        clean_hosts_file "\${targetName}.tmp" > "\${targetName}"
      else
        cp "\${targetName}.tmp" "\${targetName}"
      fi
      rm "\${targetName}.tmp"
      break
    fi
    # In the case of an error: wait the remaining time.
    TIME_SPAN=\$((\$STOP_TIME - \$START_TIME))
    WAIT_TIME=\$((\$WAIT_TIME - \$TIME_SPAN))
    [ \$WAIT_TIME -gt 0 ] && sleep \$WAIT_TIME
    # Increase the number of repeats.
    REPEAT=\$((\$REPEAT + 1))
    [ \$REPEAT = 4 ] && break
  done
}

# Function: download and clean host files by whitelist
download_clean_host_file() {
  # Set lock file.
  LOCK_FILE="/tmp/blocking_hosts.lock"

  # Check lock file.
  if [ ! -f "\$LOCK_FILE" ]; then
    sleep \$((\$\$ % 5 + 5))
    [ -f "\$LOCK_FILE" ] && exit 0
    echo \$\$ > "\$LOCK_FILE"

    # Start downloading files.
    # Create whitelist. The whitelist entries will be removed from the
    # hosts files, i.e. blacklist files.
    URL="https://raw.githubusercontent.com/yxd0018/super-hosts/master/src/whitelist"
    download_file \${URL} "${BH_WHITELIST}" 0

    HOSTS_FILE_NUMBER=1
    [ -d "/tmp/blocking_hosts" ] || mkdir "/tmp/blocking_hosts"
    for URL in "https://gitlab.com/ZeroDot1/CoinBlockerLists/-/raw/master/hosts" \\
              "https://gitlab.com/ZeroDot1/CoinBlockerLists/-/raw/master/hosts_optional" \\
              "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt" \\
              "http://www.malwaredomainlist.com/hostslist/hosts.txt" \\
              "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt" \\
              "https://someonewhocares.org/hosts/zero/hosts" \\
              "https://raw.githubusercontent.com/lassekongo83/Frellwits-filter-lists/master/Frellwits-Swedish-Hosts-File.txt" \\
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" \\
              "https://raw.githubusercontent.com/yxd0018/super-hosts/master/src/hosts"; do
      HOSTS_FILE="/tmp/blocking_hosts/hosts\`printf '%02d' \$HOSTS_FILE_NUMBER\`"
      download_file \${URL} \${HOSTS_FILE} 1
      HOSTS_FILE_NUMBER=\$((\$HOSTS_FILE_NUMBER + 1))
    done
    rm "\$LOCK_FILE"
  fi
}

# Function: create DNSMASQ setting
create_filter() {
  # Inspect downloaded hosts files.
  ANY_FILE_OK=1
  DNSMASQ_PARAM=""
  for HOSTS_FILE in /tmp/blocking_hosts/hosts[0-9][0-9]; do
    if [ -s "\$HOSTS_FILE" ]; then
      ANY_FILE_OK=0
      DNSMASQ_PARAM=\${DNSMASQ_PARAM:+\$DNSMASQ_PARAM }"--addn-hosts=\$HOSTS_FILE"
    else
      rm "\$HOSTS_FILE"
    fi
  done
  if [ \$ANY_FILE_OK = 0 ]; then
    logger "Restarting dnsmasq with additional hosts file(s) ...\${DNSMASQ_PARAM}"
    killall -TERM dnsmasq
    dnsmasq --conf-file=/tmp/dnsmasq.conf \$DNSMASQ_PARAM &
  fi
}

############################
# actual start
############################

if [ \${SKIP_DOWNLOAD} = 0 ]; then
  download_clean_host_file

create_filter

EOF

# Make it executeable.
chmod 755 "$BH_SCRIPT"


# skip as the dnsmasq setting is done manually to avoid eprom writing
# Add crontab entry to execute script on 2nd day of Jan and July at 2am.
# grep -q "$BH_SCRIPT" /tmp/crontab || echo "0 2 2 Jan,Jul * root $BH_SCRIPT" >>/tmp/crontab


# port setting
# 7000 admin
# 7001 ssh
# 7002 openvpn
# 7003 openvpn admin
# 7004 wireguard

# VPN wireguard
iptables -t nat -I POSTROUTING -o br0 -j SNAT --to $(nvram get lan_ipaddr)

# openvpn
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
iptables -I FORWARD -p udp -s 10.8.0.0/24 -j ACCEPT
iptables -I INPUT -p udp --dport=1194 -j ACCEPT
iptables -I OUTPUT -p udp --sport=1194 -j ACCEPT

iptables -I INPUT -p udp -i eth0 -j ACCEPT
iptables -I FORWARD -i eth0 -o tun0 -j ACCEPT
iptables -I FORWARD -i tun0 -o eth0 -j ACCEPT

iptables -I INPUT -p udp -i br0 -j ACCEPT
iptables -I FORWARD -i br0 -o tun0 -j ACCEPT
iptables -I FORWARD -i tun0 -o br0 -j ACCEPT

# Execute script in background.
sh "$BH_SCRIPT" &
