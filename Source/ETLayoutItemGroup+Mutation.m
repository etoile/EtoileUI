/* 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayoutItemGroup+Mutation.h"
#import "ETItemTemplate.h"
#import "ETController.h"
#import "ETEvent.h"
#import "EtoileUIProperties.h"
#import "ETCompatibility.h"

@interface ETLayoutItemGroup (ETSource)
- (BOOL) isReloading;
@end


@implementation ETLayoutItemGroup (ETMutationHandler)

/* Returns whether children have been removed, added or inserted since the last 
layout update.

For example, returns YES when the receiver has been reloaded but the layout 
hasn't yet been updated.<br /> 
Also returns YES when autolayout is disabled and the UI needs to be refreshed by 
calling -updateLayout. */
- (BOOL) hasNewContent
{
	return _hasNewContent;
}
	
/* Sets whether children have been removed, added or inserted since the last 
layout update.

Also invalidates any item-related caches (e.g. -arrangedItems).

-reload calls this method to indicate the layout needs to be updated, otherwise 
the UI won't reflect the latest receiver content. */
- (void) setHasNewContent: (BOOL)flag
{
	_hasNewContent = flag;
	if (_hasNewContent)
	{
		/* When -items has changed, we invalidate our sort/filter caches */
		DESTROY(_sortedItems);
		DESTROY(_arrangedItems);
		_filtered = NO;
		_sorted = NO;
	}
}

/* Would be cleaner if this mutation backend was a singleton object acting as a 
   mutation coordinator for the layout item tree and the related model graph.
   May be refactor  it into a class named ETLayoutItemMutationCoordinator...
   The following methods haven't been turned into class method because of this 
   future refactoring in perspective. */
static 	BOOL _coalescingMutation = NO;

/* Returns whether no model mutations should happen on all represented objects 
   bound to layout items. This is valid for represented objects at every levels 
   in the layout item tree, in other words model mutations aren't just suspended 
   for the receiver.
   If the return value is YES, the mutation handler method
   -handleInsert:item:atIndex: will skip calling 
   -handleModelInsert:item:atIndex: until -endCoalescingModelMutation has been 
   called. This means a node added, removed or inserted into the layout item 
   tree won't result in a collection change on the model side, for example a 
   move into another collection for the represented object bound the node. 
   That's commonly used for preventing the propagation of the implicit removal 
   from the existing parent item that occurs when a layout item is 
   inserted/added to a new parent. */
- (BOOL) isCoalescingModelMutation
{
	return _coalescingMutation;
}

/* Signals model mutations must be discarded until -endCoalescingModelMutation 
   gets called. */
- (void) beginCoalescingModelMutation
{
	_coalescingMutation = YES;
}

/* Signals model mutations must be handled normally by creating a model 
   mutation for each layout item mutation. */
- (void) endCoalescingModelMutation
{
	_coalescingMutation = NO;
}

/* Disables the autolayout and returns whether the autolayout was previously 
enabled.

You must pair every -beginMutate with an -endMutate:.

See also -endMutate:. */
- (BOOL) beginMutate
{
	BOOL wasAutolayoutEnabled = [self isAutolayout];
	[self setAutolayout: NO];
	return wasAutolayoutEnabled;
}

/* Restores autolayout to its previous value, marks the receiver has having 
new content and triggers a layout update.

You must pass the value returned by -beginMutate: in parameter.

When wasAutolayoutEnabled or +isAutolayoutEnabled are NO, the layout update 
won't happen. For example, this would be case on invoking -endMutate: nested 
inside another -begin/endMutate pair.  */
- (void) endMutate: (BOOL)wasAutolayoutEnabled
{
	[self setHasNewContent: YES];
	[self setAutolayout: wasAutolayoutEnabled];

	if ([self canUpdateLayout])
		[self updateLayout];
}

/* Element Mutation Handler */

- (BOOL) handleAdd: (ETEvent *)event item: (ETLayoutItem *)item
{
	//ETDebugLog(@"Add item in %@", self);
	
	if ([[item parentItem] isEqual: self])
	{
		ETLog(@"WARNING: Trying to add item %@ to the item group %@ it "
			@"already belongs to", item, self);
		return NO;
	}
	
	BOOL validatedAdd = YES;

	/* Don't touch the model when it is turned into layout items in the reload 
	   phase. We must be sure we won't trigger model updates that would result 
	   in a new UI update/reload when it's already underway. */
	if ([self isReloading] == NO)
		validatedAdd = [self handleModelAdd: nil item: item];
	
	if (validatedAdd)
	{
		[self beginCoalescingModelMutation];

		[self handleAttachItem: item];
		[_layoutItems addObject: item];
		[self setHasNewContent: YES];
		if ([self canUpdateLayout])
			[self updateLayout];

		[self endCoalescingModelMutation];
	}

	return validatedAdd;
}

