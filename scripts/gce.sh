#!/bin/sh
# Copyright 2018 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#  https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## DELETE THE ROOT PASSWORD ##
passwd -d
##############################
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

#Remove rhgb and quiet from kernel command line
sed -i -e $'/rhgb/s/rhgb//' /etc/default/grub
sed -i -e $'/quiet/s/quiet//' /etc/default/grub
#add console to kernel command line
#sed -i -e $'/GRUB_CMDLINE_LINUX/s/=".*$/="console=ttyS0,38400n8d"/' /etc/default/grub
sed -i -e $'/GRUB_CMDLINE_LINUX/s/=".*$/="serial=tty0 console=ttyS0,38400n8d"/' /etc/default/grub
echo 'GRUB_TERMINAL="serial"' >> /etc/default/grub
echo 'GRUB_SERIAL_COMMAND="serial --speed=19200 --unit=0 --word=8 --parity=no --stop=1"' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

## We have to update our images before we install yum-cron otherwise our changes
## will get clobbered when yum updates.
yum -y install yum-cron
## Make changes to yum-cron.conf on el7/centos7
grep apply_updates /etc/yum/yum-cron.conf
cp /etc/yum/yum-cron.conf /tmp/yum-cron.conf
## Apply updates
sed -i 's/update_cmd =.*/update_cmd = default/' /tmp/yum-cron.conf
sed -i 's/apply_updates =.*/apply_updates = yes/' /tmp/yum-cron.conf
cat /tmp/yum-cron.conf > /etc/yum/yum-cron.conf
grep apply_updates /etc/yum/yum-cron.conf
## This enables the service on both el6 and el7 based VMs.
chkconfig yum-cron on
#
## Clean up the cache for smaller images.
yum clean all
#
## Blacklist the floppy module.
echo "blacklist floppy" > /etc/modprobe.d/blacklist-floppy.conf
#
## Set the default timeout to 0 and update grub2.
sed -i 's:GRUB_TIMEOUT=.*:GRUB_TIMEOUT=0:' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
echo "Running dracut."
dracut -f
#
## Disable IPv6 for Yum.
echo "ip_resolve=4" >> /etc/yum.conf
#
## Ensure no attempt will be made to persist network MAC addresses.
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules
sed -i '/^\(HWADDR\)=/d' /etc/sysconfig/network-scripts/ifcfg-*
#
## Disable password authentication by default.
sed -i -e '/^PasswordAuthentication /s/ yes$/ no/' /etc/ssh/sshd_config

## Disable requiring password for sudo
sed -i -e $'/^%whee/s/^/#/' /etc/sudoers
sed -i -e $'/NOPASSWD/s/#//' /etc/sudoers

#
## Set ServerAliveInterval and ClientAliveInterval to prevent SSH
## disconnections. The pattern match is tuned to each source config file.
## The $'...' quoting syntax tells the shell to expand escape characters.
sed -i -e $'/^\tServerAliveInterval/d' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tServerAliveInterval 420' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tTunnel no' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tCiphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,aes128-cbc,3des-cbc' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tStrictHostKeyChecking no' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tHostBasedAuthentication no' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tForwardX11 no' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tForwardAgent no' /etc/ssh/ssh_config
sed -i -e $'/^Host \\*$/a \\\tProtocol 2' /etc/ssh/ssh_config
sed -i -e '/ClientAliveInterval/s/^.*/ClientAliveInterval 420/' /etc/ssh/sshd_config
#
## Disable root login via SSH by default.
sed -i -e '/PermitRootLogin yes/s/^.*/PermitRootLogin no/' /etc/ssh/sshd_config
## Disable sshd tunnelt.
sed -i -e '/PermitTunnel.*$/s/^.*/PermitTunnel no/' /etc/ssh/sshd_config
## Allow tcp forwarding
sed -i -e '/AllowTcpForwarding.*$/s/^.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config
## Disallow X11 Forwarding
sed -i -e '/X11Forwarding.*$/s/^.*/X11Forwarding no/' /etc/ssh/sshd_config

#
## Configure NTPD to use our servers.
sed -i -e '/pool.ntp.org/d' /etc/ntp.conf
cat >>/etc/ntp.conf <<EOD
## Use the Google Compute Engine ntp server.
## iburst speeds up the initial sync.
server metadata.google.internal iburst
EOD
