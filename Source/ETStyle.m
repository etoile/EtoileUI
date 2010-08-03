/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import "ETStyle.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETCompatibility.h"

@implementation ETStyle

static NSMutableSet *stylePrototypes = nil;
static NSMapTable *styleSharedInstances = nil;

/** Registers a prototype for every ETStyle subclasses.

The implementation won't be executed in the subclasses but only the abstract 
base class.

Since [ETUIItem] is an ETStyle subclass, every [ETLayoutItem] and [ETDecoratorItem]
subclass will also get registered as a style (not yet true).

You should never need to call this method.

See also [NSObject(ETAspectRegistration)]. */
+ (void) registerAspects
{
	stylePrototypes = [[NSMutableSet alloc] init];

	FOREACH([self allSubclasses], subclass, Class)
	{
		/* -init returns nil in in some ETDecoratorItem subclasses.
		   Astract class like ETUIItem should also not be registered.
		   In the long run we will replace this check by: nil == instance */
		if ([subclass isSubclassOfClass: [ETUIItem class]])	
			continue;

		[self registerStyle: AUTORELEASE([[subclass alloc] init])];
	}
}

/** Returns ET. */
+ (NSString *) typePrefix
{
	return @"ET";
}

/** Returns 'Style'. */
+ (NSString *) baseClassName
{
	return @"Style";
}

/** Makes the given prototype available to EtoileUI facilities (inspector, etc.) 
that allow to change a style at runtime.

Also publishes the prototype in the shared aspect repository (not yet implemented). 

Raises an invalid argument exception if aStyle class isn't a subclass of ETStyle. */
+ (void) registerStyle: (ETStyle *)aStyle
{
	if ([aStyle isKindOfClass: [ETStyle class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Prototype %@ must be a subclass of ETStyle to get "
		                    @"registered as a style prototype.", aStyle];
	}

	[stylePrototypes addObject: aStyle];
	// TODO: Make a class instance available as an aspect in the aspect 
	// repository.
}

/** Returns all the style prototypes directly available for EtoileUI facilities 
that allow to transform the UI at runtime. */
+ (NSSet *) registeredStyles
{
	return AUTORELEASE([stylePrototypes copy]);
}

/** Returns all the style classes directly available for EtoileUI facilities 
that allow to transform the UI at runtime.

These style classes are a subset of the registered style prototypes since 
several prototypes might share the same class. */
+ (NSSet *) registeredStyleClasses
{
	return (NSSet *)[[[self registeredStyles] mappedCollection] class];
}

/** <override-never />
Returns the shared instance that corresponds to the receiver class. */	
+ (id) sharedInstance
{
	if (styleSharedInstances == nil)
	{
		ASSIGN(styleSharedInstances, [NSMapTable mapTableWithStrongToStrongObjects]);
	}

	ETStyle *style = [styleSharedInstances  objectForKey: self];

	if (style == nil)
	{
		style = AUTORELEASE([[self alloc] init]);
		[styleSharedInstances setObject: style forKey: self];
	}

	return style;
}

/** <override-dummy />
Returns the initializer invocation used by -copyWithZone: to create a new 
instance. 

This method returns nil. You can override it to return a custom invocation and 
in this way shares complex initialization logic between -copyWithZone: and 
the designated initializer in a subclass.
 
e.g. if you return an invocation like -initWithWindow: aWindow. 
-copyWithZone: will automatically set the target to be the copy allocated with 
<code>[[[self class] allocWithZone: aZone]</code> and then initializes the copy 
by invoking the invocation. */
- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone
{
	return nil;
}

- (id) copyWithZone: (NSZone *)aZone
{
	NSInvocation *initInvocation = [self initInvocationForCopyWithZone: aZone];
	ETStyle *newStyle = [[self class] alloc];
	
	if (nil != initInvocation)
	{
		[initInvocation invokeWithTarget: newStyle];
		[initInvocation getReturnValue: &newStyle];
	}

	newStyle->_isSharedStyle = _isSharedStyle;

	return newStyle;
}

/** Returns whether the receiver can be shared between several owners.

TODO: Not really implemented yet... */
- (BOOL) isSharedStyle
{
	return _isSharedStyle;
}

/** Sets whether the receiver can be shared between several owners.

TODO: Not really implemented yet... */
- (void) setIsSharedStyle: (BOOL)shared
{
	_isSharedStyle = shared;
}

/** <override-subclass />
Main rendering method for the custom drawing implemented by subclasses.
    
Renders the receiver in the active graphics context with the given layout item 
in the role of the element on which the style is applied.

item indicates in which item the receiver is rendered. Usually this item is the 
one on which the receiver is indirectly set through -[ETLayoutItem styleGroup]. 
However the item can be unrelated to the style or nil.<br />
See -[ETLayoutItem drawingBoundsForStyle:] to retrieve the right drawing area. 

dirtyRect can be used to optimize the drawing. You only need to redraw what is 
inside that redisplayed area and won't be clipped by the graphics context.

Here is how the method can be implemented in a subclass:

<example>
NSRect bounds = [item drawingBoundsForStyle: self];

[NSGraphicsContext saveGraphicsState];

// Drawing code
[[NSColor redColor] set];
[NSBezierPath fillRect: bounds];
// and more...

[NSGraphicsContext restoreGraphicsState];
</example> */
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
      dirtyRect: (NSRect)dirtyRect
{

}

/** Draws a selection indicator that covers the whole item frame if 
 the given indicator rect is equal to it. */
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	//ETLog(@"--- Drawing selection %@ in view %@", NSStringFromRect([item drawingBoundsForStyle: self]), [NSView focusView]);
	
	NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
	BOOL gstateAntialias = [ctxt shouldAntialias];

	/* Disable the antialiasing for the stroked rect */
	[ctxt setShouldAntialias: NO];
	
	/* Align on pixel boundaries for fractional pixel margin and frame. 
	   Fractional item frame results from the item scaling. 
	   NOTE: May be we should adjust pixel boundaries per edge and only if 
	   needed to get a perfect drawing... */
	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);

	/* Draw the interior */
	[[[NSColor lightGrayColor] colorWithAlphaComponent: 0.45] setFill];
	[NSBezierPath fillRect: normalizedIndicatorRect];

	/* Draw the outline
	   FIXME: Cannot get the outline precisely aligned on pixel boundaries for 
	   GNUstep. With the current code which works well on Cocoa, the top border 
	   of the outline isn't drawn most of the time and the image drawn 
	   underneath seems to wrongly extend beyond the border. */
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] setStroke];
	[NSBezierPath setDefaultLineWidth: 1.0];
	[NSBezierPath strokeRect: normalizedIndicatorRect];

	[ctxt setShouldAntialias: gstateAntialias];
}

