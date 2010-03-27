include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = EtoileUITests

ADDITIONAL_INCLUDE_DIRS += -I../

# Remove -Werror set by etoile.make to ignore NSMenuItem protocol warnings
# GCC requires <NSMenuItem> with -[(id) addItem: (id)]... because NSMenuItem 
# declares -addItem: (id <NSMenuItem>). To be removed once the compiler is 
# improved to check protocol in a less zealous way when the receiver is 
# dynamically typed, or NSMenuItem protocol is deprecated on GNUstep...
ADDITIONAL_OBJCFLAGS = -std=c99 -Wno-import -Wno-unused -Wno-implicit

EtoileUITests_OBJC_FILES = \
	test_ETLayer.m \
	test_ETLayoutItem.m \
	test_ETLayoutItemBuilder.m \
	test_ETPickboard.m \
	test_ETController.m \
	test_ETView.m \
	test_ETLayout.m \
	test_ETInstrument.m \
	TestCell.m \
	TestCompositeLayout.m \
	TestItemCopy.m \
	TestItemGeometry.m \
	TestStyle.m

include $(GNUSTEP_MAKEFILES)/subproject.make
