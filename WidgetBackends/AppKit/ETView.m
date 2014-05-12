/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h> 
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/runtime.h>
#import "ETView.h"
#import "ETDecoratorItem.h"
#import "ETLayoutItem.h"
#import "ETUIItemIntegration.h"
#import "NSObject+EtoileUI.h"
#import "NSView+EtoileUI.h"
#import "ETCompatibility.h"
#import "ETFlowLayout.h"


@implementation ETView

#pragma mark - Initialization

/** Returns the ETLayoutItemFactory selector that creates an item which matches the 
receiver expectations.

By default, returns 'itemGroup'. */
- (SEL) defaultItemFactorySelector
{
	return @selector(itemGroup);
}

- (id) initWithFrame: (NSRect)frame
{
	return [self initWithFrame: frame item: nil];
}

/** <init /> 
Initializes and returns a supervisor view instance that is bound to the given 
item.

You should never need to use this method which uses internally by EtoileUI.

When the item is not nil, the given frame is ignored and the item frame and 
autoresizing mask are set on the view.

See also -[ETUIItem supervisorView]. */
- (id) initWithFrame: (NSRect)frame item: (ETUIItem *)anItem
{
	self = [super initWithFrame: frame];
	if (nil == self)
		return nil;

	/* Will call back -setItemWithoutInsertingView: */
	[anItem setSupervisorView: self sync: ETSyncSupervisorViewFromItem];
	[self setAutoresizesSubviews: NO];

	return self;
}

// NOTE: Mac OS X doesn't always update the ref count returned by 
// NSExtraRefCount if the memory management methods aren't overriden to use
// the extra ref count functions.
#ifndef GNUSTEP
- (id) retain
{
	NSIncrementExtraRefCount(self);
	return self;
}

- (NSUInteger) retainCount
{
	return NSExtraRefCount(self) + 1;
}

- (oneway void) release
{
	if (NSDecrementExtraRefCountWasZero(self))
		[self dealloc];
}
#endif

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	// NOTE: item (our owner) and _temporaryView are weak references
	DESTROY(_wrappedView);
	
	[super dealloc];
}

/** Returns a receiver copy but without an UI item bound to it.

The returned view copies are shallow copies that don't include subviews unlike 
-copy invoked on NSView and its other subclasses.

A temporary view set on the receiver won't be copied. */
- (id) copyWithZone: (NSZone *)aZone
{
	/* -subviews doesn't return a defensive copy on Cocoa unlike GNUstep */
	NSArray *existingSubviews = [NSArray arrayWithArray: [self subviews]];
	/* We don't let the wrapped view be archived/unarchived as a subview since 
	   some widget views need extra adjustments once deserialized. 
	   See -[NSPopUpButton copyWithZone:]. */
	NSArray *copiableSubviews = [NSArray array];

	// TODO: This might be a quite costly and require optimizations (e.g. when 
	// the only subview is the wrapped view)
	[self setSubviews: copiableSubviews];

	ETView *viewCopy = [super copyWithZone: aZone];
	NSView *wrappedViewCopy = [_wrappedView copyWithZone: aZone];

	[viewCopy setContentView: wrappedViewCopy temporary: NO];
	viewCopy->_wrappedView = wrappedViewCopy;
	/* The flipping isn't encoded by the NSView archiving, that's why we must 
	   copy it manually.
	   We also use -setFlipped: because we have to mark the coordinates to be 
	   rebuilt on GNUstep. */
	[viewCopy setFlipped: [self isFlipped]];

	[self setSubviews: existingSubviews];

	return viewCopy;
}

#pragma mark Basic Properties -

- (NSArray *) propertyNames
{
	NSArray *properties = A(@"item", @"wrappedView", @"temporaryView", 
		@"contentView", @"mainView");
	return [properties arrayByAddingObjectsFromArray: [super propertyNames]];
}

// TODO: Rewrite the next two methods in a more sensible way