/** <override-dummy />
Notifies the receiver that the styled layout item has been resized.

You can override this method to alter the style state. For example, [ETShape]
overrides it to resize/scale the bezier path as needed.

Usually the new bounds corresponds to the item content bounds.<br />
However when the receiver style is used as a cover style, the new bounds 
corresponds to the item size at a zero origin.

See also -[ETLayoutItem contentBounds], -[ETLayoutItem size] and 
-[ETLayoutItem coverStyle]. */
- (void) didChangeItemBounds: (NSRect)bounds
{

}

@end



@implementation ETDropIndicator

// NOTE: -copyWithZone: implementation can be omitted, the ivars are transient.

- (id) initWithLocation: (NSPoint)dropLocation 
            hoveredItem: (ETLayoutItem *)hoveredItem
           isDropTarget: (BOOL)dropOn
{
	SUPERINIT

	_dropLocation = dropLocation;
	ASSIGN(_hoveredItem, hoveredItem);
	_dropOn = dropOn;

	return self;
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
- (float) thickness
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
	// NOTE: On Mac OS X, the graphics state doesn't save NSBezierPath 
	// attributes such as +defaultLineWidth unlike what Cocoa Drawing said.
	[NSGraphicsContext saveGraphicsState];

	[[self color] setFill];
	[NSBezierPath setDefaultLineWidth: [self thickness] / 2];
	[NSBezierPath fillRect: indicatorRect];
	/*[NSBezierPath strokeLineFromPoint: NSMakePoint(indicatorLineX, NSMinY(hoveredRect))
							  toPoint: NSMakePoint(indicatorLineX, NSMaxY(hoveredRect))];*/

	[NSGraphicsContext restoreGraphicsState];
	
	_prevInsertionIndicatorRect = indicatorRect;
}

