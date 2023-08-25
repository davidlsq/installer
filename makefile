SCRIPT_VIRTUAL = python/virtual.py
SCRIPT_SERVER  = python/server.py
SCRIPT_IMAGE   = bootstrap/scripts/image.py

CONFIG                  = config
CONFIG_VIRTUAL          = $(CONFIG)/virtual
CONFIG_VIRTUAL_PASSWORD = $(CONFIG_VIRTUAL)/password.yml
CONFIG_SERVER           = $(CONFIG)/server
CONFIG_SERVER_PASSWORD  = $(CONFIG_SERVER)/password.yml

BUILD                  = build
BUILD_DEBIAN_AARCH64   = $(BUILD)/debian-x86_64.iso
BUILD_DEBIAN_X86_64    = $(BUILD)/debian-aarch64.iso
BUILD_VIRTUAL          = $(BUILD)/virtual
BUILD_VIRTUAL_KEYS     = $(BUILD_VIRTUAL)/keys
BUILD_VIRTUAL_SSH      = $(BUILD_VIRTUAL)/ssh
BUILD_VIRTUAL_PASSWORD = $(BUILD_VIRTUAL)/password.yml
BUILD_VIRTUAL_IMAGE    = $(BUILD)/virtual.iso
BUILD_SERVER           = $(BUILD)/server
BUILD_SERVER_KEYS      = $(BUILD_SERVER)/keys
BUILD_SERVER_SSH       = $(BUILD_SERVER)/ssh
BUILD_SERVER_PASSWORD  = $(BUILD_SERVER)/password.yml
BUILD_SERVER_IMAGE     = $(BUILD)/server.iso

$(BUILD):
	@mkdir $@

$(BUILD_DEBIAN_AARCH64): | $(BUILD)
	@wget -q https://cdimage.debian.org/images/release/12.1.0/arm64/iso-cd/debian-12.1.0-arm64-netinst.iso -O $@

$(BUILD_DEBIAN_X86_64): | $(BUILD)
	@wget -q https://cdimage.debian.org/images/release/12.1.0/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso -O $@

$(BUILD_VIRTUAL): | $(BUILD)
	@mkdir $@

$(BUILD_VIRTUAL_KEYS): | $(BUILD_VIRTUAL)
	@$(SCRIPT_VIRTUAL) configure/keys $@

$(BUILD_VIRTUAL_SSH): $(BUILD_VIRTUAL_KEYS)
	@$(SCRIPT_VIRTUAL) configure/ssh $@ $<

$(BUILD_VIRTUAL_PASSWORD): | $(BUILD_VIRTUAL)
	@$(SCRIPT_VIRTUAL) configure/password $@ $(CONFIG_VIRTUAL_PASSWORD)

$(BUILD_VIRTUAL_IMAGE): $(BUILD_DEBIAN_AARCH64) $(BUILD_VIRTUAL_KEYS) $(BUILD_VIRTUAL_PASSWORD)
	@$(SCRIPT_IMAGE) --iso $< --host virtual --output $@

$(BUILD_SERVER): | $(BUILD)
	@mkdir $@

$(BUILD_SERVER_KEYS): | $(BUILD_SERVER)
	@$(SCRIPT_SERVER) configure/keys $@

$(BUILD_SERVER_SSH): $(BUILD_SERVER_KEYS)
	@$(SCRIPT_SERVER) configure/ssh $@ $<

$(BUILD_SERVER_PASSWORD): | $(BUILD_SERVER)
	@$(SCRIPT_SERVER) configure/password $@ $(CONFIG_SERVER_PASSWORD)

$(BUILD_SERVER_IMAGE): $(BUILD_DEBIAN_X86_64) $(BUILD_SERVER_KEYS) $(BUILD_SERVER_PASSWORD)
	@$(SCRIPT_IMAGE) --iso $< --host server --output $@

SERVER_GITHUB = server-github
$(SERVER_GITHUB): $(BUILD_SERVER_KEYS) $(BUILD_SERVER_PASSWORD)
	@tar -cz $</server* $</user.pub $</ansible* $(word 2,$^) | base64 | \
	 gh secret set SERVER_ARCHIVE -R davidlsq/installer

DOWNLOAD  = $(BUILD_DEBIAN_AARCH64) $(BUILD_DEBIAN_X86_64)
CONFIGURE = $(BUILD_VIRTUAL_KEYS) $(BUILD_VIRTUAL_SSH) $(BUILD_VIRTUAL_PASSWORD) $(BUILD_SERVER_KEYS) $(BUILD_SERVER_SSH) $(BUILD_SERVER_PASSWORD)
IMAGE     = $(BUILD_VIRTUAL_IMAGE) $(BUILD_SERVER_IMAGE)

.DEFAULT_GOAL := image
.NOT_PARALLEL := configure
.PHONY: clean download configure image all test $(SERVER_GITHUB)

tmpclean:
	@rm -rf $(addsuffix .tmp,$(IMAGE))

clean:
	@rm -rf $(BUILD)

download: $(DOWNLOAD)

configure: $(CONFIGURE)

image: $(IMAGE)

all: image

test:
	@pre-commit run -a
