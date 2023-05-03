TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = MobileSlideShow

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AlbumManager

AlbumManager_FILES = src/Tweak.x src/AlbumManager.m
AlbumManager_LIBRARIES = sandy
AlbumManager_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk