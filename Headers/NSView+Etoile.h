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

+ (NSRect) defaultFrame;

- (id) init;
- (BOOL) isWidget;
- (BOOL) isSupervisorView;
- (BOOL) isWindowContentView;

- (id) owningItem;

/* Copying */

- (id) copyWithZone: (NSZone *)zone;

/* Collection Protocol */

- (BOOL) isOrdered;
- (BOOL) isEmpty;
- (id) content;
- (NSArray *) contentArray;
- (void) addObject: (id)view;
- (void) insertObject: (id)view atIndex: (unsigned int)index;
- (void) removeObject: (id)view;

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

- (NSArray *) properties;

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

