include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

APP_NAME = PhotoViewExample

$(APP_NAME)_OBJC_FILES = \
	ContainerController.m \
	../main.m

$(APP_NAME)_RESOURCE_FILES = ContainerExample.nib

$(APP_NAME)_GUI_LIBS = -lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
