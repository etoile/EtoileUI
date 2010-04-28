/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETUIItem.h"
#import "ETView.h"
#import "ETCompatibility.h"

@interface ETDecoratorItem (Private)
- (NSRect) convertDecoratorRectToVisibleContent: (NSRect)rectInDecorator;
- (NSPoint) convertDecoratorPointToVisibleContent: (NSPoint)aPoint;
@end


@implementation ETDecoratorItem

/** Do not use. May be remove later. */
+ (id) item
{
	NSAssert([self isEqual: [ETDecoratorItem class]] == NO, @"ETDecoratorItem "
		"is an abstract class which cannot be instantiated.");
	return AUTORELEASE([[self alloc] initWithSupervisorView: nil]);
}

/** <init />
Initializes and returns a new decorator whose decoration border is provided by 
supervisorView.

If you write a subclass that uses no supervisor view, you must override this 
initializer. */
- (id) initWithSupervisorView: (ETView *)supervisorView
{
	SUPERINIT

	[self setSupervisorView: supervisorView];
	[self setDecoratedItem: nil];

	return self;
}

- (id) init
{
	return nil;
}

// NOTE: -copyWithZone: implementation can be omitted, the ivars are transient.

/** Returns whether the view used by the receiver is a widget. 

By default, returns YES. */
- (BOOL) usesWidgetView
{
	return YES;
}

- (ETUIItem *) decoratedItemAtPoint: (NSPoint)aPoint
{
	/* All the items in a decorator chain have the same -isFlipped value, no 
	   need to use NSMouseInRect. */
	BOOL isInside = NSMouseInRect(aPoint, [self visibleContentRect], [self isFlipped]);

	if (isInside && _decoratedItem != nil)
	{
		NSPoint contentRelativePoint = [self convertDecoratorPointToVisibleContent: aPoint];
		return [_decoratedItem decoratedItemAtPoint: contentRelativePoint];
	}
	else
	{
		return self;
	}
}

/* For debugging */
- (void) drawCoverStyleMarkerWithRect: (NSRect)realDirtyRect
{
	[[[NSColor redColor] colorWithAlphaComponent: 0.2] set];
	[NSBezierPath fillRect: realDirtyRect];
}

// TODO: To be used, when EtoileUI will draw everything by itself including the 
// views without relying on the view hierarchy machinery.
//NSRect rectInContent = [self convertDecoratorRectToContent: dirtyRect];
//[_decoratedItem render: inputValues dirtyRect: rectInContent inContext: ctxt];
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt
{
	BOOL isLastDecorator = (nil != _decoratorItem);

	if (isLastDecorator)
		return;

	ETLayoutItem *item = [self firstDecoratedItem];

	if ([item isLayoutItem] == NO)
		return;

	/* See also -[ETLayoutItem render:dirtyRect:inContext:] */
	[NSGraphicsContext saveGraphicsState];
	[[NSBezierPath bezierPathWithRect: dirtyRect] setClip];
	//[self drawCoverStyleMarkerWithRect: realDirtyRect];
	[[item coverStyle] render: inputValues layoutItem: item dirtyRect: dirtyRect];
	[NSGraphicsContext restoreGraphicsState];
}

/** <override-never /> 
Set the decoration rect associated with the receiver.

If you want to intercept a decoration rect update, see -handleSetDecorationRect:. */
- (void) setDecorationRect: (NSRect)rect
{
	/* We don't do [[self supervisorView] setFrame: rect]; but rather let the 
	   outermost decorator resize us as a subview. */
	BOOL isLastDecorator = (_decoratorItem == nil);
	if (isLastDecorator)
	{
		[self handleSetDecorationRect: rect];
	}
	else
	{
		[_decoratorItem decoratedItemRectChanged: rect];
	}
}

/** <override-dummy />
Returns the content rect portion that remains visible when the content is 
clipped. The visible rect is expressed in the content coordinate space unlike 
-visibleContentRect. */
- (NSRect) visibleRect
{
	return [self contentRect];
}

