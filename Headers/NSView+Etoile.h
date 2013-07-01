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
+ (void)_setUpEtoileUITraits;

+ (NSRect) defaultFrame;

- (id) init;
- (BOOL) isWidget;
- (BOOL) isSupervisorView;
- (BOOL) isWindowContentView;

- (id) owningItem;
- (id <ETFirstResponderSharingArea>) firstResponderSharingArea;
- (id <ETEditionCoordinator>) editionCoordinator;
- (ETLayoutItem *) candidateFocusedItem;

/* Copying */

- (id) copyWithZone: (NSZone *)zone;

/* Frame Utility Methods */

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

/* Property Value Coding */

- (NSArray *) propertyNames;

/* Basic Properties */

- (NSImage *) snapshot;
- (NSImage *) icon;

#ifdef GNUSTEP
- (void) setSubviews: (NSArray *)newSubviews;
- (void) viewWillDraw;
#endif

@end

@interface NSScrollView (Etoile)
- (BOOL) isWidget;
@end

