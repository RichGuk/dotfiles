# RichGuk's Archlinux install

This follows the sets I use to setup a new Archlinux machine.

All my machines are UEFI. I use luks + btrfs for filesystem and systemd-boot
for boot management.

## Partitions + Filesystem setup

I only have two partitions on my SSDs. Boot and Encrypted btrfs.

```bash
gdisk /dev/sda

Create two partitions:
+512M ef00
+rest of space  8300

Command (? for help): o
This option deletes all partitions and creates a new protective MBR.
Proceed? (Y/N): y

Command (? for help): n
Partition number (1-128, default 1):
First sector (34-4194270, default = 2048) or {+-}size{KMGTP}:
Last sector (2048-4194270, default = 4194270) or {+-}size{KMGTP}: +512M
Hex code or GUID (L to show codes, Enter = 8300): ef00
Changed type of partition to 'EFI System'

Command (? for help): n
Partition number (2-128, default 2):
First sector (34-4194270, default = 1050624) or {+-}size{KMGTP}:
Last sector (1050624-4194270, default = 4194270) or {+-}size{KMGTP}: (press enter to use entire disk)
Hex code or GUID (L to show codes, Enter = 8300): (press enter to use default)
Changed type of partition to 'Linux filesystem'

w
```

This gives you two partitions

```
/dev/sda1
/dev/sda2
```

Next we need to setup the luks encryption.

```bash
cryptsetup luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 cryptroot
```

Now we can format the drives and create the btrfs subvolumes. I liked to subvol
my root/home so I can easily setup snapshots of these later.

```bash
mkfs.fat -F32 /dev/sda1
mkfs.btrfs /dev/mapper/cryptroot

mount -o compress=zstd /dev/mapper/cryptroot /mnt
mkdir /mnt/snapshots
btrfs subvol create /mnt/@
btrfs subvol create /mnt/@home
btrfs subvol create /mnt/snapshots/@
btrfs subvol create /mnt/snapshots/@home
btrfs subvol create /mnt/snapshots/btrbk
```

If we're restoring home from a backup we can do that now using [btrfs-send/btrfs-receive](https://btrfs.wiki.kernel.org/index.php/Incremental_Backup).

```bash
btrfs send /mnt/backup/@home.backup | pv | btrfs receive /mnt
(or via SSH)
btrfs send /mnt/backup/@home.backup | pv | ssh root@arch-livedisk btrfs receive /mnt
```

