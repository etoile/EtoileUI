PACKAGE_NAME = EtoileUI

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

FRAMEWORK_NAME = EtoileUI
PROJECT_NAME = $(FRAMEWORK_NAME)
VERSION = 0.4.1

EtoileUI_LIBRARIES_DEPEND_UPON += -lm -lEtoileFoundation \
	$(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

EtoileUI_SUBPROJECTS = Source CoreObjectBackend

ADDITIONAL_CPPFLAGS += -DCOREOBJECT=1
ADDITIONAL_OBJCFLAGS += -DCOREOBJECT=1
EtoileUI_LIBRARIES_DEPEND_UPON += -lCoreObject -lEtoileSerialize

ifeq ($(test), yes)
	BUNDLE_NAME = $(FRAMEWORK_NAME)

	EtoileUI_SUBPROJECTS += Tests
	EtoileUI_LDFLAGS += -lUnitKit $(EtoileUI_LIBRARIES_DEPEND_UPON)
endif

EtoileUI_HEADER_FILES_DIR = Headers

OTHER_HEADER_DIRS = AspectRepository Persistency

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
	ETLayoutItem+Reflection.h \
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
	ETPersistencyController.h \
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
	COUIServer.h

EtoileUI_HEADER_FILES += \
	EtoileCompatibility.h \
	NSImage+NiceScaling.h \
	ETPlugInRegistry+Icons.h

EtoileUI_OBJC_FILES += \
	AspectRepository/ETAspectCategory.m \
	AspectRepository/ETAspectRepository.m

ifeq ($(objectmerging), yes)

EtoileUI_OBJC_FILES += \
	ModelDescription/ETActionHandler+ModelDescription.m \
	ModelDescription/ETController+ModelDescription.m \
	ModelDescription/ETDecoratorItem+ModelDescription.m \
	ModelDescription/ETLayoutItem+ModelDescription.m \
	ModelDescription/ETLayout+ModelDescription.m \
	ModelDescription/ETStyle+ModelDescription.m \
	ModelDescription/ETUIItem+ModelDescription.m

EtoileUI_OBJC_FILES += \
	Persistency/ETController+CoreObject.m \
	Persistency/ETLayout+CoreObject.m \
	Persistency/ETLayoutItem+CoreObject.m \
	Persistency/ETStyle+CoreObject.m

endif

EtoileUI_RESOURCE_FILES = \
	English.lproj/Inspector.gorm \
	English.lproj/BrowserPrototype.gorm \
	English.lproj/OutlinePrototype.gorm \
	English.lproj/TablePrototype.gorm \
	English.lproj/ViewModelPrototype.gorm

# CoreObject Extensions
EtoileUI_RESOURCE_FILES += \
	English.lproj/RevertToPanel.gorm

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
-include etoile.make
-include ../../documentation.make
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

before-all::
	$(ECHO_NOTHING) \
	for headerDir in $(OTHER_HEADER_DIRS); do \
		for header in `ls -1 $$headerDir/*.h`; do \
			if [ ! -e Headers/`basename $$header` ]; then \
				ln -s ../$$header Headers; \
			fi; \
		done; \
	done \
	$(END_ECHO)

before-clean::
	$(ECHO_NOTHING) \
	for header in `ls -1 Headers/*.h`; do \
		if [ -L $$header ]; then \
			rm $$header; \
		fi; \
	done \
	$(END_ECHO)
