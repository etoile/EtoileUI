/** <title>NSView+Etoile</title>

	<abstract>NSView additions.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/ETCollection.h>

@class ETLayoutItem;
@protocol ETFirstResponderSharingArea, ETEditionCoordinator;

@interface NSView (Etoile) <NSCopying, ETCollection, ETCollectionMutation>

/** @taskunit Type Querying */

- (BOOL) isWindowContentView;

/** @taskunit Frame Utility Methods */

- (CGFloat) height;
- (CGFloat) width;
- (void) setHeight: (CGFloat)height;
- (void) setWidth: (CGFloat)width;
- (CGFloat) x;
- (CGFloat) y;
- (void) setX: (CGFloat)x;
- (void) setY: (CGFloat)y;

- (void) setFrameSizeFromTopLeft: (NSSize)size;
- (void) setHeightFromTopLeft: (int)height;
- (NSPoint) topLeftPoint;
- (void) setFrameSizeFromBottomLeft: (NSSize)size;
- (void) setHeightFromBottomLeft: (int)height;
- (NSPoint) bottomLeftPoint;

/** @taskunit Generating an Image Representation */

- (NSImage *) snapshot;
- (NSImage *) icon;

#ifdef GNUSTEP
- (void) setSubviews: (NSArray *)newSubviews;
- (void) viewWillDraw;
#endif

@end
