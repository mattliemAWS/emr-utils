#!/bin/bash

#Update for security patches
sudo yum -y update

########INITIAL SETUP########
##Filesystem Configuration
#Disable unused filesystem
sudo touch /etc/modprobe.d/CIS.conf
sudo echo "install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
install vfat /bin/true" >> /etc/modprobe.d/CIS.conf
#Ensure sticky bit is set on all world-writable directories
sudo df --local -P | awk '{ if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

##Configure Softwarwe Updates
#Ensure gpgcheck is globally activated
sudo sed -i 's/gpgcheck=0/gpgcheck=1/' /etc/yum.repos.d/amzn-nosrc.repo

##Filesystem Integrity Checking
#Ensure AIDE is installed
sudo yum install -y aide
sudo aide --init
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
#Ensure filesystem integrity is regularly checked
sudo crontab -u root -l > mycron
sudo echo "0 5 * * * /usr/sbin/aide --check" >> mycron
sudo crontab mycron
sudo rm mycron

##Secure Boot Settings
#Ensure permissions on bootloader config are configured
sudo chown root:root /boot/grub/menu.lst
sudo chmod og-rwx /boot/grub/menu.lst
#Ensure authentication required for single user mode
sudo echo "SINGLE=/sbin/sulogin" >> /etc/sysconfig/init
#Ensure interactive boot is not enabled
sudo sed -i 's/PROMPT=yes/PROMPT=no/' /etc/sysconfig/init

##Additional Process Hardening
#Ensure core dumps are restricted
sudo echo "* hard core 0" >> /etc/security/limits.conf
sudo echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf

########SERVICES########
##Special Purpose Services
#Ensure X Window System is not installed
sudo yum remove -y xorg-x11*
#Ensure NFS and RPC are not enabled
sudo chkconfig nfs off
sudo chkconfig rpcbind off
# Ensure telnet client is not installed
sudo yum remove -y telnet

########NETWORK CONFIGURATIONS########
##Network Parameters
#3.1.2 Ensure packet redirect sending is disabled/IPV6
sudo echo "net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1" >> /etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
sudo sysctl -w net.ipv4.conf.default.send_redirects=0
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
sudo sysctl -w net.ipv4.conf.all.secure_redirects=0
sudo sysctl -w net.ipv4.conf.default.secure_redirects=0
sudo sysctl -w net.ipv4.conf.all.log_martians=1
sudo sysctl -w net.ipv4.conf.default.log_martians=1
sudo sysctl -w net.ipv4.conf.all.rp_filter=1
sudo sysctl -w net.ipv4.conf.default.rp_filter=1
sudo sysctl -w net.ipv6.conf.all.accept_ra=0
sudo sysctl -w net.ipv6.conf.default.accept_ra=0
sudo sysctl -w net.ipv6.conf.all.accept_redirects=0
sudo sysctl -w net.ipv6.conf.default.accept_redirects=0
sudo sysctl -w net.ipv6.route.flush=1
sudo sysctl -w net.ipv4.route.flush=1

########Logging and Auditing########
##Configure System Accounting
#Ensure audit logs are not automatically deleted
sudo sed -i 's/max_log_file_action = ROTATE/max_log_file_action = keep_logs/' /etc/audit/auditd.conf

#Ensure changes to system administration scope (sudoers) is collected
sudo echo "-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d/ -p wa -k scope
-w /var/log/sudo.log -p wa -k actions
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale
-w /etc/selinux/ -p wa -k MAC-policy
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
-w /var/log/wtmp -p wa -k logins 
-w /var/log/btmp -p wa -k logins
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295 -k delete
-a always,exit -F arch=b64 -S mount -F auid>=500 -F auid!=4294967295 -k mounts 
-a always,exit -F arch=b32 -S mount -F auid>=500 -F auid!=4294967295 -k mounts
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F path=/usr/lib/hadoop-yarn/bin/container-executor -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/screen -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/crontab -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/gpasswd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/passwd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/ssh-agent -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/lockfile -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/chsh -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/wall -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/at -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/write -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/chage -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/chfn -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/newgrp -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/libexec/openssh/ssh-keysign -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/libexec/utempter/utempter -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/sbin/seunshare -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/sbin/ccreds_chkpwd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/sbin/usernetctl -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/sbin/sendmail.sendmail -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/cgexec -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/mount -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/fusermount -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/cgclassify -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/su -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/bin/umount -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/lib64/dbus-1/dbus-daemon-launch-helper -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/sbin/pam_timestamp_check -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/sbin/mount.nfs -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/sbin/netreport -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-a always,exit -F path=/sbin/unix_chkpwd -F perm=x -F auid>=500 -F auid!=4294967295 -k privileged
-e 2" >> /etc/audit/audit.rules

