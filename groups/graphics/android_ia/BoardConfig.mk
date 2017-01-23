BOARD_KERNEL_CMDLINE += vga=current i915.modeset=1 drm.atomic=1 i915.nuclear_pageflip=1 drm.vblankoffdelay=1 i915.fastboot=1
USE_OPENGL_RENDERER := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
USE_INTEL_UFO_DRIVER := false
INTEL_VA := true
BOARD_GRAPHIC_IS_GEN := true
BOARD_GPU_DRIVERS := i965
BOARD_USE_MESA := true
GRALLOC_DRM := true
BOARD_USES_IA_PLANNER := true

# System's VSYNC phase offsets in nanoseconds
VSYNC_EVENT_PHASE_OFFSET_NS := 7500000
SF_VSYNC_EVENT_PHASE_OFFSET_NS := 5000000

BOARD_GPU_DRIVERS ?= i965 swrast
ifneq ($(strip $(BOARD_GPU_DRIVERS)),)
TARGET_HARDWARE_3D := true
endif

{{#hwc2}}
TARGET_USES_HWC2 := true
{{/hwc2}}

{{^hwc2}}
TARGET_USES_HWC2 := false
{{/hwc2}}

{{#drmhwc}}
BOARD_USES_DRM_HWCOMPOSER := true
BOARD_USES_IA_HWCOMPOSER := false
{{/drmhwc}}

{{^drmhwc}}
BOARD_USES_DRM_HWCOMPOSER := false
BOARD_USES_IA_HWCOMPOSER := true
{{/drmhwc}}
