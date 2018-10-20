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


install
text
cdrom
lang en_US.UTF-8
keyboard us
network --onboot yes --bootproto=dhcp --noipv6 --device=eth0
authconfig --enableshadow --passalgo=sha512
timezone --utc UTC
clearpart --all --initlabel
bootloader --location=mbr
part / --size=100 --grow --fsoptions="defaults" --label=/ --fstype=xfs

# Repositories to use
repo --name="CentOS" --baseurl=http://mirror.centos.org/centos/7/os/x86_64/ --cost=100
## Uncomment for rolling builds
#repo --name="Updates" --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/ --cost=100
repo
rootpw root_password_will_be_deleted
firewall --disabled
selinux --disabled

services --disabled=NetworkManager,kdump --enabled=network,sshd,ntpd
skipx

reboot
zerombr
%packages --nobase
@core
openssh-server
openssh-clients
acpid
kpartx
gdisk
net-tools
ntp
parted
rsync
vim
# Make sure that subscription-manager and rhn packages are not installed as
# they conflict with GCE packages.
-subscription-manager
-*rhn*
-alsa-utils
-b43-fwcutter
-dmraid
-eject
-gpm
-kexec-tools
-irqbalance
-microcode_ctl
-smartmontools
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-efibootmgr
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6050-firmware
-kernel-firmware
-libertas-usb8388-firmware
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-rt61pci-firmware
-rt73usb-firmware
-xorg-x11-drv-ati-firmware
-zd1211-firmware
%end

%post
set -x
rm -f /etc/boto.cfg /etc/udev/rules.d/*persistent-net.rules
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules
sed -i '/^\(HWADDR\)=/d' /etc/sysconfig/network-scripts/ifcfg-*
cat >>/etc/dhclient.conf <<EOL
# Set the dhclient retry interval to 10 seconds instead of 5 minutes.
retry 10;
EOL

## Set the network settings for eth0.
## Set the MTU.
## Set dhclient to be persistent instead of oneshot.
## Enable IPv6.
cat >>/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOL
MTU=1460
PERSISTENT_DHCLIENT="y"
IPV6INIT=yes
EOL
## Remove files which shouldn't make it into the image.
rm -f /etc/boto.cfg /etc/udev/rules.d/*-persistent-net.rules
#
firewall-offline-cmd --set-default-zone=trusted
%end
