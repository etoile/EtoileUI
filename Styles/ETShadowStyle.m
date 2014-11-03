/*
	Copyright (C) 2007 Eric Wasylishen

	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETShadowStyle.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"

@implementation ETShadowStyle

+ (id) shadowWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext
{
	return [[[ETShadowStyle alloc] initWithStyle: style objectGraphContext: aContext] autorelease];
}

- (id) initWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

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

- (NSImage *) icon
{
	return [NSImage imageNamed: @"edit-shadow"];
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