- (NSString *) description
{
	NSString *desc = [super description];

	if ([item isLayoutItem])
	{
		ETLayout *layout = [(ETLayoutItem *)item layout];
		
		if (layout != nil)
		{
			desc = [@"<" stringByAppendingString: desc];
			desc = [desc stringByAppendingFormat: @" + %@>", layout, nil];
		}
	}

	return desc;
}

- (NSString *) displayName
{
	if ([item isGroup])
		return [self description];

	// FIXME: Trim the angle brackets out.
	NSString *desc = @"<";

	if (_wrappedView != nil)
	{
		desc = [desc stringByAppendingFormat: @"%@ in ", [_wrappedView className]];
	}

	return [desc stringByAppendingFormat: @"%@>", [super description]];
}

- (BOOL) acceptsFirstResponder
{
	//ETLog(@"%@ accepts first responder", self);
	return YES;
}

- (id) owningItem
{
	return [self layoutItem];
}

// TODO: Rename -layoutItem to -item because it can return any ETUIItem.

/** Returns the item that owns the receiver. */
- (id) layoutItem
{
	return item;
}

/** This method is only exposed to be used internally by EtoileUI.<br />
You must never call this method.

Sets the item that owns the receiver. 

The item isn't retained. */
- (void) setItemWithoutInsertingView: (ETUIItem *)anItem
{	
	item = anItem;
}

/** Returns the item as the supervisor view next responder. */
- (id) nextResponder
{
	return item;
}

/** This method is only exposed to be used internally by EtoileUI.<br />
You must never call this method but -[ETLayoutItem isFlipped:].

Returns whether the receiver uses flipped coordinates or not.

Default returned value is YES. */
- (BOOL) isFlipped
{
#ifdef USE_NSVIEW_RFLAGS
 	return _rFlags.flipped_view;
#else
	return _flipped;
#endif
}

/** This method is only exposed to be used internally by EtoileUI.<br />
You must never call this method but -[ETLayoutItem setFlipped:].

Unlike NSView, ETView uses flipped coordinates by default.

You can revert to non-flipped coordinates by passing NO to this method. */
- (void) setFlipped: (BOOL)flag
{
#ifdef USE_NSVIEW_RFLAGS
	_rFlags.flipped_view = flag;
	[self _invalidateCoordinates];
	[self _rebuildCoordinates];
#else
	_flipped = flag;
#endif
}

#pragma mark Embbeded Views -