There will now be a subvolume in /mnt called @home.backup. The subvolume will
probably be readonly. To [avoid Received UUID](https://github.com/digint/btrbk#restoring-backups)
later on we should snapshot this backup now to create a rw version.

```bash
btrfs subvol delete /mnt/@home # if it exists
btrfs subvol snapshot /mnt/@home.backup /mnt/@home
btrfs subvol delete /mnt/@home.backup
```


I like to subvolume some directories to avoid including them in backups.
I also turn off copy-on-write for databases/VMs.

```bash
mkdir -p /mnt/var/cache
mkdir -p /mnt/var/lib

btrfs subvol create /mnt/var/cache/pacman
btrfs subvol create /mnt/var/lib/machines
btrfs subvol create /mnt/var/log
btrfs subvol create /mnt/var/lib/mysql
btrfs subvol create /mnt/var/lib/postgres

chattr +C /mnt/var/lib/mysql
chattr +C /mnt/var/lib/postgres
chattr +C /mnt/var/lib/machines
```

Now we can mount the file system correctly ready for installation.

```bash
umount -R /mnt
mount -o compress=zstd,noatime,nodiratime,subvol=@ /dev/mapper/cryptroot /mnt
mkdir /mnt/home /mnt/boot
mount -o compress=zstd,noatime,nodiratime,subvol=@home /dev/mapper/cryptroot /mnt/home
mount /dev/sda1 /mnt/boot
```

I use the following options for btrfs:

- `noatime` - (no access time) - Disables writing access time to each file when
they're accessed. I don't use any applications that need it so I
disable it to save myself from pointless writes.
- `nodiratime` - (no directory access time) - Same thing but for directories.
- `compress=zstd` - I use zstd to apply some compression. Its fast and invisible.
Helps a lot with text files (needs Kernel > 4.14, I used to use lzo before).


## Install the system

The following steps are mostly taken from [Archlinux install guide](https://wiki.archlinux.org/index.php/installation_guide).


Install the base system.

```bash
pacstrap /mnt base base-devel ntp htop neovim vim linux wpa_supplicant \
zsh zsh-syntax-highlighting zsh-completions \
fzf git tmux btrfs-progs rsync openssh nodejs yarn ruby
```

Generate fstab.
```bash
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

Example fstab:

```conf
# Static information about the filesystems.
# See fstab(5) for details.

# <file system> <dir> <type> <options> <dump> <pass>
# /dev/mapper/cryptroot
UUID=45431545-67de-4ce1-81b2-e881b09bd6f9       /               btrfs           rw,noatime,nodiratime,compress=zstd:3,space_cache,subvolid=277,subvol=/@,subvol=@ 0 0

# /dev/vda1
UUID=559E-32F1          /boot           vfat            rw,noatime,nodiratime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,errors=remount-ro       0 2

# /dev/mapper/cryptroot
UUID=45431545-67de-4ce1-81b2-e881b09bd6f9       /home           btrfs           rw,noatime,nodiratime,compress=zstd:3,space_cache,subvolid=276,subvol=/@home,subvol=@home 0 0
```

Before chrooting into the install I like to record the current UUIDs/partition
setup because I find it easier to do now than when in chroot.

```bash
lsblk -f >> /mnt/install-lsblk-info
```

Now we can setup chroot and setup the main system.

```bash
arch-chroot /mnt

nvim /etc/locale.gen # Uncomment en_GB.UTF-8
locale-gen
echo LANG=en_GB.UTF-8 > /etc/locale.conf

echo keymap=uk > /etc/vconsole.conf 

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

echo new-host > /etc/hostname

passwd # for root
```

Edit `/etc/hosts` with the following (updating hostname with correct one).
```conf
127.0.0.1       localhost
::1             localhost
127.0.1.1       new-host.localdomain      new-host

```

Modify `/etc/mkinitcpio.conf` to add _systemd_, _sd-vconsole_, _sd-encrypt_
and move _keyboard_.


```diff
--- HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
+++ HOOKS=(base systemd udev autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)


--- BINARIES=()
+++ BINARIES=(btrfs)
```

Install the changes.

```bash
mkinitcpio -P
```

Install the systemd-boot loader.

```bash
bootctl --path=/boot install
```

Configure boot entry for the install. We need the UUID info from earlier.
Open `nvim /boot/loader/entries/arch.conf`:

```conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options amd_iommu=on iommu=pt rd.luks.name=UUID_OF_LUKS_PARTITION_SDA2=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard rw
```

(note amd_iommu for [PCI passthrough](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF)

Edit `/boot/loader/loader.conf`:
```conf
default arch
timeout 2
```

After that we should be ready to reboot.

```bash
exit
umount -R /mnt
reboot
```

Should hopefully have a fresh system.

## Post install

First thing I like to do is enable a few key things (network, ssh, TRIM)
and create my user with sudo access.

Login as root with password from setup and run the following:


```bash
systemctl enable sshd ntpd fstrim.timer

useradd -m -G power,audio,wheel,input,kvm -s /bin/zsh rich
passwd rich
```

Edit sudoers to enable wheel group access:

```bash
export EDITOR=nvim
visudo

## Uncomment to allow members of group wheel to execute any command
%wheel ALL=(ALL) ALL
```

Save file,  exit and login as new user.

First thing I like to do is setup my AUR manager. I'm using [yay](https://aur.archlinux.org/packages/yay/).

```bash
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si
```

Graphics setup:
```bash
sudo pacman -Sy xorg-server xf86-video-fbdev xf86-video-nouveau | xf86-video-amdgpu
```

KDE envrionment (login manager, desktop, needed fonts and themes):

```bash
sudo pacman -Sy plasma colord-kde kdeconnect  \
sddm sddm-kcm \
konsole dolphin kate \
adobe-source-code-pro-fonts noto-fonts noto-fonts-emoji ttf-opensans ttf-roboto ttf-fira-mono \
ttf-bitstream-vera

yay -Sy chili-sddm-theme osx-arc-darker \
otf-san-francisco sierrabreeze-kwin-decoration-git archlinux-artwork \
materia-kde kvantum-theme-materia materia-gtk-theme \
plasma5-applets-eventcalendar

sudo systemctl enable sddm
sudo systemctl start sddm
```

Some other packages I have installed:
```bash
pacman -Sy inetutils firefox chromium git virt-manager libvirt \
docker docker-compose kubectl helm
```
Finally now libvirt and docker are installed we can add myself to the groups
and start them.

```
sudo usermod -a -G docker,libvirt rich
sudo systemctl enable docker libvirtd
```

Follow [README.md](README.md) to setup my home config files + KDE theme etc.

Finally configure SDDM. Edit the following:

sudo cat /etc/sddm.conf.d/kde_settings.conf
```conf
[Autologin]
Relogin=false
Session=plasma
User=rich

[General]
HaltCommand=/usr/bin/systemctl poweroff
Numlock=none
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=breeze

[Users]
MaximumUid=60000
MinimumUid=1000
```

Finally give access to avatar.

```bash
setfacl -m u:sddm:r /home/rich/.face
setfacl -m u:sddm:x /home/rich
```


