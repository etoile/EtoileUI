/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETSelectTool.h"
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETHandle.h"
#import "ETActionHandler.h"
#import "ETLayoutItem+Factory.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayout.h"
#import "ETSelectionAreaItem.h"
#import "ETCompatibility.h"

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask

@implementation ETSelectTool

- (id) init
{
	SUPERINIT
	[self setCursor: [NSCursor pointingHandCursor]];
	[self setAllowsMultipleSelection: YES];
	[self setAllowsEmptySelection: YES];
	_actionHandlerPrototype = [[ETActionHandler alloc] init];
	_selectionAreaItem = [[ETSelectionAreaItem alloc] init];
	return self;
}

DEALLOC(DESTROY(_actionHandlerPrototype); DESTROY(_selectionAreaItem));

- (id) copyWithZone: (NSZone *)aZone
{
	ETSelectTool *newTool = [super copyWithZone: aZone];

	[newTool setAllowsEmptySelection: [self allowsEmptySelection]];
	[newTool setAllowsMultipleSelection: [self allowsMultipleSelection]];
	newTool->_removeItemsAtPickTime = _removeItemsAtPickTime;
	ASSIGN(newTool->_actionHandlerPrototype, _actionHandlerPrototype);
	newTool->_selectionAreaItem = [_selectionAreaItem copyWithZone: aZone];

	return newTool;
}

/** Returns whether the tool can be used to select several items among the 
children of the target item. */
- (BOOL) allowsMultipleSelection
{
	return _multipleSelectionAllowed;
}

/** Sets whether the tool can be used to select several items among the children 
of the target item. */
- (void) setAllowsMultipleSelection: (BOOL)multiple
{
	_multipleSelectionAllowed = multiple;
	// FIXME: [[self layoutOwner] syncLayoutViewWithItem: self];
}

/** Returns whether the tool allows to have no items selected among the children 
of the target item. */
- (BOOL) allowsEmptySelection
{
	return _emptySelectionAllowed;
}

/** Sets whether the tool allows to have no items selected among the children of 
the target item. */
- (void) setAllowsEmptySelection: (BOOL)empty
{
	_emptySelectionAllowed = empty;
	// FIXME: [[self layoutOwner] syncLayoutViewWithItem: self];
}

/** Returns whether the dragged items should be removed immediately when they 
get picked.

By default, returns YES. 

The returned value is only meaningful during a drag session. */
- (BOOL) shouldRemoveItemsAtPickTime
{
	return _removeItemsAtPickTime;
}

/** Sets whether the dragged items should be removed immediately when they 
get picked. */
- (void) setShouldRemoveItemsAtPickTime: (BOOL)flag
{
	_removeItemsAtPickTime = flag;
}

/** Returns the selection area item. By default, it returns an 
ETSelectionAreaItem object which uses a rectangular shape to draw a selection 
rectangle. */
- (ETSelectionAreaItem *) selectionAreaItem
{
	return _selectionAreaItem;
}

/** Sets the selection area item.

You can set a customized ETSelectionAreaItem object if you don't want to use 
the default selection rectangle. */
- (void) setSelectionAreaItem: (ETSelectionAreaItem *)anItem
{
	ASSIGN(_selectionAreaItem, anItem);
}

/** Returns whether a rubber band selection is underway with the receiver. */
- (BOOL) isSelectingArea
{
	return (_newSelectionAreaUnderway);
}

/** Returns the selected items in the target item. */
- (NSArray *) selectedItems
{
	// TODO: Should return controller selection if available

	/* Let the target item layout returns a custom selection. 
	   ETOutlineLayout would return a hierarchical selection. This way, we can 
	   make the tool compatible with such view-based layout.
	   NOTE: not in used presently. */
	return [(ETLayoutItemGroup *)[self targetItem] selectedItemsInLayout];
}

/** Forces the receiver as the first responder in order it intercepts all 
actions to be send, this way it can handle some actions by itself and when 
needed replicate other actions on each selected item. */
- (void) didBecomeActive
{
	[self makeFirstMainResponder: self];
}

