SCRIPT_SSH_KEYGEN     = bootstrap/scripts/ssh-keygen.sh
SCRIPT_SSH_KNOWN_HOST = bootstrap/scripts/ssh-known-host.sh
SCRIPT_SSH_IDENTITY   = bootstrap/scripts/ssh-identity.sh
SCRIPT_IMAGE          = bootstrap/scripts/image.py

DEBIAN_AARCH64 = bootstrap/debian-aarch64.iso
$(DEBIAN_AARCH64):
	@wget -q https://cdimage.debian.org/images/release/12.1.0/arm64/iso-cd/debian-12.1.0-arm64-netinst.iso -O $@

VIRTUAL_CONFIGURE = configure/virtual
$(VIRTUAL_CONFIGURE):
	@mkdir $@

VIRTUAL_KEYS = $(VIRTUAL_CONFIGURE)/keys
$(VIRTUAL_KEYS): $(VIRTUAL_CONFIGURE)
	@mkdir $@
	@$(SCRIPT_SSH_KEYGEN) $@/server
	@$(SCRIPT_SSH_KEYGEN) $@/user
	@$(SCRIPT_SSH_KEYGEN) $@/ansible

VIRTUAL_SSH = $(VIRTUAL_CONFIGURE)/ssh
$(VIRTUAL_SSH): $(VIRTUAL_KEYS)
	@mkdir $@

	@$(SCRIPT_SSH_KNOWN_HOST) $</server virtual.local $@/known_hosts

	@$(SCRIPT_SSH_IDENTITY) $</user    $@/known_hosts david   virtual.local $@/config
	@$(SCRIPT_SSH_IDENTITY) $</ansible $@/known_hosts ansible virtual.local $@/config

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
	@mkdir $@
	@$(SCRIPT_SSH_KEYGEN) $@/server
	@$(SCRIPT_SSH_KEYGEN) $@/user
	@$(SCRIPT_SSH_KEYGEN) $@/ansible

SERVER_SSH = $(SERVER_CONFIGURE)/ssh
$(SERVER_SSH): $(SERVER_KEYS)
	@mkdir $@
	
	@$(SCRIPT_SSH_KNOWN_HOST) $</server  server.local       $@/known_hosts
	@$(SCRIPT_SSH_KNOWN_HOST) $</server  server.davidlsq.fr $@/known_hosts

	@$(SCRIPT_SSH_IDENTITY) $</user    $@/known_hosts david   server.local       $@/config
	@$(SCRIPT_SSH_IDENTITY) $</ansible $@/known_hosts ansible server.local       $@/config
	@$(SCRIPT_SSH_IDENTITY) $</user    $@/known_hosts david   server.davidlsq.fr $@/config
	@$(SCRIPT_SSH_IDENTITY) $</ansible $@/known_hosts ansible server.davidlsq.fr $@/config

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
