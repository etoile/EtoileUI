//
//  NSView+Etoile.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETCollection.h>


@interface NSView (Etoile) <NSCopying, ETCollection, ETCollectionMutation>

- (BOOL) isContainer;

/* Copying */

- (id) copyWithZone: (NSZone *)zone;

/* Collection Protocol */

- (BOOL) isEmpty;
- (id) content;
- (NSArray *) contentArray;
- (void) addObject: (id)view;
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

/* Basic Properties */

- (NSImage *) icon;

@end

/* Utility Functions */

NSRect ETMakeRect(NSPoint origin, NSSize size);
NSRect ETScaleRect(NSRect frame, float factor);
NSSize ETScaleSize(NSSize size, float factor);
