# Ansible playbook to bootstrap Arch linux

Contains `disk-bootstrap.sh` which will partition given disk, encrypt and bootstrap btrfs with snapshots. After that it will run

Should add .ssh folder with keys to download dotfiles

* will detect wireless cards
* install amd ucode on amd machine (intel should be done when needed) 