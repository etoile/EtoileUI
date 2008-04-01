PACKAGE_NAME = EtoileUI

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = EtoileUI
VERSION = 0.1

# -lm for FreeBSD at least (not sure it's needed for EtoileUI now)
LIBRARIES_DEPEND_UPON += -lm -lEtoileFoundation \
	$(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

EtoileUI_SUBPROJECTS = Source

EtoileUI_HEADER_FILES_DIR = Headers

EtoileUI_HEADER_FILES = \
        EtoileCompatibility.h \
        NSBezierPathCappedBoxes.h \
        NSImage+NiceScaling.h \
        UKNibOwner.h \
        UKPluginsRegistry+Icons.h

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make

