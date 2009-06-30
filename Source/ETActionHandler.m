/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETActionHandler.h"
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETGeometry.h"
#import "ETInstrument.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask

@implementation ETActionHandler

static NSMutableDictionary *sharedActionHandlers = nil;

+ (id) sharedInstance
{
	if (sharedActionHandlers == nil)
		sharedActionHandlers = [[NSMutableDictionary alloc] init];

	NSString *className = NSStringFromClass(self);
	id handler = [sharedActionHandlers objectForKey: className];
	if (handler == nil)
	{
		handler = AUTORELEASE([[self alloc] init]);
		[sharedActionHandlers setObject: handler
		                         forKey: className];
	}

	return handler;
}

/* <override-dummy />
Makes the clicked item the first responder of the active instrument.

Overrides this method when you want to customize how simple click are handled. */
- (void) handleClickItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Click %@", item);
	[[ETInstrument activeInstrument] makeFirstResponder: (id)item];
}

/** <override-dummy />
Tries to send the double action bound to the base item or the parent item. The
parent item is used when double action is set on the base item. 

Each time a target can receive the action, the -doubleClickedItem property is 
updated on the base item or the parent item, otherwise it is set to nil, then 
the action is sent.

Overrides this method when you want to customize how double-click are handled. */
- (void) handleDoubleClickItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Double click %@", item);

	ETLayoutItemGroup *itemGroup = [item parentItem];
	
	if ([[item baseItem] doubleAction] != NULL)
	{
		itemGroup = [item baseItem];
	}

	BOOL foundTarget = ([ETApp targetForAction: [itemGroup doubleAction] 
	                                        to: [itemGroup target]
	                                      from: itemGroup] != nil);
	if (foundTarget)
	{
		[itemGroup setValue: item forKey: kETDoubleClickedItemProperty];
	}
	else
	{
		[itemGroup setValue: nil forKey: kETDoubleClickedItemProperty];
	}
	
	[[ETApplication sharedApplication] sendAction: [itemGroup doubleAction] 
	                                           to: [itemGroup target] 
	                                         from: itemGroup];
}

- (void) handleDragItem: (ETLayoutItem *)item byDelta: (NSSize)delta
{
	ETDebugLog(@"Drag %@", item);
	[self handleTranslateItem: item byDelta: delta];
}

- (void) handleTranslateItem: (ETLayoutItem *)item byDelta: (NSSize)delta
{
	NSRect prevBoundingFrame = [item convertRectToParent: [item boundingBox]];

	[item setPosition: ETSumPointAndSize([item position], delta)];

	/* Compute and redisplay the translation area */
	NSRect newBoundingFrame = [item convertRectToParent: [item boundingBox]];
	NSRect dirtyRect = NSUnionRect(newBoundingFrame, prevBoundingFrame);
	[[item parentItem] setNeedsDisplayInRect: dirtyRect];
	[[item parentItem] displayIfNeeded];

	ETLog(@"Translate dirty rect %@", NSStringFromRect(dirtyRect));
}

/** <override-dummy />
Does nothing.

Overrides this method when you want to customize how enter are handled.<br />
You can use this method and -handleExitItem: to implement roll-over effect. */
- (void) handleEnterItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Enter %@", item);
}

/** <override-dummy />
Does nothing.

Overrides this method when you want to customize how exit are handled. */
- (void) handleExitItem: (ETLayoutItem *)item
{
	ETDebugLog(@"Exit %@", item);
}

- (void) handleEnterChildItem: (ETLayoutItem *)childItem
{
	ETDebugLog(@"Exit child %@", childItem);
}

- (void) handleExitChildItem: (ETLayoutItem *)childItem
{
	ETDebugLog(@"Enter child %@", childItem);
}

/* Key Actions */

- (BOOL) handleKeyEquivalent: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	return NO;
}

- (void) handleKeyUp: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	// FIXME: -handleKeyUp: isn't declared anywhere...
	// [[item nextResponder] handleKeyUp: keyInput];
}

- (void) handleKeyDown: (id <ETKeyInputAction>)keyInput onItem: (ETLayoutItem *)item
{
	// FIXME: [[item nextResponder] handleKeyDown: keyInput];
}

/** Returns whether item can be selected or not. 

By default returns YES, except when the item is a base item, then returns NO. */
- (BOOL) canSelect: (ETLayoutItem *)item
{
	//if ([item isBaseItem])
	//	return NO;

	return YES;
}

/** Sets the item as selected and marks it to be redisplayed. */
- (void) handleSelect: (ETLayoutItem *)item
{
	ETLog(@"Select %@", item);
	[item setSelected: YES];
	[item setNeedsDisplay: YES];

	// TODO: Cache the selection in the controller if there is one
	//[[[item baseItem] controller] addSelectedObject: item];
}

/** Returns whether item can be deselected or not. 

By default returns YES.

TODO: Problably remove, since it should be of any use and just adds complexity. */
- (BOOL) canDeselect: (ETLayoutItem *)item
{
	return YES;
}

/** Sets the item as not selected and marks it to be redisplayed. */
- (void) handleDeselect: (ETLayoutItem *)item
{
	ETLog(@"Deselect %@", item);
	[item setSelected: NO];

	// TODO: May be cache in the controller... 
	//[[[item baseItem] controller] removeSelectedObject: item];
}

/* Generic Actions */

/** Overrides to return YES if you want that items to which the receiver is 
bound to can become first responder. By default, returns NO. */
- (BOOL) acceptsFirstResponder
{
	return YES;
}

/** Tells the receiver that the item to which it is bound is asked to become 
the first responder. Returns YES by default, to let the item become first 
responder.

Overrides to handle how the receiver or the item to which it is bound to, react 
to the first responder status (e.g. UI feedback).

Moreover this method can be used as a last chance to refuse this status. */
- (BOOL) becomeFirstResponder
{
	return YES;
}

/** Tells the receiver that the item to which it is bound is asked to hand  
on the first responder status. Returns YES by default, to let the item 
resigns from the first responder status.

Overrides to handle how the receiver or the item to which it is bound to, react  
to the loss of the first responder status (e.g. UI feedback).

Moreover this method can be used to prevent to hand over the first responder 
status, when others request it. */
- (BOOL) resignFirstResponder
{
	return YES;
}

- (BOOL) acceptsFirstMouse
{
	return NO;
}

- (void) sendBackward: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent firstItem]])
		return;

	int currentIndex = [parent indexOfItem: item];

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: currentIndex - 1];
	RELEASE(item);
}

- (void) sendToBack: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent firstItem]])
		return;

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: 0];
	RELEASE(item);
}

- (void) bringForward: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent lastItem]])
		return;

	int currentIndex = [parent indexOfItem: item];

	RETAIN(item);
	[item removeFromParent];
	[parent insertItem: item atIndex: currentIndex + 1];
	RELEASE(item);
}

- (void) bringToFront: (id)sender onItem: (ETLayoutItem *)item
{
	ETLayoutItemGroup *parent = [item parentItem];
	
	if ([item isEqual: [parent lastItem]])
		return;

	RETAIN(item);
	[item removeFromParent];
	[parent addItem: item];
	RELEASE(item);
}

- (void) ungroup: (id)sender onItem: (ETLayoutItem *)item
{
	if ([item isGroup])
		[(ETLayoutItemGroup *)item unmakeGroup];
}

@end
