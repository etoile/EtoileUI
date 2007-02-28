include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I../Headers

#
# Main application
#
LIBRARY_NAME = libEtoileUI
VERSION = 0.1

# For FreeBSD at least (not sure it's needed for EtoileUI now)
LIBRARIES_DEPEND_UPON += -lm

#
# Resource files
#
$(LIBRARY_NAME)_MAIN_MODEL_FILE =

$(LIBRARY_NAME)_RESOURCE_FILES =

$(LIBRARY_NAME)_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
$(LIBRARY_NAME)_LANGUAGES = \
	English
	
#
# Class files
#
$(LIBRARY_NAME)_OBJC_FILES = \
	NSBezierPathCappedBoxes.m \
	NSImage+NiceScaling.m \
	UKNibOwner.m

#
# Header files to be installed
#
$(LIBRARY_NAME)_HEADER_FILES_DIR = ../Headers

$(LIBRARY_NAME)_HEADER_FILES_INSTALL_DIR = /EtoileUI

$(LIBRARY_NAME)_HEADER_FILES = \
	Cocoa.h \
	EtoileCompatibility.h \
	NSBezierPathCappedBoxes.h \
	NSImage+NiceScaling.h \
	UKNibOwner.h

#
# C files
#
$(LIBRARY_NAME)_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make

-include GNUmakefile.postamble
