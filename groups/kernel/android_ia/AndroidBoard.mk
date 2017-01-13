ifneq ($(TARGET_PREBUILT_KERNEL),)
$(error TARGET_PREBUILT_KERNEL defined but AndroidIA kernels build from source)
endif

TARGET_KERNEL_SRC ?= kernel/android_ia

{{#x86_64}}
TARGET_KERNEL_ARCH := x86_64
TARGET_KERNEL_CONFIG ?= kernel_64_defconfig
ADDITIONAL_DEFAULT_PROPERTIES += ro.boot.moduleslocation=/system/lib64/modules
{{/x86_64}}

{{^x86_64}}
ADDITIONAL_DEFAULT_PROPERTIES += ro.boot.moduleslocation=/system/lib/modules
$(error 32bit Kernel builds are not supported.)
{{/x86_64}}

KERNEL_CONFIG_DIR := {{{kernel_config_dir}}}

KERNEL_NAME := bzImage

# Set the output for the kernel build products.
KERNEL_OUT := $(abspath $(TARGET_OUT_INTERMEDIATES)/kernel)
KERNEL_BIN := $(KERNEL_OUT)/arch/$(TARGET_KERNEL_ARCH)/boot/$(KERNEL_NAME)
KERNEL_MODULES_INSTALL := $(TARGET_OUT)/lib/modules

KERNELRELEASE = $(shell cat $(KERNEL_OUT)/include/config/kernel.release)

build_kernel := $(MAKE) -C $(TARGET_KERNEL_SRC) \
		O=$(KERNEL_OUT) \
		ARCH=$(TARGET_KERNEL_ARCH) \
		CROSS_COMPILE="$(KERNEL_CROSS_COMPILE_WRAPPER)" \
		KCFLAGS="$(KERNEL_CFLAGS)" \
		KAFLAGS="$(KERNEL_AFLAGS)" \
		$(if $(SHOW_COMMANDS),V=1) \
		INSTALL_MOD_PATH=$(abspath $(TARGET_OUT))

KERNEL_CONFIG_FILE := device/intel/android_ia/kernel_config/$(TARGET_KERNEL_CONFIG)

KERNEL_CONFIG := $(KERNEL_OUT)/.config
$(KERNEL_CONFIG): $(KERNEL_CONFIG_FILE)
	$(hide) mkdir -p $(@D) && cat $(wildcard $^) > $@
	$(build_kernel) oldnoconfig

# Produces the actual kernel image!
$(PRODUCT_OUT)/kernel: $(KERNEL_CONFIG) | $(ACP)
	$(build_kernel) $(KERNEL_NAME) modules
	$(hide) $(ACP) -fp $(KERNEL_BIN) $@

ALL_EXTRA_MODULES := $(patsubst %,$(TARGET_OUT_INTERMEDIATES)/kmodule/%,$(TARGET_EXTRA_KERNEL_MODULES))
$(ALL_EXTRA_MODULES): $(TARGET_OUT_INTERMEDIATES)/kmodule/%: $(PRODUCT_OUT)/kernel
	@echo Building additional kernel module $*
	$(build_kernel) M=$(abspath $@) modules

# Copy modules in directory pointed by $(KERNEL_MODULES_ROOT)
# First copy modules keeping directory hierarchy lib/modules/`uname-r`for libkmod
# Second, create flat hierarchy for insmod linking to previous hierarchy
$(KERNEL_MODULES_INSTALL): $(PRODUCT_OUT)/kernel $(ALL_EXTRA_MODULES)
	$(hide) rm -rf $(TARGET_OUT)/lib/modules
	$(build_kernel) modules_install
	$(hide) for kmod in "$(TARGET_EXTRA_KERNEL_MODULES)" ; do \
		echo Installing additional kernel module $${kmod} ; \
		$(subst +,,$(subst $(hide),,$(build_kernel))) M=$(abspath $(TARGET_OUT_INTERMEDIATES))/$${kmod}.kmodule modules_install ; \
	done
	$(hide) rm -f $(TARGET_OUT)/lib/modules/*/{build,source}
{{#x86_64}}
	$(hide) rm -rf $(TARGET_OUT)/lib64/modules
	$(hide) cp -rf $(TARGET_OUT)/lib/modules/$(KERNELRELEASE)/ $(TARGET_OUT)/lib64/modules
	$(hide) ln -s /lib64/modules/$$(basename $$f) $(TARGET_OUT)/lib/modules/$(KERNELRELEASE)/$$f || exit 1;
{{/x86_64}}
{{^x86_64}}
		$(hide) cp -rf $(TARGET_OUT)/lib/modules/$(KERNELRELEASE)/ $(TARGET_OUT)/lib/modules
		$(hide) ln -s /lib/modules/$$(basename $$f) $(TARGET_OUT)/lib/modules/$(KERNELRELEASE)/$$f || exit 1;
{{/x86_64}}
	$(hide) touch $@

# Makes sure any built modules will be included in the system image build.
ALL_DEFAULT_INSTALLED_MODULES += $(KERNEL_MODULES_INSTALL)

installclean: FILES += $(KERNEL_OUT) $(PRODUCT_OUT)/kernel

.PHONY: kernel
kernel: $(PRODUCT_OUT)/kernel

#Firmware
SYMLINKS := $(subst $(FIRMWARES_DIR),$(TARGET_OUT)/etc/firmware,$(filter-out $(FIRMWARES_DIR)/$(FIRMWARE_FILTERS),$(shell find $(FIRMWARES_DIR) -type l)))

$(SYMLINKS): FW_PATH := $(FIRMWARES_DIR)
$(SYMLINKS):
	@link_to=`readlink $(subst $(TARGET_OUT)/lib/firmware,$(FW_PATH),$@)`; \
	echo "Symlink: $@ -> $$link_to"; \
	mkdir -p $(@D); ln -sf $$link_to $@

ALL_DEFAULT_INSTALLED_MODULES += $(SYMLINKS)
