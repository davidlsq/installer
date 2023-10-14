common:
	mkdir -p $@

common/debian-arm64.iso: | common
	wget -q https://cdimage.debian.org/images/release/12.2.0/arm64/iso-cd/debian-12.2.0-arm64-netinst.iso -O $@

common/debian-amd64.iso: | common
	wget -q https://cdimage.debian.org/images/release/12.2.0/amd64/iso-cd/debian-12.2.0-amd64-netinst.iso -O $@

virtual/config:
	mkdir -p $@

virtual/config/playbook: | virtual/config
	ansible-playbook -i "localhost,virtual" -c local -e '{"config_dir":"$(shell pwd)/$@"}' virtual/config.yml

virtual/virtual.iso: common/debian-arm64.iso virtual/config/playbook
	./scripts/debian.sh --iso $< --directory virtual --host virtual --output $@

infra/config:
	mkdir -p $@

infra/config/bitwarden.yml: | infra/config
	./scripts/bitwarden-import.py  --organization Infra --output $@

infra/config/playbook: | infra/config
	ansible-playbook -i "localhost,raspi,server" -c local -e '{"config_dir":"$(shell pwd)/$@"}' infra/config.yml

infra/raspi.img: infra/config/playbook
	./scripts/raspi.sh  --directory infra --host raspi --output $@

infra/server.iso: common/debian-amd64.iso infra/config/bitwarden.yml infra/config/playbook
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

.PHONY: dd-raspi dd-server

dd-raspi: infra/raspi.img
	@./scripts/dd-image.sh --image infra/raspi.img

dd-server: infra/server.iso
	@./scripts/dd-image.sh --image infra/server.iso

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