- (void) drawRectangularInsertionIndicatorInRect: (NSRect)indicatorRect
{
	// NOTE: On Mac OS X, the graphics state doesn't save NSBezierPath 
	// attributes such as +defaultLineWidth unlike what Cocoa Drawing said.
	[NSGraphicsContext saveGraphicsState];

	[[self color] setStroke];
	[NSBezierPath setDefaultLineWidth: [self thickness]];
	[NSBezierPath strokeRect: indicatorRect];
	
	[NSGraphicsContext restoreGraphicsState];

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
	float indicatorWidth = 4.0;
	float indicatorLineX = 0.0;

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
	float itemMiddleWidth = itemRect.origin.x + itemRect.size.width / 2;

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


@implementation ETShadowStyle

+ (id) shadowWithStyle: (ETStyle *)style
{
	return [[[ETShadowStyle alloc] initWithStyle: style] autorelease];
}

- (id) initWithStyle: (ETStyle *)style
{
	SUPERINIT;
	ASSIGN(_content, style);
	// FIXME: implement on GNUstep
#ifndef GNUSTEP
	_shadow = [[NSShadow alloc] init];
	[_shadow setShadowOffset: NSMakeSize(4.0, -4.0)];
	[_shadow setShadowColor: [NSColor blackColor]];
	[_shadow setShadowBlurRadius: 5.0];
#endif
	return self;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	// FIXME: This will usually draw outside of item's frame..
	//        A shadow should increase the size of the item's frame.
	//        Maybe the shadow style should be a decorator item instead?
	[NSGraphicsContext saveGraphicsState];
	[_shadow set];
	[_content render: inputValues layoutItem: item dirtyRect: dirtyRect];
	[NSGraphicsContext restoreGraphicsState];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[_content didChangeItemBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end



@implementation ETTintStyle

+ (id) tintWithStyle: (ETStyle *)style color: (NSColor *)color
{
	ETTintStyle *tint = [[[ETTintStyle alloc] initWithStyle: style] autorelease];
	[tint setColor: color];
	return tint;
}

+ (id) tintWithStyle: (ETStyle *)style
{
	return [[[ETTintStyle alloc] initWithStyle: style] autorelease];
}

- (id) initWithStyle: (ETStyle *)style
{
	SUPERINIT;
	ASSIGN(_content, style);
	_color = [[NSColor colorWithDeviceRed:0.005 green:0.0 blue:0.01 alpha:0.7] retain];
	return self;
}

- (void) setColor: (NSColor *)color
{
	ASSIGN(_color, color);
}

- (NSColor *) color
{
	return _color;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	[_content render: inputValues layoutItem: item dirtyRect: dirtyRect];
	
	[NSGraphicsContext saveGraphicsState];
	[_color set];
	NSRectFillUsingOperation([item drawingBoundsForStyle: self], NSCompositeSourceOver);
	[NSGraphicsContext restoreGraphicsState];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[_content didChangeItemBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end


@implementation ETSpeechBubbleStyle

/**
 * Returns a bezier path for a speech bubble positioned around rect, to be
 * placed on the left side of a speaker.
 *
 * Coordinates are unflipped.
 *
 * Modelled after:
 * http://jesseross.com/clients/etoile/ui/concepts/01/workspace_200.jpg
 */
+ (NSBezierPath *)leftSpeechBubbleAroundRect: (NSRect)rect
{
	const float radius = 9.0;
	NSBezierPath *path = [NSBezierPath bezierPath];
	
	// Add some padding to the inner rectangle
	rect = NSInsetRect(rect, -1, -3);
	
	// Calculate the bounding points of the inner area of the bubble
	NSPoint bottomLeft = NSMakePoint(NSMinX(rect), NSMinY(rect));
	NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
	NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
	NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
	
	// Bottom left corner
	[path moveToPoint: NSMakePoint(bottomLeft.x, bottomLeft.y + (-1 * radius))];
	[path appendBezierPathWithArcWithCenter: bottomLeft radius: radius startAngle: 270 endAngle: 180 clockwise: YES];
	// Left edge
	[path lineToPoint: NSMakePoint(bottomLeft.x - radius, topLeft.y)];	
	// Top left corner
	[path appendBezierPathWithArcWithCenter: topLeft radius: radius startAngle: 180 endAngle: 90 clockwise: YES];
	// Top edge
	[path lineToPoint: NSMakePoint(topRight.x, topLeft.y + (radius))];	
	// Top right corner
	[path appendBezierPathWithArcWithCenter: topRight radius: radius startAngle: 90 endAngle: 0 clockwise: YES];
	// Right edge
	[path lineToPoint: NSMakePoint(bottomRight.x + radius, bottomRight.y)];
	
	// Partial bottom right corner (62 degree arc)
	[path appendBezierPathWithArcWithCenter: bottomRight radius: radius startAngle: 0 endAngle: 298 clockwise: YES];
	// Curve out to the tip
	[path relativeCurveToPoint: NSMakePoint(7.5, -8.5) controlPoint1: NSMakePoint(-1, -4) controlPoint2: NSMakePoint(7.5, -8.5)];
	// Curve back to the bottom edge of the speech bubble
	[path curveToPoint: NSMakePoint(bottomRight.x - 5, bottomRight.y + (-1 * radius)) controlPoint1:NSMakePoint(bottomRight.x + 2.5, bottomRight.y + (-18)) controlPoint2: NSMakePoint(bottomRight.x - 5, bottomRight.y + (-1 * radius))];
	
	// Connect back to the bottom left corner
	[path closePath];
	
	return path;
}


+ (id) speechWithStyle: (ETStyle *)style
{
	return [[[ETSpeechBubbleStyle alloc] initWithStyle: style] autorelease];
}

- (id) initWithStyle: (ETStyle *)style
{
	SUPERINIT;
	ASSIGN(_content, style);
	return self;
}

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	[NSGraphicsContext saveGraphicsState];
	
	// The bubble uses unflipped coordinates
	NSRect itemBounds = [item drawingBoundsForStyle: self];
	NSBezierPath *bubble = [ETSpeechBubbleStyle leftSpeechBubbleAroundRect: itemBounds];
	 // Inset the rect to leave room for the shadow
	NSRect bounds = NSInsetRect([bubble bounds], -6, -6);
	
	BOOL flipped = [item isFlipped];
	NSAffineTransform *xform = nil;
	if (flipped)
	{
		xform = [NSAffineTransform transform];
		[xform scaleXBy: 1.0 yBy: -1.0];
		[xform translateXBy: 0 yBy: -1 * itemBounds.size.height];
		[xform concat];
		bounds.origin.y = itemBounds.size.height - (bounds.size.height + bounds.origin.y);
	}

	// FIXME: Should be done when the style is set on the item
	[item setBoundingBox: bounds];
	
#ifndef GNUSTEP

	// Draw shadow
	[NSGraphicsContext saveGraphicsState];

	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset: NSMakeSize(2.0, -2.0)];
	[shadow setShadowColor: [[NSColor blackColor] colorWithAlphaComponent: 0.3]];
	[shadow setShadowBlurRadius: 5.0];
	[shadow set];
	[[NSColor whiteColor] setFill];
	[bubble fill];
	
	[shadow release];
	[NSGraphicsContext restoreGraphicsState];

	// Draw gradient fill
	NSColor *endColor = [NSColor colorWithCalibratedRed: 227.0/255.0 
		green: 226.0/255.0 blue: 228.0/255.0 alpha: 1];
	NSGradient *gradient = [[NSGradient alloc]initWithStartingColor: [NSColor whiteColor]
														endingColor: endColor];
	[gradient drawInBezierPath: bubble angle: 90];
	[gradient release];

#else

	// Draw plain fill
	[[NSColor whiteColor] setFill];
	[bubble fill];

#endif
	
	[[[NSColor blackColor] colorWithAlphaComponent: 0.4] setStroke];
	[bubble stroke];
	
	if (flipped)
	{
		[xform invert];
		[xform concat];
	}
	
	[_content render: inputValues layoutItem: item dirtyRect: dirtyRect];
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void) didChangeItemBounds: (NSRect)bounds
{
	[_content didChangeItemBounds: bounds];
	[super didChangeItemBounds: bounds];
}

@end
