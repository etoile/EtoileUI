/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2009
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETUIItem.h"
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETView.h"
#import "ETScrollableAreaItem.h"
#import "ETWindowItem.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETUIItem

/** Returns a rect value that subclasses can used to initalize new items, when 
both size and position are undetermined in the initialization context. */
+ (NSRect) defaultItemRect
{
	return NSMakeRect(0, 0, 50, 50);
}

/** <override-dummy />
Returns whether the view used by the receiver is a widget. 

By default, returns NO. */
- (BOOL) usesWidgetView
{
	return NO;
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

- (id) copyWithZone: (NSZone *)aZone
{
	ETUIItem *newItem = [super copyWithZone: aZone];
	ETDecoratorItem *decorator = _decoratorItem;

	RETAIN(decorator);
	[self setDecoratorItem: nil];

	newItem->_view = [_view copyWithZone: aZone]; // -release?
	[newItem->_view setLayoutItemWithoutInsertingView: (id)newItem];

	// NOTE: The decorator set up below must mirror -setDecoratorItem:.
	ETDecoratorItem *decoratorCopy = [decorator copyWithZone: aZone];
	[decoratorCopy handleDecorateItem: newItem 
	                   supervisorView: [newItem supervisorView] 
	                           inView: nil];
	[decoratorCopy setDecoratedItem: newItem];
	newItem->_decoratorItem = decoratorCopy;

	[self setDecoratorItem: decorator];
	RELEASE(decorator);

	return newItem;
}

- (NSArray *) properties
{
	NSArray *properties = A(kETFlippedProperty, kETDecoratorItemProperty, 
		kETDecoratedItemProperty, @"firstDecoratedItem", @"lastDecoratorItem", 
		@"decorationRect", @"isDecoratorItem", @"isWindowItem", 
		@"isScrollableAreaItem", @"enclosingItem", @"supervisorView", 
		@"shouldSyncSupervisorViewGeometry", @"usesWidgetView");
	return [[super properties] arrayByAddingObjectsFromArray: properties];
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

// TODO: Would be better to only allow -setSupervisorView: to be called once 
// and prevents supervisorView replacement. Presently developers must not 
// overlook this possibility when they write a subclass, otherwise weird issues 
// might occur.

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

/** Looks up the view which can display a rect by climbing up the layout 
item tree until a display view which contains rect is found. This view is 
returned through the out parameter aView and the returned value is the dirty 
rect in the coordinate space of aView.

This method hooks the layout item tree display mechanism into the AppKit view 
hierarchy which implements the underlying display support.

You should never need to call this method, unless you write a subclass which 
needs some special redisplay policy. */
- (NSRect) convertDisplayRect: (NSRect)rect 
        toAncestorDisplayView: (NSView **)aView 
                     rootView: (NSView *)topView
                   parentItem: (ETLayoutItemGroup *)parent
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
			return [parent convertDisplayRect: rectInParent toAncestorDisplayView: aView rootView: topView parentItem: [parent parentItem]];
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
- (void) render: (NSMutableDictionary *)inputValues 
      dirtyRect: (NSRect)dirtyRect 
      inContext: (id)ctxt
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
	/* Take in account the case where both sides are nil unlike -isEqual: */
	if (decorator == _decoratorItem)
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

	/* Dismantle existing decorator */
	ASSIGN(_decoratorItem, nil);
	[existingDecorator setDecoratedItem: nil];
	[existingDecorator handleUndecorateItem: self 
	                         supervisorView: [self supervisorView]
	                                 inView: parentView];
	/* Set up new decorator */
	[decorator setFlipped: [self isFlipped]];
	[decorator handleDecorateItem: self
	               supervisorView: [self supervisorView]
	                       inView: parentView];
	// NOTE: We disconnect decorator and decorated item as early as 
	// possible and we reconnect them as late as possible to prevent any 
	// accidental synchronization to be propagated through the decorator 
	// chain which might be in an invalid state between the two ASSIGN. 
	// e.g. a decorated item whose supervisor isn't yet inserted 
	// in its decorator item supervisor view and at the same time an 
	// unexpected frame change on the decorated item or its supervisor view  
	// that triggers -decoratedItemRectChanged:... -visibleContentRect 
	// could then wrongly return a zero rect.
	[decorator setDecoratedItem: self];
	ASSIGN(_decoratorItem, decorator);

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

/** Traverses the decorator chain to remove the given decorator item.

This method won't remove other decorator items in the chain, even if they follow 
the removed one. */
- (void) removeDecoratorItem: (ETDecoratorItem *)aDecorator
{
	if ([aDecorator isEqual: _decoratorItem])
	{
		[self setDecoratorItem: [_decoratorItem decoratorItem]];
	}
	else
	{
		[_decoratorItem removeDecoratorItem: aDecorator];
	}
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
	BOOL hasDecorator = (_decoratorItem != nil);

	if (hasDecorator)
	{
		/* When a decorator (like ETWindowItem) doesn't use a supervisor view,
		   [[self supervisorView] frame] won't transparently match
		   [[_decoratorItem supervisorView] wrappedView] frame] as expected. */
		return [_decoratorItem contentRect];
	}
	else
	{
		return [[self supervisorView] frame];
	}
}

/** Returns whether the receiver is a decorator item.

See ETDecoratorItem and also -[NSObject(EtoileUI) isLayoutItem]. */
- (BOOL) isDecoratorItem
{
	return [self isKindOfClass: [ETDecoratorItem class]];
}

/** Returns whether the receiver is a window decorator item. 

See ETWindowItem. */
- (BOOL) isWindowItem
{
	return [self isKindOfClass: [ETWindowItem class]];
}

/** Returns whether the receiver is scrollable area decorator item. 

See ETScrollableAreaItem. */
- (BOOL) isScrollableAreaItem
{
	return [self isKindOfClass: [ETScrollableAreaItem class]];
}

/* Enclosing Item */

/** Returns the first item which contains the receiver area. 

When a decorator item is set on the receiver, it is returned, otherwise the 
parent item is returned. When no parent item is available, nil is returned. */
- (id) enclosingItem
{
	ETUIItem *firstDecoratedItem = [self firstDecoratedItem];

	if (_decoratorItem != nil)
	{
		return _decoratorItem;
	}
	else if ([firstDecoratedItem isLayoutItem])
	{
		return [(ETLayoutItem *)firstDecoratedItem parentItem];
	}

	return nil;
}

/** Returns a rect expressed in the enclosing item content coordinate space 
equivalent to the given rect expressed in the receiver coordinate space. */
- (NSRect) convertRectToEnclosingItem: (NSRect)aRect
{
	id enclosingItem = [self enclosingItem];

	if (enclosingItem == nil)
		return aRect;

	// NOTE: Instead of the type-based switch below, we could rely on 
	// polymorphism with -[enclosingItem convertRectFromEnclosedItem: self].
	// However it doesn't seem worth the complexity since no new subtypes are  
	// going to be introduced in the switch logic at a later point.
	if ([enclosingItem isLayoutItem])
	{
		ETLayoutItem *firstDecoratedItem = [self firstDecoratedItem];
		NSParameterAssert([firstDecoratedItem isLayoutItem]);

		/* The last decorator coordinate space is identical to the receiver 
		   coordinate space, hence the rect to convert expressed in the former  
		   is also valid in the latter. */
		return [firstDecoratedItem convertRectToParent: aRect];
	}
	else if ([enclosingItem isDecoratorItem])
	{
		return [enclosingItem convertDecoratorRectFromContent: aRect];
	}
	else
	{
		ASSERT_INVALID_CASE;
		return ETNullRect;
	}
}

/** Returns a point expressed in the enclosing item content coordinate space 
equivalent to the given point expressed in the receiver coordinate space. */
- (NSPoint) convertPointToEnclosingItem: (NSPoint)aPoint
{
	return [self convertRectToEnclosingItem: ETMakeRect(aPoint, NSZeroSize)].origin;
}

/* Actions */

/** Returns the next responder in the responder chain. 

The next responder is the enclosing item unless specified otherwise. */
- (id) nextResponder
{
	// TODO: Verify that -enclosingItem is not too slow.
	return [self enclosingItem];
}

/* Framework Private */

/** <override-dummy /> */
- (void) didChangeDecoratorOfItem: (ETUIItem *)item
{

}


/* Default implementation inherited by ETLayoutItem but overriden by ETDecoratorItem */
- (ETUIItem *) decoratedItemAtPoint: (NSPoint)aPoint
{
	NSRect bounds = ETMakeRect(NSZeroPoint, [self decorationRect].size);
	BOOL isInside = NSMouseInRect(aPoint, bounds, [self isFlipped]);

	return (isInside ? self : (ETUIItem *)nil);
}

/** Returns the innermost decorator item whose content rect contains aPoint.
aPoint must be expressed in the receiver coordinate space.

Will return self, when the receiver is the matched innermost decorator, and nil 
when the point is not located inside the receiver.  */
- (ETUIItem *) decoratorItemAtPoint: (NSPoint)aPoint
{
	return [[self lastDecoratorItem] decoratedItemAtPoint: aPoint];
}

/* Framework Private */

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

