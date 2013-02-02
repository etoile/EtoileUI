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
#import "NSObject+EtoileUI.h"
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
	[self setAutoresizesSubviews: YES];

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
	[NC removeObserver: self];

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

/* Basic Accessors */

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

/* Embbeded Views */

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

	/* Ensure the resizing of all subviews is handled automatically */
	[self setAutoresizesSubviews: YES];

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
		[(ETLayoutItem *)item setFrame: frame];
	}
	else
	{
		[(ETLayoutItem *)item setContentSize: frame.size];
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
		[(ETLayoutItem *)item setSize: size];
	}
	else
	{
		[(ETLayoutItem *)item setContentSize: size];
	}
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
	// NOTE: Rounding error prevents the assertion below to work
	//ETAssert(NSEqualRects(rect, _rectToRedraw));
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

- (NSRect) dirtyRect
{
	return _rectToRedraw;
}

- (void) viewWillDraw
{
	const NSRect *rects = NULL;
	NSInteger nbOfRects = 0;
	
	_rectToRedraw = NSZeroRect;

	[self getRectsBeingDrawn: &rects count: &nbOfRects];

	for (int i = 0; i < nbOfRects; i++)
	{
		_rectToRedraw = NSUnionRect(_rectToRedraw, rects[i]);
	}
	//ETLog(@"Rect to redraw %@ for %@", NSStringFromRect(_rectToRedraw), self);

	[super viewWillDraw];
}

- (NSRect) coverStyleDirtyRectForItem: (ETLayoutItem *)anItem 
                         inParentView: (ETView *)parentView
{
	NSParameterAssert([anItem isLayoutItem]);

	NSRect parentDirtyRect = [self convertRect: [parentView dirtyRect] 
	                                  fromView: parentView];
	return NSIntersectionRect(parentDirtyRect, [anItem drawingBox]);
}

- (NSRect) adjustedDirtyRectWithRect: (NSRect)dirtyRect
{
	BOOL shouldDrawCoverStyle = ([item decoratorItem] == nil);

	if (NO == shouldDrawCoverStyle)
		return dirtyRect;

	NSView *parentView = [self superview];

	if (NO == [parentView isSupervisorView])
		return dirtyRect;

	return [self coverStyleDirtyRectForItem: [item firstDecoratedItem] 
	                           inParentView: (ETView *)parentView];
}

#ifdef GNUSTEP

/* Main and canonical method which is used to take control of the drawing on 
GNUstep and pass it to the layout item tree as needed. */
- (void) displayRectIgnoringOpacity: (NSRect)aRect 
                          inContext: (NSGraphicsContext *)context
{
	//ETLog(@"-displayRectIgnoringOpacity:inContext:");

	if ([self canDraw] == NO)
		return;

	// FIXME: We cannot call -getRectsBeingDrawn:count: now on GNUstep (crash with libobjc2)
	//[self viewWillDraw];
	[super displayRectIgnoringOpacity: aRect inContext: context];
	
	if ([self lockFocusIfCanDrawInContext: context] == NO)
		return;

	// FIXME: Use...
	//NSRect adjustedDirtyRect = [self adjustedDirtyRectWithRect: aRect];

	[item render: nil dirtyRect: aRect inContext: nil];
	[self unlockFocus];
}

#else

- (BOOL) lockFocusInRect: (NSRect)rectToRedraw
{
	BOOL lockFocus = [self lockFocusIfCanDraw];
	NSRectClip(rectToRedraw);
	return lockFocus;
}

// NOTE: Very often NSView instance which has been sent a display message will 
// call this method on its subviews. These subviews will do the same with their own 
// subviews. Here is the other method often used in the same way:
//_recursiveDisplayRectIfNeededIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:topView:
// The previous method usually follows the message on next line:
//_displayRectIgnoringOpacity:isVisibleRect:rectIsVisibleRectForView:

/* First canonical method which is used to take control of the drawing on 
Cocoa and pass it to the layout item tree as needed. 

visibleRect is the same than [self visibleRect]. */
- (void) _recursiveDisplayAllDirtyWithLockFocus: (BOOL)lockFocus visRect: (NSRect)visibleRect
{
	ETDebugLog(@"-_recursiveDisplayAllDirtyWithLockFocus:visRect: %@", self);

	if (NSEqualRects(visibleRect, NSZeroRect))
		return;

	[super _recursiveDisplayAllDirtyWithLockFocus: lockFocus visRect: visibleRect];

	/* Most of the time, the focus isn't locked */
	if ([self lockFocusInRect: _rectToRedraw])
	{
		NSRect adjustedDirtyRect = [self adjustedDirtyRectWithRect: _rectToRedraw];

		[item render: nil dirtyRect: adjustedDirtyRect inContext: nil];
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
		NSRect adjustedDirtyRect = [self adjustedDirtyRectWithRect: _rectToRedraw];

		[item render: nil dirtyRect: adjustedDirtyRect inContext: nil];
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

/* Intercept and Discard Events */

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
