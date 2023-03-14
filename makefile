SCRIPT_PASSWORD_CRYPT = bootstrap/scripts/password-crypt.py
SCRIPT_PASSWORD_CLEAR = bootstrap/scripts/password-clear.py
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
	@$(SCRIPT_PASSWORD_CRYPT) virtual root $@
	@$(SCRIPT_PASSWORD_CRYPT) virtual user $@
	@$(SCRIPT_PASSWORD_CRYPT) virtual ansible $@

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

DEBIAN_X86_64 = bootstrap/debian-x86_64.iso
$(DEBIAN_X86_64) :
	@wget -q https://cdimage.debian.org/images/release/11.6.0/amd64/iso-cd/debian-11.6.0-amd64-netinst.iso -O $@

SERVER_PASSWORD = host_vars/server/password.yml
$(SERVER_PASSWORD) :
	@echo "password:" > $@
	@$(SCRIPT_PASSWORD_CRYPT) server root $@
	@$(SCRIPT_PASSWORD_CRYPT) server user $@
	@$(SCRIPT_PASSWORD_CRYPT) server ansible $@
	@$(SCRIPT_PASSWORD_CLEAR) server ddclient $@
	@$(SCRIPT_PASSWORD_CLEAR) server ovh_application_key $@
	@$(SCRIPT_PASSWORD_CLEAR) server ovh_application_secret $@
	@$(SCRIPT_PASSWORD_CLEAR) server ovh_consumer_key $@

SERVER_SSH = files/server/ssh
$(SERVER_SSH) :
	@mkdir $@
	@$(SCRIPT_SSH_KEYGEN) $@/server
	@$(SCRIPT_SSH_KEYGEN) $@/user
	@$(SCRIPT_SSH_KEYGEN) $@/ansible

SERVER_IMAGE = bootstrap/server.iso
$(SERVER_IMAGE) : $(DEBIAN_X86_64) $(SERVER_PASSWORD) $(SERVER_SSH)
	@$(SCRIPT_IMAGE) --iso $< --host server --output $@

SERVER_INSTALL = server.install
$(SERVER_INSTALL) : $(SERVER_SSH)
	@$(SCRIPT_SSH_KNOWN_HOST) $(SERVER_SSH)/server server.local
	@$(SCRIPT_SSH_IDENTITY) $(SERVER_SSH)/user server.local david
	@$(SCRIPT_SSH_IDENTITY) $(SERVER_SSH)/ansible server.local ansible
	@$(SCRIPT_SSH_KNOWN_HOST) $(SERVER_SSH)/server server.davidlsq.fr
	@$(SCRIPT_SSH_IDENTITY) $(SERVER_SSH)/user server.davidlsq.fr david
	@$(SCRIPT_SSH_IDENTITY) $(SERVER_SSH)/ansible server.davidlsq.fr ansible

DOWNLOAD  = $(DEBIAN_AARCH64) $(DEBIAN_X86_64)
CONFIGURE = $(VIRTUAL_PASSWORD) $(VIRTUAL_SSH) $(SERVER_PASSWORD) $(SERVER_SSH)
IMAGE     = $(VIRTUAL_IMAGE) $(SERVER_IMAGE)
INSTALL   = $(VIRTUAL_INSTALL) $(SERVER_INSTALL)

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
