/**	<title>ETStyle/title>

	<abstract>Base class to implement pluggable styles as subclasses and make 
	possible UI styling at runtime.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/ETRendering.h>

@class ETLayoutItem;

/** ETStyle is an abstract base class that represents a style element.

EtoileUI pluggable styles are usually written by subclassing ETStyle.

Many classes in EtoileUI are subclasses of ETStyle whose instances are inserted 
in an ETStyleGroup object bound to a layout item. 

Each style can be asked to render or draw with -render:layoutItem:dirtyRect:. 
This method is usually called indirectly like that:
-[ETStyle render:layoutItem:dirtyRect:]
-[ETStyleGroup render:layoutItem:dirtyRect:]
-[ETLayoutItem render:dirtyRect:inContext:]
...
-[ETLayoutItem display] or similar redisplay methods.

ETStyle objects are usually shared between multiple style groups 
(or other owners) . Thereby they don't know on which UI areas they are applied 
and expect to be provided a layout item through -render:layoutItem:dirtyRect:. */
@interface ETStyle : NSObject <ETRendering, NSCopying>
{
	BOOL _isSharedStyle;
}

+ (void) registerAspects;
+ (void) registerStyle: (ETStyle *)aStyle;
+ (NSSet *) registeredStyles;
+ (NSSet *) registeredStyleClasses;

/* Factory Method */

+ (id) sharedInstance;

- (BOOL) isSharedStyle;

/* Copying */

- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone;

/* Style Rendering */

- (SEL) styleSelector;
- (void) render: (NSMutableDictionary *)inputValues;
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
      dirtyRect: (NSRect)dirtyRect;
	  
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
	  
- (void) didChangeItemBounds: (NSRect)bounds;
- (NSRect) boundingBoxForItem: (ETLayoutItem *)anItem;

@end

// TODO: Support bottom and top indicator position
/** The drop indicator positions which can computed by ETDropIndicator.

Based on the drop indicator position, the indicator drawing will vary. e.g. bar 
or rectangle. */
typedef enum
{
/** No visible indicator. */
	ETIndicatorPositionNone,
/** Drop on indicator. */
	ETIndicatorPositionOn, 
/** Left bar indicator. */
	ETIndicatorPositionLeft,
/** Right bar indicator. */
	ETIndicatorPositionRight
} ETIndicatorPosition;

@interface ETDropIndicator : ETStyle
{
	NSPoint _dropLocation;
	ETLayoutItem *_hoveredItem;
	BOOL _dropOn;
	NSRect _prevInsertionIndicatorRect;
	NSRect _lastIndicatorRect;
}

- (id) initWithLocation: (NSPoint)dropLocation 
            hoveredItem: (ETLayoutItem *)hoveredItem
           isDropTarget: (BOOL)dropOn;

- (float) thickness;
- (NSColor *) color;

- (void) drawVerticalInsertionIndicatorInRect: (NSRect)indicatorRect;
- (void) drawRectangularInsertionIndicatorInRect: (NSRect)indicatorRect;
- (NSRect) previousIndicatorRect;
- (NSRect) currentIndicatorRect;

- (ETIndicatorPosition) indicatorPosition;
+ (ETIndicatorPosition) indicatorPositionForPoint: (NSPoint)dropPoint
                                    nearItemFrame: (NSRect)itemRect;

@end

@interface ETShadowStyle : ETStyle
{
	ETStyle *_content;
	id _shadow;
}
+ (id) shadowWithStyle: (ETStyle *)style;
- (id) initWithStyle: (ETStyle *)style;

@end

@interface ETTintStyle : ETStyle
{
	ETStyle *_content;
	NSColor *_color;
}

+ (id) tintWithStyle: (ETStyle *)style color: (NSColor *)color;
+ (id) tintWithStyle: (ETStyle *)style;
- (id) initWithStyle: (ETStyle *)style;
- (void) setColor: (NSColor *)color;
- (NSColor *) color;

@end

/**
 * Draws a speech bubble around the item to which this style is applied.
 */
@interface ETSpeechBubbleStyle : ETStyle
{
	ETStyle *_content;
}

+ (id) speechWithStyle: (ETStyle *)style;
- (id) initWithStyle: (ETStyle *)style;

@end
