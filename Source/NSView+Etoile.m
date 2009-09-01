/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Model.h>
#import "NSView+Etoile.h"
#import "ETView.h"
#import "NSImage+Etoile.h"
#import "ETCompatibility.h"


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

/** Returns YES when the receiver is an ETView class or subclass instance, 
otherwise returns NO. */
- (BOOL) isSupervisorView
{
	return [self isKindOfClass: [ETView class]];
}

/** Returns whether the receiver is currently used as a window content view. */
- (BOOL) isWindowContentView
{
	// NOTE: -window will be nil in -viewDidMoveToSuperview with
	// [self isEqual: [[self window] contentView]];
	return [[self superview] isKindOfClass: NSClassFromString(@"NSThemeFrame")];
}

/* Copying */

/** Returns a view copy of the receiver. 

The superview of the resulting copy is always nil. The whole subview tree is 
also copied, in other words the new object is a deep copy of the receiver. */
- (id) copyWithZone: (NSZone *)zone
{
	NSView *superview = [self superview];

	RETAIN(superview);
	[self removeFromSuperview];

#ifdef GNUSTEP
	// FIXME: Scroll view and keyed archiving issue workaround (GNUstep bug #27311)
	NSData *viewData = [NSArchiver archivedDataWithRootObject: self];
	NSView *viewCopy = [NSUnarchiver unarchiveObjectWithData: viewData];
#else
	NSData *viewData = [NSKeyedArchiver archivedDataWithRootObject: self];
	NSView *viewCopy = [NSKeyedUnarchiver unarchiveObjectWithData: viewData];
#endif

	[superview addSubview: self];
	RELEASE(superview);

	return RETAIN(viewCopy);
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

#ifdef GNUSTEP
- (void) setSubviews: (NSArray *)subviews
{
	NSUInteger oldCount = [_sub_views count];
	NSUInteger newCount = [subviews count];
	NSUInteger maxCount = MAX(oldCount, newCount);
	NSUInteger i;

	for (i = 0; i < maxCount; i++)
	{
		if (i < oldCount && i < newCount)
		{
			NSView *existingSubview = [_sub_views objectAtIndex: i];
			NSView *newSubview = [subviews objectAtIndex: i];

			if (existingSubview != newSubview)
			{
				[self replaceSubview: existingSubview with: newSubview]; 
			}
		}
		else if (i < oldCount) /* i >= newCount */
		{
			[self removeSubview: [_sub_views objectAtIndex: i]]; 
		}
		else if (i < newCount) /* i >= oldCount */
		{
			[self addSubview: [subviews objectAtIndex: i]];
		}
	}
}
#endif

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
