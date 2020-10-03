# Ansible playbook to bootstrap Arch linux

Contains `disk-bootstrap.sh` which will partition given disk, encrypt and bootstrap btrfs with snapshots. After that it will run

Should add .ssh folder with keys to download dotfiles

This should be added to live usb 

```bash
cp -r Ansible-Playbook airootfs/install 
sudo mkarchiso -v -w /tmp/archiso-tmp /home/alulord/archlive
sudo dd bs=4M if="location of iso" of=/dev/sdd status=progress oflag=sync
```

## Running on host machine

If you are on wifi connect to internet via `iwctl`

```iwctl
station wlan0 connect name_of_network
```

Copy your `.ssh` folder to `/install`

```bash
cp -r /media/location/.ssh /install
```

Navigate to `/install` and set up disks with following command (and follow prompts) 

```bash
./disk-bootstrap.sh /dev/sdX
```

Once installed you will be in `systemd-nspawn` system. Right now `chpasswd` is not working, so we have to set up password manually. Press `Ctrl+]` 3 times to quit `systemd-nspawn`. Once out run following commands to get to correct nspawn container:

```bash
systemd-nspawn -D /mnt
passwd
logout
systemd-nspawn -bD /mnt
``` 

Once inside navigate to `/install` and run ansible playbook. By default, `basic` tags will run only basic installation without gui. You can further modify the installation with supported tags `x,wireless,laptop,tlp,asus,bluetooth,i3,sway,logitech,redshift,syncthing` e.g

```bash
ansible-playbook playbook.yaml  --tags all,x,wireless,i3,redshift
```

or just for cli install

```bash
ansible-playbook playbook.yaml  --tags basic
```


This will bootstrap installation with dotfiles and necessary configs. If it is done, you can `poweroff` nspawn container.

We have to regenerate bootstrap (we don't have `/sys` or `/proc` mounted)

```bash
arch-chroot /mnt
refind-install
```

After this you can reboot into system a finish installation

### Finishing installation

There are some packages which for now were problematic to install via ansible.

If needed connect to wifi using

```bash
nmcli d wifi c name_of_network password SecretPassword
```

Navigate to home dir and init dotfiles submodules

```
dotfiles submodule update --init
```

Install some additional packages, which gave trouble:

* freetype2-cleartype
* libpdfium-nojs
* megasync
* nemo-megasync
* spotify

## TODO

[] layout switching for sway/waybar