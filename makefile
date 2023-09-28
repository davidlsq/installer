common:
	mkdir -p $@

common/debian-arm64.iso: | common
	wget -q https://cdimage.debian.org/images/release/12.1.0/arm64/iso-cd/debian-12.1.0-arm64-netinst.iso -O $@

common/debian-amd64.iso: | common
	wget -q https://cdimage.debian.org/images/release/12.1.0/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso -O $@

virtual/config:
	mkdir -p $@
	ansible-playbook -i "localhost," -c local -e '{"config_dir":"$(shell pwd)/$@"}' $@.yml

virtual/image.iso: common/debian-arm64.iso virtual/config
	./image.sh --iso $< --image virtual --output $@

server/config:
	mkdir -p $@
	ansible-playbook -i "localhost," -c local -e '{"config_dir":"$(shell pwd)/$@"}' $@.yml

server/image.iso: common/debian-amd64.iso server/config
	./image.sh --iso $< --image server --output $@

DOWNLOAD = common/debian-arm64.iso common/debian-amd64.iso
CONFIG   = virtual/config server/config
IMAGE    = virtual/image.iso server/image.iso

.DEFAULT_GOAL := image
.NOT_PARALLEL := config

.PHONY: clean download config image all test server-github server-playbook-check server-playbook

tmpclean:
	rm -rf $(addsuffix .tmp,$(IMAGE))

clean:
	rm -rf common $(CONFIG) $(IMAGE)

download: $(DOWNLOAD)

config: $(CONFIG)

image: $(IMAGE)

all: image

test:

github-push: server/config
	(find server/files server/group_vars -type l; find server/github) | \
	  tar -T - -hcz | base64 | gh secret set SERVER_ARCHIVE -R davidlsq/installer

github-pull:
	@echo "${SERVER_ARCHIVE}" | base64 -d | tar zxf -

github-playbook-check: github-pull
	ansible-playbook -i server/github/inventory server/install.yml

github-playbook: github-pull
	ansible-playbook -i server/github/inventory server/install.yml