/* When a temporary view is just removed and the wrapped view is reinserted, 
isTemporary is NO and the code below takes care to resize the wrapped view 
to match the supervisor view size. The supervisor view may have been resized 
when the temporary view was in use. */
- (void) tileContentView: (NSView *)view temporary: (BOOL)isTemporary
{
	if (nil == view)
		return;

	if ([item isLayoutItem] && NO == isTemporary)
	{
		/* We don't touch the autoresizing mask previously set by the user or in 
		   -[ETLayoutItem setView:] by with -autoresizingMaskForContentAspect: */
		[view setFrame: [(id)item contentRectWithRect: [view frame]
		                                contentAspect: [(id)item contentAspect]
		                                   boundsSize: [self frame].size]];
		// TODO: For now this is not true when the item is decorated because 
		// the decorator touches the supervisor view autoresizing directly.
		//NSParameterAssert([item autoresizingMask] == [self autoresizingMask]);
	}
	else
	{
		/* Reset frame to fill the receiver */
		[view setFrameOrigin: NSZeroPoint];
		[view setFrameSize: [self frame].size];
		
		/* Reset autoresizing */
		[view setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	}
}

/** Sets the item view.<br />
The receiver is the view owner.

If a temporary view is currently set, the new wrapped view won't become visible 
until you remove the temporary view.

You must never call this method but -[ETLayoutItem setView:]. */
- (void) setWrappedView: (NSView *)view
{
	NSAssert([_temporaryView isEqual: view] == NO, @"A temporary view "
		"cannot be set as a wrapped view.");

	[self setContentView: view temporary: NO];
	ASSIGN(_wrappedView, view);
	[self tileContentView: view temporary: NO];
}

/** Returns the item view.<br />
The receiver is the view owner. */
- (NSView *) wrappedView
{
	return _wrappedView;
}

/** Sets the view to be used temporarily as a wrapped view. 

When a temporary view is set, this view is visible in place of -wrappedView.

If you pass nil, the visible view is reverted to -wrappedView. */
- (void) setTemporaryView: (NSView *)subview
{	
	NSAssert([_wrappedView isEqual: subview] == NO, @"A wrapped view "
		"cannot be set as a temporary view.");

	[self setContentView: subview temporary: YES];
	_temporaryView = subview;
	if (nil != subview)
	{
		[self tileContentView: subview temporary: YES];
	}
	else
	{
		[self tileContentView: _wrappedView temporary: NO];
	}
}

/** Returns the view temporarily used as a wrapped view or nil.

When a widget-based layout is set on -item, this method returns the widget view 
installed by the layout. */
- (NSView *) temporaryView
{
	return _temporaryView;
}

- (void) checkViewHierarchyValidity
{
	if (_wrappedView != nil)
	{
		NSAssert1([[_wrappedView superview] isEqual: self], @"The wrapped view"
			"%@ has been wrongly moved to a superview without first removing "
			"it explicitely with -[ETLayoutItem setView: nil] or "
			"-[ETView setWrappedView: nil]", _wrappedView);
	}
	if (_temporaryView != nil)
	{
		NSAssert1([[_temporaryView superview] isEqual: self], @"The temporary view"
			"%@ has been wrongly moved to a superview without first removing "
			"it explicitely with -[ETLayoutItem setLayoutView: nil] or "
			"-[ETView setTemporaryView: nil]", _temporaryView);
	}
}

/* See -setWrappedView: and -setTemporaryView: documentation which explains the 
implemented behavior. */
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary
{
	[self checkViewHierarchyValidity];

	BOOL isCopying = (item == nil);

	if (view != nil && isCopying == NO && [item isDecoratorItem] == NO)
	{
		NSString *selSubstring = (temporary ? @"Temporary" : @"Wrapped");

		NSAssert2([[view superview] isSupervisorView] == NO, @"You must not move "
			"view %@ to a new superview without first removing it explicitely "
			"with -[ETLayoutItem setView: nil] or -[ETView set%@View: nil]", 
			view, selSubstring);
	}

	if (temporary) /* Temporary view setter */
	{
		NSParameterAssert(_wrappedView == nil || [_wrappedView superview] == self);

		/* In case a temporary view is already in use, we remove it */
		[_temporaryView removeFromSuperview];

		if (view != nil)
		{
			[self addSubview: view];
			[_wrappedView setHidden: YES];
		}
		else /* Passed a nil temporary view */
		{
			[_wrappedView setHidden: NO];
		}
	}
	else /* Wrapped view setter */
	{
		NSParameterAssert(nil == _temporaryView);

		/* In case a wrapped view is already in use, we remove it */
		[_wrappedView removeFromSuperview];

		if (view != nil)
		{
			[self addSubview: view];
		}
		else /* Passed a nil wrapped view */
		{

		}
	}
	/* Ensure that NSView subclass don't override -canDraw without calling the 
	   superclass implementation, to be sure our swizzled implementation is called. */
	ETAssert(view == nil || [view canDraw] == NO);
	
	/* Ensure the resizing of all subviews is handled automatically if needed */
	[self setAutoresizesSubviews: (view != nil)];
}

/** Returns the current content view which is either the wrapped view or 
the temporary view. 

The wrapped view is returned when -temporaryView is nil. When a temporary view 
is set, it overrides the wrapped viewin the role of content view. 
	
Take note that as long as -temporaryView returns a non nil value, calling -
setWrappedView: has no effect on -contentView, the method will continue to 
return the temporary view. */
- (NSView *) contentView
{
	NSView *contentView = _temporaryView;
	
	if (contentView == nil)
		contentView = _wrappedView;
	
	return contentView;
}

/* Actions */

/** Invokes -inspect: action on the receiver item. 

See also -[ETActionHandler inspectItem:onItem:]. */
- (IBAction) inspectItem: (id)sender
{
	[item inspect: sender];
}

#pragma mark Sizing

#ifndef GNUSTEP
#define CHECKSIZE(size) \
NSAssert1(size.width >= 0 && size.height >= 0, @"For a supervisor view, the " \
	"frame must always have a positive size %@", NSStringFromSize(size));
#else
#define CHECKSIZE(size)
#endif

- (void) updateLayoutForLiveResize
{
	BOOL isLiveWindowResize = ([self inLiveResize] && [[self window] contentView] == self);
	
	if (isLiveWindowResize)
	{
		[(ETLayoutItem *)item updateLayoutRecursively: YES];
	}
}

- (void) setFrame: (NSRect)frame
{
	CHECKSIZE(frame.size)
	[super setFrame: frame];

	if ([item shouldSyncSupervisorViewGeometry] == NO)
		return;

	if ([item decoratorItem] == nil)
	{
		[(ETLayoutItem *)item setFrame: frame];
	}
	else
	{
		[(ETLayoutItem *)item setContentSize: frame.size];
	}
	[self updateLayoutForLiveResize];
}

/* GNUstep doesn't rely on -setFrameSize: in -setFrame: unlike Cocoa, so we 
   in -setFrame: too.
   See -setFrame: below to understand the reason behind this method. */
#ifdef GNUSTEP
- (void) setFrameSize: (NSSize)size
{
	CHECKSIZE(size)
	[super setFrameSize: size];
	if ([item shouldSyncSupervisorViewGeometry] == NO)
		return;

	if ([item decoratorItem] == nil)
	{
		[(ETLayoutItem *)item setSize: size];
	}
	else
	{
		[(ETLayoutItem *)item setContentSize: size];
	}
	[self updateLayoutForLiveResize];
}

- (void) setFrameOrigin: (NSPoint)origin
{
	[super setFrameOrigin: origin];
	if ([item shouldSyncSupervisorViewGeometry] == NO)
		return;

	if ([item decoratorItem] == nil)
	{
		[(ETLayoutItem *)item setOrigin: origin];
	}
}
#endif

#ifdef DEBUG_LAYOUT
- (void) setAutoresizingMask: (NSUInteger)mask
{
	ETLog(@"Will alter resizing mask from %d to %d %@", [self autoresizingMask], 
		mask, self);
	[super setAutoresizingMask: mask];
}

- (void) resizeSubviewsWithOldSize: (NSSize)aSize
{
	[_temporaryView resizeWithOldSuperviewSize: aSize];
	[_wrappedView resizeWithOldSuperviewSize: aSize];
}
#endif

#pragma mark Intercepted Events -

- (void) mouseDown: (NSEvent *)theEvent { }
- (void) rightMouseDown: (NSEvent *)theEvent { }
- (void) otherMouseDown: (NSEvent *)theEvent { }
- (void) mouseUp: (NSEvent *)theEvent { }
- (void) rightMouseUp: (NSEvent *)theEvent { }
- (void) otherMouseUp: (NSEvent *)theEvent { }
- (void) mouseMoved: (NSEvent *)theEvent { }
- (void) mouseDragged: (NSEvent *)theEvent { }
- (void) scrollWheel: (NSEvent *)theEvent { }
- (void) rightMouseDragged: (NSEvent *)theEvent { }
- (void) otherMouseDragged: (NSEvent *)theEvent { }
- (void) mouseEntered: (NSEvent *)theEvent { }
- (void) mouseExited: (NSEvent *)theEvent { }
- (void) keyDown: (NSEvent *)theEvent { }
- (void) keyUp: (NSEvent *)theEvent { }
- (void) flagsChanged: (NSEvent *)theEvent { }
#ifndef GNUSTEP
- (BOOL) validateProposedFirstResponder: (NSResponder *)responder forEvent: (NSEvent *)event { return YES; }
- (BOOL) wantsForwardedScrollEventsForAxis: (NSEventGestureAxis)axis { return NO; }
- (void) tabletPoint: (NSEvent *)theEvent { }
- (void) tabletProximity: (NSEvent *)theEvent { }
- (void) cursorUpdate: (NSEvent *)event { }
- (void) magnifyWithEvent: (NSEvent *)event { }
- (void) rotateWithEvent: (NSEvent *)event { }
- (void) swipeWithEvent: (NSEvent *)event { }
- (void) beginGestureWithEvent: (NSEvent *)event { }
- (void) endGestureWithEvent: (NSEvent *)event { }
- (void) touchesBeganWithEvent: (NSEvent *)event { }
- (void) touchesMovedWithEvent: (NSEvent *)event { }
- (void) touchesEndedWithEvent: (NSEvent *)event { }
- (void) touchesCancelledWithEvent: (NSEvent *)event { }
#endif

@end

#pragma mark Drawing -

#ifndef GNUSTEP
static void ETSwizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector)
{
	/* The original method in the target class or some superclass */
	Method originalMethod = class_getInstanceMethod(class, originalSelector);
	Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

	/* If the original method is in a superclass, add the new implementation 
	   under the original method name to the target class. */
	BOOL isOriginalMethodFromSuperclass = class_addMethod(class, originalSelector,
		method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));

	if (isOriginalMethodFromSuperclass)
	{
		/* Replace the swizzled method implementation with the implementation 
		   of the superclass method we override in the target class. */
		class_replaceMethod(class, swizzledSelector,
			method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
	}
	else
	{
        method_exchangeImplementations(originalMethod, swizzledMethod);
	}
}