/** <override-dummy />
Returns the content rect portion that remains visible when the content is 
clipped. The visible content rect is expressed in the receiver coordinate space. 
See also -contentRect.

When the content is not clipped by the receiver, -visibleContentRect and 
-contentRect are equal.

With ETDecoratorItem, the content rect and the visible content rect are equal, 
because the content is resized rather than clipped when a decorator is 
resized. However subclasses can decide otherwise (e.g. ETScrollableAreaItem). */
- (NSRect) visibleContentRect
{
	return [self contentRect];
}

/** Returns the content rect expressed in the receiver coordinate space (the 
area that lies inside -decorationRect).

The receiver content rect is equal to [[self decoratedItem] decorationRect]. */
- (NSRect) contentRect
{
	NSView *wrappedView = [[self supervisorView] wrappedView];
	
	if (nil != wrappedView)
	{
		return [wrappedView frame];
	}
	else
	{
		return NSZeroRect;
	}

	/*NSAssert(NSEqualRects([_decoratedItem decorationRect], contentRect), 
		@"The content rect must be equal to the decorated item decoration rect");*/
}

/** Returns a rect expressed in the receiver coordinate space equivalent to
rect parameter expressed in the receiver content coordinate space.

The receiver coordinate space is the area that lies inside -decorationRect.
The receiver content coordinate space is the area that lies inside -contentRect.

See also -convertDecoratorRectToContent:. */
- (NSRect) convertDecoratorRectFromContent: (NSRect)rectInContent
{
	NSRect rectInDecorator = rectInContent;
	NSRect visibleRect = [self visibleRect];
	NSRect contentRect = [self contentRect];
	BOOL isContentClipped = (NSEqualSizes(visibleRect.size, contentRect.size) == NO);

	/* Convert to the visible content coordinate space
	
	   When the origin is beyond the visible content boundaries, the rebased 
	   origin will have x and/or y negative. */
	if (isContentClipped)
	{
		rectInDecorator.origin.x -= [self visibleRect].origin.x;
		rectInDecorator.origin.y -= [self visibleRect].origin.y;
	}

	/* Convert to the decoration coordinate space */
	rectInDecorator.origin.x += [self visibleContentRect].origin.x;
	rectInDecorator.origin.y += [self visibleContentRect].origin.y;

	return rectInDecorator;
}

/** Returns a point expressed in the receiver coordinate space equivalent to
point parameter expressed in the receiver content coordinate space.

See also -convertDecoratorRectFromContent:. */
- (NSPoint) convertDecoratorPointFromContent: (NSPoint)aPoint
{
	return [self convertDecoratorRectFromContent: ETMakeRect(aPoint, NSZeroSize)].origin;
}

/** Returns a rect expressed in the receiver content coordinate space equivalent 
to rect parameter expressed in the receiver coordinate space.

For extra details, see -convertDecoratorRectFromContent:. */
- (NSRect) convertDecoratorRectToContent: (NSRect)rectInDecorator
{
	NSRect rectInContent = rectInDecorator;
	NSRect visibleRect = [self visibleRect];
	NSRect contentRect = [self contentRect];
	BOOL isContentClipped = (NSEqualSizes(visibleRect.size, contentRect.size) == NO);

	rectInContent.origin.x -= [self visibleContentRect].origin.x;
	rectInContent.origin.y -= [self visibleContentRect].origin.y;

	/* Convert to the visible content coordinate space
	
	   When the origin is beyond the visible content boundaries, the rebased 
	   origin will have x and/or y negative. */
	if (isContentClipped)
	{
		rectInContent.origin.x += [self visibleRect].origin.x;
		rectInContent.origin.y += [self visibleRect].origin.y;
	}
	
	return rectInContent;
}

/** Returns a point expressed in the receiver coordinate space equivalent to
point parameter expressed in the receiver content coordinate space.

See also -convertDecoratorRectToContent:. */
- (NSPoint) convertDecoratorPointToContent: (NSPoint)aPoint
{
	return [self convertDecoratorRectToContent: ETMakeRect(aPoint, NSZeroSize)].origin;
}

- (NSRect) convertDecoratorRectToVisibleContent: (NSRect)rectInDecorator
{
	NSRect rectInContent = rectInDecorator;

	rectInContent.origin.x -= [self visibleContentRect].origin.x;
	rectInContent.origin.y -= [self visibleContentRect].origin.y;
	
	return rectInContent;
}

