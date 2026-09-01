#
# Copyright (C) 2023 The risingOS Android Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

PRODUCT_SOONG_NAMESPACES += \
    vendor/rising/prebuilts

# Overlays
PRODUCT_PACKAGE_OVERLAYS += \
    vendor/rising/overlays

ifneq ($(WITH_GMS),true)
PRODUCT_PACKAGES += \
    ThemePicker
endif

ifeq ($(TARGET_SUPPORTS_64_BIT_APPS),true)
TARGET_FACE_UNLOCK_SUPPORTED ?= true
ifeq ($(TARGET_FACE_UNLOCK_SUPPORTED),true)

ifeq ($(TARGET_SUPPORTS_GFU),true)
$(call inherit-product-if-exists, vendor/google/faceunlock/config.mk)
else
PRODUCT_PACKAGES += \
    FaceUnlock

PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.face.sense_service=true

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.biometrics.face.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.biometrics.face.xml

PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += \
    system/etc/default-permissions/default_permissions_co.aospa.sense.xml \
    system/etc/permissions/android.hardware.biometrics.face.xml \
    system/etc/permissions/privapp_whitelist_co.aospa.sense.xml \
    system/etc/sysconfig/hiddenapi-whitelist-co.aospa.sense.xml \
    system/lib64/libFaceDetectCA.so \
    system/lib64/libMegviiUnlock-jni-1.2.so \
    system/lib64/libMegviiUnlock.so \
    system/lib64/libmegface.so \
    system/priv-app/FaceUnlock/FaceUnlock.apk
endif

endif
endif

PRODUCT_COPY_FILES += \
    vendor/rising/prebuilts/bootanimation/bootanimation_rising.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation_rising.zip \
    vendor/rising/prebuilts/bootanimation/bootanimation_cyberpunk.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation_cyberpunk.zip \
    vendor/rising/prebuilts/bootanimation/bootanimation_valorant.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation_valorant.zip \
    vendor/rising/prebuilts/bootanimation/bootanimation_google.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation_google.zip \
    vendor/rising/prebuilts/bootanimation/bootanimation_google_monet.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation_google_monet.zip
