include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -std=c99
ADDITIONAL_OBJCFLAGS += -I. 

APP_NAME = FormExample

$(APP_NAME)_OBJC_FILES = $(wildcard *.m) ../main.m

$(APP_NAME)_PRINCIPAL_CLASS = ETApplication

$(APP_NAME)_MAIN_MODEL_FILE = $(APP_NAME).gorm

$(APP_NAME)_RESOURCE_FILES = $(APP_NAME).gorm

$(APP_NAME)_GUI_LIBS = -lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
