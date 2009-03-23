/*  <title>NSView+Etoile</title>

	NSView+Etoile.m
	
	<abstract>NSView additions.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/NSImage+Etoile.h>
#import <EtoileUI/ETCompatibility.h>


@implementation NSView (Etoile)

+ (NSRect) defaultFrame
{
	return NSMakeRect(0, 0, 100, 50);
}

- (id) init
{
	return [self initWithFrame: [[self class] defaultFrame]];
}

/** Returns whether the receiver is a widget (or control in AppKit terminology) 
on which actions should be dispatched.

By default, returns NO. */
- (BOOL) isWidget
{
	return NO;
}

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

- (BOOL) isOrdered
{
	return YES;
}

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
			"-addObject: parameter %@ must be of type NSView", self, object];
	}
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{
	if ([object isKindOfClass: [NSView class]])
	{
		[self addSubview: object 
		      positioned: NSWindowBelow 
		      relativeTo: [[self subviews] objectAtIndex: index]];
	}
	else
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			"-insertObject:atIndex: parameter %@ must be of type NSView", self, 
			object];
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
				"-removeObject: parameter %@ must be a subview of the receiver", 
				self, object];
		}		
	}
	else
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			"-removeObject: parameter %@ must be of type NSView", self, object];
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
		bottomLeftPoint.y += [self height];
		
	return bottomLeftPoint;
}

/* Property Value Coding */

- (NSArray *) properties
{
	// TODO: Expose more properties
	NSArray *properties = [NSArray arrayWithObjects: @"x", @"y", @"width", 
		@"height", @"superview", @"window", @"tag", @"hidden", 
		@"autoresizingMask", @"autoresizesSubviews", @"subviews", @"flipped", 
		@"frame", @"frameRotation", @"bounds", @"boundsRotation", @"isRotatedFromBase", 
		@"isRotatedOrScaledFromBase", @"postsFrameChangedNotifications", 
		@"postsBoundsChangedNotifications", @"enclosingScrollView", 
		@"visibleRect", @"opaque", @"opaqueAncestor", @"needsDisplay", 
		@"canDraw",  @"shouldDrawColor", @"widthAdjustLimit",
		@"heightAdjustLimit", @"printJobTitle", @"mouseDownCanMoveWindow", 
		@"needsPanelToBecomeKey", nil]; 
	
	return [[super properties] arrayByAddingObjectsFromArray: properties];
}

/* Basic Properties */

/** Returns an image snapshot of the receiver view. */
- (NSImage *) snapshot 
{
	NSImage *img = [[NSImage alloc] initWithView: self fromRect: [self bounds]];

	return AUTORELEASE(img); 
}

- (NSImage *) icon
{
	return [self snapshot];
}

@end

@implementation NSScrollView (Etoile)

/** Returns YES to indicate that the receiver is a widget on which actions 
should be dispatched. */
- (BOOL) isWidget
{
	return YES;
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