- (BOOL) handleModelAdd: (ETEvent *)event item: (ETLayoutItem *)item;
{
	id repObject = [self representedObject];
	// FIXME: Implement
	//BOOL isValidElementType = NO;
	BOOL validatedMutate = YES;

	// FIXME: Rewrite the code below once the source protocol is rethough or 
	// eliminate.
	/*if ([PROVIDER_SOURCE respondsToSelector: @selector(container:addItems:atPath:operation:)])
	{
		NSArray *items = [NSArray arrayWithObject: item];

		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			addItems: items atPath: [self indexPath] operation: event];
	}
	else if ([PROVIDER_SOURCE respondsToSelector: @selector(container:insertItems:atPaths:operation:)])
	{
		NSArray *items = [NSArray arrayWithObject: item];
		NSIndexPath *indexPath = [[self indexPath] indexPathByAddingIndex: [self count]];
		NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
				
		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			insertItems: items atPaths: indexPaths operation: event];
	}*/
	if (validatedMutate && [[self baseItem] shouldMutateRepresentedObject] 
	 && [repObject isMutableCollection])
	{
		ETDebugLog(@"Add %@ in represented object %@", [item representedObject], 
			repObject);
		[repObject addObject: [item representedObject]];
	}
	
	return validatedMutate;
}

- (BOOL) handleInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index
{
	if ([[item parentItem] isEqual: self])
	{
		ETLog(@"WARNING: Trying to insert item %@ in the item group %@ it "
			@"already belongs to", item, self);
		return NO;
	}
	
	BOOL validatedInsert = YES;
	
	if ([self isReloading] == NO)
		validatedInsert = [self handleModelInsert: nil item: item atIndex: index];
	
	if (validatedInsert)
	{
		[self beginCoalescingModelMutation];

		[self handleAttachItem: item];
		[_layoutItems insertObject: item atIndex: index];
		[self setHasNewContent: YES];
		if ([self canUpdateLayout])
			[self updateLayout];

		[self endCoalescingModelMutation];
	}

	return validatedInsert;

// NOTE: The code below is kept as an example to implement selection caching 
// at later time if better performance are necessary.
#if 0	
	NSMutableIndexSet *indexes = [self selectionIndexes];
	
	/* In this example, 1 means selected and 0 unselected.
       () represents old item index shifted by insertion
	   
       Item index      0   1   2   3   4
       Item selected   0   1   0   1   0
   
       When you call shiftIndexesStartingAtIndex: 2 by: 1, you get:
       Item index      0   1   2   3   4
       Item selected   0   1   0   0   1  0
       Now by inserting an item at 2:
       Item index      0   1   2  (2) (3) (4)
       Item selected   0   1   0   0   1   0
		   
       That's precisely the selections state we expect once item at index 2
       has been removed. */
	
	[item setParentItem: nil];
	[_layoutItems insertObject: item atIndex: index];
	[indexes shiftIndexesStartingAtIndex: index by: 1];
	[self setSelectionIndexes: indexes];
#endif
}

- (BOOL) handleModelInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index
{
	id repObject = [self representedObject];
	// FIXME: Implement
	//BOOL isValidElementType = NO;
	BOOL validatedMutate = YES;

	// FIXME: Rewrite the code below once the source protocol is rethough or 
	// eliminate.		
	/*if ([PROVIDER_SOURCE respondsToSelector: @selector(container:insertItems:atPaths:operation:)])
	{
		NSArray *items = [NSArray arrayWithObject: item];
		NSIndexPath *indexPath = [[self indexPath] indexPathByAddingIndex: index];
		NSArray *indexPaths = [NSArray arrayWithObject: indexPath];

		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			insertItems: items atPaths: indexPaths operation: event];
	}*/
	if (validatedMutate && [[self baseItem] shouldMutateRepresentedObject] 
	 && [repObject isMutableCollection])
	{
		ETDebugLog(@"Insert %@ in represented object %@ at index %d", 
			[item representedObject], repObject, index);
		[repObject insertObject: [item representedObject] atIndex: index];
	}
	
	return validatedMutate;
}

