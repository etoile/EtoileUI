/*  <title>ETDecoratorItem</title>

	ETDecoratorItem.m
	
	<abstract>ETUIItem subclass which makes possibe to decorate any layout 
	items, usually with a widget view.</abstract>
 
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
 
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

#import <EtoileFoundation/Macros.h>
#import "ETDecoratorItem.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETView.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETUIItem

/** Returns a rect value that subclasses can used to initalize new items, when 
both size and position are undetermined in the initialization context. */
+ (NSRect) defaultItemRect
{
	return NSMakeRect(0, 0, 50, 50);
}

- (void) dealloc
{
	if (_decoratorItem != nil)
	{
		 /* Unset the decorated item weak reference on the decorator side */
		[self setDecoratorItem: nil];
	}
	DESTROY(_view);

	[super dealloc];
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
	/* Note whether the next release call will deallocate the receiver, because 
	   once the receiver is deallocated you have no way to safely learn if self
	   is still valid or not.
	   Take note the retain count is NSExtraRefCount plus one. */
	BOOL isDeallocated = (NSExtraRefCount(self) == 0);
	BOOL hasRetainCycle = (_view != nil);

#ifdef GNUSTEP
	[super release];
#else
	if (NSDecrementExtraRefCountWasZero(self))
		[self dealloc];
#endif

	/* Tear down the retain cycle owned by the receiver.
	   By releasing us, we release _view.
	   If we got deallocated by [super release], self and _view are now
	   invalid and we must never use them (by sending a message for example).  */
	if (hasRetainCycle && isDeallocated == NO
	  && NSExtraRefCount(self) == 0 && NSExtraRefCount(_view) == 0)
	{
		DESTROY(self);
	}
}

/* <override-dummy /> 
Returns whether the receiver uses flipped coordinates.

Default implementation returns YES. */
- (BOOL) isFlipped
{
	return YES;
}

/* Returns the supervisor view associated with the receiver. The supervisor view 
is a wrapper view around the receiver view (see -[ETLayoutItem view]). 

You shouldn't use this method unless you write a subclass.

The supervisor view is used internally by EtoileUI to support views or widgets 
provided by the widget backend (e.g. AppKit) within a layout item tree. See 
also ETView. */
- (id) supervisorView
{
	return _view;
}

/** Sets the supervisor view associated with the receiver. 

You should never need to call this method.

See also -supervisorView:. */
- (void) setSupervisorView: (ETView *)supervisorView
{
	 /* isFlipped is also sync in -setFlipped: (see subclasses) */
	[supervisorView setFlipped: [self isFlipped]];
	[supervisorView setLayoutItemWithoutInsertingView: (id)self];
	ASSIGN(_view, supervisorView);

	BOOL hasDecorator = (_decoratorItem != nil);
	if (hasDecorator)
	{
		id parentView = [[self displayView] superview];
		/* Usually results in [_decoratorItem setView: supervisorView] */
		[_decoratorItem handleDecorateItem: self supervisorView: [self supervisorView] inView: parentView];
	}
}

/** Returns the display view of the receiver. The display view is the last
supervisor view of the decorator item chain.

You can retrieve the outermost decorator by calling -lastDecoratorItem. */
- (ETView *) displayView
{
	ETUIItem *decorator = self;
	ETView *supervisorView = [self supervisorView];

	while (decorator != nil)
	{
		if ([decorator supervisorView] == nil)
			return supervisorView;

		supervisorView = [decorator supervisorView];
		decorator = [decorator decoratorItem];
	}

	return supervisorView;
}

