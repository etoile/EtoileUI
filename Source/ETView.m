/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h> 
#import <EtoileFoundation/NSObject+Model.h>
#import "ETView.h"
#import "ETDecoratorItem.h"
#import "ETLayoutItem.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"
#import "ETFlowLayout.h"

#define NC [NSNotificationCenter defaultCenter]

#ifndef GNUSTEP
@interface NSView (CocoaPrivate)
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect;
- (void) _recursiveDisplayRectIfNeededIgnoringOpacity: (NSRect)aRect 
	isVisibleRect: (BOOL)isVisibleRect rectIsVisibleRectForView: (BOOL)isRectForView topView: (BOOL)isTopView;
@end
#endif

@interface ETView (Private)
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary;
@end


@implementation ETView

- (Class) defaultItemClass
{
	return [ETLayoutItem class];
}

// TODO: Move this method to ETUIItemFactory
- (id) initWithLayoutView: (NSView *)layoutView
{
	self = [self initWithFrame: [layoutView frame]];
	if (self == nil)
		return nil;

	id existingSuperview = [layoutView superview];
	ETLayout *layout = [ETLayout layoutWithLayoutView: layoutView];
	
	if ([existingSuperview isSupervisorView])
	{
	   [[existingSuperview layoutItem] addItem: [self layoutItem]];
	}
	else /* existingSuperview isn't a view-based node in a layout item tree */
	{
	   [existingSuperview addSubview: self];
	}

	[[self layoutItem] setLayout: layout]; /* inject the initial view as a layout */

	return self;
}

- (id) initWithFrame: (NSRect)frame
{
	return [self initWithFrame: frame layoutItem: nil];
}

