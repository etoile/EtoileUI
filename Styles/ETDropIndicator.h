/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETCompatibility.h>
#import <EtoileUI/ETStyle.h>

@class COObjectGraphContext;
@class ETLayoutItem;

// TODO: Support bottom and top indicator position
/** The drop indicator positions which can computed by [ETDropIndicator].

Based on the drop indicator position, the indicator drawing will vary. e.g. bar 
or rectangle. */
typedef NS_ENUM(NSUInteger, ETIndicatorPosition)
{
	ETIndicatorPositionNone, /** No visible indicator. */
	ETIndicatorPositionOn, /** Drop on indicator. */
	ETIndicatorPositionLeft, /** Left bar indicator. */
	ETIndicatorPositionRight /** Right bar indicator. */
};

/** @abstract Draws a drop insertion bar.

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
}

- (instancetype) initWithLocation: (NSPoint)dropLocation 
            hoveredItem: (ETLayoutItem *)hoveredItem
           isDropTarget: (BOOL)dropOn
     objectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) CGFloat thickness;
@property (nonatomic, readonly) NSColor *color;

- (void) drawVerticalInsertionIndicatorInRect: (NSRect)indicatorRect;
- (void) drawRectangularInsertionIndicatorInRect: (NSRect)indicatorRect;
@property (nonatomic, readonly) NSRect previousIndicatorRect;
@property (nonatomic, readonly) NSRect currentIndicatorRect;

@property (nonatomic, readonly) ETIndicatorPosition indicatorPosition;
+ (ETIndicatorPosition) indicatorPositionForPoint: (NSPoint)dropPoint
                                    nearItemFrame: (NSRect)itemRect;

@end