- (BOOL) handleRemove: (ETEvent *)event item: (ETLayoutItem *)item
{
	/* Very important to return immediately, -handleDetachItem: execution would 
	   lead to a weird behavior: the item parent item would be set to nil. */
	if ([[item parentItem] isEqual: self] == NO)
		return NO;

	BOOL validatedRemove = YES;

	/* Take note that -reload calls -removeAllItems. 
	   See -handleAdd:item: to know more. */	
	if ([self isReloading] == NO && [self isCoalescingModelMutation] == NO)
		validatedRemove = [self handleModelRemove: nil item: item];

	if (validatedRemove)
	{
		[self beginCoalescingModelMutation];

		[self handleDetachItem: item];
		[_layoutItems removeObject: item];
		[self setHasNewContent: YES];
		if ([self canUpdateLayout])
			[self updateLayout];

		[self endCoalescingModelMutation];
	}
	
	return validatedRemove;

// NOTE: The code below is kept as an example to implement selection caching 
// at later time if better performance are necessary.
#if 0	
	NSMutableIndexSet *indexes = [self selectionIndexes];
	int removedIndex = [self indexOfItem: item];
	
	if ([indexes containsIndex: removedIndex])
	{
		/* In this example, 1 means selected and 0 unselected.
		
		   Item index      0   1   2   3   4
		   Item selected   0   1   0   1   0
		   
		   When you call shiftIndexesStartingAtIndex: 3 by: -1, you get:
		   Item index      0   1   2   3   4
		   Item selected   0   1   1   0   0
		   Now by removing item 2:
		   Item index      0   1   3   4
		   Item selected   0   1   1   0   0
		   		   
		   That's precisely the selections state we expect once item at index 2
		   has been removed. */
		[indexes shiftIndexesStartingAtIndex: removedIndex + 1 by: -1];
		
		/* Verify basic shitfing errors before really updating the selection */
		if ([[self selectionIndexes] containsIndex: removedIndex + 1])
		{
			NSAssert([indexes containsIndex: removedIndex], 
				@"Item at the index of the removal must remain selected because it was previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex - 1])
		{
			NSAssert([indexes containsIndex: removedIndex - 1], 
				@"Item before the index of the removal must remain selected because it was previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex + 1] == NO)
		{
			NSAssert([indexes containsIndex: removedIndex] == NO, 
				@"Item at the index of the removal must not be selected because it wasn't previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex - 1] == NO)
		{
			NSAssert([indexes containsIndex: removedIndex - 1] == NO, 
				@"Item before the index of the removal must not be selected because it wasn't previously");
		}
		[self setSelectionIndexes: indexes];
	}
#endif

}

- (BOOL) handleModelRemove: (ETEvent *)event item: (ETLayoutItem *)item
{
	id repObject = [self representedObject];
	 // FIXME: Implement
	//BOOL isValidElementType = NO;
	BOOL validatedMutate = YES;

	// FIXME: Rewrite the code below once the source protocol is rethough or 
	// eliminate.		
	/*if ([PROVIDER_SOURCE respondsToSelector: @selector(container:removeItemsAtPaths:operation:)])
	{
		NSArray *indexPaths = [NSArray arrayWithObject: [item indexPath]];

		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			removeItemsAtPaths: indexPaths operation: event];
	}*/
	if (validatedMutate && [[self baseItem] shouldMutateRepresentedObject] 
	 && [repObject isMutableCollection])
	{
		ETDebugLog(@"Remove %@ in represented object %@", [item representedObject], 
			repObject);
		[repObject removeObject: [item representedObject]];
	}
	
	return validatedMutate;
}

/* Set Mutation Handlers */

- (void) handleAdd: (ETEvent *)event items: (NSArray *)items
{
	BOOL wasAutolayoutEnabled = [self beginMutate];

	FOREACH(items, item, ETLayoutItem *)
	{
		[self handleAdd: event item: item];
	}

	[self endMutate: wasAutolayoutEnabled];
}

- (void) handleRemove: (ETEvent *)event items: (NSArray *)items
{
	BOOL wasAutolayoutEnabled = [self beginMutate];

	FOREACH(items, item, ETLayoutItem *)
	{
		[self handleRemove: event item: item];
	}

	[self endMutate: wasAutolayoutEnabled];
}

/* Collection Protocol Backend */

- (void) handleAdd: (ETEvent *)event object: (id)object
{
	id item = [object isLayoutItem] ? object : [self itemWithObject: object isValue: [object isCommonObjectValue]];
	
	if ([object isLayoutItem] == NO)
	{
		ETDebugLog(@"Boxed object %@ in item %@ to be added to %@", object, item, self);
	}

	[self handleAdd: event item: item];
}

- (void) handleInsert: (ETEvent *)event object: (id)object
{

}

- (void) handleRemove: (ETEvent *)event object: (id)object
{
	/* Try to remove object by matching it against child items */
	if ([object isLayoutItem] && [self containsItem: object])
	{
		[self handleRemove: event item: object];
	}
	else
	{
		/* Remove items with boxed object matching the object to remove */	
		NSArray *itemsMatchedByRepObject = nil;
		
		itemsMatchedByRepObject = [[self items] 
			objectsMatchingValue: object forKey: @"representedObject"];
		[self handleRemove: event items: itemsMatchedByRepObject];
		
		itemsMatchedByRepObject = [[self items] 
			objectsMatchingValue: object forKey: @"value"];
		[self handleRemove: event items: itemsMatchedByRepObject];
	}
}

/* Providing */

- (BOOL) isReloading
{
	return _reloading;
}

- (NSArray *) itemsFromSource
{
	switch ([self checkSourceProtocolConformance])
	{
		case 1:
			ETDebugLog(@"Will -reloadFromFlatSource");
			/* We allow the flat source protocol to return item groups that 
			   will load their child items based on their represented object 
			   content. */
			if ([self isEqual: [self baseItem]])
			{
				return [self itemsFromFlatSource];
			}
			else
			{
				return [self itemsFromRepresentedObject];
			}
			break;
		case 2:
			ETDebugLog(@"Will -reloadFromTreeSource");
			return [self itemsFromTreeSource];
			break;
		case 3:
			ETDebugLog(@"Will -reloadFromRepresentedObject");
			return [self itemsFromRepresentedObject];
			break;
		default:
			ETLog(@"WARNING: source protocol is incorrectly supported by %@.", [self source]);
	}
	
	return nil;
}

- (NSArray *) itemsFromFlatSource
{
	ETLayoutItemGroup *baseItem = [self baseItem];
	int nbOfItems = [[baseItem source] numberOfItemsInItemGroup: baseItem];
	NSMutableArray *itemsFromSource = [NSMutableArray arrayWithCapacity: nbOfItems];

	for (int i = 0; i < nbOfItems; i++)
	{
		ETLayoutItem *item = [[baseItem source] itemGroup: baseItem itemAtIndex: i];
		[itemsFromSource addObject: item];
	}
	
	return itemsFromSource;
}

- (NSArray *) itemsFromTreeSource
{
	ETLayoutItemGroup *baseItem = [self baseItem];
	// NOTE: [self indexPathFromItem: baseItem] is equal to [baseItem indexPathForItem: self]
	NSIndexPath *indexPath = [self indexPathFromItem: baseItem];
	
	ETDebugLog(@"-itemsFromTreeSource in %@", self);
	
	/* Request number of items to the source by passing receiver index path 
	   expressed in a way relative to the base item */
	int nbOfItems = [[baseItem source] itemGroup: baseItem
	                         numberOfItemsAtPath: indexPath];
	NSMutableArray *itemsFromSource = [NSMutableArray arrayWithCapacity: nbOfItems];

	for (int i = 0; i < nbOfItems; i++)
	{
		NSIndexPath *indexSubpath = [indexPath indexPathByAddingIndex: i];
		/* Request item to the source by passing item index path expressed in a
		   way relative to the base item */
		ETLayoutItem *item = [[baseItem source] itemGroup: baseItem 
		                                       itemAtPath: indexSubpath];
		
		//ETLog(@"Retrieved item %@ known by path %@", item, indexSubpath);

		if (item != nil)
		{
			[itemsFromSource addObject: item];
		}
		else
		{
			[NSException raise: @"ETInvalidReturnValueException" 
				format: @"Item at path %@ returned by source %@ must not be "
				@"nil", indexSubpath, [baseItem source]];
		}
	}
	
	return itemsFromSource;
}

/* Makes the represented object returns layout items as a source would but only
   turning immediate children into ETLayoutItem or ETLayoutItemGroup instances. 
   An empty array of items is returned when the represented object isn't a 
   collection. This method is only invoked if thereceivertem bound to the 
   represented object is an item group. */
- (NSArray *) itemsFromRepresentedObject
{
	NSMutableArray *childItems = nil;
	id repObject = [self representedObject];
	
	if ([repObject isCollection])
	{
		// TODO: Replace existing code once ETCollection is implemented everywhere
		//id repObject = [self representedObject];
		//NSEnumerator *e = [repObject objectEnumerator];
		//NSMutableArray = [NSMutableArray arrayWithCapacity: [repObject count]];
		NSArray *contentObjects = [repObject contentArray];
		NSEnumerator *e = [contentObjects objectEnumerator];
		id childRepObject = nil;
		
		childItems = [NSMutableArray arrayWithCapacity: [contentObjects count]];
		
		while ((childRepObject = [e nextObject]) != nil)
		{
			[childItems addObject: [self itemWithObject: childRepObject isValue: NO]];
			//[self handleAdd: nil item: [self itemWithObject: childRepObject isValue: NO]];
		}
	}
	else
	{
		childItems = [NSArray array];
	}
	
	return childItems;
}

/** Returns 0 when source doesn't conform to any parts of 
ETLayoutItemGroupIndexSource or ETLayoutItemGroupPathSource informal protocols.

Returns 1 when source conform to ETLayoutItemGroupIndexSource protocol for flat 
collections and display of items in a linear style.

Returns 2 when source conform to ETLayoutItemGroupPathSource protocol for tree 
collections and display of items in a hiearchical style.

If tree collection part of the protocol is implemented through 
-itemGroup:numberOfItemsAtPath: , ETLayoutItemGroup by default ignores flat 
collection part of protocol like -numberOfItemsInItemGroup:. */
- (int) checkSourceProtocolConformance
{
	id source = [[self baseItem] source];

	if ([source isEqual: [self baseItem]])
	{
		return 3;
	}
	else if ([source respondsToSelector: @selector(itemGroup:numberOfItemsAtPath:)])
	{
		if ([source respondsToSelector: @selector(itemGroup:itemAtPath:)])
		{
			return 2;
		}
		else
		{
			ETLog(@"%@ implements itemGroup:numberOfItemsAtPath: but misses "
				  @"itemGroup:itemAtPath: as requested by "
				  @"ETLayoutItemGroupPathSource protocol.", source);
			return 0;
		}
	}
	else if ([source respondsToSelector: @selector(numberOfItemsInItemGroup:)])
	{
		if ([source respondsToSelector: @selector(itemGroup:itemAtIndex:)])
		{
			return 1;
		}
		else
		{
			ETLog(@"%@ implements numberOfItemsInItemGroup: but misses "
				  @"itemGroup:itemAtIndex as  requested by "
				  @"ETLayoutItemGroupIndexSource  protocol.", source);
			return 0;
		}
	}
	else
	{
		ETLog(@"%@ implements neither numberOfItemsInItemGroup: nor "
			  @"itemGroup:numberOfItemsAtPath: as requested by "
			  @"ETLayoutItemGroupIndexSource and ETLayoutItemGroupPathSource "
			  @"protocol.", source);
		return 0;
	}
}

/* The receiver registers itself as an observer on the source object in 
-setSource:. See also ETSourceDidUpdateNotification.*/
- (void) sourceDidUpdate: (NSNotification *)notif
{
	NSParameterAssert([notif object] == [self source]);
	[self reloadIfNeeded];
}

/* Controller Coordination */

- (id <ETTemplateProvider>) lookUpTemplateProvider
{
	id <ETTemplateProvider> provider = [self controller];

	if (nil == provider)
	{
		provider = [[self baseItem] controller];
	}
	if (nil == provider)
	{
		provider = [ETController basicTemplateProvider];
	}
	return provider;
}

/** Creates a new ETLayoutItem or ETLayoutItemGroup object based on whether 
object return NO or YES to -isCollection. 
If isValue is equal to YES, the given object is set as the value rather than a 
represented object on the item. See -[ETLayoutItem setValue:].

We delegate the item creation to the right template looked up in the receiver 
controller or the base item controller (no receiver controller). As a last 
resort (no base item controller), we use +[ETController basicTemplateProvider].
See -[ETItemTemplate newItemWithRepresentedObject:options:].

The returned object is autoreleased. */
- (id) itemWithObject: (id)object isValue: (BOOL)isValue
{
	id <ETTemplateProvider> provider = [self lookUpTemplateProvider];
	ETUTI *type = ([object isCollection] ? [provider currentGroupType] : [provider currentObjectType]);
	ETItemTemplate *template = [provider templateForType: type];
	ETLayoutItem *item = [template newItemWithRepresentedObject: object options: nil];

	// TODO: Move that in ETItemTemplate with a kETTemplateOptionIsValue in the options dict.
 	/* If the object is a simple value object rather than a true model object
	   we don't set it as represented object but as a value. */
	if (nil != object && isValue)
	{
		[item setValue: object];
	}

	return AUTORELEASE(item);
}

@end
