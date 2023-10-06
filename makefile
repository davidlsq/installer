common:
	mkdir -p $@

common/debian-arm64.iso: | common
	wget -q https://cdimage.debian.org/images/release/12.1.0/arm64/iso-cd/debian-12.1.0-arm64-netinst.iso -O $@

common/debian-amd64.iso: | common
	wget -q https://cdimage.debian.org/images/release/12.1.0/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso -O $@

virtual/config:
	ansible-playbook -i "localhost," -c local -e '{"config_dir":"$(shell pwd)/$@"}' $@.yml
	./scripts/archive.sh --directory virtual --host virtual --output $@/virtual.tar.gz

virtual/virtual.iso: common/debian-arm64.iso virtual/config
	./scripts/debian.sh --iso $< --directory virtual --host virtual --output $@

infra/config:
	ansible-playbook -i "localhost," -c local -e '{"config_dir":"$(shell pwd)/$@"}' $@.yml
	./scripts/archive.sh --directory infra --host server --output $@/server.tar.gz
	./scripts/archive.sh --directory infra --host raspi --output $@/raspi.tar.gz

infra/raspi.img: infra/config
	./scripts/raspi.sh  --directory infra --host raspi --output $@

infra/server.iso: common/debian-amd64.iso infra/config
	./scripts/debian.sh --iso $< --directory infra --host server --output $@

DOWNLOAD = common/debian-arm64.iso common/debian-amd64.iso
CONFIG   = virtual/config infra/config
IMAGE    = virtual/virtual.iso infra/raspi.img infra/server.iso

.DEFAULT_GOAL := image
.NOT_PARALLEL := config

.PHONY: clean download config image all test

tmpclean:
	rm -rf $(addsuffix .tmp,$(IMAGE))

clean: tmpclean
	rm -rf common $(CONFIG) $(IMAGE)

download: $(DOWNLOAD)

config: $(CONFIG)

image: $(IMAGE)

all: image

test:

.PHONY: bitwarden-push

bitwarden-push: infra/config
	./scripts/bitwarden.sh --passwords $</raspi_password.yml,$</server_password.yml,$</server_password_samba.yml --folder Infra

.PHONY: playbook-check playbook

playbook-check: infra/config
	ansible-playbook -i infra/config/inventory_local_ip_address -C infra/raspi.yml infra/server.yml

playbook: infra/config
	ansible-playbook -i infra/config/inventory_local_ip_address infra/raspi.yml infra/server.yml

.PHONY: github-push github-pull github-playbook-check github-playbook

github-push: infra/config
	./scripts/github-push.sh --file infra/config/raspi_ssh_keys_github --var RASPI_GITHUB_SSH_KEY
	./scripts/github-push.sh --file infra/config/raspi_ssh_keys_host.pub --var RASPI_HOST_SSH_KEY
	./scripts/github-push.sh --file infra/config/server_ssh_keys_github --var SERVER_GITHUB_SSH_KEY
	./scripts/github-push.sh --file infra/config/server_ssh_keys_host.pub --var SERVER_HOST_SSH_KEY
