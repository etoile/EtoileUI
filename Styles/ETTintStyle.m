/*
	Copyright (C) 2007 Eric Wasylishen

	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETTintStyle.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"

@implementation ETTintStyle

+ (id) tintWithStyle: (ETStyle *)style color: (NSColor *)color objectGraphContext: (COObjectGraphContext *)aContext
{
	ETTintStyle *tint = [[ETTintStyle alloc] initWithStyle: style objectGraphContext: aContext];
	[tint setColor: color];
	return tint;
}

+ (id) tintWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext
{
	return [[ETTintStyle alloc] initWithStyle: style objectGraphContext: aContext];
}

- (instancetype) initWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_content = style;
	_color = [NSColor colorWithDeviceRed:0.005 green:0.0 blue:0.01 alpha:0.7];
	return self;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"layer-shade"];
}

- (void) setColor: (NSColor *)color
{
	_color = color;
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
