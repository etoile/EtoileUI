/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/Macros.h>
#import "ETInstrument.h"
#import "ETEvent.h"
#import "ETEventProcessor.h"
#import "ETGeometry.h"
#import "ETLayoutItem+Events.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETLayoutItemGroup.h"
#import "ETApplication.h"
#import "ETInstruments.h"
#import "ETLayout.h"
#import "ETView.h"
#import "ETCompatibility.h"

@interface ETInstrument (Private)
- (BOOL) makeFirstResponder: (id)aResponder inWindow: (NSWindow *)aWindow;
- (void) setHoveredItemStack: (NSMutableArray *)itemStack;
@end


@implementation ETInstrument

static NSMutableSet *instrumentClasses = nil;

/** Initializes ETInstrument class by preparing the registered instrument classes. */
+ (void) initialize
{
	if (self == [ETInstrument class])
	{
		instrumentClasses = [[NSMutableSet alloc] init];
		FOREACH([self allSubclasses], subclass, Class)
		{
			[self registerInstrumentClass: subclass];
		}
	}
}

+ (NSString *) typePrefix
{
	return @"ET";
}

+ (NSString *) baseClassName
{
	return @"Instrument";
}

/** Registers the given class as an instrument class available to interact with 
the UI.

Raises an invalid argument exception if instrumentClass isn't a subclass of 
ETInstrument. */
+ (void) registerInstrumentClass: (Class)instrumentClass
{
	if ([instrumentClass isSubclassOfClass: [ETInstrument class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Class %@ must be a subclass of ETInstrument to get "
		                    @"registered as an instrument class.", instrumentClass, nil];
	}

	[instrumentClasses addObject: instrumentClass];
	// TODO: Make a class instance available as an aspect in the aspect 
	// repository.
}

/** Returns all the instrument classes available to interact with the UI. */
+ (NSSet *) registeredInstrumentClasses
{
	return AUTORELEASE([instrumentClasses copy]);
}

+ (NSArray *) registeredInstruments
{
	// FIXME: Implement
	return nil;
}

/** Shows a palette which lists all the registered instruments. 

The palette is a layout item whose represented object is the ETInstrument class 
object. */
+ (void) show: (id)sender
{
	// FIXME: Implement
}

static ETInstrument *activeInstrument = nil;

/** Returns the active instrument through which the events are dispatched in the 
layout item tree. */
+ (id) activeInstrument
{
	if (activeInstrument == nil)
	{
		[self setMainInstrument: [ETArrowTool instrument]];
		ASSIGN(activeInstrument, [self mainInstrument]);
	}

	return activeInstrument;
}

/** Returns the instrument attached to the hovered item through its layout.

This insturment will usually be activated if the hovered item is clicked (on 
mouse down precisely). */
+ (id) activatableInstrument
{
	return [[self activeInstrument] lookUpInstrumentInHoveredItemStack];;
}

static ETInstrument *mainInstrument = nil;

/** Returns the instrument to be used as active instrument when no other 
instruments can be looked up and activated.

The main instrument is implicitly attached to the root item in the layout item 
tree. */
+ (id) mainInstrument
{
	return mainInstrument;
}

/** Sets the instrument to be be used as active instrument when no other 
instruments can be looked up and activated.

See also -mainInstrument. */
+ (void) setMainInstrument: (id)anInstrument
{
	ASSIGN(mainInstrument, anInstrument);
}

/** Returns a new autoreleased instrument instance. */
+ (id) instrument
{
	return AUTORELEASE([[self alloc] init]);
}

- (id) init
{
	SUPERINIT

	_hoveredItemStack = nil; /* Lazily initialized */
	[self setCursor: [NSCursor arrowCursor]];

	return self;
}

- (void) dealloc
{

	DESTROY(_hoveredItemStack); 
	DESTROY(_firstKeyResponder); 
	DESTROY(_firstMainResponder);
	// NOTE: _layoutOwner is a weak reference
	if ([_targetItem isEqual: _layoutOwner] == NO) /* See -setTargetItem: */
	{
		DESTROY(_targetItem);
	}
	DESTROY(_cursor);

	[super dealloc];
}

// TODO: For each document set the editor instrument. Eventually offer a 
// delegate method either through ETInstrument or ETDocumentManager to give 
// more control over this...
+ (void) setEditorInstrument: (id)anInstrument
{
	//[documentLayout setAttachedInstrument: anInstrument];
}

// TODO: Think about...
+ (void) setEditorTargetItems: (NSArray *)items
{

}

/** Returns the layout item on which the receiver is currently acting.

The target item is very often different from the hit item returned by 
-hitTestWithEvent:. For example, when you select layout items with a selection 
rectangle (see ETSelectTool), the target item is where the mouse down occured, 
but as the selection rectangle is resized by the dragging, the mouse might enter 
and exit descendant items. Each time a descendant items is hovered or the mouse 
is outside of the boundaries of the target item, the hit item won't match the 
target item.

By default, the target item is the item bound to the -ownerLayout. This bound 
item is named the layout context in ETLayout.

See also -setTargetItem:. */
- (ETLayoutItem *) targetItem
{
	// TODO: Would be better to observe an ETLayoutContextDidChangeNotification 
	if (_targetItem == nil && [(id)[[self layoutOwner] layoutContext] isLayoutItem])
	{
		[self setTargetItem: (ETLayoutItem *)[[self layoutOwner] layoutContext]];
	}
	return _targetItem;
}

/** Sets the layout item on which the receiver is currently acting.

If you write a tool subclass which interprets mouse move or drag events in its 
own way, descendant items might be entered and exited. By setting a target item 
at the beginning of the motion, you can track what is the background item 
targeted by the tool and the event coordinates relative to this target item. 
For example, a brush tool can create a stroke that crosses one or several layout 
items, yet every stroke dabs must normally be applied/drawn in only one target 
item. In case the stroke motion ends elsewhere than in the target item, the 
stroke should similarly still be inserted in the target item (where the brush 
stroke started with the mouse down event).

You easily set a target item by overriding -hitTestWithEvent:inItem:.

See also -targetItem. */
- (void) setTargetItem: (ETLayoutItem *)anItem
{
	/* To avoid a retain cycle, we handle specially the case where the target 
	   item is the layout context which owns the layout which owns us 
	   (aka -ownerLayout).
	   
	   Here is what the ownership chain looks like with...
	   x --> y : x owns/retains y
	   
	   layout context --> layout --> instrument
	         |                           |
			 v                           |
		child/target item <---------------
		
		We first check that _targetItem and anItem are not the same, otherwise 
		RELEASE(_targetItem) would result in an extra release.
	 */
	if ([anItem isEqual: _targetItem])
		return;

	ASSIGN(_targetItem, anItem);


	if ([_targetItem isEqual: [self layoutOwner]])
		RELEASE(_targetItem);
}

/** Sets the first responder window based on aResponder location in the layout 
item tree.

This method calls either -makeFirstKeyResponder: or -makeFirstMainResponder:. */
- (BOOL) makeFirstResponder: (id)aResponder
{
	NSWindow *window = nil;

	if ([aResponder isLayoutItem])
	{
		window = [[aResponder closestAncestorDisplayView] window];
	}
	else if ([aResponder isKindOfClass: [NSView class]])
	{
		window = [aResponder window];
	}
	else if ([aResponder isKindOfClass: [NSWindow class]])
	{
		window = aResponder;
	}

	ETDebugLog(@"Try make first responder: %@", aResponder);

	return [self makeFirstResponder: aResponder inWindow: window];
}

/** Sets the first responder in the current key window. */
- (BOOL) makeFirstKeyResponder: (id)aResponder
{
	return [self makeFirstResponder: aResponder inWindow: [ETApp keyWindow]];
}

/** Sets the first responder in the current main window. */
- (BOOL) makeFirstMainResponder: (id)aResponder
{
	return [self makeFirstResponder: aResponder inWindow: [ETApp mainWindow]];
}

- (BOOL) makeFirstResponder: (id)aResponder inWindow: (NSWindow *)aWindow
{
	if (aWindow == nil)
	{
		ETLog(@"WARNING: Try to make first responder %@ wich is not currently"
			"located in a window", aResponder);
		return NO;
	}

	id responder = aResponder;

	/* -makeFirstResponder: argument must a NSResponder, otherwise the receiver 
	   window becomes the first responder on the AppKit side. We solve the issue 
	   by wrapping the responder in a proxy when needed. */
	if ([responder isKindOfClass: [NSResponder class]] == NO)
		responder = [ETFirstResponderProxy responderProxyWithObject: aResponder];

	BOOL isNowFirstResponder = [aWindow makeFirstResponder: responder];
	/* We must retain the responder because -[NSWindow makeFirstResponder:] 
	   doesn't do it and nobody will retain ETFirstResponderProxy instances 
	   beside us. */
	if (isNowFirstResponder)
	{
		if ([_firstMainResponder isLayoutItem])
		{
			[_firstMainResponder setNeedsDisplay: YES];
		}
		ASSIGN(_firstMainResponder, responder);
		if ([responder isLayoutItem])
		{
			[responder setNeedsDisplay: YES];
		}
	}

	return isNowFirstResponder;
}

/** Returns the first responder in the current key window. */
- (id) firstKeyResponder
{
	id responder = [[ETApp keyWindow] firstResponder];
	
	if ([responder isKindOfClass: [ETFirstResponderProxy class]])
		responder = [responder object];
		
	return responder;
}

/** Returns the first responder in the current main window. */
- (id) firstMainResponder
{
	id responder = [[ETApp mainWindow] firstResponder];
	
	if ([responder isKindOfClass: [ETFirstResponderProxy class]])
		responder = [responder object];
		
	return responder;
}

- (BOOL) isFirstKeyResponderStillValid
{
	return ([[ETApp keyWindow] firstResponder] == [ETApp keyWindow]);
}

/** Returns the item which is decorated by the key window in the layout item tree.

The key window can be retrieved through the decorator item with 
[[[[ETInstrument activeInstrument] keyItem] windowDecoratorItem] window]. */
- (ETLayoutItem *) keyItem
{
	id contentView = [[ETApp keyWindow] contentView];

	if ([contentView respondsToSelector: @selector(layoutItem)] == NO)
		return nil;

	return [contentView layoutItem];
}

/** Returns the item which is decorated by the main window in the layout item tree.

The main window can be retrieved through the decorator item with 
[[[[ETInstrument activeInstrument] mainItem] windowDecoratorItem] window]. */
- (ETLayoutItem *) mainItem
{
	id contentView = [[ETApp mainWindow] contentView];

	if ([contentView respondsToSelector: @selector(layoutItem)] == NO)
		return nil;

	return [contentView layoutItem];
}

/** <override-never />
Updates the cursor with the one provided by the activatable instrument.

You should never to call this method, only ETEventProcessor is expected to use 
it. */
+ (void) updateCursorIfNeeded
{
	[[(ETInstrument *)[self activatableInstrument] cursor] set];
}

/** <override-never />
Updates the active instrument with a new one looked up in the active instrument 
hovered item stack.

You should never to call this method, only ETEventProcessor is expected to use 
it. 

Take a look at -didBecomeActive and -didBecomeInactive to react to activation 
and deactivation in your ETInstrument subclasses. */
+ (ETInstrument *) updateActiveInstrumentWithEvent: (ETEvent *)anEvent
{
	ETInstrument *instrumentToDeactivate = [ETInstrument activeInstrument];
	ETInstrument *instrumentToActivate = [instrumentToDeactivate lookUpInstrumentInHoveredItemStack];

	if ([instrumentToActivate isEqual: instrumentToDeactivate])
		return instrumentToActivate;

	ETDebugLog(@"Update active instrument to %@", instrumentToActivate);

	[instrumentToActivate setHoveredItemStack: [instrumentToDeactivate hoveredItemStack]];
	[instrumentToDeactivate setHoveredItemStack: nil]; /* To detect invalid item stack more easily */
	
	RETAIN(instrumentToDeactivate);
	ASSIGN(activeInstrument, instrumentToActivate);

	[instrumentToDeactivate didBecomeInactive];
	[instrumentToActivate didBecomeActive];

	RELEASE(instrumentToDeactivate);

	return instrumentToActivate;
}

/** Returns the hovered item stack that is used internally to:
<list>
<item>track enter and exit in each item</item>
<item>look up the instrument to activate</item>
</list>
ETEventProcessor uses it to synthetize enter/exit events.

You should never need to use this method. */
- (NSMutableArray *) hoveredItemStack
{
	/* We do a lazy initialization to eliminate an endless recursion when the 
	   instrument is initialized inside -[ETWindowLayout init] which is 
	   initiated by -[ETLayoutItem windowGroup]. */
	if (_hoveredItemStack == nil)
		_hoveredItemStack = [[NSMutableArray alloc] initWithObjects: [self hitItemForNil], nil];

	NSParameterAssert([_hoveredItemStack firstObject] == [self hitItemForNil]);

	return _hoveredItemStack;
}

- (void) setHoveredItemStack: (NSMutableArray *)itemStack
{
	NSParameterAssert(itemStack == nil || [itemStack firstObject] == [self hitItemForNil]);
	ASSIGN(_hoveredItemStack, itemStack);
}

/** Looks up and returns the instrument to be activated in the current hovered 
item stack.

The stack is traversed upwards to the root item. The traversal ends on the 
first layout with an instrument attached to it.

The stack is never empty because the pointer never exits the root item which 
covers the whole screen. 

You should rarely need to override this method. */
- (ETInstrument *) lookUpInstrumentInHoveredItemStack
{
	ETInstrument *foundInstrument = nil;
	/* The last/top object is the instrument at the lowest/deepest level in the 
	   layout item tree. */
	NSEnumerator *e = [[self hoveredItemStack] reverseObjectEnumerator];
	ETLayoutItem *item = nil;

	while ((item = [e nextObject]) != nil)
	{
		ETDebugLog(@"Look up instrument at level %@ in hovered item stack", item);

		/* The top item can be an ETLayoutItem instance */
		if ([item isGroup] == NO)
			continue;
		
		foundInstrument = [[(ETLayoutItemGroup *)item layout] attachedInstrument];
		if (foundInstrument != nil)
			break;
	}

	// NOTE: In case we attach a non-removable instrument to the root item, we 
	// could set foundInstrument to nil.
	BOOL overRootItem = (foundInstrument == nil);
	if (overRootItem)
		foundInstrument = [[self class] mainInstrument];
	
	NSParameterAssert(foundInstrument != nil);

	return foundInstrument;
}

// NOTE: The hovered items stack is rebuilt each time we enter a handle (because 
// the root item in the layout is never present in the stack).
- (void) rebuildHoveredItemStackUpToItem: (ETLayoutItem *)topItem
{
	NSParameterAssert(topItem != nil);

	ETLayoutItem *item = topItem;
	NSMutableArray *newStack = [NSMutableArray array];
	
	do
	{
		[newStack insertObject: item atIndex: 0];
		item = [item parentItem];
	} while (item != nil);

	// FIXME: Work around inspectors and other windows whose content view 
	// has a layout item with no parent, when it should be a window layer child.
	if ([newStack firstObject] != [ETLayoutItem windowGroup])
	{
		[newStack insertObject: [ETLayoutItem windowGroup] atIndex: 0];
	}

	[self setHoveredItemStack: newStack];

	ETDebugLog(@" + Rebuilt hovered item stack\n %@", newStack);
}

- (void) rebuildHoveredItemStackIfNeededForEvent: (ETEvent *)anEvent
{
	ETLayoutItem *hoveredItem = [anEvent layoutItem];
	ETLayoutItem *lastHoveredItemParent = [[self hoveredItemStack] lastObject];
	
	BOOL notMovedBackToParent = (lastHoveredItemParent != hoveredItem);
	if (notMovedBackToParent)
	{
		/* If two child items are contiguous or overlap, then on exit we don't 
		   traverse their parent area before moving into the other child item. 
		   However their parent item must be the same, the contrary means we 
		   have lost events or that the two child items are contiguous but 
		   belong to two contiguous yet different parent items. In both cases, 
		   we rebuild the hovered item stack rather than trying to cope with 
		   such complex border cases.
		   Fast movements, lost events and very tight nesting of items are our
		   worst ennemies ;-) */
		BOOL hasLostMoveEventsOrParentMismatch = (lastHoveredItemParent != [hoveredItem parentItem]);

		 /* Hovered item stack (minus the item we just pop) does not match our 
			event location. */
		if (hasLostMoveEventsOrParentMismatch)
			[self rebuildHoveredItemStackUpToItem: hoveredItem];
	}
}

/** Sets the layout to which the instrument is attached to.

aLayout has ownership over the receiver, so it won't be retained. */
- (void) setLayoutOwner: (ETLayout *)aLayout
{
	_layoutOwner = aLayout;
	if ([(id)[aLayout layoutContext] isLayoutItem])
		[self setTargetItem: (ETLayoutItem *)[aLayout layoutContext]];
}

/** Returns the layout to which the instrument is attached to. */
- (ETLayout *) layoutOwner
{
	return _layoutOwner;
}

/** Called when the instrument becomes active, usually when the pointer enters 
    in an area that falls under the control of a layout, to which this 
	instrument is attached to. */
- (void) didBecomeActive
{
	ETDebugLog(@"Instrument %@ did become active", self);
}

/** Called when the instrument becomes inactive, usually when the pointer exists 
    the area that falls under the control of a layout, to which this instrument 
	is attached to. */
- (void) didBecomeInactive
{
	ETDebugLog(@"Instrument %@ did become inactive", self);
}

/** Returns the root item that -hitTestWithEvent: is expected to return when 
the mouse is not within in a window area. For now, return -windowGroup as 
-[ETApplication layoutItem] does. */
- (ETLayoutItem *) hitItemForNil
{
	return [ETLayoutItem windowGroup];
}

/** Returns the layout item hovered at the mouse location reported by anEvent.

Never returns nil. If the mouse isn't over a window, the layout item that 
plays the role of the local root item is returned. If the mouse is over a 
window whose content view isn't bound to a layout item, then this window is 
ignored and the local root item is also returned. */
- (ETLayoutItem *) hitTestWithEvent: (ETEvent *)anEvent
{
	ETLayoutItem *testedItem = [[anEvent contentItem] firstDecoratedItem];
	ETLayoutItem *hitItem = nil;
	BOOL isImplicitWindowLayer = (testedItem == nil);

	/* Mouse is not over a window or the content view is not a container. */
	if (isImplicitWindowLayer)
	{
		hitItem = [self hitItemForNil];
		[anEvent setLayoutItem: hitItem];
		[anEvent setLocationInLayoutItem: [anEvent location]];
		return hitItem;
	}

	/* Even if the content view is flipped, -locationInWindow returns a point 
	   in a non-flipped coordinate space.
	   WARNING: Any transform applied to the content view probably need to be 
	   applied to the point returned by -locationInWindow... */
	NSPoint contentViewRelativePoint = [anEvent locationInWindowItem];

	hitItem = [self hitTest: contentViewRelativePoint
	              withEvent: anEvent
	                 inItem: (ETLayoutItemGroup *)testedItem];
	[anEvent setLayoutItem: hitItem];

	NSParameterAssert(hitItem != nil && [anEvent layoutItem] == hitItem);

	return hitItem;
}

/* Does the hit test in:
- explicit children when the item is an ETLayoutItemGroup
- implicit children when the item has a layout (both ETLayoutItem and 
ETLayoutItemGroup can use a layout)

Explicit children are the usual children returned by -[ETLayoutItemGroup items]. 
Implicit children are the children hidden in the layout which are returned by 
[[[anItem layout] rootItem] items].

For the hit test phase, at each recursion level in the layout item tree, both 
-hitTest:withEvent:inItem: and -hitTest:withEvent:inChildrenOfItem: are entered.
Hence whether or not the item has children, this method will be called. */
- (ETLayoutItem *) hitTest: (NSPoint)itemRelativePoint 
                 withEvent: (ETEvent *)anEvent 
          inChildrenOfItem: (ETLayoutItem *)anItem
{
	NSPoint pointInParentContent = [anItem convertRectToContent: ETMakeRect(itemRelativePoint, NSZeroSize)].origin;

	/* Hit in implicit children (owned by the layout)

	   NOTE: We currently expect -[ETLayout rootItem] to have the same frame
	   than anItem. */
	ETLayoutItem *hitItem = [self hitTest: pointInParentContent
                                withEvent: anEvent
	                               inItem: [[anItem layout] rootItem]];
	if (hitItem != nil)
		return hitItem;

	/* Force return when either: 
	   - the item cannot have explicit children
	   - the layout doesn't reuse the children geometry and provides a 
	     completely standalone presentation 
	
	   NOTE: An item without a layout is not opaque. */
	BOOL isOpaqueItem = ([anItem isGroup] == NO || 
		([anItem layout] != nil && [[anItem layout] isOpaque]));
	
	if (isOpaqueItem)
		return anItem;

	/* Hit in explicit children */
	FOREACH([(ETLayoutItemGroup *)anItem items], childItem, ETLayoutItem *)
	{
		NSPoint childRelativePoint = [childItem convertPointFromParent: pointInParentContent];
		BOOL isInside = [childItem pointInside: childRelativePoint useBoundingBox: YES];

		if (isInside) /* Traverse the subtree */
		{
			hitItem = [self hitTest: childRelativePoint
			              withEvent: anEvent 
			                 inItem: childItem];
		}

		if (hitItem != nil)
			return hitItem;
	}
	
	return anItem;
}
// TODO: Benchmark this method. If it proves to be bottleneck, optimize. 
// Handles the dispatch on the decorator chain, probably by adding -contentRect
// to ETLayoutItem and verifying whether itemRelativePoint is contained in the 
// content rest
- (ETLayoutItem *) hitTest: (NSPoint)itemRelativePoint 
                 withEvent: (ETEvent *)anEvent 
				    inItem: (ETLayoutItem *)anItem
{
	if (anItem == nil)
		return nil;

#ifdef DEBUG_EVENT
	if ([anEvent type] == NSLeftMouseDown)
	{
		ETLog(@"Will try hit test at %@ in %@: %d", NSStringFromPoint(itemRelativePoint), 
			anItem, [anItem pointInside: itemRelativePoint useBoundingBox: YES]);
	}
#endif

	BOOL isOutside = ([anItem pointInside: itemRelativePoint useBoundingBox: YES] == NO);
	
	if (isOutside)
		return nil;

	NSPoint hitItemRelativePoint = itemRelativePoint;
	ETLayoutItem *hitItem = [self willHitTest: itemRelativePoint
	                                withEvent: anEvent
	                                   inItem: anItem
	                              newLocation: &hitItemRelativePoint];

	// NOTE: The next two lines could eventually be put in -willHitTest:XXX
	// The current choice makes harder to wrongly override the method and 
	// newLocation: acts as an explicit hint to update the event location.
	[anEvent setLayoutItem: hitItem];
	[anEvent setLocationInLayoutItem: hitItemRelativePoint];

	BOOL hitTestCustomized = (hitItem != anItem);
	BOOL shouldContinue = ([self shouldContinueHitTest: itemRelativePoint 
	                                      withEvent: anEvent 
	                                         inItem: hitItem 
	                                    wasReplaced: hitTestCustomized]);

	if (shouldContinue)
	{
		hitItem = [self hitTest: itemRelativePoint 
		              withEvent: anEvent 
		       inChildrenOfItem: hitItem];
	}

	return ([hitItem acceptsActions] ? hitItem : (ETLayoutItem *)nil);
	// NOTE: We could eventually prevent the hit test success with 
	// [anItem acceptsActions] && [anItem pointInside: itemRelativePoint] and 
	// bypass the hit test in the entire item tree connected to an item.
	// However because -[ETFreeLayout rootItem] has no action handler, 
	// -acceptsActions returns NO and prevents handle hit test. The best choice 
	// is either doesn't use -acceptActions with hit test phase or introduce 
	// an ETNullActionHandler, so -acceptsActions can return YES for the root 
	// item in a composite layout (such as ETFreeLayout).
}

/** Overrides to implement your own hit test strategy that prevents 
-hitTest:withEvent:inItem: to be run and handle the hit test in anItem, by
returning a custom item or nil. 

By default, returns anItem and -hitTest:withEvent:inItem: continues to procede 
as usual. */
- (ETLayoutItem *) willHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
                   newLocation: (NSPoint *)returnedItemRelativePoint
{
	return anItem;
}

/** By default, returns YES, unless wasItemReplaced is YES because 
-willHitTest:withEvent:inItem: has returned a custom item, in that case returns 
NO. */
- (BOOL) shouldContinueHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
				   wasReplaced: (BOOL)wasItemReplaced
{
	return (wasItemReplaced == NO);
}

- (void) trySendEventToWidgetView: (ETEvent *)anEvent
{
	ETLayoutItem *item = [self hitTestWithEvent: anEvent];
	BOOL backendHandled = [[ETEventProcessor sharedInstance] trySendEvent: anEvent
													   toWidgetViewOfItem: item];

	if (backendHandled)
		[anEvent markAsDelivered];
}

- (BOOL) tryActivateItem: (ETLayoutItem *)item withEvent: (ETEvent *)anEvent
{
	ETLayoutItem *itemToActivate = (item != nil ? item : (ETLayoutItem *)[[anEvent contentItem] firstDecoratedItem]);
	BOOL isActivateEvent = (itemToActivate != [self keyItem]);

	if (isActivateEvent)
		[anEvent markAsDelivered];

	return [[ETEventProcessor sharedInstance] tryActivateItem: item withEvent: anEvent];
}

- (void) mouseDown: (ETEvent *)anEvent
{
	[self tryActivateItem: nil withEvent: anEvent];
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
		return;
}

- (void) mouseUp: (ETEvent *)anEvent
{
	[self trySendEventToWidgetView: anEvent];
}

- (void) mouseDragged: (ETEvent *)anEvent
{
	[self trySendEventToWidgetView: anEvent];
}

/** Does nothing by default. */
- (void) mouseMoved: (ETEvent *)anEvent
{

}

- (void) mouseEntered: (ETEvent *)anEvent
{
	/* Don't redo the hit test done in -_mouseMoved. */
	[[[anEvent layoutItem] actionHandler] handleEnterItem: [anEvent layoutItem]];
}

- (void) mouseExited: (ETEvent *)anEvent
{
	/* Don't redo the hit test done in -_mouseMoved. */
	[[[anEvent layoutItem] actionHandler] handleExitItem: [anEvent layoutItem]];
}

- (void) mouseEnteredChild: (ETEvent *)anEvent
{
	ETLayoutItem *item = [anEvent layoutItem];

	[[[item parentItem] actionHandler] handleEnterChildItem: item];
}

- (void) mouseExitedChild: (ETEvent *)anEvent
{
	ETLayoutItem *item = [anEvent layoutItem];

	[[[item parentItem] actionHandler] handleExitChildItem: item];
}

- (BOOL) performKeyEquivalent: (ETEvent *)anEvent inItem: (ETLayoutItem *)item
{
	if ([[item actionHandler] handleKeyEquivalent: anEvent onItem: item]
		|| [[item view] performKeyEquivalent: (NSEvent *)[anEvent backendEvent]])
	{
		return YES;
	}

	if ([item isGroup])
		return NO;

	FOREACH([(ETLayoutItemGroup *)item items], childItem, ETLayoutItem *)
	{
		if ([self performKeyEquivalent: anEvent inItem: childItem])
			return YES;
	}

	return NO;
}


- (BOOL) performKeyEquivalent: (ETEvent *)anEvent
{
	BOOL isHandled = [self performKeyEquivalent: anEvent inItem: [self keyItem]];

	if (isHandled)
		return YES;

	return [[ETApp mainMenu] performKeyEquivalent: (NSEvent *)[anEvent backendEvent]];
}

- (void) tryPerformKeyEquivalentAndSendKeyEvent: (ETEvent *)anEvent toResponder: (id)aResponder
{
	NSEventType type = [anEvent type]; // FIXME: Should be ETEventType

	if (type != NSKeyDown && type != NSKeyUp)
		return;

	if ([self performKeyEquivalent: anEvent])
		return;

	if ([aResponder isLayoutItem])
	{
		if (type == NSKeyDown)
		{
			[[aResponder actionHandler] handleKeyDown: anEvent onItem: aResponder];
		}
		else
		{
			[[aResponder actionHandler] handleKeyUp: anEvent onItem: aResponder];
		}
	}
	else if ([aResponder isFirstResponderProxy]) /* For instrument */
	{
		if (type == NSKeyDown)
		{
			[(ETInstrument *)aResponder keyDown: anEvent];
		}
		else
		{
			[(ETInstrument *)aResponder keyUp: anEvent];		
		}
	}
	else /* For views and other AppKit responders */
	{
		if (type == NSKeyDown)
		{
			[aResponder keyDown: (NSEvent *)[anEvent backendEvent]];
		}
		else
		{
			[aResponder keyUp: (NSEvent *)[anEvent backendEvent]];
		}
	}
}

- (void) keyDown: (ETEvent *)anEvent
{
	[self tryPerformKeyEquivalentAndSendKeyEvent: anEvent toResponder: [self firstKeyResponder]];
}

- (void) keyUp: (ETEvent *)anEvent
{
	[self tryPerformKeyEquivalentAndSendKeyEvent: anEvent toResponder: [self firstKeyResponder]];
}

- (BOOL) isFirstResponderProxy
{
	return YES;
}

/* Cursor */

/** Sets the cursor that represents the receiver, and which replaces the 
current cursor when the receiver is the activatable instrument. */
- (void) setCursor: (NSCursor *)aCursor
{
	ASSIGN(_cursor, aCursor);
}

/** Returns the cursor that represents the receiver. */
- (NSCursor *) cursor
{
	return _cursor;
}

/* UI Utility */

/** Returns a menu that can be used to configure the receiver behavior. */
- (NSMenu *) menuRepresentation
{
	return nil;
}

@end


@implementation ETFirstResponderProxy

- (id) initWithObject: (id)anObject
{
	SUPERINIT
	ASSIGN(_object, anObject);
	return self;
}

/** Initializes and returns an autoreleased responder proxy which adapts 
anObject to NSResponder interface.

The returned instance will consume most NSResponder messages you send to it 
without forwarding them to anObject. Only -acceptsFirstResponder, 
-becomeFirstResponder and -resignsFirstResponder are forwarded. */
+ (ETFirstResponderProxy *) responderProxyWithObject: (id)anObject
{
	return AUTORELEASE([[self alloc] initWithObject: anObject]);
}

DEALLOC(DESTROY(_object))

/** Returns whether anObject is equal to either -object or the receiver. */
- (BOOL) isEqual: (id)anObject
{
	if ([anObject isEqual: _object])
		return YES;

	return [super isEqual: anObject];
}

- (BOOL) isFirstResponderProxy
{
	return YES;
}

/** Returns whether the real object is a layout item or not. */
- (BOOL) isLayoutItem
{
	/* We cannot use -forwardInvocation: here because -isLayoutItem is 
	   first declared on NSObject. */
	return [_object isLayoutItem];
}

/** Returns the real object which is represented by the receiver. */
- (id) object
{
	return _object;
}

#define RESPONDER_FORWARD(methodName) \
	if ([_object respondsToSelector: @selector(methodName)])\
	{\
		return [_object methodName];\
	}\
	else if ([_object isLayoutItem])\
	{\
		return [[_object actionHandler] methodName];\
	}\
\
	return [super methodName];\

/** Forwards -acceptsFirstResponder to the real object, or to the action handler 
bound to it in case the real object is a layout item. */
- (BOOL) acceptsFirstResponder
{
	RESPONDER_FORWARD(acceptsFirstResponder)
}

/** Forwards -becomeFirstResponder to the real object, or to the action handler 
bound to it in case the real object is a layout item. */
- (BOOL) becomeFirstResponder
{
	RETAIN(self);
	RESPONDER_FORWARD(becomeFirstResponder)
}

/** Forwards -resignFirstResponder to the real object, or to the action handler 
bound to it in case the real object is a layout item. */
- (BOOL) resignFirstResponder
{
	RESPONDER_FORWARD(resignFirstResponder)
	DESTROY(self);
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
	/* Take over superclass implementations by checking _object first. */
	if ([_object respondsToSelector: aSelector])
		return YES;

	if ([super respondsToSelector: aSelector])
		return YES;

	return NO;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
	NSMethodSignature *sig = [_object methodSignatureForSelector: aSelector];

	if (sig == nil)
	{
		sig = [super methodSignatureForSelector: aSelector];
	}

	return sig;
}

- (void) forwardInvocation: (NSInvocation *)inv
{
	if ([self respondsToSelector: [inv selector]] == NO)
	{
		[self doesNotRecognizeSelector: [inv selector]];
		return;
	}

	[inv invokeWithTarget: _object];
}

@end
