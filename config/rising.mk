-include vendor/addons/config.mk
include vendor/rising/config/properties.mk
include vendor/rising/config/packages.mk
include vendor/rising/config/version.mk
include vendor/rising/overlays/build.mk
include vendor/rising/prebuilts/prebuilts.mk
ifeq ($(WITH_PIXEL_OVERLAYS),true)
-include vendor/pixeloverlays/config.mk
endif
-include vendor/google/mainline_modules/config.mk
ifeq ($(WITH_MICROG),true)
include vendor/microg/products/gms.mk
endif

# Adblock
PRODUCT_COPY_FILES += \
    vendor/rising/etc/adblock/init.adblock.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/init.adblock.rc

PRODUCT_SOONG_NAMESPACES += \
    vendor/rising/common

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.freeform_window_management.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.software.freeform_window_management.xml

# BtHelper
PRODUCT_PACKAGES += \
    BtHelper

# ColumbusService
ifneq ($(TARGET_SUPPORTS_QUICK_TAP),false)
PRODUCT_PACKAGES += \
    ColumbusService
endif

# Dexopt
PRODUCT_DEXPREOPT_SPEED_APPS += \
    TrebuchetQuickStep \
    NexusLauncherRelease

# Rising Walls
PRODUCT_PACKAGES += \
    RisingWalls \
    Backgrounds

# Product Copy
PRODUCT_COPY_FILES += \
    frameworks/base/data/keyboards/Vendor_045e_Product_028e.kl:$(TARGET_COPY_OUT_PRODUCT)/usr/keylayout/Vendor_045e_Product_0719.kl \
    frameworks/native/data/etc/android.software.freeform_window_management.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.software.freeform_window_management.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/android.software.sip.voip.xml

ifeq ($(LINEAGE_BUILD),)
# Extracted APN's from Cheetah
PRODUCT_COPY_FILES += \
    vendor/rising/prebuilts/apn/apns-conf.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/apns-conf.xml
endif

TARGET_SHIP_LEGACY_BOOT_ANIMATION ?= false
ifeq ($(TARGET_SHIP_LEGACY_BOOT_ANIMATION),true)
PRODUCT_COPY_FILES += vendor/rising/prebuilts/bootanimation/bootanimation_rising.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
endif

# TFLite service.
PRODUCT_PACKAGES += libtensorflowlite_jni

# Allow TFLite service modules to be installed to the system partition
PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += \
    system/lib/libtensorflowlite_jni.so \
    system/lib64/libtensorflowlite_jni.so

$(call inherit-product, vendor/rising/config/vars.mk)
