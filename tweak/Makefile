export THEOS_PACKAGE_SCHEME = roothide

ARCHS = arm64e
TARGET := iphone:clang:16.5:15.0

INSTALL_TARGET_PROCESSES = VLC VLC-iOS

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VLCCrossfade

VLCCrossfade_FILES = Tweak.x Crossfader.m

VLCCrossfade_CFLAGS = -fobjc-arc

VLCCrossfade_FRAMEWORKS = UIKit Foundation AVFoundation CoreMedia

VLCCrossfade_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Prefs
include $(THEOS_MAKE_PATH)/aggregate.mk