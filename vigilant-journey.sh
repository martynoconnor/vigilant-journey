#!/bin/bash

# A development of Urban Train, using loops and arrays rather than listing each
# iteration out as actual code.

# Script requires that you have iptables and ipset installed

# Bash doesn't support multi-dimensional arrays, meaning that the country name
# and digram have to go into separate arrays, or, in this case, we just use the
# digram as the name of the ipset - it's less human readable, but not by any 
# huge amount.

clear

# Define the country digrams
# This script pulls from the ipdeny.com zone file listings
# See http://ipdeny.com/ipblocks/ for more information and a list of the available
# IP blocks. Simply add the digram here below into the countries array.

countries=(ru sy tw cn tm ua kz il al ar bh sa by ba hr cz eg ee ge pl hk iq md ng qa ro sk si za tj th ae uz)

echo "######################################################"
echo "# Vigilant Journey - a Revised Firewall setup script #"
echo "######################################################"

# Begin script timer.
script_start=`date +%s`

echo
echo "Checking for /etc/iptables directory"
echo

# Check if the /etc/iptables directory exists, do nothing if it does exist.

if [ -d "/etc/iptables" ]; then
  echo "The /etc/iptables directory exists..."
  echo "No futher action required"
fi

# Check if directory exists, create it if not.

if [ ! -d "/etc/iptables" ]; then
  mkdir -p /etc/iptables
fi

echo
echo "#######################################################"
echo "# Downloading and iterating through country IP blocks #"
echo "#######################################################"

# Loop through the digrams, delete the old zone file if it exists, then
# download the latest zone file using the digram, then for each zone file
# cat the contents and feed that into ipset, creating a set with the same 
# name as the digram.

for x in "${countries[@]}"; do
	ipset -N $x hash:net	
	rm -f /etc/iptables/$x.zone
	wget -P . http://www.ipdeny.com/ipblocks/data/countries/$x.zone -O /etc/iptables/$x.zone 
		for i in $(cat /etc/iptables/$x.zone ); do ipset -A $x $i; done

# Take the digram named ipset and create an iptables rule to drop any traffic
# which comes from or is going to any of the ipsets specified within each rule.

iptables -A INPUT -p tcp -m set --match-set $x src -j DROP; done

echo 
echo "#####################################################"
echo "# Block all AWS public IPs, cause real people don't #"
echo "# browse to your site or server from an AWS box.    #"
echo "#####################################################"

rm -f ipv4_aws.json
wget https://ip-ranges.amazonaws.com/ip-ranges.json
jq -r '.prefixes | .[].ip_prefix' < ip-ranges.json > ipv4_aws.json
aws='ipv4_aws.json'
awslines=`cat $aws`
for line in $awslines ; do
    /sbin/iptables -A INPUT -s $line -j DROP
done

# Stop script timer and output execution time
script_end=`date +%s`
script_runtime=$((script_end-script_start))
echo
echo "Total script execution time was" $script_runtime "seconds."
echo
echo "You can check the status of your firewall rules with the command"
echo "iptables -L -n, and you can check individual ipsets with by using"
echo "the command ipset list xx, where xx is the country digram."
echo