- (NSRect) convertDisplayRect: (NSRect)rect 
        toAncestorDisplayView: (NSView **)aView 
                     rootView: (NSView *)topView
                   parentItem: (ETLayoutItem *)parent
{
	NSView *displayView = [self supervisorView];
	NSRect decorationBounds = ETMakeRect(NSZeroPoint, [self decorationRect].size);
	BOOL canDisplayRect = (displayView != nil && NSContainsRect(decorationBounds, rect)) ;
	BOOL hasReachedWindow = (displayView == topView);

	if (canDisplayRect || hasReachedWindow)
	{
		*aView = displayView;
		return rect;
	}
	else /* Recurse up in the tree until rect is completely enclosed by the receiver */
	{
		if (_decoratorItem != nil) /* First traverse the decorator chain */
		{
			NSRect rectInDecorator = [_decoratorItem convertDecoratorRectFromContent: rect];
			return [_decoratorItem convertDisplayRect: rectInDecorator 
			                    toAncestorDisplayView: aView 
			                                 rootView: topView 
			                               parentItem: parent];
		}
		else if (parent != nil) /* Then move up to the parent item */
		{
			NSRect rectInParent = [[self firstDecoratedItem] convertRectToParent: rect];
			return [parent convertDisplayRect: rectInParent toAncestorDisplayView: aView rootView: topView parentItem: parent];
		}
		else
		{
			// NOTE: -convertDisplayRect:XXX invoked on nil can return a rect
			// with random values rather than a zero rect.
			return NSZeroRect;
		}
	}
}

/** <override-subclass /> */
- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view
{

}

/** <override-subclass />

To be implemented... */
- (void) beginEditingUI
{

}

/** Returns the item that decorates the receiver.

From the returned item viewpoint, the receiver is the decorated item. */
- (ETDecoratorItem *) decoratorItem
{
	return _decoratorItem;
}

- (void) setFirstDecoratedItemFrame: (NSRect)frame
{
	if ([[self firstDecoratedItem] isLayoutItem])
		[[self firstDecoratedItem] setFrame: frame];
}

/** Sets the item that decorates the receiver.

A decorator can customize the item view border without the layout item tree 
structure, this way the tree structure maintains a very tight mapping with the 
model graph and remains semantic. */
- (void) setDecoratorItem: (ETDecoratorItem *)decorator
{
	if ([decorator isEqual: _decoratorItem])
		return;

	if ([decorator canDecorateItem: self] == NO && decorator != nil)
		return;

	/* Memorize our decorator to let the new decorator inserts itself into it */
	ETDecoratorItem *existingDecorator = _decoratorItem;
	/* Item could have a decorator, so [[item supervisorView] superview] would
	   not give the parent view in this case but the decorator view. */
	id parentView = [[self displayView] superview];
	NSRect existingFrame = [[self lastDecoratorItem] decorationRect];
	
	[[self displayView] removeFromSuperview];

	RETAIN(existingDecorator);
	RETAIN(decorator);

	ASSIGN(_decoratorItem, decorator);

	/* Dismantle existing decorator */
	[existingDecorator setDecoratedItem: nil];
	[existingDecorator handleUndecorateItem: self inView: parentView];
	/* Set up new decorator */
	[decorator setFlipped: [self isFlipped]];
	[decorator setDecoratedItem: self];
	[decorator handleDecorateItem: self
	               supervisorView: [self supervisorView]
	                       inView: parentView];

	/* When a decorator view has been resized, moved or removed, we must reflect
	   it on the decorated view which may not have been resized.
	   Not updating the frame is especially visible when the view is used as a 
	   document view within a scroll view and this scroll view frame is modified. 
	   Switching to a layout view reveals the issue even more clearly. */
	[self setFirstDecoratedItemFrame: existingFrame];
	[self didChangeDecoratorOfItem: self];

	RELEASE(existingDecorator);
	RELEASE(decorator);
}

/** Returns the outermost item in the decorator chain. */
- (id) lastDecoratorItem
{
	if (_decoratorItem != nil)
	{
		return [_decoratorItem lastDecoratorItem];
	}
	else
	{
		return self;
	}
}

/** <override-subclass />
Returns the item decorated by the receiver. */
- (ETUIItem *) decoratedItem
{
	return nil;
}

/** Returns the innermost item in the decorator chain. */
- (id) firstDecoratedItem
{
	id decorator = [self decoratedItem];
	
	if (decorator != nil)
	{
		return [decorator firstDecoratedItem];
	}
	else
	{
		return self;
	}
}

/** <override-dummy />
ETLayoutItem and ETDecoratorItem instances accept all decorator kinds.

You can override this method to decide otherwise in your subclasses. For 
example, ETWindowItem returns NO because a window unlike a view cannot 
be decorated. */
- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item
{
	return YES;
}

