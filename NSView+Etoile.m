//
//  NSView+Etoile.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETContainer.h>


@implementation NSView (Etoile)

/* Copying */

/** Returns a view copy of the receiver. The superview of the resulting copy is
	always nil. The whole subview tree is also copied, in other words the new
	object is a deep copy of the receiver.*/
- (id) copyWithZone: (NSZone *)zone
{
	NSData *viewData = [NSKeyedArchiver archivedDataWithRootObject: self];
	NSView *viewCopy = [NSKeyedUnarchiver unarchiveObjectWithData: viewData];

	RETAIN(viewCopy);
	return viewCopy;
}

/* Collection Protocol */

- (id) content
{
	return [self subviews];
}

- (NSArray *) contentArray
{
	return [self subviews];
}

/* Utility Methods */

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

- (BOOL) isContainer
{
	return [self isKindOfClass: [ETContainer class]];
}

@end

/* Utility Functions */

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
