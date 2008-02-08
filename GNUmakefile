include $(GNUSTEP_MAKEFILES)/common.make

#test=yes

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

ifeq ($(test), yes)
BUNDLE_NAME = EtoileUI
else
FRAMEWORK_NAME = EtoileUI
endif

PROJECT_NAME=$(FRAMEWORK_NAME)

EtoileUI_LIBRARIES_DEPEND_UPON += -lm

#EtoileUI_SUBPROJECTS = 

EtoileUI_OBJC_FILES = \
	ETApplication.m \
	ETBrowserLayout.m \
	ETCollection.m \
	ETContainer+Controller.m \
	ETContainer.m \
	ETEvent.m \
	ETFilter.m \
	ETFlowLayout.m \
	ETFlowView.m \
	ETFreeLayout.m \
	ETInspector.m \
	ETLayer.m \
	ETLayoutItemBuilder.m \
	ETLayoutItem+Events.m \
	ETLayoutItemGroup+Factory.m \
	ETLayoutItemGroup.m \
	ETLayoutItemGroup+Mutation.m \
	ETLayoutItem.m \
	ETLayoutLine.m \
	ETLayout.m \
	ETLineLayout.m \
	ETLineView.m \
	ETObjectBrowserLayout.m \
	ETObjectChain.m \
	ETObject.m \
	ETObjectRegistry+EtoileUI.m \
	ETObjectRegistry.m \
	ETOutlineLayout.m \
	ETPaneLayout.m \
	ETPaneSwitcherLayout.m \
	ETPickboard.m \
	ETPropertyValueCoding.m \
	ETStackLayout.m \
	ETStackView.m \
	ETStyle.m \
	ETStyleRenderer.m \
	ETTableLayout.m \
	ETTableView.m \
	ETTextEditorLayout.m \
	ETTransform.m \
	ETView.m \
	ETViewModelLayout.m \
	ETWindowItem.m \
	FSBrowserCell.m \
	NSImage+Etoile.m \
	NSIndexPath+Etoile.m \
	NSIndexSet+Etoile.m \
	NSObject+Etoile.m \
	NSObject+EtoileUI.m \
	NSObject+Model.m \
	NSString+Etoile.m \
	NSView+Etoile.m \
	NSWindow+Etoile.m


ifeq ($(test), yes)
EtoileUI_OBJC_FILES +=
endif

EtoileUI_HEADER_FILES_DIR +=
EtoileUI_HEADER_FILES = \
	ETApplication.h \
	ETBrowserLayout.h \
	ETCollection.h \
	ETCompatibility.h \
	ETContainer+Controller.h \
	ETContainer.h \
	ETEvent.h \
	ETFilter.h \
	ETFlowLayout.h \
	ETFlowView.h \
	ETFreeLayout.h \
	ETInspecting.h \
	ETInspector.h \
	ETLayer.h \
	ETLayout.h \
	ETLayoutItemBuilder.h \
	ETLayoutItem+Events.h \
	ETLayoutItemGroup+Factory.h \
	ETLayoutItemGroup.h \
	ETLayoutItemGroup+Mutation.h \
	ETLayoutItem.h \
	ETLayoutLine.h \
	ETLineLayout.h \
	ETLineView.h \
	ETObjectBrowserLayout.h \
	ETObjectChain.h \
	ETObject.h \
	ETObjectRegistry+EtoileUI.h \
	ETObjectRegistry.h \
	EtoileUI.h \
	ETOutlineLayout.h \
	ETPaneLayout.h \
	ETPaneSwitcherLayout.h \
	ETPickboard.h \
	ETPropertyValueCoding.h \
	ETRendering.h \
	ETStackLayout.h \
	ETStackView.h \
	ETStyle.h \
	ETStyleRenderer.h \
	ETTableLayout.h \
	ETTableView.h \
	ETTextEditorLayout.h \
	ETTransform.h \
	ETView.h \
	ETViewModelLayout.h \
	ETWindowItem.h \
	FSBrowserCell.h \
	GNUstep.h \
	NSImage+Etoile.h \
	NSIndexPath+Etoile.h \
	NSIndexSet+Etoile.h \
	NSObject+Etoile.h \
	NSObject+EtoileUI.h \
	NSObject+Model.h \
	NSString+Etoile.h \
	NSView+Etoile.h \
	NSWindow+Etoile.h


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

#include $(GNUSTEP_MAKEFILES)/aggregate.make

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
include etoile.make
endif