@interface NSView (ETViewAdditions)
- (BOOL) isSupervisorViewBacked;
@end

@implementation NSView (ETViewAdditions)

+ (void) load
{
	ETSwizzleMethod(self, @selector(canDraw), @selector(EtoileUI_canDraw));
}

/* Returns YES for supervisor descendant views, but NO for supervisor view 
themselves. */
- (BOOL) isSupervisorViewBacked
{
	NSView *view = self;

	while (view != nil)
	{
		if ([view isSupervisorView])
			return YES;
			
		view = [view superview];
	}
	return NO;
}

// TODO: Use -canDrawAppKitPrimitive as the original implementation name
- (BOOL) EtoileUI_canDraw
{
	if ((self != [[self window] contentView]) && [self isSupervisorViewBacked])
	{
		return NO;
	}
	return [self EtoileUI_canDraw];
}

@end

#else

@implementation ETAppKitDrawingIntegration

/* For Mac OS X, returning NO with -canDraw doesn't prevent subviews from being 
drawn unlike GNUstep (or Cocotron), it just causes -drawRect: to be skipped. */
- (BOOL) canDraw
{
	if ([[self window] contentView] == self)
		return [super canDraw];

	return NO;
}

@end

#endif

@implementation ETView (ETAppKitDrawingIntegration)

