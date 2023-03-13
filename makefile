SCRIPT_PASSWORD       = bootstrap/scripts/password.py
SCRIPT_SSH_KEYGEN     = bootstrap/scripts/ssh-keygen.sh
SCRIPT_SSH_KNOWN_HOST = bootstrap/scripts/ssh-known-host.sh
SCRIPT_SSH_IDENTITY   = bootstrap/scripts/ssh-identity.sh
SCRIPT_IMAGE          = bootstrap/scripts/image.py

DEBIAN_AARCH64 = bootstrap/debian-aarch64.iso
$(DEBIAN_AARCH64) :
	@wget -q https://cdimage.debian.org/images/release/11.6.0/arm64/iso-cd/debian-11.6.0-arm64-netinst.iso -O $@

VIRTUAL_PASSWORD = host_vars/virtual/password.yml
$(VIRTUAL_PASSWORD) :
	@echo "password:" > $@
	@$(SCRIPT_PASSWORD) virtual root $@
	@$(SCRIPT_PASSWORD) virtual user $@
	@$(SCRIPT_PASSWORD) virtual ansible $@

VIRTUAL_SSH = files/virtual/ssh
$(VIRTUAL_SSH) :
	@mkdir $@
	@$(SCRIPT_SSH_KEYGEN) $@/server
	@$(SCRIPT_SSH_KEYGEN) $@/user
	@$(SCRIPT_SSH_KEYGEN) $@/ansible

VIRTUAL_IMAGE = bootstrap/virtual.iso
$(VIRTUAL_IMAGE) : $(DEBIAN_AARCH64) $(VIRTUAL_PASSWORD) $(VIRTUAL_SSH)
	@$(SCRIPT_IMAGE) --iso $< --host virtual --output $@

VIRTUAL_INSTALL = virtual.install
$(VIRTUAL_INSTALL) : $(VIRTUAL_SSH)
	@$(SCRIPT_SSH_KNOWN_HOST) $(VIRTUAL_SSH)/server virtual.local
	@$(SCRIPT_SSH_IDENTITY) $(VIRTUAL_SSH)/user virtual.local david
	@$(SCRIPT_SSH_IDENTITY) $(VIRTUAL_SSH)/ansible virtual.local ansible

DOWNLOAD  = $(DEBIAN_AARCH64)
CONFIGURE = $(VIRTUAL_PASSWORD) $(VIRTUAL_SSH)
IMAGE     = $(VIRTUAL_IMAGE)
INSTALL   = $(VIRTUAL_INSTALL)

.DEFAULT_GOAL := image
.NOT_PARALLEL := configure
.PHONY        : clean download configure image install $(INSTALL)

tmpclean :
	@rm -rf $(addsuffix .tmp,$(IMAGE))

clean : tmpclean
	@rm -rf $(DOWNLOAD) $(CONFIGURE) $(IMAGE)

download : $(DOWNLOAD)

configure : $(CONFIGURE)

image : $(IMAGE)

install : $(INSTALL)
