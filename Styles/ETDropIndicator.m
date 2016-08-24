/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETDropIndicator.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"

@implementation ETDropIndicator

+ (NSString *) baseClassName
{
	return @"DropIndicator";
}

- (id) initWithLocation: (NSPoint)dropLocation 
            hoveredItem: (ETLayoutItem *)hoveredItem
           isDropTarget: (BOOL)dropOn
     objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_dropLocation = dropLocation;
	_hoveredItem = hoveredItem;
	_dropOn = dropOn;

	return self;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"arrow-270"];
}

// FIXME: Handle layout orientation, only works with horizontal layout
// currently, in other words the insertion indicator is always vertical.
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	//ETLog(@"Draw indicator rect %@ in %@", NSStringFromRect([self currentIndicatorRect]), item);

	if (_dropOn) /* Add */
	{
		//NSRect hoveredRect = [_hoveredItem frame];
		[self drawRectangularInsertionIndicatorInRect: [item drawingBoundsForStyle: self]];
	}
	else /* Insert */
	{
		[self drawVerticalInsertionIndicatorInRect: [self currentIndicatorRect]];
	}
}

- (void) setUpDrawingAttributes
{

}

/** Returns the line width to used to draw the indicator. */
- (CGFloat) thickness
{
	return 8.0;
}

/** Returns the color used to draw to the indicator. */
- (NSColor *) color
{
	return [NSColor blueColor];
}

- (void) drawVerticalInsertionIndicatorInRect: (NSRect)indicatorRect
{
	NSBezierPath *indicatorPath = [NSBezierPath bezierPathWithRect: indicatorRect];

	[[self color] setFill];
	[indicatorPath setLineWidth: [self thickness] / 2];
	[indicatorPath fill];
	/*[NSBezierPath strokeLineFromPoint: NSMakePoint(indicatorLineX, NSMinY(hoveredRect))
							  toPoint: NSMakePoint(indicatorLineX, NSMaxY(hoveredRect))];*/
	
	_prevInsertionIndicatorRect = indicatorRect;
}

- (void) drawRectangularInsertionIndicatorInRect: (NSRect)indicatorRect
{
	NSBezierPath *indicatorPath = [NSBezierPath bezierPathWithRect: indicatorRect];

	[[self color] setStroke];
	[indicatorPath setLineWidth: [self thickness]];
	[indicatorPath stroke];

	_prevInsertionIndicatorRect = indicatorRect;
}

- (NSRect) previousIndicatorRect
{
	return NSIntegralRect(_prevInsertionIndicatorRect);
}

- (NSRect) verticalIndicatorRect
{
	// NOTE: Should we use... -[[item layout] displayRectOfItem: hoveredItem];
	NSRect hoveredRect = [_hoveredItem frame];
	CGFloat indicatorWidth = 4.0;
	CGFloat indicatorLineX = 0.0;

	/* Decides whether to draw on left or right border of hovered item */
	switch ([[self class] indicatorPositionForPoint: _dropLocation 
	                                  nearItemFrame: hoveredRect])
	{
		case ETIndicatorPositionRight:
			indicatorLineX = NSMaxX(hoveredRect);
			//ETLog(@"Draw right insertion bar");
			break;
		case ETIndicatorPositionLeft:
			indicatorLineX = NSMinX(hoveredRect);
			//ETLog(@"Draw left insertion bar");
			break;
		default:
			ASSERT_INVALID_CASE;
	}

	/* Computes indicator rect */
	return NSMakeRect(indicatorLineX - indicatorWidth / 2.0, 
		NSMinY(hoveredRect), indicatorWidth, NSHeight(hoveredRect));
}

- (NSRect) currentIndicatorRect
{
	if (_dropOn)
	{
		return ETMakeRect(NSZeroPoint, [_hoveredItem drawingBoundsForStyle: self].size);
	}
	else
	{
		return [self verticalIndicatorRect];
	}
}

/** Returns where the drop indicator is drawn and its orientation.

See ETIndicatorPosition enum. */
- (ETIndicatorPosition) indicatorPosition
{
	if (_dropOn)
	{
		return ETIndicatorPositionOn;
	}
	else
	{
		return [[self class] indicatorPositionForPoint: _dropLocation
		                                 nearItemFrame: [_hoveredItem frame]];
	}
}

/** Returns the indicator position to be used when the pointer is at the given 
point in the area inside or close to the item rect.

Both the given point and rect must be expressed in the item parent coordinate 
space.  */
+ (ETIndicatorPosition) indicatorPositionForPoint: (NSPoint)dropPoint
                                    nearItemFrame: (NSRect)itemRect
{
	CGFloat itemMiddleWidth = itemRect.origin.x + itemRect.size.width / 2;

	if (dropPoint.x >= itemMiddleWidth)
	{
		return ETIndicatorPositionRight;
	}
	else if (dropPoint.x < itemMiddleWidth)
	{
		return ETIndicatorPositionLeft;
	}
	return ETIndicatorPositionNone;
}

@end
