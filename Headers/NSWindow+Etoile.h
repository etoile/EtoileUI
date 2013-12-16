/** <title>NSWindow+Etoile</title>

	<abstract>NSWindow additions.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETCompatibility.h>

@class ETLayoutItem;

@interface NSWindow (Etoile) <NSCopying>

+ (unsigned int) defaultStyleMask;

- (id) init;
- (id) initWithFrame: (NSRect)frame styleMask: (unsigned int)windowStyle;
- (id) initWithContentRect: (NSRect)frame styleMask: (unsigned int)windowStyle;

- (ETLayoutItem *) candidateFocusedItem;

- (void) setFrameSizeFromTopLeft: (NSSize)size;
- (void) setContentSizeFromTopLeft: (NSSize)size;
- (NSPoint) topLeftPoint;

- (NSRect) frameRectInContent;
- (NSRect) contentRectInFrame;

- (BOOL) isSystemPrivateWindow;
- (BOOL) isCacheWindow;

- (IBAction) browse: (id)sender;

/** @taskunit GNUstep Compatibility */

#ifdef GNUSTEP
- (BOOL) inLiveResize;
#endif

@end


/** Full screen window which can become key. */
@interface ETFullScreenWindow : NSWindow

- (id) init;
- (BOOL) canBecomeKeyWindow;

@end
