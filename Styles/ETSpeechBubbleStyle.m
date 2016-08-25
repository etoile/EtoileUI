/*
	Copyright (C) 2007 Eric Wasylishen

	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETSpeechBubbleStyle.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
// FIXME: Add -concat to the Appkit graphics backend
#import "ETWidgetBackend.h"

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
	const CGFloat radius = 9.0;
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


+ (id) speechWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext
{
	return [[ETSpeechBubbleStyle alloc] initWithStyle: style objectGraphContext: aContext];
}

- (instancetype) initWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_content = style;
	return self;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"balloon-left"];
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

	[NSGraphicsContext restoreGraphicsState];

	// Draw gradient fill
	NSColor *endColor = [NSColor colorWithCalibratedRed: 227.0/255.0 
		green: 226.0/255.0 blue: 228.0/255.0 alpha: 1];
	NSGradient *gradient = [[NSGradient alloc]initWithStartingColor: [NSColor whiteColor]
														endingColor: endColor];
	[gradient drawInBezierPath: bubble angle: 90];

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