// TODO: Would be nice to simplify this a bit and try to share more with 
// ETInstrument implementation.
- (ETInstrument *) lookUpInstrumentInHoveredItemStack
{
	ETInstrument *foundInstrument = nil;
	ETInstrument *parentInstrument = nil;
	/* The last/top object is the instrument at the lowest/deepest level in the 
	   layout item tree. */
	NSEnumerator *e = [[self hoveredItemStack] reverseObjectEnumerator];
	ETLayoutItem *item = nil;

	//ETLog(@"Hovered item stack %@", [self hoveredItemStack]);

	while ((item = [e nextObject]) != nil)
	{
		//ETLog(@"Look up instrument at level %@ in hovered item stack", item);

		/* The top item can be an ETLayoutItem instance */
		if ([item isGroup] == NO)
			continue;
		
		//ETLog(@" ---> Found instrument %@", [[(ETLayoutItemGroup *)item layout] attachedInstrument]);
		
		foundInstrument = [[(ETLayoutItemGroup *)item layout] attachedInstrument];
		parentInstrument = [[[(ETLayoutItemGroup *)item parentItem] layout] attachedInstrument];
		if (foundInstrument != nil && [[parentInstrument class] isEqual: [self class]] == NO)
			break;
	}

	// NOTE: In case we attach a non-removable instrument to the root item, we 
	// could set foundInstrument to nil.
	BOOL overRootItem = (foundInstrument == nil);
	if (overRootItem)
		foundInstrument = [[self class] mainInstrument];

	return foundInstrument;
}

/* When the hit test is inside the target item, we customize it to restrict it 
to either the target item itself or its immediate children. */
- (BOOL) shouldContinueHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
				   wasReplaced: (BOOL)wasItemReplaced
{
	// FIXME: Remove -isKindOfClass: test.
	if ([anItem isKindOfClass: NSClassFromString(@"ETHandleGroup")] == NO 
		&& [anItem pointInside: itemRelativePoint useBoundingBox: NO] == NO)
	{
		return NO;
	}

	ETLayoutItemGroup *targetItem = (ETLayoutItemGroup *)[self targetItem];
	BOOL isBackground = (anItem == targetItem);
	BOOL isBackgroundChild = [targetItem containsItem: anItem];

	/* Return target item child as hit test result when selecting/clicking */
	if (isBackgroundChild)
	{
		return NO;
	}

	/* Return target item as hit test result when selecting area */
	if ([self isSelectingArea] && isBackground)
	{
		return NO;
	}

	return YES;
}

/* Forces the target item as hit test result when selecting an area, otherwise 
returns anItem exactly as ETInstrument would do and let the hit test continues.

This method is called immediately when -hitTestWithEvent:inItem: is first 
entered. At that time, anItem is a window layer child and 
returnedItemRelativePoint is a point in the window frame rect. */
- (ETLayoutItem *) willHitTest: (NSPoint)itemRelativePoint 
                     withEvent: (ETEvent *)anEvent 
				        inItem: (ETLayoutItem *)anItem
                   newLocation: (NSPoint *)returnedItemRelativePoint
{
	ETLayoutItemGroup *targetItem = (ETLayoutItemGroup *)[self targetItem];

	if ([self isSelectingArea] && [anItem isGroup])
	{
		NSRect locAsRectInWindowItem = ETMakeRect(*returnedItemRelativePoint, NSZeroSize);
		NSRect rectInTarget = [targetItem convertRect: locAsRectInWindowItem 
		                                     fromItem: (ETLayoutItemGroup *)anItem];
		NSPoint locInTargetContent = [targetItem convertRectToContent: rectInTarget].origin;
		*returnedItemRelativePoint = locInTargetContent;
		return targetItem;
	}

	return anItem;
}

- (void) setTargetItem: (id)anItem
{
	NSAssert(anItem != nil, @"");
	[super setTargetItem: anItem];
	[anItem setSelected: NO];
	[(ETLayoutItem *)[[self layoutOwner] layoutContext] display]; // FIXME: Ugly... because we need to erase the removed handles
}

