SCRIPT_VIRTUAL = python/virtual.py
SCRIPT_SERVER  = python/server.py
SCRIPT_IMAGE   = bootstrap/scripts/image.py

DEBIAN_AARCH64 = bootstrap/debian-aarch64.iso
$(DEBIAN_AARCH64):
	@wget -q https://cdimage.debian.org/images/release/12.1.0/arm64/iso-cd/debian-12.1.0-arm64-netinst.iso -O $@

VIRTUAL_CONFIGURE = configure/virtual
$(VIRTUAL_CONFIGURE):
	@mkdir $@

VIRTUAL_KEYS = $(VIRTUAL_CONFIGURE)/keys
$(VIRTUAL_KEYS): $(VIRTUAL_CONFIGURE)
	@$(SCRIPT_VIRTUAL) configure/keys $@

VIRTUAL_SSH = $(VIRTUAL_CONFIGURE)/ssh
$(VIRTUAL_SSH): $(VIRTUAL_KEYS)
	@$(SCRIPT_VIRTUAL) configure/ssh $@ $<

VIRTUAL_IMAGE = bootstrap/virtual.iso
$(VIRTUAL_IMAGE): $(DEBIAN_AARCH64) $(VIRTUAL_SSH)
	@$(SCRIPT_IMAGE) --iso $< --host virtual --output $@

DEBIAN_X86_64 = bootstrap/debian-x86_64.iso
$(DEBIAN_X86_64):
	@wget -q https://cdimage.debian.org/images/release/12.1.0/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso -O $@

SERVER_CONFIGURE = configure/server
$(SERVER_CONFIGURE):
	@mkdir $@

SERVER_KEYS = $(SERVER_CONFIGURE)/keys
$(SERVER_KEYS): $(SERVER_CONFIGURE)
	@$(SCRIPT_SERVER) configure/keys $@

SERVER_SSH = $(SERVER_CONFIGURE)/ssh
$(SERVER_SSH): $(SERVER_KEYS)
	@$(SCRIPT_SERVER) configure/ssh $@ $<

SERVER_IMAGE = bootstrap/server.iso
$(SERVER_IMAGE): $(DEBIAN_X86_64) $(SERVER_SSH)
	@$(SCRIPT_IMAGE) --iso $< --host server --output $@

SERVER_GITHUB = server-github
$(SERVER_GITHUB): $(SERVER_KEYS)
	@tar -cz $</server* $</user.pub $</ansible* ansible/host_vars/server/password.yml | base64 | \
	 gh secret set SERVER_ARCHIVE -R davidlsq/installer

DOWNLOAD  = $(DEBIAN_AARCH64) $(DEBIAN_X86_64)
CONFIGURE = $(VIRTUAL_KEYS) $(VIRTUAL_SSH) $(SERVER_KEYS) $(SERVER_SSH) $(SERVER_ARCHIVE)
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
