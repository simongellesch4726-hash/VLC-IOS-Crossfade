ARCHS = arm64e
TARGET := iphone:clang:16.5:15.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = VLCCrossfadePrefs
VLCCrossfadePrefs_FILES = VLCCFPrefsListController.m
VLCCrossfadePrefs_INSTALL_PATH = /Library/PreferenceBundles
VLCCrossfadePrefs_FRAMEWORKS = UIKit
VLCCrossfadePrefs_PRIVATE_FRAMEWORKS = Preferences
VLCCrossfadePrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/VLCCrossfade.plist$(ECHO_END)
