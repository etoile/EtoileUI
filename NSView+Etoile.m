//
//  NSView+Etoile.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETCompatibility.h>


@implementation NSView (Etoile)

- (BOOL) isContainer
{
	return [self isKindOfClass: [ETContainer class]];
}

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

- (BOOL) isEmpty
{
	return ([[self subviews] count] == 0);
}

- (id) content
{
	return [self subviews];
}

- (NSArray *) contentArray
{
	return [self subviews];
}

- (void) addObject: (id)object
{
	if ([object isKindOfClass: [NSView class]])
	{
		[self addSubview: object];
	}
	else
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			"addObject: parameter %@ must be of type NSView", self, object];
	}
}

- (void) removeObject: (id)object
{
	if ([object isKindOfClass: [NSView class]])
	{
		if ([[object superview] isEqual: self])
		{
			[object removeFromSuperview];
		}
		else
		{
			[NSException raise: NSInvalidArgumentException format: @"For %@ "
				"removeObject: parameter %@ must be a subview of the receiver", 
				self, object];
		}		
	}
	else
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			"removeObject: parameter %@ must be of type NSView", self, object];
	}	
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

/** Sets the size of the view without moving the top left point.
	If the receiver has a superview, checks whether this superview is flipped or
	not. If non-flipped coordinates are used, the frame origin is adjusted 
	before calling -setFrameSize:, otherwise this method is equivalent to 
	-setFrameSize:.
	Be careful that calling this method with no receiver superview results in 
	the view origin being altered. */
- (void) setFrameSizeFromTopLeft: (NSSize)size
{
	NSView *superview = [self superview];
	float delta = [self height] - size.height;
	
	if (superview == nil || [superview isFlipped] == NO)
		[self setY: [self y] + delta];
	
	[self setFrameSize: size];
}

/** Sets the height of the view without moving the top left point.
	If the receiver has a superview, checks whether this superview is flipped or
	not. If non-flipped coordinates are used, the frame origin is adjusted 
	before calling -setHeight:, otherwise this method is equivalent to 
	-setHeight:.
	Be careful that calling this method with no receiver superview results in 
	the view origin being altered. */
- (void) setHeightFromTopLeft: (int)height
{
	[self setFrameSizeFromTopLeft: NSMakeSize([self width], height)];
}

/** Returns the top left point of the view.
	If the receiver has a superview, checks whether this superview is flipped or
	not. If non-flipped coordinates are used, the frame origin is adjusted 
	before returning the value, otherwise this method is equivalent to 
	-frameOrigin.
	Be careful that calling this method with no receiver superview results in 
	a view origin different from -frameOrigin. */
- (NSPoint) topLeftPoint
{
	NSPoint topLeftPoint = [self frame].origin;
	
	if ([self superview] == nil || [[self superview] isFlipped] == NO)
		topLeftPoint.y += [self height];
		
	return topLeftPoint;
}

/** Sets the size of the view without moving the bottom left point.
	If the receiver has a superview, checks whether this superview is flipped or
	not. If flipped coordinates are used, the frame origin is adjusted 
	before calling -setFrameSize:, otherwise this method is equivalent to 
	-setFrameSize:. */
- (void) setFrameSizeFromBottomLeft: (NSSize)size
{
	NSView *superview = [self superview];
	float delta = [self height] - size.height;
	
	if (superview != nil && [superview isFlipped])
		[self setY: [self y] + delta];
	
	[self setFrameSize: size];
}

/** Sets the height of the view without moving the bottom left point.
	If the receiver has a superview, checks whether this superview is flipped or
	not. If flipped coordinates are used, the frame origin is adjusted 
	before calling -setHeight:, otherwise this method is equivalent to 
	-setHeight:. */
- (void) setHeightFromBottomLeft: (int)height
{
	[self setFrameSizeFromBottomLeft: NSMakeSize([self width], height)];
}

/** Returns the bottom left point of the view.
	If the receiver has a superview, checks whether this superview is flipped or
	not. If flipped coordinates are used, the frame origin is adjusted before
	returning the value, otherwise this method is equivalent to 
	-frameOrigin. */
- (NSPoint) bottomLeftPoint
{
	NSPoint bottomLeftPoint = [self frame].origin;
	
	if ([self superview] != nil && [[self superview] isFlipped])
		bottomLeftPoint.y -= [self height];
		
	return bottomLeftPoint;
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