#ifdef DEBUG_DRAWING
- (void) drawInvalidatedAreaWithRect: (NSRect)needsDisplayRect
{
	if ([self lockFocusIfCanDraw] == NO)
	{
		ETLog(@"WARNING: Cannot draw invalidated area %@ in %@", 
			NSStringFromRect(needsDisplayRect), self);
		return;	
	}
	[[[NSColor redColor] colorWithAlphaComponent: 0.2] set];
	[NSBezierPath fillRect: needsDisplayRect];
	[self unlockFocus];
}

- (void) setNeedsDisplayInRect: (NSRect)dirtyRect
{
	//[self displayRect: dirtyRect];
	[self drawInvalidatedAreaWithRect: dirtyRect];
}
#endif

/* For debugging, tells us whether the receiver is drawing the item tree backed 
by it. */
- (BOOL) isDrawing
{
	return _isDrawing;
}

/* Draws the item tree bound backed by the supervisor view. 

ETLayoutItem and ETDecorator both draw the subviews, that belong to their 
supervisor view, with -displayRectIgnoringOpacity:inContext:. */
- (void) drawRect: (NSRect)rect
{
	_isDrawing = YES;
	[[NSBezierPath bezierPathWithRect: NSZeroRect] setClip];
	[NSGraphicsContext saveGraphicsState];
	[item render: nil dirtyRect: rect inContext: nil];
	[NSGraphicsContext restoreGraphicsState];
	_isDrawing = NO;
}

@end