- (NSPoint) convertDecoratorPointToVisibleContent: (NSPoint)aPoint
{
	return [self convertDecoratorRectToVisibleContent: ETMakeRect(aPoint, NSZeroSize)].origin;
}

- (NSSize) decorationSizeForContentSize: (NSSize)aSize
{
	NSRect decorationRect = [self decorationRect];
	NSRect contentRect = [self visibleContentRect];
	float widthOffset = decorationRect.size.width - contentRect.size.width;
	float heightOffset = decorationRect.size.height - contentRect.size.height;

	return NSMakeSize(aSize.width + widthOffset, aSize.height + heightOffset);
}

- (BOOL) isFlipped
{
	return [[self supervisorView] isFlipped];
}

- (void) setFlipped: (BOOL)flipped
{
	[[self supervisorView] setFlipped: flipped];
	[_decoratorItem setFlipped: flipped];	
}

/** <override-dummy />
Sets the autoresizing mask of the supervisor view. */
- (void) setAutoresizingMask: (unsigned int)aMask
{
	[[self supervisorView] setAutoresizingMask: aMask];
}

- (ETUIItem *) decoratedItem
{
	return _decoratedItem;
}

/** Sets the decorated item associated with the receiver.

You should never need to call this method. */
- (void) setDecoratedItem: (ETUIItem *)item
{
	/* Weak reference because decorator retains us */
	_decoratedItem = item;
}

/** <override-dummy />
Returns whether item can be decorated by the receiver.

You can override this method to restrict which item kinds can be decorated by 
the receiver. However you must only return YES when the superclass 
implementation returns the same. */
- (BOOL) canDecorateItem: (ETUIItem *)item
{
	return [item acceptsDecoratorItem: self];
}

/* Inserts newView as a decorated view. */
- (void) setDecoratedView: (NSView *)newView
{
	if ([self supervisorView] == nil)
	{
		NSRect newViewFrame = (newView != nil ? [newView frame] : NSZeroRect);
		ETView *wrapperView = [[ETView alloc] initWithFrame: newViewFrame 
												 item: self];
		[self setSupervisorView: wrapperView];
		RELEASE(wrapperView);
	}
	[[self supervisorView] setWrappedView: newView];
}

/** <override-dummy />
Overrides to customize how the receiver is set up when it is inserted with 
-setDecorator:.

This methods provides a basic implemention that works well when a subclass uses 
a supervisor view. Whether you extend this behavior or replace it, you must 
call the superclass implementation.

To take over the decorated item insertion into the receiver supervisor view, 
pass nil as decoratedView.
To take over the outermost decorator insertion into the parent niew, pass nil 
as parentView. This last case is only useful when the receiver will be 
inserted as the last decorator.

<list>
<item>decoratedView is equal to [item supervisorView]</item>
<item>parentView is equal to [[item displayView] superview]</item>
</list>

Take in account that parentView can be nil. */
- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (NSView *)decoratedView 
                     inView: (ETView *)parentView 
{
	[self saveAndOverrideAutoresizingMaskOfDecoratedItem: item];
	BOOL shouldInsertDecoratedView = (nil != decoratedView);
	if (shouldInsertDecoratedView)
	{
		[self setDecoratedView: decoratedView];
	}

	/* If the display view bound to item was part of the view hierarchy owned by 
	   the layout item tree, inserts the new display view into the existing 
	   parent view. */
	if (parentView != nil)
	{
		ETDebugLog(@"Handle decorate with parent %@ parent view %@ item "
			"display view %@", [item parentItem], parentView, [item displayView]);

		/* We don't insert the decorator supervisor view, but the decorator 
		   display view, because this decorator could be a decorator chain (by 
		   being decorated itself too). The new display view is thus the 
		   supervisor view of the last decorator item. */
		[parentView addSubview: [self displayView]]; // More sure than [item displayView]

		/* No need to update the layout since the new display view will have 
		   the size and location of the previous one. Unlike when you add or
		   or remove an item which involves to recompute the layout. */
	}
}

