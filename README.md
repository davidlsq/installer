# installer

Build iso images to automatically install Debian 12

## Dependencies

[Nix OS](https://nixos.org/) is used for the development/build/deployment environment. The dependencies are also listed in the file [versions](versions)

**Install nix:**

```sh
curl -L https://nixos.org/nix/install | sh
```

**Enter a shell:**

```sh
nix-shell
```

## Images

The default `make` goal builds all the images. The first time, it asks for the passwords

### virtual

```sh
make bootstrap/virtual.iso
virtual/root ?
virtual/user ?
virtual/ansible ?
```

The image can be installed in a [UTM](https://mac.getutm.app) virtual machine :

![utm](doc/utm.png)

At first boot, select the `[CDROM] Install grub entry` :

![grub](doc/grub.png)

The installation is fully automatic and Debian starts without other manipulation. At first boot, an [Ansible](https://docs.ansible.com) playbook runs inside the virtual machine, installing everything in about one minute

You can log you with :

```sh
ssh -i files/virtual/ssh/user david@virtual.local
```

`make install` deploys the key files in `~/.ssh`. After to run the Ansible playbook manually :

```sh
ansible-playbook -i inventory/virtual.local virtual.yml
```