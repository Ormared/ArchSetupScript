
timedatectl set-ntp true

pacman -S --noconfirm pacman pacman-contrib terminus-font
setfont ter-v22b

pacman -S --confirm gptfdisk btrfs-progs

echo "Please enter disk to work on: (example /dev/sda)"
read DISK

sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}

# partition
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1: 'BIOSBOOT' ${DISK}
sgdisk -n 2::+100M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK}
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}

if  [[ ! -d "/sys/firmware/efi" ]]; then
    sgdisk -A 1:set:2 ${DISK}
fi

echo -ne "
=======================================================
                PARTITION FINISHED
=======================================================
"
sleep 2

# make filesystems
echo -e "\nCreating Filesystems...\n$HR"
if [[ ${DISK} =~ "nvme" ]]; then
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}p2"
mkfs.btrfs -L "ROOT" "${DISK}p3" -f
mount -t btrfs "${DISK}p3" /mnt
else
mkfs.vfat -F32 -n "EFIBOOT" "${DISK}2"
mkfs.btrfs -L "ROOT" "${DISK}3" -f
mount -t btrfs "${DISK}3" /mnt
fi
ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt
;;
*)
echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
;;
esac


echo -ne "
=======================================================
                FILESYSTEM CREATION FINISHED
=======================================================
"
sleep 2

# mount target
mount -t btrfs -o subvol=@ -L ROOT /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/


echo -ne "
=======================================================
                MOUNT FINISHED
=======================================================
"
sleep 2
