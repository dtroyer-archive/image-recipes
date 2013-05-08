# This is a basic CentOS 6 spin designed to work in OpenStack and other
# virtualized environments. It's configured with cloud-init so it will
# take advantage of ec2-compatible metadata services for provisioning
# ssh keys and user data. 
#
# Note that unlike the standard F18 install, this image has /tmp on disk
# rather than in tmpfs, since memory is usually at a premium.

# Repositories
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-18&arch=$basearch
repo --name=fedora-updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f18&arch=$basearch 

# Common configuration
lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC
network --bootproto=dhcp --device=eth0 --onboot=on
# placeholder, the actual firewall used is generated on %post
firewall --service=ssh
auth --useshadow --enablemd5
selinux --enforcing

# Simple disk layout
bootloader --timeout=0 --location=mbr --append="console=tty console=ttyS0"
#bootloader --timeout=0 --location=mbr --driveorder=sda --append="console=tty console=ttyS0"
part biosboot --fstype=biosboot --size=1 --ondisk sda
part / --size 10000 --fstype ext4 --ondisk sda

# Start a few things
services --enabled=network,sshd,rsyslog,iptables,cloud-init,cloud-init-local,cloud-config,cloud-final

# Bare-minimum packages
%packages --nobase
#@core
kernel
rsync
tar
tmpwatch

# cloud-init does magical things with EC2 metadata, including provisioning
# a user account with ssh keys.
cloud-init

# Not needed with pv-grub (as in EC2). Would be nice to have
# something smaller for F19 (syslinux?), but this is what we have now.
grub2

# Needed initially, but removed below.
firewalld

# Basic firewall. If you're going to rely on your cloud service's
# security groups you can remove this.
iptables-services

# cherry-pick a few things from @standard

# Some things from @core we can do without in a minimal install
-biosdevname
-NetworkManager
-plymouth
-polkit
-sendmail

%end

# Fix up the installation
%post --nochroot
echo "Configure GRUB2 for serial console"
echo GRUB_TIMEOUT=0 > $INSTALL_ROOT/etc/default/grub
echo GRUB_TERMINAL=console >>$INSTALL_ROOT/etc/default/grub
echo GRUB_CMDLINE_LINUX=\"console=ttyS0 console=tty\" >>$INSTALL_ROOT/etc/default/grub
echo GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0\" >>$INSTALL_ROOT/etc/default/grub
mount -o bind /dev $INSTALL_ROOT/dev
/usr/sbin/chroot $INSTALL_ROOT /sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
umount $INSTALL_ROOT/dev
%end


%post --erroronfail

echo -n "Writing fstab"
cat <<EOF > /etc/fstabx
LABEL=_/   /         ext4    defaults        1 1
EOF
echo .

echo -n "Grub tweaks"
sed -i '1i# This file is for use with pv-grub; legacy grub is not installed in this image' /boot/grub/grub.conf
sed -i 's/^timeout=5/timeout=0/' /boot/grub/grub.conf
sed -i 's/^default=1/default=0/' /boot/grub/grub.conf
sed -i '/splashimage/d' /boot/grub/grub.conf
# need to file a bug on this one
sed -i 's/root=.*/root=LABEL=_\//' /boot/grub/grub.conf
echo .
if ! [[ -e /boot/grub/menu.lst ]]; then
  echo -n "Linking menu.lst to old-style grub.conf for pv-grub"
  ln /boot/grub/grub.conf /boot/grub/menu.lst
  ln -sf /boot/grub/grub.conf /etc/grub.conf
fi

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

# If you want to remove rsyslog and just use journald, also uncomment this.
#echo -n "Enabling persistent journal"
#mkdir /var/log/journal/ 
#echo .

# this is installed by default but we don't need it in virt
#echo "Removing linux-firmware package."
#yum -C -y remove linux-firmware

# Remove firewalld; was supposed to be optional in F18, but is required to
# be present for install/image building.
echo "Removing firewalld."
yum -C -y remove firewalld

# Non-firewalld-firewall
echo -n "Writing static firewall"
cat <<EOF > /etc/sysconfig/iptables
# Simple static firewall loaded by iptables.service. Replace
# this with your own custom rules, run lokkit, or switch to 
# shorewall or firewalld as your needs dictate.
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate NEW -m tcp -p tcp --dport 22 -j ACCEPT
#-A INPUT -m conntrack --ctstate NEW -m tcp -p tcp --dport 80 -j ACCEPT
#-A INPUT -m conntrack --ctstate NEW -m tcp -p tcp --dport 443 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF
echo .

# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

# Rename the 'ec2-user' account to 'fedora'
sed -i '
  s/name: ec2-user/name: fedora/g
  s/gecos: EC2/gecos: Fedora/g
' /etc/cloud/cloud.cfg

echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
echo "(Don't worry -- that out-of-space error was expected.)"

# Leave behind a build stamp
echo "build=$(date +%F.%T)" >/etc/.build

%end
