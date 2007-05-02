include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = -I../Headers

#
# Main application
#
FRAMEWORK_NAME = EtoileUI
VERSION = 0.1

# For FreeBSD at least (not sure it's needed for EtoileUI now)
LIBRARIES_DEPEND_UPON += -lm

#
# Resource files
#
EtoileUI_MAIN_MODEL_FILE =

EtoileUI_RESOURCE_FILES =

EtoileUI_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
EtoileUI_LANGUAGES = \
	English
	
#
# Class files
#
EtoileUI_OBJC_FILES = \
	NSBezierPathCappedBoxes.m \
	NSImage+NiceScaling.m \
	UKNibOwner.m

#
# Header files to be installed
#
EtoileUI_HEADER_FILES_DIR = ../Headers

EtoileUI_HEADER_FILES = \
	EtoileCompatibility.h \
	NSBezierPathCappedBoxes.h \
	NSImage+NiceScaling.h \
	UKNibOwner.h

#
# C files
#
EtoileUI_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble
