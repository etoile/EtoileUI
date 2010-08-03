/**	<title>ETStyle</title>

	<abstract>Base class to implement pluggable styles as subclasses and make 
	possible UI styling at runtime.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem;

/** ETStyle is an abstract base class that represents a style element.

EtoileUI pluggable styles are usually written by subclassing ETStyle.

Many classes in EtoileUI are subclasses of ETStyle whose instances are inserted 
in an [ETStyleGroup] object bound to a layout item. 

Each style can be asked to render or draw with -render:layoutItem:dirtyRect:. 
This method is usually called indirectly like that:

<list>
<item>-[ETStyle render:layoutItem:dirtyRect:]</item>
<item>-[ETStyleGroup render:layoutItem:dirtyRect:]</item>
<item>-[ETLayoutItem render:dirtyRect:inContext:]</item>
<item>...</item>
<item>-[ETLayoutItem display] or similar redisplay methods.</item>
</list>

ETStyle objects are usually shared between multiple style groups 
(or other owners) . Thereby they don't know on which UI areas they are applied 
and expect to be provided a layout item through -render:layoutItem:dirtyRect:. */
@interface ETStyle : NSObject <NSCopying>
{
	@private
	BOOL _isSharedStyle;
}

+ (void) registerAspects;
+ (void) registerStyle: (ETStyle *)aStyle;
+ (NSSet *) registeredStyles;
+ (NSSet *) registeredStyleClasses;

/* Factory Method */

+ (id) sharedInstance;

- (BOOL) isSharedStyle;
- (void) setIsSharedStyle: (BOOL)shared;

/* Copying */

- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone;

/* Style Rendering */

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
      dirtyRect: (NSRect)dirtyRect;

/* Drawing Primitives */
	  
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;

/* Notifications */
	  
- (void) didChangeItemBounds: (NSRect)bounds;

@end

// TODO: Support bottom and top indicator position
/** The drop indicator positions which can computed by [ETDropIndicator].

Based on the drop indicator position, the indicator drawing will vary. e.g. bar 
or rectangle. */
typedef enum
{
	ETIndicatorPositionNone, /** No visible indicator. */
	ETIndicatorPositionOn, /** Drop on indicator. */
	ETIndicatorPositionLeft, /** Left bar indicator. */
	ETIndicatorPositionRight /** Right bar indicator. */
} ETIndicatorPosition;

/** Draws a drop insertion bar.

ETDropIndicator is usually inserted and removed into the style group of the 
item group targeted by a drop validation. [ETPickDropCoordinator] manages that 
transparently.

You can subclass this class to use a custom color and/or thickness or even draw 
something else e.g. a circle, an image etc. You can override 
-[ETStyle render:layoutItem:dirtyRect:] if needed, and -currentIndicatorRect 
if you want to draw outside of the vertical indicator rect area.<br />
Warning: Subclassing is untested, surely require changes to the class and 
better documention.<br />

Finally a new drop indicator instantiated with -init can be used with 
-[ETLayout setDropIndicator:], [ETPickDropCoordinator] will retrieve it at 
drop validation time. */
@interface ETDropIndicator : ETStyle
{
	@private
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

/** Draws a shadow. */
@interface ETShadowStyle : ETStyle
{
	@private
	ETStyle *_content;
	id _shadow;
}
+ (id) shadowWithStyle: (ETStyle *)style;
- (id) initWithStyle: (ETStyle *)style;

@end

/** Draws an existing style tinted with a color.

Warning: Unstable API. */
@interface ETTintStyle : ETStyle
{
	@private
	ETStyle *_content;
	NSColor *_color;
}

+ (id) tintWithStyle: (ETStyle *)style color: (NSColor *)color;
+ (id) tintWithStyle: (ETStyle *)style;
- (id) initWithStyle: (ETStyle *)style;
- (void) setColor: (NSColor *)color;
- (NSColor *) color;

@end

/** Draws a speech bubble around the item to which this style is applied. */
@interface ETSpeechBubbleStyle : ETStyle
{
	@private
	ETStyle *_content;
}

+ (id) speechWithStyle: (ETStyle *)style;
- (id) initWithStyle: (ETStyle *)style;

@end
