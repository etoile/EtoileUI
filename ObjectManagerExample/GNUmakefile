include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

APP_NAME = ObjectManagerExample

ObjectManagerExample_OBJC_FILES = \
	ObjectManagerController.m \
	../main.m

ObjectManagerExample_MAIN_MODEL_FILE = \
	ObjectManager.gorm

ObjectManagerExample_RESOURCE_FILES = ObjectManager.gorm

ObjectManagerExample_GUI_LIBS = -lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