sudo service auditd restart

#Configure rslog
sudo echo "\$FileCreateMode 0640" >>  /etc/rsyslog.conf

########Access, Authentication and Authorization########
##Configure Cron
#Ensure permissions on /etc/crontab are configured
sudo chown root:root /etc/crontab
sudo chmod og-rwx /etc/crontab
#Ensure permissions on /etc/cron.hourly are configured
sudo chown root:root /etc/cron.hourly
sudo chmod og-rwx /etc/cron.hourly
#Ensure permissions on /etc/cron.daily are configured
sudo chown root:root /etc/cron.daily
sudo chmod og-rwx /etc/cron.daily
#Ensure permissions on /etc/cron.weekly are configured
sudo chown root:root /etc/cron.weekly
sudo chmod og-rwx /etc/cron.weekly
#Ensure permissions on /etc/cron.monthly are configured
sudo chown root:root /etc/cron.monthly
sudo chmod og-rwx /etc/cron.monthly
#Ensure permissions on /etc/cron.d are configured
sudo chown root:root /etc/cron.d
sudo chmod og-rwx /etc/cron.d
#Ensure at/cron is restricted to authorized users
sudo rm -f /etc/cron.deny
sudo rm -f /etc/at.deny
sudo touch /etc/cron.allow
sudo touch /etc/at.allow
sudo chmod og-rwx /etc/cron.allow
sudo chmod og-rwx /etc/at.allow
sudo chown root:root /etc/cron.allow
sudo chown root:root /etc/at.allow

##SSH Server Configurations
sudo echo "PermitUserEnvironment no
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
ClientAliveInterval 300
ClientAliveCountMax 0
Banner /etc/issue.net
Protocol 2
LogLevel INFO
MaxAuthTries 4
IgnoreRhosts yes
HostbasedAuthentication no
LoginGraceTime 60
PermitUserEnvironment no
PermitEmptyPasswords no
AllowUsers ec2-user hadoop root
AllowGroups 
DenyUsers 
DenyGroups " >> /etc/ssh/sshd_config

sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

sudo sed -i 's/PermitRootLogin forced-commands-only/PermitRootLogin no/' /etc/ssh/sshd_config

###checkpoint1###
##Configure PAM
#Ensure password creation requirements are configured
sudo echo "minlen=14
dcredit=-1
ucredit=-1
ocredit=-1
lcredit=-1" >> /etc/security/pwquality.conf
#Ensure password reuse is limited
sudo sed -i 's/pam_unix.so sha512 shadow nullok try_first_pass use_authtok/pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5/' /etc/pam.d/password-auth
sudo sed -i 's/pam_unix.so sha512 shadow nullok try_first_pass use_authtok/pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5/' /etc/pam.d/system-auth

#Ensure default user shell timeout is 900 seconds or less
sudo echo "TMOUT=600" >> /etc/bashrc
sudo echo "TMOUT=600" >> /etc/profile

#Ensure access to the su command is restricted
sudo echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
sudo sed -i 's/10\:ec2-user/10\:ec2-user,root,hadoop/' /etc/group

###checkpoint2###

#Ensure auditing for processes that start prior to auditd is enabled 
sudo sed -i '/kernel/ s/$/ audit=1/' /boot/grub/menu.lst

#Ensure inactive password lock is 30 days or less
sudo useradd -D -f 30

##SSH Server Configurations
sudo echo "PermitUserEnvironment no
PermitRootLogin no" >> /etc/ssh/sshd_config

#Ensure telnet client is not installed
sudo yum -y remove telnet

#Ensure password expiration is 90 days or less
sudo sed -i 's/99999/90/' /etc/login.defs
sudo sed -i 's/PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs

###checkpoint 3####
##Disable Unused FileSystems##
sudo sed -i 's/tmpfs   defaults/tmpfs   defaults,nodev,nosuid,noexec/' /etc/fstab
sudo mount -o remount,nodev,nosuid,noexec /dev/shm

##Ensure permissions on all logfiles are configured
sudo find /var/log -type f -exec chmod g-wx,o-rwx {} +

##Ensure sticky bit is set on all world-writable directories
sudo df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

##Ensure system is disabled when audit logs are full
sudo sed -i 's/space_left_action = SYSLOG/space_left_action = email/' /etc/audit/auditd.conf
sudo sed -i 's/admin_space_left_action = SUSPEND/admin_space_left_action = halt/' /etc/audit/auditd.conf
