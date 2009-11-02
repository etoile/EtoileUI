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
#import "EtoileUIProperties.h"
#import "ETCompatibility.h"


@implementation ETActionHandler

/** <override-dummy />
Returns the style class that can be used together with the receiver class.

Action handler and style very often exist as a class pair whose instances are 
thought to be used together.

Returns Nil by default. */
+ (Class) styleClass
{
	return Nil;
}

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

	//ETLog(@"Translate dirty rect %@", NSStringFromRect(dirtyRect));
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

/* Touch Tracking Actions */

/** <override-dummy />
Tells the receiver a touch begins at a location inside the given item.<br />
Does nothing by default and returns NO.

Overrides to return YES and initiate a tracking sequence which will make the 
active instrument invokes -handleContinueTouch:atPoint:onItem: repeatedly (even 
when the touch moves outside the given item) and finally -handleEndTouch:onItem:. 

The point is expressed relative to the item received in parameter.

[aTouch layoutItem] is equal to the given item. */
- (BOOL) handleBeginTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{
	return NO;
}

/** <override-dummy /> 
Tells the receiver a touch initiated on the given item has moved to a new 
location.<br />
Does nothing by default.

Overrides to handle how the receiver reacts to each step in the tracking 
sequence motion.<br />
-handleEndTouch:onItem: is always invoked once the touch is released.

The point is expressed relative to the item received in parameter.<br />
For now, aPoint is not yet supported and is equal to ETNullPoint. */
- (void) handleContinueTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{

}

/** <override-dummy />
Tells the receiver a touch initiated on the given item has ended.<br />
Does nothing by default.

Overrides to handle how the receiver reacts to the touch release. This is the 
last step in the tracking sequence.

You can retrieve the item on which the touch has ended with [aTouch layoutItem]. 
The touch location related to this item can be retrieved with 
[aTouch locationInLayoutItem]. */
- (void) handleEndTouch: (id <ETTouchAction>)aTouch onItem: (ETLayoutItem *)item
{

}

/* Select Actions */

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

@end


@implementation ETButtonItemActionHandler

/** Returns ETBasicItemStyle class. */
+ (Class) styleClass
{
	return NSClassFromString(@"ETBasicItemStyle");
}

- (BOOL) handleBeginTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{
	[item setSelected: YES];
	[item setNeedsDisplay: YES];
	return YES;
}

- (void) handleContinueTouch: (id <ETTouchAction>)aTouch atPoint: (NSPoint)aPoint onItem: (ETLayoutItem *)item
{
	if ([item isEqual: [aTouch layoutItem]])
	{
		[item setSelected: YES];
		[item setNeedsDisplay: YES];
	}
	else
	{
		[item setSelected: NO];
		[item setNeedsDisplay: YES];	
	}
}

- (void) handleEndTouch: (id <ETTouchAction>)aTouch onItem: (ETLayoutItem *)item
{
	[item setSelected: NO];
	[item setNeedsDisplay: YES];

	if ([item isEqual: [aTouch layoutItem]])
	{
		BOOL foundTarget = ([ETApp targetForAction: [item action] 
	                                            to: [item target]
		                                      from: item] != nil);
		if (foundTarget)
		{
			[ETApp sendAction: [item action] 
			               to: [item target] 
			             from: item];
		}
	}
}

@end
