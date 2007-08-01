//
//  NSView+Etoile.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <EtoileUI/NSView+Etoile.h>


@implementation NSView (Etoile)

- (float) height
{
	return [self frame].size.height;
}

- (float) width
{
	return [self frame].size.width;
}

- (void) setHeight: (float)height
{
	float width = [self  width];
	
	[self setFrameSize: NSMakeSize(width, height)];
}

- (void) setWidth: (float)width
{
	float height = [self height];
	
	[self setFrameSize: NSMakeSize(width, height)];
}

- (float) x
{
	return [self frame].origin.x;
}

- (float) y
{
	return [self frame].origin.y;
}

- (void) setX: (float)x
{
	float y = [self  y];
	
	[self setFrameOrigin: NSMakePoint(x, y)];
}

- (void) setY: (float)y
{
	float x = [self x];
	
	[self setFrameOrigin: NSMakePoint(x, y)];
}

@end

NSRect ETMakeRect(NSPoint origin, NSSize size)
{
	return NSMakeRect(origin.x, origin.y, size.width, size.height);
}

NSRect ETScaleRect(NSRect frame, float factor)
{
	NSSize prevSize = frame.size;
	
	frame.size = ETScaleSize(frame.size, factor);
	// NOTE: frame.origin.x -= (frame.size.width - prevSize.width) / 2;
	//       frame.origin.y -= (frame.size.height - prevSize.height) / 2;
	frame.origin.x += (prevSize.width - frame.size.width) / 2;
	frame.origin.y += (prevSize.height - frame.size.height) / 2;

	return frame;
}

NSSize ETScaleSize(NSSize size, float factor)
{	
	size.width *= factor;
	size.height *= factor;

	return size;
}
