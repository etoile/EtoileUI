include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = libEtoileUI

# For FreeBSD at least (not sure it's needed for EtoileUI now)
LIBRARIES_DEPEND_UPON += -lm

libEtoileUI_OBJC_FILES = \
	NSBezierPathCappedBoxes.m \
	NSImage+NiceScaling.m \
	UKNibOwner.m

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/subproject.make

-include GNUmakefile.postamble

