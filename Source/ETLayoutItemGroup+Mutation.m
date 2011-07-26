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
- (int) checkSourceProtocolConformance;
- (NSArray *) itemsFromSourceWithIndexProtocol;
- (NSArray *) itemsFromRepresentedObject;
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
		[self didChangeValueForProperty: @"items"];
		[self setNeedsDisplay: YES];
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
   -handleInsertItem:atIndex: will skip calling 
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

- (void) handleAddItem: (ETLayoutItem *)item
{
	if ([[item parentItem] isEqual: self])
	{
		ETLog(@"WARNING: Trying to add item %@ to the item group %@ it "
			@"already belongs to", item, self);
		return;
	}

	/* Don't touch the model when it is turned into layout items in the reload 
	   phase. We must be sure we won't trigger model updates that would result 
	   in a new UI update/reload when it's already underway. */
	if ([self isReloading] == NO)
	{
		[self mutateRepresentedObjectForAddedItem: item];
	}
		
	[self beginCoalescingModelMutation];

	[self handleAttachItem: item];
	[_layoutItems addObject: item];
#ifdef OBJECTMERGING
	if ([self isPersistent])
	{
		[item becomePersistentInContext: [self editingContext] rootObject: [self rootObject]];
	}
#endif
	[self setHasNewContent: YES];
	if ([self canUpdateLayout])
		[self updateLayout];

	[self endCoalescingModelMutation];
}

- (BOOL) isValidMutationForRepresentedObject: (id)repObject
{
	return ([[self baseItem] shouldMutateRepresentedObject] && [repObject isMutableCollection]);
}

- (void) mutateRepresentedObjectForAddedItem: (ETLayoutItem *)item;
{
	id repObject = [self representedObject];

	if ([self isValidMutationForRepresentedObject: repObject] == NO)
		return;

	ETDebugLog(@"Add %@ in represented object %@", [item representedObject], repObject);
	[repObject addObject: [item representedObject]];
}

- (void) handleInsertItem: (ETLayoutItem *)item atIndex: (int)index
{
	if ([[item parentItem] isEqual: self])
	{
		ETLog(@"WARNING: Trying to insert item %@ in the item group %@ it "
			@"already belongs to", item, self);
		return;
	}

	if ([self isReloading] == NO)
	{
		[self mutateRepresentedObjectForInsertedItem: item atIndex: index];
	}

	[self beginCoalescingModelMutation];

	[self handleAttachItem: item];
	[_layoutItems insertObject: item atIndex: index];
#ifdef OBJECTMERGING
	if ([self isPersistent])
	{
		[item becomePersistentInContext: [self editingContext] rootObject: [self rootObject]];
	}
#endif
	[self setHasNewContent: YES];
	if ([self canUpdateLayout])
		[self updateLayout];

	[self endCoalescingModelMutation];
}

- (void) mutateRepresentedObjectForInsertedItem: (ETLayoutItem *)item atIndex: (int)index
{
	id repObject = [self representedObject];

	if ([self isValidMutationForRepresentedObject: repObject] == NO)
		return;

	ETDebugLog(@"Insert %@ in represented object %@ at index %d", 
		[item representedObject], repObject, index);
	[repObject insertObject: [item representedObject] atIndex: index];
}

- (void) handleRemoveItem: (ETLayoutItem *)item
{
	/* Very important to return immediately, -handleDetachItem: execution would 
	   lead to a weird behavior: the item parent item would be set to nil. */
	if ([[item parentItem] isEqual: self] == NO)
		return;

	/* Take note that -reload calls -removeAllItems. 
	   See -handleAdd:item: to know more. */	
	if ([self isReloading] == NO && [self isCoalescingModelMutation] == NO)
	{
		[self mutateRepresentedObjectForRemovedItem: item];
	}

	[self beginCoalescingModelMutation];

	[self handleDetachItem: item];
	[_layoutItems removeObject: item];
	[self setHasNewContent: YES];
	if ([self canUpdateLayout])
		[self updateLayout];

	[self endCoalescingModelMutation];
}

