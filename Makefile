export ARCHS = armv7 arm64
export TARGET = iphone:clang::9.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BylineEnhancer5
BylineEnhancer5_FILES = Tweak.xm
BylineEnhancer5_OBJC_FILES += $(shell ls AASpringRefresh/AASpringRefresh/*.m)
BylineEnhancer5_CFLAGS = -I AASpringRefresh/AASpringRefresh
BylineEnhancer5_PURE_OBJCFLAGS = -fobjc-arc
BylineEnhancer5_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Byline"
