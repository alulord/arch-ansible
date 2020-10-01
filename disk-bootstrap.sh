#!/usr/bin/env bash
set -e

DRIVE="$1"
DISK_SIZE="$2"
if [[ -n "$DISK_SIZE" ]]; then
  DISK_SIZE="+$DISK_SIZE"
fi

sgdisk --zap-all --clear $DRIVE
sgdisk --clear \
  --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
  --new=2:0:+8GiB --typecode=2:8200 --change-name=2:cryptswap \
  --new=3:0:"${DISK_SIZE:-0}" --typecode=3:8300 --change-name=3:cryptsystem \
  "$DRIVE"
partprobe "$DRIVE"

cryptsetup luksFormat --align-payload=8192 -s 256 -c aes-xts-plain64 /dev/disk/by-partlabel/cryptsystem
cryptsetup open /dev/disk/by-partlabel/cryptsystem system
cryptsetup open --type plain --key-file /dev/urandom /dev/disk/by-partlabel/cryptswap swap

mkswap -L swap /dev/mapper/swap
swapon -L swap
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
mkfs.btrfs --force --label system /dev/mapper/system

o=defaults,x-mount.mkdir
o_btrfs=$o,compress=lzo,ssd,space_cache,noatime
mount -t btrfs LABEL=system /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/snapshots
umount -R /mnt

mount -t btrfs -o subvol=root,$o_btrfs LABEL=system /mnt
mount -t btrfs -o subvol=home,$o_btrfs LABEL=system /mnt/home
mount -t btrfs -o subvol=snapshots,$o_btrfs LABEL=system /mnt/.snapshots
mount -o $o LABEL=EFI /mnt/boot

pacstrap /mnt base base-devel git nano ansible
genfstab -L -p /mnt >>/mnt/etc/fstab
sed -i "s+LABEL=swap+/dev/mapper/swap+" /mnt/etc/fstab

mkdir /mnt/install
echo "luks_uuid: $(blkid -t PARTLABEL=cryptsystem -s UUID -o value)" >>/install/group_vars/all.yaml
echo "root_uuid: $(blkid -t LABEL=system -s UUID -o value)" >>/install/group_vars/all.yaml
echo "pts/0" >>/mnt/etc/securetty
cp -r /install /mnt/
systemd-nspawn -D /mnt
systemd-nspawn --bind /sys/firmware/efi/efivars -bD /mnt
arch-chroot /mnt
#rm -rf /mnt/install
echo "All done, reboot system"