- (void) mouseDragged: (ETEvent *)anEvent
{
	//[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
		return;

	// FIXME: Something more sensible [layoutOwner item] (or windowContentItem or rootItem), 
	// for the last two cases, it's better to do it only if those items have 
	// ETSelectTool attached to their layout.
	ETLayoutItem *hitItem = [self hitTestWithEvent: anEvent];
	BOOL backgroundHit = ([hitItem isEqual: [self targetItem]]);
	BOOL startNewSelectionArea = ([self isSelectingArea] == NO && backgroundHit && [self isMoving] == NO);
	BOOL startMove = (backgroundHit == NO && [self isMoving] == NO);

	if (startNewSelectionArea)
	{
		[self beginSelectingAreaAtPoint: [anEvent locationInLayoutItem]];
	}
	else if ([self isSelectingArea])
	{
		[self resizeSelectionAreaToPoint: [anEvent locationInLayoutItem]];
	}
	else if (startMove)
	{
		[super mouseDragged: anEvent];
	}
	else if ([self isMoving])
	{
		// NOTE: Here hitItem can be be the background rather than the handle or 
		// the moved item.
		[super mouseDragged: anEvent];
	}
}

- (void) mouseDown: (ETEvent *)anEvent
{
	[self tryActivateItem: nil withEvent: anEvent];
	[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
	{
		return;
	}
	/* The field editor has not received the event with -trySendEventToWidgetView:, 
	   the event is not directed towards it. */
	[self tryRemoveFieldEditorItemWithEvent: anEvent];

	/* Make ourself the first responder in case thos status was given to a widget 
	   (e.g. a field editor) since the last event which was not delegated 
	   with -tryActivateItem:withEvent: or -trySendEventToWidgetView: */
	[self makeFirstKeyResponder: self];

	ETLayoutItem *item = [self hitTestWithEvent: anEvent];
	BOOL backgroundClick = ([item isEqual: [self targetItem]]);

	if (backgroundClick)
	{
		[self deselectAllWithItem: item];
	}
	else
	{
		// NOTE: If hitItem is a handle, the selected items won't be deselected 
		// and the handle wrongly selected, because the handle action handler 
		// overrides -canSelect:.
		[self alterSelectionWithEvent: anEvent];
	}
}

- (void) handleClickWithEvent: (ETEvent *)anEvent
{
	ETLayoutItem *item = [self hitTestWithEvent: anEvent];
	
	// NOTE: May be replace next line by ([[item layout] isEqual: [self layoutOwner]);
	BOOL backgroundClick = ([item isEqual: [self targetItem]]);
	BOOL isDoubleClick = ([(NSEvent *)[anEvent backendEvent] clickCount] == 2);
	BOOL doubleClickEditableChild = ([item isGroup] && isDoubleClick);
	// NOTE: We must cast -targetItem returned object otherwise -containsItem: 
	// might wrongly be evaluted to YES. Alternatively -targetItem return 
	// type could be overriden, but our local and explicit cast is harder to break.
	BOOL clickOutsideOfEditedChild = (backgroundClick == NO 
		&& [(ETLayoutItemGroup *)[self targetItem] containsItem: item] == NO);

	if (doubleClickEditableChild)
	{
		[self beginEditingInsideSelection];
	}
	else if (clickOutsideOfEditedChild)
	{
		[self endEditingInsideSelection];
	}
	else
	{
		/* Normally -alterSelectionWithEvent: is expected to return immediately 
		   because the event is a not a mouse down. However subclasses might 
		   want to override this behavior so that the selection changes occur on 
		   mouse up rather than mouse down. See -mouseDown: too. */
		[self alterSelectionWithEvent: anEvent];
	}
}

/* Outside of the boundaries doesn't count because the parent instrument will 
be reactivated when we exit our owner layout. */
- (void) mouseUp: (ETEvent *)anEvent
{
	ETDebugLog(@"Mouse up with select tool on item %@", [self hitTestWithEvent: anEvent]);

	//[self trySendEventToWidgetView: anEvent];
	if ([anEvent wasDelivered])
		return;

	if ([self isSelectingArea])
	{
		[self endSelectingArea];
		return;
	}
	else if ([self isMoving])
	{
		// TODO: Depending on the modifier pick or select...
		[super mouseUp: anEvent];
	}
	else
	{
		[self handleClickWithEvent: anEvent];
	}
}

- (void) translateByDelta: (NSSize)aDelta
{
	if ([_draggedItem isKindOfClass: [ETHandle class]])
	{
		[super translateByDelta: aDelta];
	}
	else
	{
		FOREACH([self selectedItems], item, ETLayoutItem *)
		{
			[[item actionHandler] handleTranslateItem: item 
			                                  byDelta: aDelta];
		}
	}
	// TODO: Post translate notification
}

- (void) keyDown: (ETEvent *)anEvent
{
	// FIXME: Is this exactly what we should do... My brain is tired.
	if ([[self firstKeyResponder] isEqual: self] == NO)
	{
		[super keyDown: anEvent];
		return;
	}

	NSString *chars = [anEvent characters];

	if ([chars length] == 1)
	{
		if ([chars characterAtIndex: 0] == NSCarriageReturnCharacter)
		{
			[self insertNewLine: nil];
		}
		else if ([chars characterAtIndex: 0] == NSDeleteCharacter)
		{
			[self endEditingInsideSelection];
		}
		else
		{
			[self tryPerformKeyEquivalentAndSendKeyEvent: anEvent toResponder: [self nextResponder]];
		}
	}
	else
	{
		[self tryPerformKeyEquivalentAndSendKeyEvent: anEvent toResponder: [self nextResponder]];
	}
}

- (void) insertNewLine: (id)sender
{
	[self beginEditingInsideSelection];
}

/* If the selection consists of a single item, makes it the target item. */
- (void) beginEditingInsideSelection
{
	NSArray *selectedItems = [self selectedItems];
	if ([selectedItems count] == 1)
	{
		ETDebugLog(@"Retarget tool %@ to item %@", self, [selectedItems firstObject]);
		[self setTargetItem: [selectedItems firstObject]];
	}
}

/** Restores the original target item. */
- (void) endEditingInsideSelection
{
	ETDebugLog(@"Restore original target of tool %@ to item %@", self, [[self layoutOwner] layoutContext]);
	[self setTargetItem: (ETLayoutItem *)[[self layoutOwner] layoutContext]];
}

/** Shows the selection area item in the layout. */
- (void) beginSelectingAreaAtPoint: (NSPoint)aPoint
{
	ETDebugLog(@"Begin selecting area at %@", NSStringFromPoint(aPoint));

	ETLayout *backgroundLayout = [(ETLayoutItemGroup *)[self targetItem] layout];

	_newSelectionAreaUnderway = YES;
	_localStartDragLoc = aPoint;
	/* The root item is mapped to backgroundItem extent, so their coordinate 
	   space are equal. */
	[[self selectionAreaItem] setFrame: ETMakeRect(_localStartDragLoc, NSZeroSize)];
	NSAssert1([backgroundLayout rootItem] != nil, @"Root item in %@ must never "
		"be nil or -beginSelectingAreaAtPoint: shouldn't have been called", backgroundLayout);
	[(ETLayoutItemGroup *)[backgroundLayout rootItem] addItem: [self selectionAreaItem]];
}

- (void) resizeSelectionAreaToRect: (NSRect)aRect
{
	ETDebugLog(@"Resize selection to rect %@", NSStringFromRect(aRect));

	ETLayoutItemGroup *backgroundItem = (ETLayoutItemGroup *)[self targetItem];
	/* The new rect might have negative width and/or height that got to be 
	   starndardized by shifting the origin. Whether backgroundItem uses 
	   flipped coordinates or not, doesn't matter to compute and standardize 
	   the new selection rect. */
	NSRect newSelectionRect = ETStandardizeRect(aRect);

	[[self selectionAreaItem] setNeedsDisplay: YES]; /* Invalid existing rect */
	[[self selectionAreaItem] setFrame: newSelectionRect];
	[[self selectionAreaItem] setNeedsDisplay: YES]; /* Invalid new rect */

	FOREACHI([backgroundItem items], childItem)
	{
		if (NSIntersectsRect([childItem frame], newSelectionRect))
		{
			[self addItemToSelection: childItem];
		}
		else
		{
			[self removeItemFromSelection: childItem];
		}
	}

	/* Now redisplay both selection area and newly selected/unselected items */
	[[self targetItem] displayIfNeeded];
}

/** Updates the selection area towards aPoint, then the selected items based on 
their intersection with the new selection rect. */
- (void) resizeSelectionAreaToPoint: (NSPoint)aPoint
{
	_localLastDragLoc = aPoint;

	float newWidth = _localLastDragLoc.x - _localStartDragLoc.x;
	float newHeight = _localLastDragLoc.y -_localStartDragLoc.y;

	[self resizeSelectionAreaToRect: NSMakeRect(_localStartDragLoc.x, 
		_localStartDragLoc.y, newWidth, newHeight)];
}

/** Hides the selection area item in the layout. */
- (void) endSelectingArea
{
	ETDebugLog(@"End selecting area at %@", NSStringFromPoint(_localLastDragLoc));

	ETLayout *backgroundLayout = [(ETLayoutItemGroup *)[self targetItem] layout];

	[[self selectionAreaItem] setNeedsDisplay: YES];	
	[(ETLayoutItemGroup *)[backgroundLayout rootItem] removeItem: [self selectionAreaItem]];
	_newSelectionAreaUnderway = NO;
	_localStartDragLoc = NSZeroPoint; /* Debugging hint */

	/* Now redisplay the last selection area to erase it */
	[[self targetItem] displayIfNeeded];
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

/** Alters the current selection based on the layout item attached to anEvent 
and the modifier keys. */
- (void) alterSelectionWithEvent: (ETEvent *)anEvent
{
	if ([anEvent type] != NSLeftMouseDown)
		return;

	ETLayoutItem *item = [anEvent layoutItem];
	BOOL extendSelection = ([self allowsMultipleSelection] 
		&& ([anEvent modifierFlags] & SELECTION_BY_RANGE_KEY_MASK)
		&& ([item isSelected] == NO));
	BOOL reduceSelection = ([self allowsMultipleSelection] 
		&& ([anEvent modifierFlags] & SELECTION_BY_RANGE_KEY_MASK)
		&& [item isSelected]);
	BOOL addToSelection = ([self allowsMultipleSelection] 
		&& ([anEvent modifierFlags] & SELECTION_BY_ONE_KEY_MASK)
		&& [item isSelected] == NO);
	BOOL removeFromSelection = (([anEvent modifierFlags] & SELECTION_BY_ONE_KEY_MASK)
		&& [item isSelected]);

	/* The statements below are in a precise order that ensures the 
	   selection behavior exactly matches the table view selection rules as 
	   implemented on Mac OS X. For example, if both the two modifier keys are 
	   pressed together, the shift modifier takes over the command. 
	   In future me may change this if we want other rules for Etoile. */
	if (extendSelection)
	{
		[self extendSelectionToItem: item];
	}
	else if (reduceSelection)
	{
		[self reduceSelectionFromItem: item];
	}
	else if (addToSelection)
	{
		[self addItemToSelection: item];
	}
	else if (removeFromSelection)
	{
		[self removeItemFromSelection: item];
	}
	else
	{
		[self makeSingleSelectionWithItem: item];
	}
}


/** Selects every items whose index as element in the target item are greater 
than the first selection index and lower than the index of the given item.

item will be selected. */
- (void) extendSelectionToItem: (ETLayoutItem *)item
{
	//TODO: -handleSelect:willExtendOrReduceSelectionByRange:
	ETLayoutItemGroup *parent = [item parentItem];
	unsigned int newSelectionIndex = [parent indexOfItem: item];
	NSIndexSet *selectionIndexes = [parent selectionIndexes];

	if ([selectionIndexes isEmpty])
	{
		[parent setSelectionIndex: newSelectionIndex];
		return;
	}

	unsigned int firstSelectionIndex = [selectionIndexes firstIndex];
	unsigned int lastSelectionIndex = [selectionIndexes lastIndex];

	if (newSelectionIndex > firstSelectionIndex) /* Extend or reduce downwards */
	{
		lastSelectionIndex = newSelectionIndex;
	}
	else if (newSelectionIndex < firstSelectionIndex) /* Extend upward */
	{
		firstSelectionIndex = newSelectionIndex;
	}
	else
	{
		ETLog(@"WARNING: -extendSelectionToItem: parameter must be an item not "
			"yet selected unlike %@", item);
		return;
	}

	[parent setSelectionIndexes: [NSIndexSet indexSetWithIndexesInRange: 
		NSMakeRange(firstSelectionIndex, lastSelectionIndex - firstSelectionIndex + 1)]];
}

/** Deselects every items whose index as element in the target item are greater 
than the index of the given item.

item will be selected. */
- (void) reduceSelectionFromItem: (ETLayoutItem *)item
{
	[self extendSelectionToItem: item];
}

/** Tells item to select itself if -[ETActionHandler canSelect:] returns YES. */
- (void) addItemToSelection: (ETLayoutItem *)item
{
	if ([item isSelected])
		return;

	if ([[item actionHandler] canSelect: item])
		[[item actionHandler] handleSelect: item];
}

/** Tells item to deselect itself. */
- (void) removeItemFromSelection: (ETLayoutItem *)item
{
	if ([item isSelected] == NO)
		return;

	[[item actionHandler] handleDeselect: item];
}

/** Tells item to select itself if -[ETActionhandler canSelect] returns YES. */
- (void) makeSingleSelectionWithItem: (ETLayoutItem *)item
{
	if ([item isSelected]) /* Already selected */
		return;

	if ([[item actionHandler] canSelect: item])
	{
		[self deselectAllWithItem: item];
		[[item actionHandler] handleSelect: item];
	}
}

/** Tells each item currently selected in the target item to deselect itself. */
- (void) deselectAllWithItem: (ETLayoutItem *)item
{
	/* Deselect all */
	FOREACH([self selectedItems], selectedItem, ETLayoutItem *)
	{
		[[selectedItem actionHandler] handleDeselect: selectedItem];
		// NOTE: We should eventually update the controller selection here
		// rather than in -handleDeselect:
	}
}

/** Sets the action handler used to check the actions that can sent to 
selected items. */
- (void) setActionHandlerPrototype: (id)aHandler
{
	ASSIGN(_actionHandlerPrototype, aHandler);
}

/** Returns the action handler used to check the actions that can sent to 
selected items.

By default, an ETActionHandler instance is used. */
- (id) actionHandlerPrototype
{
	return _actionHandlerPrototype;
}

/** Returns self as the action handler.

You must never use this method.

This method allows to filter actions in the responder chain and multiplex them 
on the selection elements, when the receiver becomes the first responder. */
- (id) actionHandler
{
	return self;
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
	if ([super respondsToSelector: aSelector])
		return YES;

	SEL twoParamSelector = NSSelectorFromString([NSStringFromSelector(aSelector) 
		stringByAppendingString: @"onItem:"]);
	if ([_actionHandlerPrototype respondsToSelector: twoParamSelector])
		return YES;
		
	/*if ([_actionHandlerPrototype respondsToSelector: aSelector])
		return YES;*/

	return NO;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
	NSMethodSignature *sig = [super methodSignatureForSelector: aSelector];

	/*if (sig == nil)
		[_actionHandlerPrototype methodSignatureForSelector: aSelector];*/

	if (sig == nil)
	{
		/* Get the signature of every standard actions */
		sig = [super methodSignatureForSelector: @selector(group:)];
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

	FOREACH([self selectedItems], item, ETLayoutItem *)
	{
			[inv invokeWithTarget: item];
	}
}

/** Returns the target item as next responder. */
- (id) nextResponder
{
	return [self targetItem];
}

/** Forces the receiver as the first responder in the current key window, by 
ignoring aResponder. */
- (BOOL) makeFirstKeyResponder: (id)aResponder
{
	return [super makeFirstKeyResponder: self];
}

/** Forces the receiver as the first responder in the current main window, by 
ignoring aResponder. */
- (BOOL) makeFirstMainResponder: (id)aResponder
{
	return [super makeFirstMainResponder: self];
}

/** Tells each item currently deselected in the target item to select itself. */
- (IBAction) selectAll: (id)sender
{
	FOREACH([(ETLayoutItemGroup *)[self targetItem] items], item, ETLayoutItem *)
	{
		if ([item isSelected] == NO && [[item actionHandler] canSelect: item])
		{
			[[item actionHandler] handleSelect: item];
		}
		// NOTE: We should eventually update the controller selection here...
	}
}

/** Moves the currently selected items into a new item group and inserts it in 
the target item. */
- (IBAction) group: (id)sender
{
	ETLayoutItemGroup *targetItem = (ETLayoutItemGroup *)[self targetItem];
	ETLayoutItemGroup *newGroup = [ETLayoutItem graphicsGroup];
	NSArray *children = [self selectedItems];

	[ETLayoutItemGroup disablesAutolayout];

	NSRect unionFrame = ETUnionRectWithObjectsAndSelector(children, @selector(frame));
	[newGroup setFrame: unionFrame];
	[newGroup setLayout: [ETFreeLayout layout]];

	[targetItem addItem: newGroup];
	[newGroup setSelected: YES]; // FIXME: ETFreeLayout doesn't detect selected before -addItem:

	/* Convert the item origins to the coordinate space of the new group */
	FOREACH(children, item, ETLayoutItem *)
	{
		NSPoint rebasedPosition = [newGroup convertPointFromParent: [item position]];
		[item setPosition: rebasedPosition];
	
		// FIXME: Should rather notify the handle group about the item move to a 
		// new parent and the item frame change
		[item setSelected: NO];
		[newGroup addItem: item];
	}
	
	[ETLayoutItemGroup enablesAutolayout];

	[targetItem updateLayout];
	[targetItem setNeedsDisplayInRect: NSUnionRect(unionFrame, [newGroup frame])];
}

/* Removes the given group from its parent item and moves its child item into 
that parent. */
- (void) inlineGroup: (ETLayoutItemGroup *)aGroup
{
	ETLayoutItemGroup *parent = [aGroup parentItem];
	BOOL isChildGroup = [parent containsItem: aGroup];
	int insertionIndex = (isChildGroup ? [parent indexOfItem: aGroup] : [parent numberOfItems] - 1);

	// TODO: Use a reverse object enumerator or eventually implement -insertItems:atIndex:
	FOREACH([aGroup items], newChild, ETLayoutItem *)
	{
		if (isChildGroup)
		{
			NSPoint rebasedPosition = [aGroup convertPointToParent: [newChild position]];
			[newChild setPosition: rebasedPosition];
		}

		// FIXME: Should rather notify the handle group about the item move to a 
		// new parent and the item frame change
		[newChild setSelected: NO];
		[parent insertItem: newChild atIndex: insertionIndex];
		[newChild setSelected: YES];
	}

	[aGroup removeFromParent];
}

/* NOTE: We could implement -inlineGroup:intoItem: to support inlining a group 
   into an item which is not its parent. We can try to maintain positioning in 
   more complex cases like that in this way:

	if ([aGroup hasAncestorItem: item])
	{
		NSPoint rebasedOrigin = [aGroup convertRect: [newChild origin] toItem: item];
	}
	else if ([item hasAncestorItem: aGroup])
	{
		NSPoint rebasedOrigin = [item convertPoint: [newChild origin] fromItem: aGroup];
	} */

/** Moves and inserts the children of the currently selected items which are 
groups into the target item, then removes these remaining empty groups from the 
target item. */
- (void) ungroup: (id)sender
{
	ETLayoutItemGroup *targetItem = (ETLayoutItemGroup *)[self targetItem];
	NSMutableArray *inlinedGroups = [NSMutableArray array];
	NSMutableArray *inlinedItems = [NSMutableArray array];

	[ETLayoutItemGroup disablesAutolayout];

	FOREACHI([self selectedItems], item)
	{
		if ([item isGroup] == NO)
			continue;

		[item setSelected: NO]; // FIXME: A bit a hack to eliminate handles
		[inlinedGroups addObject: item];
		[inlinedItems addObjectsFromArray: [item items]];
		[self inlineGroup: item];
	}
	
	[ETLayoutItemGroup enablesAutolayout];

	NSRect oldUnionFrame = ETUnionRectWithObjectsAndSelector(inlinedGroups, @selector(frame));
	[targetItem updateLayout];
	NSRect newUnionFrame = ETUnionRectWithObjectsAndSelector(inlinedItems, @selector(frame));
	[targetItem setNeedsDisplayInRect: NSUnionRect(oldUnionFrame, newUnionFrame)];
}

@end
