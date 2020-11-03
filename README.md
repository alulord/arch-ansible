# Ansible playbook to bootstrap Arch linux

This is ansible playbook to help with Arch linux installation. Contains `disk-bootstrap.sh` which will partition given disk, encrypt and bootstrap btrfs with snapshots. After that you can run this ansible playbook to install Arch linux ready to use.

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

Once installed you will be in `systemd-nspawn` system. Right now `chpasswd` is not working, so we have to set up password manually. Run following commands to get to correct nspawn container:

```bash
passwd
logout
``` 

Once inside navigate to `/install` and run ansible playbook. By default, `basic` tags will run only basic installation without gui. You can further modify the installation with supported tags `x,wireless,laptop,tlp,asus,bluetooth,i3,sway,logitech,redshift,syncthing,vpn` e.g

```bash
ansible-playbook playbook.yaml  --tags all,x,wireless,i3,redshift,syncthing,vpn
```

or just for cli install

```bash
ansible-playbook playbook.yaml  --tags basic
```


This will bootstrap installation with dotfiles and necessary configs. If it is done, you can `poweroff` nspawn container.

We have to regenerate bootstrap (we don't have `/sys` or `/proc` mounted)

```bash
refind-install
```

After this you can reboot into system a finish installation

### Finishing installation

If needed connect to wifi using

```bash
nmcli d wifi c name_of_network password SecretPassword
```

To [check iptables dropped packets](https://wiki.archlinux.org/index.php/iptables#Logging) use

```bash
journalctl -k | grep "IN=.*OUT=.*" | less
```

## TODO

[] keyboard layout switching for sway/waybar
[] use firejail for applications like browsers https://github.com/pigmonkey/spark/tree/master/roles/firejail
[] use nmtrust so applications can connect only on trusted networks https://github.com/pigmonkey/spark/tree/master/roles/nmtrust
