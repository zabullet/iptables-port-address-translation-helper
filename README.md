# iptables PAT rule helper script

## Intro

A simple bash script to help manage iptables in relation to port address translation rules.
I wrote this after spooling up an Amazon NAT instance and having to write a lot of forwarding rules to forward traffic to internal servers.

**NOTES**

- You need
- I have only tested this script on AMZ Linux NAT Instances (specifically amzn-ami-vpc-nat-hvm-2018.03.0.20180508-x86_64-ebs), so I'm not sure how extensible this is to other *nix flavours.
- On Amazon NAT instances 
  - You'll want to run `/usr/sbin/configure-pat.sh` before you start
  - You'll want to disable *Source/Destination Check* on your instance
  
## Install

`wget https://github.com/zabullet/iptables-port-address-translation-helper/raw/master/pathelp.sh -O pathelp.sh`

## Usage
```
Usage: pathelp.sh -a | -d [options]

-a            Add a rule based on other parameters
-d            Interactive removal of rules
--interface   Interface to apply the rule to e.g. eth0
--proto       Protocol to apply the rule to e.g. udp or tcp
--sourcep     Source Port to forward
--dest        Destination IP to forward to
--destp       Destination Port to forward to
--nosave .    Do not persist the iptable rules between reboots. Default is to save them
--nobackup    Do not produce an iptable rule backup file pathelp.[datetime].backup. Default is to create a backup

example:  add a forwarding rule to map incoming port 2222 to 172.31.15.26:22 and don't make the rule persistent
          sudo ./pathelp.sh -a -i eth0 --proto tcp --sourcep 2222 --dest 172.31.15.26 --destp 22 --nosave

example:  delete forwarding rules interactively and don't create a backup file
          sudo ./pathelp.sh -d --nobackup
```
## Contributing

As always, contributions are welcome

- If you have questions or want to do major changes please open an issue first to discuss
- General rules
  - Contributions should drive the system to be generic and extensible
  - Contributions should not break backwards compatibility

