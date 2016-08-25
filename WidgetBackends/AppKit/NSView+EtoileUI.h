/** <title>NSView+Etoile</title>

	<abstract>NSView additions.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSView.h>
#import <EtoileFoundation/ETCollection.h>

@class ETLayoutItem;
@protocol ETFirstResponderSharingArea, ETEditionCoordinator;

@interface NSView (Etoile) <NSCopying, ETCollection, ETCollectionMutation>

/** @taskunit Type Querying */

@property (nonatomic, readonly) BOOL isWindowContentView;

/** @taskunit Frame Utility Methods */

@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;

- (void) setFrameSizeFromTopLeft: (NSSize)size;
- (void) setHeightFromTopLeft: (int)height;

@property (nonatomic, readonly) NSPoint topLeftPoint;

- (void) setFrameSizeFromBottomLeft: (NSSize)size;
- (void) setHeightFromBottomLeft: (int)height;

@property (nonatomic, readonly) NSPoint bottomLeftPoint;

/** @taskunit Generating an Image Representation */

@property (nonatomic, readonly) NSImage *snapshot;
@property (nonatomic, readonly) NSImage *icon;

#ifdef GNUSTEP
- (void) setSubviews: (NSArray *)newSubviews;
- (void) viewWillDraw;
#endif

@end
