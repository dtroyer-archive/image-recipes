# Kickstart file for Centos 6.5 x86_64

# Basic kickstart bits
text
skipx
cmdline
install

lang en_US.UTF-8
keyboard us

rootpw  --iscrypted $6$youcantcrackitpentrucanuecriptat

network --onboot=on --bootproto=dhcp
firewall --disabled
authconfig --enableshadow --passalgo=sha512
selinux --disabled
timezone --utc Etc/UTC
firstboot --disable

# The following is the partition information you requested
# Note that any partitions you deleted are not expressed
# here so unless you clear all partitions first, this is
# not guaranteed to work


#bootloader --location=mbr --driveorder=sda --append=" rhgb crashkernel=auto quiet"
zerombr
clearpart --all --initlabel

bootloader --location=mbr --driveorder=sda --append=" rhgb crashkernel=auto quiet"

#part /boot --fstype=ext4 --size=500        --ondisk=sda --asprimary
part /     --fstype=ext4 --size=1   --grow --ondisk=sda --asprimary

part swap --fstype=swap --size=1 --grow --ondisk=sdb --asprimary


repo --name=base --baseurl=http://mirrors.kernel.org/centos/6/os/x86_64
repo --name=updates --baseurl=http://mirrors.kernel.org/centos/6/updates/x86_64
repo --name=epel --baseurl=http://mirrors.kernel.org/fedora-epel/6/x86_64

#repo updates enabled
#
# Action at the end of the installation.
#
poweroff
#halt
#reboot

# Bare-minimum packages
%packages --nobase
@core
openssh-server
nano
acpid
logrotate
ntp
ntpdate
openssh-clients
rng-tools
rsync
screen
tmpwatch
wget


%post
yum upgrade -y --nogpgcheck


#
# Disable filesystem checks on volumes.
#
tune2fs -c 0 -i 0 /dev/sda1
tune2fs -c 0 -i 0 /dev/sda2

#
# Turn off udev caching of network information.
#

rm -f /lib/udev/rules.d/*net-gen*
rm -f /etc/udev/rules.d/*net.rules


sed -i 's/HWADDR.*$//' /etc/sysconfig/network-scripts/ifcfg-eth0
echo "DHCPV6C=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "DHCPV6C_OPTIONS=\"-timeout 5\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0

#
# Remove reference to installation hostname in network configuration
#
sed -i "/HOSTNAME/d" /etc/sysconfig/network

# Download, install, and configure cloud-init

yum install -y cloud-init

sed -i 's/user: ec2-user/user: root/' /etc/cloud/cloud.cfg
sed -i 's/disable_root: 1/disable_root: 0/' /etc/cloud/cloud.cfg

#
# Secure the SSH daemon by shutting down non-key access.
# 
sed s/PasswordAuthentication\ yes/PasswordAuthentication\ no/ -i /etc/ssh/sshd_config
sed s/GSSAPIAuthentication\ yes/GSSAPIAuthentication\ no/ -i /etc/ssh/sshd_config
sed s/ChallengeResponseAuthentication\ yes/ChallengeResponseAuthentication\ no/ -i /etc/ssh/sshd_config
echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config

# Add sdb swap disk in the fstab
echo "/dev/sdb swap swap defaults 0 0" >> /etc/fstab
#
# Randomize root password now.
#
dd if=/dev/urandom count=50|sha512sum|passwd --stdin root

#cloud-init 0.6.3 UserDataHandler.py
#cloud-init 0.7.4 user_data.py
for f in UserDataHandler.py user_data.py; do
[ -f /usr/lib/python2.6/site-packages/cloudinit/$f ] || continue
sed -i '
/        msg = email.message_from_string(data)/c\
        if isinstance(data, unicode):\
            msg = email.message_from_string(data.encode('\'utf-8\''))\
        else:\
            msg = email.message_from_string(data)
' /usr/lib/python2.6/site-packages/cloudinit/$f
break
done

%end
