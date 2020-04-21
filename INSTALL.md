# RichGuk's Archlinux install

This follows the sets I use to setup a new Archlinux machine.

All my machines are UEFI. I use luks + btrfs for filesystem and systemd-boot
for boot management.

## Partitions + Filesystem setup

I use two partitions: boot, encrypted root. I use swap file on 5.0+ kernel instead of partition.

Partition the disk:

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

This gives you two partitions:

```
/dev/sda1
/dev/sda2
```

Next the luks encryption:

```bash
cryptsetup luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 cryptroot
```

Create root, home and the snapshot subvols respectively:

```bash
mkfs.fat -F32 /dev/sda1
mkfs.btrfs /dev/mapper/cryptroot

mount -o compress=zstd /dev/mapper/cryptroot /mnt
mkdir /mnt/snapshots

for d in /mnt/@ /mnt/@home /mnt/snapshots/@ /mnt/snapshots/@home /mnt/snapshots/btrbk; do
  btrfs subvol create $d
done
```

If restoring home from a backup do that now using [btrfs-send/btrfs-receive](https://btrfs.wiki.kernel.org/index.php/Incremental_Backup).

e.g:

```bash
btrfs send /mnt/backup/@home.backup | pv | btrfs receive /mnt
(or via SSH)
btrfs send /mnt/backup/@home.backup | pv | ssh root@arch-livedisk btrfs receive /mnt
```

There will now be a subvolume in /mnt called @home.backup. The subvolume will
probably be readonly. To [avoid Received UUID](https://github.com/digint/btrbk#restoring-backups)
later on snapshot the backup to create a rw version.

```bash
btrfs subvol delete /mnt/@home # if it exists
btrfs subvol snapshot /mnt/@home.backup /mnt/@home
btrfs subvol delete /mnt/@home.backup
```

Now mount the file system:

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
- `compress=zstd` - I use zstd to apply some compression (needs Kernel > 4.14, I used to use lzo before).


I like to subvolume some directories to avoid including them in backups.
I also turn off copy-on-write for databases/VMs.

```bash
cd /mnt
mkdir -p var/lib

for d in var/log var/cache var/lib/machines var/lib/mysql var/lib/postgres; do
  btrfs subvol create $d
done

chattr +C var/lib/machines var/lib/mysql var/lib/postgres
```


## Install the system

The following steps are mostly taken from [Archlinux install guide](https://wiki.archlinux.org/index.php/installation_guide).


Install the base system:

```bash
pacstrap /mnt base base-devel htop neovim vim linux wpa_supplicant \
zsh zsh-syntax-highlighting zsh-completions \
fzf git tmux btrfs-progs rsync openssh nodejs yarn ruby
```

Generate fstab:

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
UUID=45431545-67de-4ce1-81b2-e881b09bd6f9       /               btrfs           rw,noatime,nodiratime,compress=zstd:3,space_cache,subvol=/@,subvol=@ 0 0

# /dev/vda1
UUID=559E-32F1          /boot           vfat            rw,noatime,nodiratime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,errors=remount-ro       0 2

# /dev/mapper/cryptroot
UUID=45431545-67de-4ce1-81b2-e881b09bd6f9       /home           btrfs           rw,noatime,nodiratime,compress=zstd:3,space_cache,subvol=/@home,subvol=@home 0 0
```

Before chrooting into the install I like to record the current UUIDs/partition
setup because I find it easier to do now than when in chroot.

```bash
lsblk -f >> /mnt/install-lsblk-info
```

Now chroot and finish the main install:

```bash
arch-chroot /mnt

# Uncomment en_GB.UTF-8
sed -i '/#en_GB.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo LANG=en_GB.UTF-8 > /etc/locale.conf

echo keymap=uk > /etc/vconsole.conf 

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
timedatectl set-ntp true

echo new-host > /etc/hostname

passwd # for root
```

Edit `/etc/hosts` with the following (updating hostname with correct one):

```conf
127.0.0.1       localhost
::1             localhost
127.0.1.1       new-host.localdomain      new-host

```

Modify `/etc/mkinitcpio.conf` to add _systemd_, _sd-vconsole_, _sd-encrypt_
and move _keyboard_:


```diff
# For USB thumbdrive keyfiles
--- MODULES=()
+++ MODULES=(ext4)

--- BINARIES=()
+++ BINARIES=(btrfs)

--- HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
+++ HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)

```

Regenerate initramfs

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
options amd_iommu=on iommu=pt rd.luks.key=UUID_OF_USB_KEY=/keys/galactica.key:UUID=UUID_OF_LUKS_PART rd.luks.name=UUID_OF_LUKS_PARTITION_SDA2=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard rw
```

note:
-  amd_iommu for [PCI passthrough](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
- If using USB flash drive for unlocking encryption add td.luks.keys


Edit `/boot/loader/loader.conf`:
```conf
default arch
timeout 2
```

Check fstab is correct and then reboot:

```bash
exit
umount -R /mnt
reboot
```

## Post install

Login as root (using password from earlier).

Until I have desktop envrionemnt setup and either systemd-networkd or network manager configured I will do manual network setup to get things installing:

```bash
ip addr add 192.168.40.15/24 dev enp1s0
ip route add default via 192.168.40.1 dev enp1s0
echo nameserver 8.8.8.8 >> /etc/resolv.conf

```

Enable some services (fstrim for SSD) and setup my users:

```bash
systemctl enable sshd systemd-timesyncd fstrim.timer

useradd -m -G power,audio,wheel,input,kvm -s /usr/bin/zsh rich
passwd rich
```

Edit sudoers to enable wheel group access:

```bash
export EDITOR=nvim
visudo

## Uncomment to allow members of group wheel to execute any command
%wheel ALL=(ALL) ALL
```

Save, exit and login as me. Then setup dotfiles (see [README.md](README.md)).

Once that's done setup AUR manager. I'm using [yay](https://aur.archlinux.org/packages/yay/).

```bash
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si
```

Graphics setup:
```bash
sudo pacman -S xorg-server xf86-video-fbdev xf86-video-nouveau | xf86-video-amdgpu
```

KDE envrionment (login manager, desktop, needed fonts and themes):

```bash
sudo pacman -S plasma colord-kde kdeconnect  \
sddm sddm-kcm \
konsole dolphin kate \
materia-kde kvantum-theme-materia \
adobe-source-code-pro-fonts noto-fonts noto-fonts-emoji ttf-opensans ttf-roboto \
ttf-fira-mono ttf-bitstream-vera inetutils firefox chromium virt-manager libvirt \
docker docker-compose kubectl helm

yay -S otf-san-francisco sierrabreeze-kwin-decoration-git archlinux-artwork plasma5-applets-eventcalendar
```

Add some addtional groups for my user:

```
sudo usermod -a -G docker,libvirt rich
sudo systemctl enable docker libvirtd
```

Configure SDDM (login manager), create _etc/sddm.conf.d/kde_settings.conf_:

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

Enable access to avatar picture:

```bash
setfacl -m u:sddm:r /home/rich/.face
setfacl -m u:sddm:x /home/rich
```

Start kde:

```bash
sudo systemctl enable sddm
sudo systemctl start sddm
```

Done.
