---
layout: post
title: "Configure ssh on Raspberry Pi"
date: 2019-10-15
categories: raspberrypi
author:
- Amit Rai Sharma
tags: raspberry-pi
---

# Install and enable ssh service
* sudo systemctl enable ssh – this command will enable ssh
* sudo systemctl start ssh – this command will start ssh service

# Check ssh service status
* sudo service ssh status – if you see following errors, then the ssh rsa key is invalid and you would have to regenerate the keys.


```bash
Loaded: loaded (/lib/systemd/system/ssh.service; enabled)
   Active: active (running) since Wed 2018-11-14 08:51:38 UTC; 6min ago
 Main PID: 1332 (sshd)
   CGroup: /system.slice/ssh.service
           └─1332 /usr/sbin/sshd -D

Nov 14 08:51:38 raspberrypi sshd[1332]: key_load_public: invalid format
Nov 14 08:51:38 raspberrypi sshd[1332]: Could not load host key: /etc/ssh/ss...y
Nov 14 08:51:38 raspberrypi sshd[1332]: key_load_public: invalid format
Nov 14 08:51:38 raspberrypi sshd[1332]: Could not load host key: /etc/ssh/ss...y
Nov 14 08:51:42 raspberrypi sshd[1338]: error: key_load_public: invalid format
Nov 14 08:51:42 raspberrypi sshd[1338]: error: Could not load host key: /etc...y
Nov 14 08:51:42 raspberrypi sshd[1338]: error: key_load_public: invalid format
Nov 14 08:51:42 raspberrypi sshd[1338]: error: Could not load host key: /etc...y
Nov 14 08:51:42 raspberrypi sshd[1338]: error: key_load_public: invalid format
Nov 14 08:51:42 raspberrypi sshd[1338]: error: Could not load host key: /etc...y
Hint: Some lines were ellipsized, use -l to show in full.
```

# Regenerate ssh key
* sudo rm /etc/ssh/ssh_host_*  – this will removed ssh_host files
* sudo dpkg-reconfigure openssh-server  – this will regenerate the rsa key for ssh server


# Connect to raspberry pi
* ssh pi@<ip address> (hint: execute ifconfig command on raspberry pi to find the ip address)