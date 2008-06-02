include $(GNUSTEP_MAKEFILES)/common.make

#test=yes

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

FRAMEWORK_NAME = EtoileUI
PROJECT_NAME = $(FRAMEWORK_NAME)

EtoileUI_LIBRARIES_DEPEND_UPON += -lm -lEtoileFoundation

ifeq ($(test), yes)
	BUNDLE_NAME = $(FRAMEWORK_NAME)

	EtoileUI_SUBPROJECTS = Tests
	EtoileUI_LDFLAGS += -lUnitKit $(EtoileUI_LIBRARIES_DEPEND_UPON)
endif


EtoileUI_OBJC_FILES = \
	ETApplication.m \
	ETBrowserLayout.m \
	ETContainer+Controller.m \
	ETContainer.m \
	ETEvent.m \
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
	ETLayoutItem+Reflection.m \
	ETLayoutLine.m \
	ETLayout.m \
	ETLineLayout.m \
	ETLineView.m \
	ETObjectBrowserLayout.m \
	ETObjectRegistry+EtoileUI.m \
	ETOutlineLayout.m \
	ETPaneLayout.m \
	ETPaneSwitcherLayout.m \
	ETPickboard.m \
	ETStackLayout.m \
	ETStackView.m \
	ETStyle.m \
	ETStyleRenderer.m \
	ETTableLayout.m \
	ETTableView.m \
	ETTextEditorLayout.m \
	ETView.m \
	ETViewModelLayout.m \
	ETWindowItem.m \
	FSBrowserCell.m \
	NSImage+Etoile.m \
	NSObject+EtoileUI.m \
	NSView+Etoile.m \
	NSWindow+Etoile.m


EtoileUI_HEADER_FILES_DIR +=
EtoileUI_HEADER_FILES = \
	ETApplication.h \
	ETBrowserLayout.h \
	ETCompatibility.h \
	ETContainer+Controller.h \
	ETContainer.h \
	ETEvent.h \
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
	ETLayoutItem+Reflection.h \
	ETLayoutLine.h \
	ETLineLayout.h \
	ETLineView.h \
	ETObjectBrowserLayout.h \
	ETObjectRegistry+EtoileUI.h \
	EtoileUI.h \
	ETOutlineLayout.h \
	ETPaneLayout.h \
	ETPaneSwitcherLayout.h \
	ETPickboard.h \
	ETStackLayout.h \
	ETStackView.h \
	ETStyle.h \
	ETStyleRenderer.h \
	ETTableLayout.h \
	ETTableView.h \
	ETTextEditorLayout.h \
	ETView.h \
	ETViewModelLayout.h \
	ETWindowItem.h \
	FSBrowserCell.h \
	GNUstep.h \
	NSImage+Etoile.h \
	NSObject+EtoileUI.h \
	NSView+Etoile.h \
	NSWindow+Etoile.h


EtoileUI_RESOURCE_FILES = \
	English.lproj/Inspector.gorm \
	English.lproj/BrowserPrototype.gorm \
	English.lproj/OutlinePrototype.gorm \
	English.lproj/TablePrototype.gorm \
	English.lproj/ViewModelPrototype.gorm


ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
include etoile.make
endif
