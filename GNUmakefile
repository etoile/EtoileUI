include $(GNUSTEP_MAKEFILES)/common.make

#test=yes

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

ifeq ($(test), yes)
BUNDLE_NAME = EtoileUI
else
FRAMEWORK_NAME = EtoileUI
endif

EtoileUI_LIBRARIES_DEPEND_UPON += -lm

#EtoileUI_SUBPROJECTS = 

EtoileUI_OBJC_FILES = \
	ETStyleRenderer.m \
	ETView.m \
	ETContainer.m \
	ETLayoutItemGroup.m \
	ETLayoutItem.m \
	ETLayer.m \
	ETInspector.m \
	ETLayout.m \
	ETFlowLayout.m \
	ETLineLayout.m \
	ETStackLayout.m \
	ETFreeLayout.m \
	ETPaneLayout.m \
	ETPaneSwitcherLayout.m \
	ETTableLayout.m \
	ETOutlineLayout.m \
	ETBrowserLayout.m \
	ETFlowView.m \
	ETLineView.m \
	ETStackView.m \
	ETTableView.m \
	ETViewLayoutLine.m \
	FSBrowserCell.m \
	ETCollection.m \
	ETObjectRegistry.m \
	NSIndexPath+Etoile.m \
	NSIndexSet+Etoile.m \
	NSObject+Etoile.m \
	NSString+Etoile.m \
	NSView+Etoile.m

ifeq ($(test), yes)
EtoileUI_OBJC_FILES += 
endif

EtoileUI_HEADER_FILES_DIR += .
EtoileUI_HEADER_FILES = \
	GNUstep.h \
	EtoileUI.h \
	ETStyleRenderer.h \
	ETView.h \
	ETContainer.h \
	ETLayoutItemGroup.h \
	ETLayoutItem.h \
	ETLayer.h \
	ETInspector.h \
	ETLayout.h \
	ETFlowLayout.h \
	ETLineLayout.h \
	ETStackLayout.h \
	ETFreeLayout.h \
	ETPaneLayout.h \
	ETPaneSwitcherLayout.h \
	ETTableLayout.h \
	ETOutlineLayout.h \
	ETBrowserLayout.h \
	ETFlowView.h \
	ETLineView.h \
	ETStackView.h \
	ETTableView.h \
	ETViewLayoutLine.h \
	FSBrowserCell.h \
	ETCollection.h \
	ETObjectRegistry.h \
	NSIndexPath+Etoile.h \
	NSIndexSet+Etoile.h \
	NSObject+Etoile.h \
	NSString+Etoile.h \
	NSView+Etoile.h

EtoileUI_RESOURCE_FILES = \
	Inspector.gorm \
	English.lproj/BrowserPrototype.gorm \
	English.lproj/OutlinePrototype.gorm \
	English.lproj/TablePrototype.gorm \
	English.lproj/ViewModelPrototype.nib


ifeq ($(FOUNDATION_LIB), apple)
ifeq ($(test), yes)
	EtoileUI_OBJC_LIBS += -framework UnitKit
endif
else
ifeq ($(test), yes)
	EtoileUI_LDFLAGS += -lUnitKit
endif
endif


ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif
