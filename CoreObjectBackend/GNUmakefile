include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = CoreObjectBackend

$(SUBPROJECT_NAME)_OBJCFLAGS = -std=c99
$(SUBPROJECT_NAME)_INCLUDE_DIRS = -I`pg_config --includedir` 
$(SUBPROJECT_NAME)_LIBRARY_DIRS = -L`pg_config --libdir` 

$(SUBPROJECT_NAME)_OBJC_FILES = COUIServer.m

include $(GNUSTEP_MAKEFILES)/subproject.make

