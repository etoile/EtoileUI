include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

APP_NAME = PhotoViewExample

PhotoViewExample_OBJC_FILES = \
	ContainerController.m \
	../main.m

PhotoViewExample_MAIN_MODEL_FILE = \
	PhotoViewExample.gorm

PhotoViewExample_RESOURCE_FILES = PhotoViewExample.gorm

PhotoViewExample_GUI_LIBS = -lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
