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
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Private.h"
#import "ETLayoutItemGroup.h"
#import "ETUIItemIntegration.h"
#import "NSObject+EtoileUI.h"
#import "NSView+EtoileUI.h"
#import "ETCompatibility.h"
#import "ETFlowLayout.h"

#define NC [NSNotificationCenter defaultCenter]

@interface ETForegroundView : ETFlippableView
@end

@interface ETView ()
@property (nonatomic, strong) ETFlippableView *foregroundView;
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

/** <init /> 
Initializes and returns a supervisor view.

You should never need to use this method which uses internally by EtoileUI.
 
The frame argument can be ignored.

See also -[ETUIItem supervisorView]. */
- (instancetype) initWithFrame: (NSRect)frame
{
	self = [super initWithFrame: frame];
	if (nil == self)
		return nil;

	_minSize = NSZeroSize;
	_maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
	/* To let ETLayoutItem and ETLayout resize views according to content aspect
	   and autoresizing policies, we disable the built-in autoresizing.
	
	   For a leaf item, autoresizesSubviews is NO, unless a view is set.
	   For a group item, autoresizesSubviews is NO, unless a layout view is set.

	   We update the view autoresizing policy in -setContentView:isTemporary:. */
	[self setAutoresizesSubviews: NO];

	_foregroundView = [[ETForegroundView alloc] initWithFrame: ETMakeRect(NSZeroPoint, frame.size)];
	_foregroundView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	
	[self addSubview: _foregroundView];

	return self;
}