- (void) mutateRepresentedObjectForRemovedItem: (ETLayoutItem *)item
{
	id repObject = [self representedObject];

	if ([self isValidMutationForRepresentedObject: repObject] == NO)
		return;

	ETDebugLog(@"Remove %@ in represented object %@", [item representedObject], 
		repObject);
	[repObject removeObject: [item representedObject]];
}

/* Set Mutation Handlers */

- (void) handleAddItems: (NSArray *)items
{
	BOOL wasAutolayoutEnabled = [self beginMutate];

	FOREACH(items, item, ETLayoutItem *)
	{
		[self handleAddItem: item];
	}

	[self endMutate: wasAutolayoutEnabled];
}

- (void) handleRemoveItems: (NSArray *)items
{
	BOOL wasAutolayoutEnabled = [self beginMutate];

	FOREACH(items, item, ETLayoutItem *)
	{
		[self handleRemoveItem: item];
	}

	[self endMutate: wasAutolayoutEnabled];
}

/* Collection Protocol Backend */

- (ETLayoutItem *) boxObject: (id)object
{
	ETLayoutItem *item = [object isLayoutItem] ? object : [self itemWithObject: object isValue: [object isCommonObjectValue]];
	
	if ([object isLayoutItem] == NO)
	{
		ETDebugLog(@"Boxed object %@ in item %@ to be inserted in %@", object, item, self);
	}
	return item;
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
			ETDebugLog(@"Will -reloadFromSource");
			return [self itemsFromSourceWithIndexProtocol];
			break;
		case 2:
			ETDebugLog(@"Will -reloadFromRepresentedObject");
			return [self itemsFromRepresentedObject];
			break;
		default:
			ETLog(@"WARNING: source protocol is incorrectly supported by %@.", [self source]);
	}
	
	return nil;
}

- (NSArray *) itemsFromSourceWithIndexProtocol
{
	ETLayoutItemGroup *baseItem = [self baseItem];
	int nbOfItems = [[baseItem source] baseItem: baseItem 
	                   numberOfItemsInItemGroup: self];
	NSMutableArray *itemsFromSource = [NSMutableArray arrayWithCapacity: nbOfItems];

	for (int i = 0; i < nbOfItems; i++)
	{
		ETLayoutItem *item = [[baseItem source] baseItem: baseItem 
		                                     itemAtIndex: i 
		                                     inItemGroup: self];
		
		if (item != nil)
		{
			[itemsFromSource addObject: item];
		}
		else
		{
			[NSException raise: @"ETInvalidReturnValueException" 
				format: @"Item at index %i in %@ returned by source %@ must not be "
				@"nil", i, self, [baseItem source]];
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
			//[self handleAddItem: [self itemWithObject: childRepObject isValue: NO]];
		}
	}
	else
	{
		childItems = [NSArray array];
	}
	
	return childItems;
}

/* Returns 0 when the base item has no source or the source is invalid.

Returns 1 when the base item source conforms to ETLayoutItemGroupIndexSource 
protocol.

Returns 2 when the represented object is expected to provide the content 
(through the collection protocol). */
- (int) checkSourceProtocolConformance
{
	id source = [[self baseItem] source];

	/* We test the receiver source to support that item groups returned by 
	   -baseItem:itemAtIndex:inItemGroup: can provide their content with 
	   -itemsFromRepresentedObject. 
	   In this case -itemsFromRepresentedObject has priority over 
	   -itemsFromSourceWithIndexProtocol. */ 
	if ([source isEqual: [self baseItem]] || [[self source] isEqual: self])
	{
		return 2;
	}
	else if ([source respondsToSelector: @selector(baseItem:numberOfItemsInItemGroup:)])
	{
		if ([source respondsToSelector: @selector(baseItem:itemAtIndex:inItemGroup:)])
		{
			return 1;
		}
		else
		{
			ETLog(@"%@ implements -numberOfItemsInItemGroup: but misses "
				  @"-baseItem:itemAtIndex:inItemGroup: as requested by "
				  @"ETLayoutItemGroupIndexSource protocol.", source);
			return 0;
		}
	}
	else
	{
		ETLog(@"%@ implements neither -baseItem:numberOfItemsInItemGroup: nor "
			  @"-baseItem:itemAtIndex:inItemGroup: as requested by "
			  @"ETLayoutItemGroupIndexSource protocol.", source);
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