/** <override-dummy />
Returns the decoration rect associated with the receiver. */
- (NSRect) decorationRect
{
	return [[self supervisorView] frame];
}

/* Framework Private */

/** <override-dummy /> */
- (void) didChangeDecoratorOfItem: (ETUIItem *)item
{

}

/** <override-dummy />
Returns whether the geometry between the receiver and the supervisor view 
shoud be synced.

This method is used internally by ETLayoutItem and ETView. You are not expected 
to override it in subclasses you write. */
- (BOOL) shouldSyncSupervisorViewGeometry
{
	return NO;
}

@end


@implementation ETDecoratorItem

/** Do not use. May be remove later. */
+ (id) item
{
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

/** Returns whether the view used by the receiver is a widget. 

By default, returns NO. */
- (BOOL) usesWidgetView
{
	return YES;
}

// TODO: The be used when EtoileUI will draw everything by itself including 
// the views without relying on the view hierarchy machinery.
- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view
{
	//NSRect rectInContent = [self convertDecoratorRectToContent: dirtyRect];
	//[_decoratedItem render: inputValues dirtyRect: rectInContent inView: view];
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
clipped. The visible content rect is expressed in the receiver coordinate space. 
See also -contentRect.

When the content is not clipped by the receiver, -visibleContentRect and 
-contentRect are equal.

With ETDecoratorItem, the content rect and the visible content rect and equal, 
because the content is resized rather than clipped when a decorator is 
resized. However subclasses can decide otherwise (e.g. ETScrollableAreaItem). */
- (NSRect) visibleContentRect
{
	return [[[self supervisorView] wrappedView] frame];
}

/** Returns the content rect expressed in the receiver coordinate space (the 
area that lies inside -decorationRect).

The receiver content rect is equal to [[self decoratedItem] decorationRect]. */
- (NSRect) contentRect
{
	NSRect contentRect = [[[self supervisorView] wrappedView] frame];

	/*NSAssert(NSEqualRects([_decoratedItem decorationRect], contentRect), 
		@"The content rect must be equal to the decorated item decoration rect");*/

	return contentRect;
}

/** Returns a rect expressed in the receiver coordinate space equivalent to
rect parameter expressed in the receiver content coordinate space.

The receiver coordinate space is the area that lies inside -decorationRect.
The receiver content coordinate space is the area that lies inside -contentRect.

See also -convertDecoratorRectToContent:. */
- (NSRect) convertDecoratorRectFromContent: (NSRect)rectInContent
{
	NSRect rectInDecorator = rectInContent;

	rectInDecorator.origin.x += [self contentRect].origin.x;
	rectInDecorator.origin.y += [self contentRect].origin.y;

	return rectInDecorator;
}

/** Returns a rect expressed in the receiver content coordinate space equivalent 
torect parameter expressed in the receiver coordinate space.

For extra details, see -convertDecoratorRectFromContent:. */
- (NSRect) convertDecoratorRectToContent: (NSRect)rectInDecorator
{
	NSRect rectInContent = rectInDecorator;

	rectInContent.origin.x -= [self contentRect].origin.x;
	rectInContent.origin.y -= [self contentRect].origin.y;

	return rectInContent;
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
												 layoutItem: (id)self];
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
             supervisorView: (ETView *)decoratedView 
                     inView: (ETView *)parentView 
{
	[self setDecoratedView: decoratedView];
	
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

To take over the outermost decorator removal from the parent view, pass nil 
as parentView. This case is only useful when the receiver is currently the last 
decorator.

Take in account that parentView can be nil. */
- (void) handleUndecorateItem: (ETUIItem *)item inView: (ETView *)parentView
{
	ETDebugLog(@"Handle undecorate with parent %@ parent view %@ item "
		"display view %@", [item parentItem], parentView, [item displayView]);

	[self setDecoratedView: nil];
	[[self displayView] removeFromSuperview];
	/* Insert the new item display view into the parent view */
	[parentView addSubview: [item supervisorView]];
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
		[self handleSetDecorationRect: rect];
	}
	else
	{
		[_decoratorItem decoratedItemRectChanged: [self convertDecoratorRectFromContent: rect]];
	}

	return rect.size;
}

@end