- (void) dealloc
{
	[NC removeObserver: self];
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
	NSArray *copiableSubviews = @[];

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
	NSArray *properties = @[@"item", @"wrappedView", @"temporaryView", 
		@"contentView", @"mainView"];
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

- (void) setFlipped: (BOOL)flag
{
	[super setFlipped: flag];
	_foregroundView.flipped = flag;
}

/* Embbeded Views */

- (void) tile
{
	_foregroundView.frame = ETMakeRect(NSZeroPoint, self.frame.size);
}

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
	_wrappedView = view;
	[self updateSubviews];
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
	[self updateSubviews];
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

- (void) validateViewHierarchy
{
	NSMutableArray *internalSubviews = [NSMutableArray new];

	if (_wrappedView != nil)
	{
		[internalSubviews addObject: _wrappedView];
	}
	if (_temporaryView != nil)
	{
		[internalSubviews addObject: _temporaryView];
	}
	if (_foregroundView != nil)
	{
		[internalSubviews addObject: _foregroundView];
	}
	NSArray *lastSubviews =
		[self.subviews subarrayFromIndex: self.subviews.count - internalSubviews.count];

	ETAssert(internalSubviews.count >= 1);
	/* When this assertions fails, this usually means the internal subviews 
	   ordering is incorrect, or that the wrapped or temporary view has been
	   moved to a superview without removing it with -setWrapped/TemporaryView:. */
	ETAssert([internalSubviews isEqual: lastSubviews]);
}

/* See -setWrappedView: and -setTemporaryView: documentation which explains the 
implemented behavior. */
- (void) setContentView: (NSView *)view temporary: (BOOL)temporary
{
	[self validateViewHierarchy];

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
	}
	
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

- (void) updateSubviews
{
	NSMutableArray *views = [self.subviews mutableCopy];

	if (_wrappedView != nil)
	{
		[views removeObject: _wrappedView];
		[views addObject: _wrappedView];
	}
	if (_temporaryView != nil)
	{
		[views removeObject: _temporaryView];
		[views addObject: _temporaryView];
	}
	if (_foregroundView != nil)
	{
		[views removeObject: _foregroundView];
		[views addObject: _foregroundView];
	}

	self.subviews = views;
	[self validateViewHierarchy];
}

- (void) setItemViews: (NSArray *)itemViews
{
	NSMutableArray *views = [itemViews.reverseObjectEnumerator.allObjects mutableCopy];

	if (_wrappedView != nil)
	{
		[views addObject: _wrappedView];
	}
	if (_temporaryView != nil)
	{
		[views addObject: _temporaryView];
	}
	if (_foregroundView != nil)
	{
		[views addObject: _foregroundView];
	}

	self.subviews = views;
	[self validateViewHierarchy];
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

	/* When we have a decorator on the item, we can constraint the size since 
	   UIItem will have reset our min and max sizes to their default values. */
	NSRect constrainedFrame = ETMakeRect(frame.origin,
		ETConstrainedSizeFromSize(frame.size, self.minSize, self.maxSize));

	[super setFrame: constrainedFrame];
	[self tile];

	if ([item shouldSyncSupervisorViewGeometry] == NO)
		return;

	if ([item decoratorItem] == nil)
	{
		[(ETLayoutItem *)item setFrame: constrainedFrame];
	}
	else
	{
		[(ETLayoutItem *)item setContentSize: constrainedFrame.size];
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
	[self tile];
	
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

/* Rendering Tree */

- (NSMutableDictionary *) inputValues
{
	if (_inputValues == nil)
	{
		return [NSMutableDictionary new];
	}
	return _inputValues;
}

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

/** Draws the background inside the item content drawing box.

The drawing occurs when the receiver is a ETLayoutItem.

For a custom bounding box without a decorator, the content drawing box remains 
identical to the content bounds (e.g. labels drawn outside the content bounds
must be drawn by a cover style).

We let items handle their custom drawing through their style objects. For 
example, by default an item with or without a view has a style to draw its 
selection state.

Layout items are smart enough to avoid drawing their view when they have one. */
- (void) drawRect: (NSRect)dirtyRect
{
	[super drawRect: dirtyRect];

	if (!item.isLayoutItem)
		return;

	/* When drawing the content, the dirty rect can be left unchanged, because
	   it already orresponds to the content drawing box */
	[(ETLayoutItem *)item renderBackground: self.inputValues
	                             dirtyRect: dirtyRect
	                             inContext: nil];
}

/** Draws the foreground.

The drawing occurs when the receiver is a ETLayoutItem.

The coordinates matrix must be adjusted to the item content coordinate space, 
before calling this method. For drawing the cover style, this method will adjust
the coordinates matrix to the item coordinate space (to take account the 
decorators).

For a window item decoration, the drawing box prevents any drawing to be done on 
the title bar, . */
- (void) drawForegroundRect: (NSRect)dirtyRect
{
	if (!item.isLayoutItem)
		return;

	ETLayoutItemGroup *layerItem = [((ETLayoutItem *)item).layout layerItem];
	
	//ETAssert(layerItem == nil || layerItem.supervisorView == nil);

	/* Draw the layer item style in the item content coordinate space */

	[layerItem renderBackground: self.inputValues
	                  dirtyRect: dirtyRect
	                  inContext: nil];

	/* Draw the cover style in the item coordinate space */

	NSRect drawingBox = ((ETLayoutItem *)item).drawingBox;
	// FIXME: NSRect adjustedDirtyRect = [self adjustedDirtyRect: dirtyRect inDrawingBox: drawingBox];
	NSRect adjustedDirtyRect = drawingBox;
	NSAffineTransform *transform = [NSAffineTransform transform];
	NSPoint contentOriginInBounds = [self adjustedOriginInDrawingBox: drawingBox];

	[transform translateXBy: contentOriginInBounds.x yBy: contentOriginInBounds.y];
	[transform concat];
	
	[(ETLayoutItem *)item renderForeground: self.inputValues
	                             dirtyRect: adjustedDirtyRect
	                             inContext: nil];

	[transform invert];
	[transform concat];
}

- (NSRect) dirtyRect
{
	return _rectToRedraw;
}

- (void) viewWillDraw
{
	[super viewWillDraw];
	
	const NSRect *rects = NULL;
	NSInteger nbOfRects = 0;
	
	_rectToRedraw = NSZeroRect;

	[self getRectsBeingDrawn: &rects count: &nbOfRects];

	for (int i = 0; i < nbOfRects; i++)
	{
		_rectToRedraw = NSUnionRect(_rectToRedraw, rects[i]);
	}
	//ETLog(@"Rect to redraw %@ for %@", NSStringFromRect(_rectToRedraw), self);
}

- (NSPoint) adjustedOriginInDrawingBox: (NSRect)drawingBox
{
	ETAssert(NSEqualPoints(((ETLayoutItem *)item).contentBounds.origin, NSZeroPoint));
	
	return [self convertPoint: NSZeroPoint toView: item.displayView];
}

/** Returns a dirty rect that takes in account a drawing box larger than the 
receiver bounds.

The dirty rect argument is one that doesn't extend beyond the receiver bounds
e.g. the one received in -drawRect:.

The drawing box is larger with a decorator (the outer decoration rect) or a 
custom bounding box that enlarges the item bounds.

When the drawing box is equal to the receiver bounds (e.g. 
-[ETLayoutItem contentDrawingBox]), the returned dirty rect is left unchanged. */
- (NSRect) adjustedDirtyRect: (NSRect)dirtyRect inDrawingBox: (NSRect)drawingBox
{
	ETLayoutItemGroup *parentItem = ((ETLayoutItem *)item).parentItem;
	ETView *parentView =
		(parentItem.supervisorView != nil ? parentItem.supervisorView : item.displayView);
	NSRect parentDirtyRect = [self convertRect: parentView.dirtyRect
	                                  fromView: parentView];
	/* Sometimes the parent dirty rect is smaller than the one received in -drawRect: */
	NSRect unionDirtyRect = NSUnionRect(dirtyRect, parentDirtyRect);

	return NSIntersectionRect(unionDirtyRect, drawingBox);
}

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


@implementation ETForegroundView

- (void) drawRect: (NSRect)dirtyRect
{
	[(ETView *)self.superview drawForegroundRect: dirtyRect];
}

@end
