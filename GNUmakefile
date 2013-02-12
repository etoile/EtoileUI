PACKAGE_NAME = EtoileUI

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

FRAMEWORK_NAME = EtoileUI
PROJECT_NAME = $(FRAMEWORK_NAME)
VERSION = 0.4.1

EtoileUI_LIBRARIES_DEPEND_UPON += -lm -lEtoileFoundation -lIconKit \
	$(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

export coreobject ?= yes

ifeq ($(coreobject), yes)
  EtoileUI_LIBRARIES_DEPEND_UPON += -lCoreObject
  EtoileUI_CPP_FLAGS += -DCOREOBJECT
  EtoileUI_OBJCFLAGS += -DCOREOBJECT
  EtoileUI_CFLAGS += -DCOREOBJECT
endif

ifeq ($(test), yes)
  BUNDLE_NAME = $(FRAMEWORK_NAME)
  EtoileUI_LDFLAGS += -lUnitKit $(EtoileUI_LIBRARIES_DEPEND_UPON)
endif

EtoileUI_HEADER_FILES_DIR = Headers

OTHER_HEADER_DIRS = AspectRepository CoreObjectUI Persistency UIBuilder

EtoileUI_HEADER_FILES = \
	Controls+Etoile.h \
	ETActionHandler.h \
	ETApplication.h \
	ETAspectCategory.h \
	ETAspectRepository.h \
	ETBasicItemStyle.h \
	ETBrowserLayout.h \
	ETColumnLayout.h \
	ETCompatibility.h \
	ETCompositeLayout.h \
	ETComputedLayout.h \
	ETController.h \
	ETDecoratorItem.h \
	ETDocumentController.h \
	ETEvent.h \
	ETFixedLayout.h \
	ETFlowLayout.h \
	ETFragment.h \
	ETFreeLayout.h \
	ETGeometry.h \
	ETInspecting.h \
	ETInspector.h \
	ETItemTemplate.h \
	ETLayer.h \
	ETLayout.h \
	ETLayoutItemBuilder.h \
	ETLayoutItemGroup.h \
	ETLayoutItemGroup+Mutation.h \
	ETLayoutItem.h \
	ETLayoutItem+KVO.h \
	ETLayoutItem+Scrollable.h \
	ETLayoutItemFactory.h \
	ETLineFragment.h \
	ETLineLayout.h \
	ETModelDescriptionRenderer.h \
	ETNibOwner.h \
	ETObjectBrowserLayout.h \
	EtoileUI.h \
	EtoileUIProperties.h \
	ETOutlineLayout.h \
	ETPaintBucketTool.h \
	ETPaneLayout.h \
	ETPaintActionHandler.h \
	ETPickDropActionHandler.h \
	ETPickboard.h \
	ETScrollableAreaItem.h \
	ETSelectionAreaItem.h \
	ETShape.h \
	ETStyle.h \
	ETStyleGroup.h \
	ETTableLayout.h \
	ETTextEditorLayout.h \
	ETTitleBarItem.h \
	ETTitleBarView.h \
	ETUIItem.h \
	ETUIObject.h \
	ETView.h \
	ETViewModelLayout.h \
	ETWidgetLayout.h \
	ETWindowItem.h \
	FSBrowserCell.h \
	NSCell+EtoileUI.h \
	NSImage+Etoile.h \
	NSObject+EtoileUI.h \
	NSView+Etoile.h \
	NSWindow+Etoile.h

EtoileUI_HEADER_FILES += \
	ETEventProcessor.h \
	ETTemplateItemLayout.h \
	ETIconLayout.h \
	ETTool.h \
	ETSelectTool.h \
	ETPickDropCoordinator.h \
	ETInstruments.h \
	ETHandle.h

EtoileUI_HEADER_FILES += \
	CoreObjectUI.h

EtoileUI_HEADER_FILES += \
	ETController+CoreObject.h \
	ETLayout+CoreObject.h \
	ETLayoutItem+CoreObject.h \
	ETStyle+CoreObject.h

EtoileUI_HEADER_FILES += \
	ETLayoutItem+UIBuilder.h

EtoileUI_HEADER_FILES += \
	EtoileCompatibility.h \
	NSImage+NiceScaling.h \
	ETPlugInRegistry+Icons.h

EtoileUI_OBJC_FILES += $(wildcard Source/*.m)

EtoileUI_OBJC_FILES += $(wildcard AspectRepository/*.m)

EtoileUI_OBJC_FILES += $(wildcard UIBuilder/*.m)

ifeq ($(coreobject), yes)
EtoileUI_OBJC_FILES += $(wildcard CoreObjectUI/*.m)

EtoileUI_OBJC_FILES += $(wildcard ModelDescription/*.m)

EtoileUI_OBJC_FILES += $(wildcard Persistency/*.m)
endif

ifeq ($(test), yes)
EtoileUI_OBJC_FILES += \
	Tests/test_ETLayer.m \
	Tests/test_ETLayoutItem.m \
	Tests/test_ETLayoutItemBuilder.m \
	Tests/test_ETPickboard.m \
	Tests/test_ETController.m \
	Tests/test_ETView.m \
	Tests/test_ETLayout.m \
	Tests/test_ETInstrument.m \
	Tests/TestCell.m \
	Tests/TestCompositeLayout.m \
	Tests/TestItemCopy.m \
	Tests/TestItemGeometry.m \
	Tests/TestStyle.m \
	Tests/TestWidgetLayout.m \
	Tests/TestWindowLayout.m

ifeq ($(coreobject), yes)
EtoileUI_OBJC_FILES += \
	Tests/TestPersistency.m
endif
endif
 
EtoileUI_RESOURCE_FILES = \
	English.lproj/Inspector.gorm \
	English.lproj/BrowserPrototype.gorm \
	English.lproj/OutlinePrototype.gorm \
	English.lproj/TablePrototype.gorm \
	English.lproj/ViewModelPrototype.gorm

EtoileUI_RESOURCE_FILES += $(wildcard Images/FugueIcons/*.png)

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
-include etoile.make
-include ../../documentation.make
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif
