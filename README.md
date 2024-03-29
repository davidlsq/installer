# installer

Collection of scripts to build images installing all the softwares needed by the machines from my home infrastructure :
- a raspberry
- a debian server

Using [Nix](https://nixos.org/download) :

```shell
# prepare the build env
nix-shell
# fetch my secrets from bitwarden
make infra/config/bitwarden.yml
# build the raspberry image
make infra/raspi.img
# copy the image into a SD card
make dd-raspi
# build the server debian iso
make infra/server.iso
# copy the iso into a USB stick
make dd-server
```

## Try it with a virtual machine

Build a minimal iso with ssh server :

```shell
make virtual/virtual.iso
```

Tested on arm64 macOS with [UTM](https://mac.getutm.app/) and apple virtualization :

![virtual image install step 1](/doc/virtual_install_01.png)

Select the install entry at first boot :

![virtual image install step 2](/doc/virtual_install_02.png)

Nothing more, after the debian installation the machine reboots to the system and run the ansible playbook installing everything

After some minutes :

```shell
ssh -F virtual/config/playbook/ssh_client david@virtual.local
```

## Detailed build steps

For the `infra/raspi` and `infra/server` machines

### Local prepare

Fetch some static secrets from bitwarden : 
```shell
make infra/config/bitwarden.yml
```

Generate dynamically other secrets and configurations files (linux user password, ssh keys, wireguard keys, ...) :
```shell
make infra/config/playbook
```

### Build rasperry image and debian iso

```shell
make infra/raspi.img
make infra/server.iso
```

The modified image and iso contains :
- the secrets used by the machine
- the configuration to install everything automatically ([debian preseed](https://wiki.debian.org/DebianInstaller/Preseed) or bash script for raspberry)
- ansible playbook and roles runnning at first boot

### Post install

Add the ssh configuration to connect to the machines :
```shell
echo "Include $(pwd)/infra/config/playbook/ssh_client" >> ~/.ssh/config

ssh server.local
ssh raspi.local
```

## Some other features

### Bitwarden push

To push the dynamically generated secrets to bitwarden :

```shell
make bitwarden-push
```

### Run the ansible playbooks

To update the home infrastructure machines without reinstalling everything with the images :

```shell
make playbook-check
make playbook
```

Also used in github actions to run a playbook check run on PR code and a playbook run after merge

### Auto update

A github action runs periodically to check the current software versions and creates PRs to update if needed

## Some alternatives

With less code, I could have more or less the same features (auto-install, configuration by code) by using [NixOs](https://nixos.org/) the linux distribution instead of debian

With no code at all, I could use [UNRAID](https://unraid.net/)
