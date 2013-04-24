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

/** See -isWidget.

This protocol is subject to change or be removed. */
@protocol ETWidget
- (id) target;
- (void) setTarget: (id)aTarget;
- (SEL) action;
- (void) setAction: (SEL)aSelector;
- (id) objectValue;
- (void) setObjectValue: (id)aValue;
- (NSActionCell *) cell;
@end


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

- (float) height;
- (float) width;
- (void) setHeight: (float)height;
- (void) setWidth: (float)width;
- (float) x;
- (float) y;
- (void) setX: (float)x;
- (void) setY: (float)y;

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