/** <init /> 
Initializes and returns a supervisor view instance that is bound to the given 
item.

You should never need to use this method which uses internally by EtoileUI.

When the item is nil, an ETLayoutItem will be instantiated and bound to the 
receiver.

The returned view uses the item autoresizing mask (see 
-[ETLayoutItem autoresizingMask]).

See also -[ETUIItem supervisorView]. */
- (id) initWithFrame: (NSRect)frame layoutItem: (ETLayoutItem *)anItem
{
	self = [super initWithFrame: frame];
	
	if (self != nil)
	{
		/* In both cases, the item will be set by calling 
		   -setLayoutItemWithoutInsertingView: that creates a retain cycle by
		    retaining it. */
		if (anItem != nil)
		{
			[self setItem: anItem];
		}
		else
		{
			[self setItem: [[[self defaultItemClass] alloc] init]];
			/* In -setLayoutItem:, -setSupervisorView: has called back 
			   -setLayoutItemWithoutInsertingView: which retained item, 
			   so we release it.

			   In any cases, we avoid to call +layoutItem (and eliminate the 
			   last line RELEASE as a byproduct) in order to simplify the 
			   testing of the retain cycle with 
			   GSDebugAllocationCount([ETLayoutItem class]). By not creating an 
			   autoreleased instance, we can ensure that releasing the receiver 
			   will dealloc the layout item immediately and won't delay it until 
			   the autorelease pool is deallocated.
			 */
			RELEASE(item);
		}
		[self setAutoresizesSubviews: YES];	/* NSView set up */
	}
	
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

- (unsigned int) retainCount
{
	return NSExtraRefCount(self) + 1;
}
#endif

- (oneway void) release
{
	BOOL hasRetainCycle = (item != nil);
	/* Memorize whether the next release call will deallocate the receiver, 
	   because once the receiver is deallocated you have no way to safely learn 
	   if self is still valid or not.
	   Take note the retain count is NSExtraRefCount plus one. */
	int refCountWas = NSExtraRefCount(self);

	/* Dealloc if only retained by ourself (ref count equal to zero), otherwise 
	   decrement ref count. */
#ifdef GNUSTEP
	[super release];
#else
	if (NSDecrementExtraRefCountWasZero(self))
		[self dealloc];
#endif

	/* Exit if we just got deallocated above. 
	   In that case, self and item are now both deallocated and invalid 
	   and we must never use them (by sending a message for example). */
	BOOL isDeallocated = (refCountWas == 0);
	if (isDeallocated)
		return;

	/* Tear down the retain cycle owned by the layout item.
	   If we are only retained by our layout item which is also retained only 
	   by us, DESTROY(item) will call -[ETLayoutItem dealloc] which in 
	   turn will call back -[ETView release] and result this time in our 
	   deallocation. */	
	BOOL isGarbageCycle = (hasRetainCycle 
		&& NSExtraRefCount(self) == 0 && NSExtraRefCount(item) == 0);
	if (isGarbageCycle)
		DESTROY(item);
}

- (void) dealloc
{
	[NC removeObserver: self];

	// NOTE: item (our owner) is destroyed by -release and _temporaryView
	// is a weak reference
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
	NSArray *copiableSubviews = A(_wrappedView);

	// TODO: This might be very costly and require optimizations (e.g. when 
	// the only subview is the wrapped view)
	[self setSubviews: copiableSubviews];

	ETView *newView = [super copyWithZone: aZone];

	// TODO: May be we can bypass -setWrappedView:
	[newView setWrappedView: [[self wrappedView] copyWithZone: aZone]];
	/* We copy the flipping manually because it isn't encoded by the NSView 
	   archiving.
	   We use -setFlipped: because we have to mark the coordinates to be rebuilt 
	   on GNUstep. */
	[newView setFlipped: [self isFlipped]];

	[self setSubviews: existingSubviews];

	return newView;
}

- (NSArray *) properties
{
	NSArray *properties = A(@"item", @"wrappedView", @"temporaryView", 
		@"contentView", @"mainView");
	return [properties arrayByAddingObjectsFromArray: [super properties]];
}

// TODO: Rewrite the next two methods in a more sensible way

- (NSString *) description
{
	NSString *desc = [super description];

	// FIXME: Rename -layoutItem to -item because it can return any ETUIItem.
	if ([[self layoutItem] isLayoutItem])
	{
		ETLayout *layout = [(ETLayoutItem *)[self layoutItem] layout];
		
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
	if ([[self layoutItem] isGroup])
		return [self description];

	// FIXME: Trim the angle brackets out.
	NSString *desc = @"<";

	if ([self wrappedView] != nil)
	{
		desc = [desc stringByAppendingFormat: @"%@ in ", [[self wrappedView] className]];
	}

	return [desc stringByAppendingFormat: @"%@>", [super description]];
}

- (BOOL) acceptsFirstResponder
{
	//ETLog(@"%@ accepts first responder", self);
	return YES;
}

/* Basic Accessors */

/** Returns the item representing the receiver in the layout item tree. 

Never returns nil. */
- (id) layoutItem
{
	// NOTE: We must use -primitiveDescription not to enter an infinite loop
	// with -description calling -layoutItem
	if (item == nil)
	{
		ETLog(@"WARNING: Item bound to %@ must never be nil", [self primitiveDescription]);
	}
	return item;
}

/** This method is only exposed to be used internally by EtoileUI.<br />
You should must never call this method.

Sets the item representing the receiver view in the layout item tree. 

The receiver will be added as a subview to the supervisor view bound to the 
parent item to which the given item belongs to. Which means, this method may 
move the view to a different place in the view hierarchy.

Throws an exception when item parameter is nil. */
- (void) setItem: (ETUIItem *)anItem
{
	NSParameterAssert(nil != anItem);
	[anItem setSupervisorView: self];
}

/** This method is only exposed to be used internally by EtoileUI.<br />
You should must never call this method. */
- (void) setLayoutItemWithoutInsertingView: (ETLayoutItem *)anItem
{	
	if (anItem == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"For ETView, "
			@"-setLayoutItem: parameter %@ must be never be nil", anItem];
	}	
	ASSIGN(item, anItem); // NOTE: Retain cycle (see -release)
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

Unlike NSView, ETContainer uses flipped coordinates by default in order to 
simplify layout computation.

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

/* Embbeded Views */

/** This method is only exposed to be used internally by EtoileUI. 

Recomputes the positioning of the main view. */
- (void) tile
{
	id mainView = [self mainView];
	
	/* Reset main view frame to fill the receiver */
	[mainView setFrameOrigin: NSZeroPoint];
	[mainView setFrameSize: [self frame].size];
	
	/* Reset autoresizing */
	[mainView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[self setAutoresizesSubviews: YES];
}

/** Sets the item view.<br />
The receiver is the view owner.

You must never call this method but -[ETLayoutItem setView:]. */
- (void) setWrappedView: (NSView *)view
{
	NSAssert([[self temporaryView] isEqual: view] == NO, @"A temporary view "
		"cannot be set as a wrapped view.");

	// NOTE: Next lines must be kept in this precise order and -tile not moved
	// into -setContentView:temporary:
	[self setContentView: view temporary: NO];
	ASSIGN(_wrappedView, view);
	[self tile]; /* Update view layout */
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
	NSAssert([[self wrappedView] isEqual: subview] == NO, @"A wrapped view "
		"cannot be set as a temporary view.");

	// NOTE: Next lines must be kept in this precise order and -tile not moved
	// into -setContentView:temporary:
	[self setContentView: subview temporary: YES];
	_temporaryView = subview;
	[self tile]; /* Update view layout */
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

/* Not really costly since aView is expected to have no superview normally. */
- (BOOL) hasSupervisorViewAncestor: (NSView *)aView
{
	NSView *ancestorView = [aView superview];

	while (nil != ancestorView)
	{
		if ([ancestorView isSupervisorView])
			return YES;

		ancestorView = [ancestorView superview];
	}

	return NO;
}

/** This method is only exposed to be used internally by EtoileUI. 

You must override this method in subclasses. */
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary
{
	[self checkViewHierarchyValidity];

	if (view != nil && [[self layoutItem] isDecoratorItem] == NO)
	{
		NSString *selSubstring = (temporary ? @"Temporary" : @"Wrapped");

		NSAssert2([self hasSupervisorViewAncestor: view] == NO, @"You must not move "
			"view %@ to a new superview without first removing it explicitely "
			"with -[ETLayoutItem setView: nil] or -[ETView set%@View: nil]", 
			view, selSubstring);
	}

	/* Reset the content view frame to fill the receiver */
	[view setFrameOrigin: NSZeroPoint];
	[view setFrameSize: [self frame].size];

	/* Ensure the resizing of all subviews is handled automatically */
	[self setAutoresizesSubviews: YES];

	if (temporary) /* Temporary view setter */
	{
		if (view != nil)
		{
			[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
			[self addSubview: view];
			[[self wrappedView] setHidden: YES];
		}
		else /* Passed a nil temporary view */
		{
			/* Restore autoresizing mask */
			//[[self temporaryView] setAutoresizingMask: [self autoresizingMask]];
			[[self temporaryView] removeFromSuperview];
			[[self wrappedView] setHidden: NO];
		}
	}
	else /* Wrapped view setter */
	{
		if (view != nil)
		{
			[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
			[self addSubview: view];
		}
		else /* Passed a nil wrapped view */
		{
			/* Restore autoresizing mask */
			//[[self wrappedView] setAutoresizingMask: [self autoresizingMask]];
			[[self wrappedView] removeFromSuperview];
		}
	}
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
	NSView *contentView = [self temporaryView];
	
	if (contentView == nil)
		contentView = [self wrappedView];
	
	return contentView;
}

/* Subclassing */

/** This method is only exposed to be used internally by EtoileUI.

Returns the direct subview of the receiver. The returned value is identical
to -wrappedView. 

If you write an ETView subclass where the wrapped view is put inside another
view (like a scroll view), you must override this method to return this 
superview. 

This method should never be called directly, uses -contentView, -wrappedView
or -temporaryView instead. */
- (NSView *) mainView
{
	return [self wrappedView];
}

/* Overriden NSView methods */

#ifndef GNUSTEP
#define CHECKSIZE(size) \
NSAssert1(size.width >= 0 && size.height >= 0, @"For a supervisor view, the " \
	"frame must always have a positive size %@", NSStringFromSize(size));
#else
#define CHECKSIZE(size)
#endif

- (void) setFrame: (NSRect)frame
{
	CHECKSIZE(frame.size)
	[super setFrame: frame];

	if ([item shouldSyncSupervisorViewGeometry] == NO)
		return;

	if ([item decoratorItem] == nil)
	{
		[item setFrame: frame];
	}
	else
	{
		[item setContentSize: frame.size];
	}
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
		[item setSize: size];
	}
	else
	{
		[item setContentSize: size];
	}
}

- (void) setFrameOrigin: (NSPoint)origin
{
	[super setFrameOrigin: origin];
	if ([item shouldSyncSupervisorViewGeometry] == NO)
		return;

	if ([item decoratorItem] == nil)
	{
		[item setOrigin: origin];
	}
}
#endif

#ifdef DEBUG_LAYOUT
- (void) setAutoresizingMask: (unsigned int)mask
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

/* Rendering Tree */

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

/* INTERLEAVED_DRAWING must always be enabled. 
   You might want to disable it for debugging how the control of the drawing is 
   handed by ETView to the layout item tree.
   
   With INTERLEAVED_DRAWING, the drawing of the layout item follows the drawing
   of the view its represents and all related subviews. This view is called the 
   supervisor view and is an ETView instance. The supervisor view can embed a 
   subview that is returned by -[ETLayoutItem view] and -[ETView wrappedView].
   Hence the layout item is able to draw its style (border, selection indicators 
   etc.) on top of the wrapped view.

   Without INTERLEAVED_DRAWING, the drawing of the layout item only occurs 
   within -drawRect: and precedes the drawing of the view its represents and all 
   related subviews. Thereby the drawing of the style of an item will be covered 
   by the drawing of its view. If the item has no view, the issue doesn't exist. 
   This view is a subview of our closest ancestor view where the item style is 
   drawn through -drawRect:, but a superview -drawRect: is followed by the 
   -drawRect: of subviews, that's why the item style cannot be drawn properly 
   in such cases. */
#define INTERLEAVED_DRAWING 1

#ifndef INTERLEAVED_DRAWING

/** Now we must let layout items handles their custom drawing through their 
style object. For example, by default an item with or without a view has a style 
to draw its selection state. 

In addition, this style implements the logic to draw layout items without 
view that plays a role similar to cell.

Layout items are smart enough to avoid drawing their view when they have one. */
- (void) drawRect: (NSRect)rect
{
	[super drawRect: rect];

	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence (triggered by display-like methods). */
	[item render: nil dirtyRect: rect inContext: nil];
}

#else

- (void) drawRect: (NSRect)rect
{
	_rectToRedraw = rect;
}

#ifdef GNUSTEP
- (void) displayIfNeeded
{
	//ETLog(@"-displayIfNeeded");
	[super displayIfNeeded];
}
#endif

- (void) displayIfNeededInRect:(NSRect)aRect
{
	//ETLog(@"-displayIfNeededInRect:");
	[super displayIfNeededInRect: aRect];
}

- (void) displayIfNeededInRectIgnoringOpacity:(NSRect)aRect
{
	//ETLog(@"-displayIfNeededInRectIgnoringOpacity:");
	[super displayIfNeededInRectIgnoringOpacity: aRect];
}

- (void) display
{	
	//ETLog(@"-display");
	[super display];
}

- (void) displayRect:(NSRect)aRect
{
	//ETLog(@"-displayRect:");
	[super displayRect: aRect];
}

- (void) displayRectIgnoringOpacity:(NSRect)aRect
{
	//ETLog(@"-displayRectIgnoringOpacity:");
	[super displayRectIgnoringOpacity: aRect];
}

#ifdef GNUSTEP

/* Main and canonical method which is used to take control of the drawing on 
GNUstep and pass it to the layout item tree as needed. */
- (void) displayRectIgnoringOpacity: (NSRect)aRect 
                          inContext: (NSGraphicsContext *)context
{
	//ETLog(@"-displayRectIgnoringOpacity:inContext:");
	[super displayRectIgnoringOpacity: aRect inContext: context];
	
	if ([self lockFocusIfCanDrawInContext: context] == NO)
		return;

	/* We always composite the rendering chain on top of each view -drawRect: 
	   drawing sequence (triggered by display-like methods). */
	[item render: nil dirtyRect: aRect inContext: nil];

	[self unlockFocus];
}

#else

- (BOOL) lockFocusInRect: (NSRect)rectToRedraw
{
	BOOL lockFocus = [self lockFocusIfCanDraw];
	if ([self wantsDefaultClipping])
	{
		/* No need to apply bounds transform to aRect because we get this rect 
		   from -drawRect: which receives a rect already adjusted. */ 
		NSRectClip(rectToRedraw);
	}
	return lockFocus;
}

// NOTE: Very often NSView instance which has been sent a display message will 
// call this method on its subviews. These subviews will do the same with their own 
// subviews. Here is the other method often used in the same way:
//_recursiveDisplayRectIfNeededIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:topView:
// The previous method usually follows the message on next line:
//_displayRectIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:

/* First canonical method which is used to take control of the drawing on 
Cocoa and pass it to the layout item tree as needed. */
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)aRect
{
	ETDebugLog(@"-_recursiveDisplayAllDirtyWithLockFocus:visRect: %@", self);
	[super _recursiveDisplayAllDirtyWithLockFocus: lockFocus visRect: aRect];

	/* Most of the time, the focus isn't locked. In this case, aRect is a 
	   portion of the content view frame and no clipping is done either. */
	if ([self lockFocusInRect: _rectToRedraw])
	{
#ifdef DEBUG_DRAWING
		//if ([self respondsToSelector: @selector(layout)] && [[(ETContainer *)self layout] isKindOfClass: [ETFlowLayout class]])
		{
			[[NSColor blackColor] set];
			[NSBezierPath setDefaultLineWidth: 6.0];
			[NSBezierPath strokeRect: aRect];
		}
#endif

		/* We always composite the rendering chain on top of each view -drawRect: 
		   drawing sequence (triggered by display-like methods). */
		[item render: nil dirtyRect: _rectToRedraw inContext: nil];

		[self unlockFocus];
		[[self window] flushWindow];
	}

	_wasJustRedrawn = YES;
}

/* Second canonical method which is used to take control of the drawing on 
Cocoa and pass it to the layout item tree as needed. */
- (void) _recursiveDisplayRectIfNeededIgnoringOpacity: (NSRect)aRect 
	isVisibleRect: (BOOL)isVisibleRect rectIsVisibleRectForView: (BOOL)isRectForView topView: (BOOL)isTopView
{
	_wasJustRedrawn = NO;

	[super _recursiveDisplayRectIfNeededIgnoringOpacity: aRect 
		isVisibleRect: isVisibleRect rectIsVisibleRectForView: isRectForView topView: isTopView];

	ETDebugLog(@"-_recursiveDisplayRectIfNeededIgnoringOpacity:XXX %@ %@", self, NSStringFromRect(aRect));
	
	/* From what I have observed, _recursiveDisplayAllDirtyXXX was only called 
	   when isVisibleRect and isRectForView are both NO, or when live resize 
	   was underway (in that case the invalidated area was the entire view).
	   If we don't make the check below _recursiveDisplayAllDirtyXXX  will draw 
	   and this method will then draw another time in the same view/receiver with 
	   with -render:dirtyRect:inContext:. 
	   The next line works pretty well... 
	   BOOL needsRedraw = (isRectForView && [self needsDisplay] && [self inLiveResize]);
	   ... but we rather use the _wasJustRedrawn flag which is a safer way to 
	   check whether _recursiveDisplayAllDirtyXXX was called by the call to 
	   super at the beginning of this method or not.
	   isVisibleRect seems to be YES when -displayXXX was used but NO when 
	   -displayIfNeededXXX was. */
	BOOL needsRedraw = (isRectForView && [self needsDisplay] && _wasJustRedrawn == NO);

	if (needsRedraw && [self lockFocusInRect: _rectToRedraw])
	{
		/* We always composite the rendering chain on top of each view -drawRect: 
		   drawing sequence (triggered by display-like methods). */
		[item render: nil dirtyRect: _rectToRedraw inContext: nil];

		[self unlockFocus];
		[[self window] flushWindow];
	}

	_wasJustRedrawn = NO;
}

- (void) _recursiveDisplayRectIfNeededIgnoringOpacity: (NSRect)aRect 
	inContext: (NSGraphicsContext *)ctxt topView: (BOOL)isTopView
{
	ASSERT_FAIL(@"This method is never called based on our tests... As it "
		"clearly got called now, we need to find out why and override it properly.");
}

- (void) _lightWeightRecursiveDisplayInRect: (NSRect)aRect
{
	ASSERT_FAIL(@"This method is never called based on our tests... As it "
		"clearly got called now, we need to find out why and override it properly.");
}

#endif

#endif /* INTERLEAVED_DRAWING */

@end
