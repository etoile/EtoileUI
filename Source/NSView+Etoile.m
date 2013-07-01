/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Trait.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "NSView+Etoile.h"
#import "ETResponder.h"
#import "ETView.h"
#import "ETWidget.h"
#import "NSImage+Etoile.h"
#import "ETCompatibility.h"

#pragma GCC diagnostic ignored "-Wprotocol"
// TODO: Once a new Gui release has been made, we can remove our 
// -setSubviews: implementation
#pragma GCC diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation NSView (Etoile)

/* In a a category, we cannot use +initialize. We also cannot
   use +load, as there is no guarantee any of the referenced
   classes (except our base class) exists yet. */
+ (void) _setUpEtoileUITraits
{
	[self applyTraitFromClass: [ETCollectionTrait class]];
	[self applyTraitFromClass: [ETMutableCollectionTrait class]];
}

+ (NSRect) defaultFrame
{
	return NSMakeRect(0, 0, 100, 50);
}

- (id) init
{
	return [self initWithFrame: [[self class] defaultFrame]];
}

- (NSString *) description
{
	NSRect frame = [self frame];
	NSString *viewDesc = [NSString stringWithFormat: @" x: %.1f y: %.1f "
		"width: %.1f height: %.1f flipped: %i hidden: %i autoresizing: %lu "
		"autoresize: %i subviews: %ld superview: %@ window: %@", frame.origin.x, 
		frame.origin.y, frame.size.width, frame.size.height, 
		[self isFlipped], [self isHidden], (unsigned long)[self autoresizingMask],
		[self autoresizesSubviews], (long)[[self subviews] count],
		[[self superview] primitiveDescription], 
		[[self window] primitiveDescription]];

	return [[super description] stringByAppendingString: viewDesc];
}

/** Returns whether the receiver is a widget (or control in AppKit terminology) 
on which actions should be dispatched.

If you override this method to return YES, your subclass must implement the 
methods listed in the ETWidget protocol.

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


/** Returns the item bound to the first supervisor view found in the view 
ancestor hierarchy.

The returned object is an ETUIItem or subclass instance. */
- (id) owningItem
{
	return [[self superview] owningItem];
}

/** Returns the first responder sharing area of -owningItem. */
- (id <ETFirstResponderSharingArea>) firstResponderSharingArea
{
	return [[self owningItem] firstResponderSharingArea];
}

/** Returns the edition coordinator of -owningItem. */
- (id <ETEditionCoordinator>) editionCoordinator
{
	return [[self owningItem] editionCoordinator];
}

/** Returns the candidate focused item of -owingItem. */
- (ETLayoutItem *) candidateFocusedItem
{
	return [self owningItem];
}

/* Copying */

/** Returns a view copy of the receiver. 

The superview of the resulting copy is always nil. The whole subview tree is 
also copied, in other words the new object is a deep copy of the receiver. */
- (id) copyWithZone: (NSZone *)zone
{
	NSView *superview = [self superview];


	RETAIN(self);
	[self removeFromSuperview];

#ifdef GNUSTEP // FIXME: Implement NSBrowser keyed archiving on GNUstep
	NSData *viewData = nil;
	NSView *viewCopy = nil;

	if ([self isKindOfClass: [NSBrowser class]])
	{
		viewData = [NSArchiver archivedDataWithRootObject: self];
		viewCopy = [NSUnarchiver unarchiveObjectWithData: viewData];
	}
	else
	{
		viewData = [NSKeyedArchiver archivedDataWithRootObject: self];
		viewCopy = [NSKeyedUnarchiver unarchiveObjectWithData: viewData];
	}
#else
	NSData *viewData = [NSKeyedArchiver archivedDataWithRootObject: self];
	NSView *viewCopy = [NSKeyedUnarchiver unarchiveObjectWithData: viewData];
#endif

	[superview addSubview: self];
	RELEASE(self);

	return RETAIN(viewCopy);
}

/* Collection Protocol */

- (BOOL) isOrdered
{
	return YES;
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

- (void) insertObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
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
			"-insertObject:atIndex:hint: parameter %@ must be of type NSView", self, 
			object];
	}
}

- (void) removeObject: (id)object atIndex: (NSUInteger)index hint: (id)hint
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
				"-removeObject:atIndex:hint: parameter %@ must be a subview of the receiver", 
				self, object];
		}		
	}
	else
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			"-removeObject:atIndex:hint: parameter %@ must be of type NSView", self, object];
	}	
}

/* Utility Methods */

- (CGFloat) height
{
	return [self frame].size.height;
}

- (CGFloat) width
{
	return [self frame].size.width;
}

- (void) setHeight: (CGFloat)height
{
	CGFloat width = [self  width];
	
	[self setFrameSize: NSMakeSize(width, height)];
}

- (void) setWidth: (CGFloat)width
{
	CGFloat height = [self height];
	
	[self setFrameSize: NSMakeSize(width, height)];
}

- (CGFloat) x
{
	return [self frame].origin.x;
}

- (CGFloat) y
{
	return [self frame].origin.y;
}

- (void) setX: (CGFloat)x
{
	CGFloat y = [self  y];
	
	[self setFrameOrigin: NSMakePoint(x, y)];
}

- (void) setY: (CGFloat)y
{
	CGFloat x = [self x];
	
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
	CGFloat delta = [self height] - size.height;
	
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
	CGFloat delta = [self height] - size.height;
	
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

- (NSArray *) propertyNames
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
	
	return [[super propertyNames] arrayByAddingObjectsFromArray: properties];
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
- (void) setSubviews: (NSArray *)newSubviews
{
	NSArray *oldSubviews = [NSArray arrayWithArray: _sub_views];
	NSUInteger oldCount = [oldSubviews count];
	NSUInteger newCount = [newSubviews count];
	NSUInteger maxCount = MAX(oldCount, newCount);

	for (int i = 0; i < maxCount; i++)
	{
		if (i < oldCount && i < newCount)
		{
			NSView *oldSubview = [oldSubviews objectAtIndex: i];
			NSView *newSubview = [newSubviews objectAtIndex: i];

			if (oldSubview != newSubview)
			{
				[self replaceSubview: oldSubview with: newSubview]; 
			}
		}
		else if (i < oldCount) /* i >= newCount */
		{
			[self removeSubview: [oldSubviews objectAtIndex: i]]; 
		}
		else if (i < newCount) /* i >= oldCount */
		{
			[self addSubview: [newSubviews objectAtIndex: i]];
		}
	}
}

- (void) viewWillDraw
{
	[[self subviews] makeObjectsPerformSelector: @selector(viewWillDraw)];
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

// FIXME: Quick hack to let us use a text view as an item view. 
// See -setView:autoresizingMask:
- (id) cell
{
	return nil;
}

@end
