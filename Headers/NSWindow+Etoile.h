/** <title>NSWindow+Etoile</title>

	<abstract>NSWindow additions.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSPanel.h>
#import <EtoileUI/ETCompatibility.h>

@class ETLayoutItem;

@interface NSWindow (Etoile) <NSCopying>

+ (NSUInteger) defaultStyleMask;

- (instancetype) init;
- (instancetype) initWithFrame: (NSRect)frame styleMask: (NSUInteger)windowStyle;
- (instancetype) initWithContentRect: (NSRect)frame styleMask: (NSUInteger)windowStyle;

@property (nonatomic, readonly) ETLayoutItem *candidateFocusedItem;

- (void) setFrameSizeFromTopLeft: (NSSize)size;
- (void) setContentSizeFromTopLeft: (NSSize)size;

@property (nonatomic, readonly) NSPoint topLeftPoint;
@property (nonatomic, readonly) NSRect frameRectInContent;
@property (nonatomic, readonly) NSRect contentRectInFrame;

@property (nonatomic, readonly) BOOL isSystemPrivateWindow;
@property (nonatomic, readonly) BOOL isCacheWindow;

- (IBAction) browse: (id)sender;

/** @taskunit GNUstep Compatibility */

#ifdef GNUSTEP
- (BOOL) inLiveResize;
#endif

@end


/** Full screen window which can become key. */
@interface ETFullScreenWindow : NSWindow
- (instancetype) init;
@property (nonatomic, readonly) BOOL canBecomeKeyWindow;
@end


@interface NSPanel (EtoileUI)
+ (NSUInteger) defaultStyleMask;
@end
