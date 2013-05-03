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

OTHER_HEADER_DIRS = Base Layouts AspectRepository CoreObjectUI Persistency UIBuilder

EtoileUI_HEADER_FILES = $(notdir $(wildcard Headers/*.h))

EtoileUI_OBJC_FILES += $(wildcard Source/*.m)

EtoileUI_OBJC_FILES += $(wildcard Base/*.m)

EtoileUI_OBJC_FILES += $(wildcard Layouts/*.m)

EtoileUI_OBJC_FILES += $(wildcard AspectRepository/*.m)

EtoileUI_OBJC_FILES += $(wildcard UIBuilder/*.m)

ifeq ($(coreobject), yes)
EtoileUI_OBJC_FILES += $(wildcard CoreObjectUI/*.m)

EtoileUI_OBJC_FILES += $(wildcard ModelDescription/*.m)

EtoileUI_OBJC_FILES += $(wildcard Persistency/*.m)
endif

ifeq ($(test), yes)
EtoileUI_OBJC_FILES += \
	Tests/TestAutoresizing.m \
	Tests/TestLayoutItem.m \
	Tests/TestLayoutItemBuilder.m \
	Tests/TestPickboard.m \
	Tests/TestController.m \
	Tests/TestSupervisorView.m \
	Tests/TestLayout.m \
	Tests/TestTool.m \
	Tests/TestCell.m \
	Tests/TestCompositeLayout.m \
	Tests/TestFormLayout.m \
	Tests/TestItemCopy.m \
	Tests/TestItemGeometry.m \
	Tests/TestItemProvider.m \
	Tests/TestResponder.m \
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