/** <override-dummy /> 
Overrides to customize how the receiver is torn down when it is removed with 
-setDecorator: nil.

This methods provides a basic implemention that works well when a subclass uses 
a supervisor view. Whether you extend this behavior or replace it, you must 
call the superclass implementation.

To take over the decorated item removal from the receiver supervisor view, pass 
nil as decoratedView.
To take over the outermost decorator removal from the parent view, pass nil 
as parentView. This case is only useful when the receiver is currently the last 
decorator.

Take in account that parentView can be nil. */
- (void) handleUndecorateItem: (ETUIItem *)item
               supervisorView: (NSView *)decoratedView 
                       inView: (ETView *)parentView 
{
	ETDebugLog(@"Handle undecorate with parent %@ parent view %@ item "
		"display view %@", [item parentItem], parentView, [item displayView]);

	BOOL shouldRemoveDecoratedView = (nil != decoratedView);

	if (shouldRemoveDecoratedView)
	{
		[self setDecoratedView: nil];
	}
	[self restoreAutoresizingMaskOfDecoratedItem: item];
	[[self displayView] removeFromSuperview];
	/* Insert the new item display view into the parent view */
	[parentView addSubview: [item supervisorView]];
}

/** <override-dummy />
Sets the last decorator item autoresizing mask to match the given item, then 
overrides the given item autoresizing mask with NSViewWidthSizable and 
NSViewHeightSizable. */
- (void) saveAndOverrideAutoresizingMaskOfDecoratedItem: (ETUIItem *)item
{
	[[[self lastDecoratorItem] supervisorView] setAutoresizingMask: 
		[[item supervisorView] autoresizingMask]];
	[[item supervisorView] setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
}

/** <override-dummy />
Sets the given item autoresizing mask to match the last decorator item. */
- (void) restoreAutoresizingMaskOfDecoratedItem: (ETUIItem *)item
{
	[[item supervisorView] setAutoresizingMask: 
		[[[self lastDecoratorItem] supervisorView] autoresizingMask]];
}

/* Private Use */

/** <override-dummy />
This method updates the decoration rect associated with the receiver.

You can override this method to customize how a subclass react to a geometry 
update when the receiver is the outermost decorator item. A common use case is 
when a subclass uses a custom decoration rect (unrelated to the supervisor 
view extent).

You must never call this method, but only override it.

NOTE: This purpose will probably evolved a bit later on... */
- (void) handleSetDecorationRect: (NSRect)rect // NOTE: May be better named -decoratorItemRectChanged:.
{
	BOOL isLastDecorator = (_decoratorItem == nil);

	/* Don't touch the other decorators in the decorator chain, but rather let 
	   the outermost decorator resize them as a subview indirectly. */
	if (isLastDecorator)
		[[self supervisorView] setFrame: rect];

	// TODO: In case, we decide to support decorator without embbeded views, we 
	// could use this method to notify recursively each decorated item in the 
	// decorator chain and let them the opportunity to update their geometry.
	//[_decoratedItem handleSetDecorationRect: [self convertDecoratorRectToContent: [self contentRect]]];
}

/** <override-dummy />
This method notifies the receiver that the decorated item has a new decoration 
rect. The existing implementation simply notifies the next decorator, and so 
on recursively. When the outermost decorator item is reached, 
-handleSetDecorationRect: is called. Finally rect.size is returned.

rect is in the receiver content coordinate space.

You can override this method to customize how a subclass react to an inner 
geometry update. A custom content size can be returned when needed. A common use 
case is to intercept decorated item resizes to clip or extend the requested 
receiver content size.

You must never call this method, but only override it. */
- (NSSize) decoratedItemRectChanged: (NSRect)rect
{
	BOOL isLastDecorator = ([self decoratorItem] == nil);

	if (isLastDecorator)
	{
		NSSize newSize = [self decorationSizeForContentSize: rect.size];
		[self handleSetDecorationRect: ETMakeRect([self decorationRect].origin, newSize)];
	}
	else
	{
		[_decoratorItem decoratedItemRectChanged: [self convertDecoratorRectFromContent: rect]];
	}

	return rect.size;
}

@end

