#Kickstart file for CentOS 7 X86_64

# Basic kickstart bits
text
skipx
cmdline
install

url --url=http://mirrors.kernel.org/centos/7/os/x86_64

# Repositories
repo --name=base --baseurl=http://mirrors.kernel.org/centos/7/os/x86_64
repo --name=updates --baseurl=http://mirrors.kernel.org/centos/7/updates/x86_64
repo --name=epel --baseurl=http://mirrors.kernel.org/fedora-epel/beta/7/x86_64/

# Common configuration
rootpw --iscrypted $1$2fakehash-bruteforcetocrackitnowalibaba
lang en_US.UTF-8
keyboard us
timezone UTC
eula --agreed
firewall --disabled
selinux --disabled
services --enabled=NetworkManager,sshd
ignoredisk --only-use=sda
auth --useshadow --enablemd5
firstboot --disable


# Halt after installation
poweroff


# System services
services --disabled="avahi-daemon,iscsi,iscsid,firstboot,kdump" --enabled="network,sshd,rsyslog,tuned"
# System timezone
timezone --isUtc UTC
# Network information
network --onboot=on --bootproto=dhcp
# System bootloader configuration
bootloader --location=mbr --append="console=tty console=ttyS0 notsc"
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part / --size 100 --fstype ext4 --grow

%post

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

cat <<EOL >> /etc/rc.local
if [ ! -d /root/.ssh ] ; then
    mkdir -p /root/.ssh
    chmod 0700 /root/.ssh
    restorecon /root/.ssh
fi
EOL

cat <<EOL >> /etc/ssh/sshd_config
UseDNS no
PermitRootLogin without-password
EOL

# bz705572
ln -s /boot/grub/grub.conf /etc/grub.conf

# bz688608
sed -i 's|\(^PasswordAuthentication \)yes|\1no|' /etc/ssh/sshd_config

# allow sudo powers to cloud-user
echo -e 'cloud-user\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# bz983611
echo "NOZEROCONF=yes" >> /etc/sysconfig/network

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tune-profiles/active-profile

#bz 1011013
# set eth0 to recover from dhcp errors
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF

#bz912801
# prevent udev rules from remapping nics
touch /etc/udev/rules.d/75-persistent-net-generator.rules

#setup getty on ttyS0
echo "ttyS0" >> /etc/securetty
cat <<EOF > /etc/init/ttyS0.conf
start on stopped rc RUNLEVEL=[2345]
stop on starting runlevel [016]
respawn
instance /dev/ttyS0
exec /sbin/agetty /dev/ttyS0 115200 vt100-nav
EOF

# lock root password
passwd -d root
passwd -l root

# clean up installation logs"
yum clean all
rm -rf /var/log/yum.log
rm -rf /var/lib/yum/*
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /root/anaconda-ks.cfg
rm -rf /var/log/anaconda*
%end

%packages --nobase --ignoremissing
@core
acpid
attr
audit
authconfig
basesystem
bash
cloud-init
coreutils
cpio
cronie
device-mapper
dhclient
e2fsprogs
efibootmgr
filesystem
glibc
grub
heat-cfntools
initscripts
iproute
iptables
iptables-ipv6
iputils
kbd
kernel
kpartx
ncurses
net-tools
nfs-utils
ntp
ntpdate
nano
openssh-clients
openssh-server
parted
passwd
policycoreutils
procps
rootfiles
rpm
rsync
rsyslog
selinux-policy
selinux-policy-targeted
sendmail
setup
screen
shadow-utils
sudo
syslinux
tar
tuned
util-linux-ng
vim-minimal
wget
yum
yum-metadata-parser
-*-firmware
-NetworkManager
-b43-openfwwf
-biosdevname
-fprintd
-fprintd-pam
-gtk2
-libfprint
-mcelog
-plymouth
-redhat-support-tool
-system-config-*
-wireless-tools

%end
