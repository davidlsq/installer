define python
    (PYTHONPATH=$$(pwd)/python:$$PYTHONPATH; cd $$(dirname $1); ./$$(basename $1))
endef

DEBIAN_AARCH64 = image/debian-aarch64.iso
$(DEBIAN_AARCH64):
	@wget -q https://cdimage.debian.org/images/release/12.1.0/arm64/iso-cd/debian-12.1.0-arm64-netinst.iso -O $@

VIRTUAL_CONFIGURE = configure/virtual
$(VIRTUAL_CONFIGURE):
	@$(call python,configure/virtual.py)

VIRTUAL_IMAGE = image/virtual.iso
$(VIRTUAL_IMAGE): $(DEBIAN_AARCH64) $(VIRTUAL_CONFIGURE)
	@$(call python,image/virtual.py)

DEBIAN_X86_64 = image/debian-x86_64.iso
$(DEBIAN_X86_64):
	@wget -q https://cdimage.debian.org/images/release/12.1.0/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso -O $@

SERVER_CONFIGURE = configure/server
$(SERVER_CONFIGURE):
	@$(call python,configure/server.py)

SERVER_IMAGE = image/server.iso
$(SERVER_IMAGE): $(DEBIAN_X86_64) $(SERVER_CONFIGURE)
	@$(call python,image/server.py)

SERVER_GITHUB = server-github
$(SERVER_GITHUB): $(SERVER_CONFIGURE)
	@tar -cz $</ssh/keys/host* $</ssh/keys/user.pub $</ssh/keys/ansible* $</password.yml | base64 | \
	 gh secret set SERVER_ARCHIVE -R davidlsq/installer

DOWNLOAD  = $(DEBIAN_AARCH64) $(DEBIAN_X86_64)
CONFIGURE = $(VIRTUAL_CONFIGURE) $(SERVER_CONFIGURE)
IMAGE     = $(VIRTUAL_IMAGE) $(SERVER_IMAGE)

.DEFAULT_GOAL := image
.NOT_PARALLEL := configure
.PHONY: clean download configure image all test $(SERVER_GITHUB)

tmpclean:
	@rm -rf $(addsuffix .tmp,$(IMAGE))

clean: tmpclean
	@rm -rf $(DOWNLOAD) $(CONFIGURE) $(IMAGE)

download: $(DOWNLOAD)

configure: $(CONFIGURE)

image: $(IMAGE)

all: image

test:
	@pre-commit run -a
