/* 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETKeyValuePair.h>
#import <EtoileFoundation/ETIndexValuePair.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayoutItemGroup+Mutation.h"
#import "ETLayoutItemGroup+Private.h"
#import "ETItemTemplate.h"
#import "ETController.h"
#import "ETEvent.h"
#import "EtoileUIProperties.h"
#import "ETCompatibility.h"

@interface ETLayoutItemGroup (ETSource)
@property (nonatomic, getter=isReloading, readonly) BOOL reloading;
- (int) checkSourceProtocolConformance;
@property (nonatomic, readonly) NSArray *itemsFromSourceWithIndexProtocol;
@property (nonatomic, readonly) NSArray *itemsFromRepresentedObject;
@end


@implementation ETLayoutItemGroup (ETMutationHandler)

/** Returns whether children have been removed, added or inserted since the last 
layout update.

For example, returns YES when the receiver has been reloaded but the layout 
hasn't yet been updated.<br /> 
Also returns YES when autolayout is disabled and the UI needs to be refreshed by 
calling -updateLayout. */
- (BOOL) hasNewContent
{
	return _hasNewContent;
}
	
/** Sets whether children have been removed, added or inserted since the last 
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
		_sortedItems = nil;
		_arrangedItems = nil;
		_filtered = NO;
		_sorted = NO;
		// TODO: Move -willChangeForProperty: just before the mutation
		[self willChangeValueForProperty: @"items"];
		[self didChangeValueForProperty: @"items"];
	}
}

- (void) didChangeContentWithMoreComing: (BOOL)moreComing
{
	if (moreComing)
		return;

	[self setHasNewContent: YES];
	[self setNeedsLayoutUpdate];
	[self didUpdateContent];
}

- (void) didUpdateContent
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName: ETCollectionDidUpdateNotification object: self];
}

/* Would be cleaner if this mutation backend was a singleton object acting as a 
   mutation coordinator for the layout item tree and the related model graph.
   May be refactor  it into a class named ETLayoutItemMutationCoordinator...
   The following methods haven't been turned into class method because of this 
   future refactoring in perspective. */
static 	BOOL _coalescingMutation = NO;

/** Returns whether no model mutations should happen on all represented objects 
bound to layout items. This is valid for represented objects at every levels 
in the layout item tree, in other words model mutations aren't just suspended 
for the receiver.

If the return value is YES, the mutation handler method 
-handleInsertItem:atIndex: will skip calling -mutateRepresentedObjectForInsertedItem: 
until -endCoalescingModelMutation has been called. This means a node added, 
removed or inserted into the layout item tree won't result in a collection 
change on the model side, for example a move into another collection for the 
represented object bound the node. 

That's commonly used for preventing the propagation of the implicit removal from 
the existing parent item that occurs when a layout item is inserted/added to a 
new parent. */
- (BOOL) isCoalescingModelMutation
{
	return _coalescingMutation;
}

/** Signals model mutations must be discarded until -endCoalescingModelMutation 
gets called. */
- (void) beginCoalescingModelMutation
{
	_coalescingMutation = YES;
}

/** Signals model mutations must be handled normally by creating a model 
mutation for each layout item mutation. */
- (void) endCoalescingModelMutation
{
	_coalescingMutation = NO;
}

/** Returns whether an item is being inserted or removed among the receiver 
items (descendant items not being taken in account).

If -representedObjectDidUpdate is called back, the receiver must not be reloaded. 
To do so, -canReload checks -isMutating. */
- (BOOL) isMutating
{
	return _mutating;
}

/* Element Mutation Handler */

- (BOOL) isValidMutationForRepresentedObject: (id)anObject
{
	return ([[self sourceItem] shouldMutateRepresentedObject] && [anObject isMutableCollection]);
}

- (NSIndexSet *) insertionIndexesForIndex: (NSUInteger)index
{
    return (index == ETUndeterminedIndex ? INDEXSET([self numberOfItems]) : INDEXSET(index));
}

- (void) handleInsertItem: (ETLayoutItem *)item
                  atIndex: (NSUInteger)index 
                     hint: (id)hint 
               moreComing: (BOOL)moreComing
{
	NSParameterAssert(item != nil);

	if ([[item parentItem] isEqual: self])
	{
		ETLog(@"WARNING: Trying to insert item %@ in the item group %@ it "
			@"already belongs to", item, self);
		return;
	}

    [self willChangeValueForProperty: @"items"
                           atIndexes: [self insertionIndexesForIndex: index]
                         withObjects: @[item]
                        mutationKind: ETCollectionMutationKindInsertion];
	_mutating = YES;

	if ([self isReloading] == NO)
	{
		[self mutateRepresentedObjectForInsertedItem: item atIndex: index hint: hint];
	}

	[self beginCoalescingModelMutation];

	[self attachItems: @[item] atIndexes: INDEXSET(index)];
	[self didChangeContentWithMoreComing: moreComing];

	[self endCoalescingModelMutation];

	_mutating = NO;
    [self didChangeValueForProperty: @"items"
                          atIndexes: [self insertionIndexesForIndex: index]
                        withObjects: @[item]
                       mutationKind: ETCollectionMutationKindInsertion];
	[self didAttachItem: item];
}

- (void) mutateRepresentedObjectForInsertedItem: (ETLayoutItem *)item 
                                        atIndex: (NSUInteger)index 
                                           hint: (id)aHint
{
	id parentCollection = [self representedObject];

	if ([self isValidMutationForRepresentedObject: parentCollection] == NO)
		return;

	id value = [item representedObject];

	ETDebugLog(@"Insert %@ in %@ at %d of %@", value, parentCollection, index, self);

	id insertedValue = value;
	id hint = aHint;

	if ([value isKeyValuePair])
	{
		insertedValue = [(ETKeyValuePair *)value value];
		hint = value;
	}
	if ([value isIndexValuePair])
	{
		insertedValue = [(ETIndexValuePair *)value value];
		hint = value;
		if ([(ETIndexValuePair *)value index] == ETUndeterminedIndex)
		{
			[(ETIndexValuePair *)value setIndex: index];
		}
		ETAssert(index == [(ETIndexValuePair *)value index]);
	}

	[parentCollection insertObject: insertedValue atIndex: index hint: hint];
}

- (NSIndexSet *) removalIndexesForItem: (ETLayoutItem *)item atIndex: (NSUInteger)index
{
    NSUInteger removalIndex = index;

    if (removalIndex == ETUndeterminedIndex)
    {
        ETAssert(item != nil);
        removalIndex = [_items indexOfObject: item];
        ETAssert(removalIndex != NSNotFound);
    }
    return INDEXSET(removalIndex);
}

- (void) handleRemoveItem: (ETLayoutItem *)item
                  atIndex: (NSUInteger)index 
                     hint: (id)hint 
               moreComing: (BOOL)moreComing
{
	NSParameterAssert(item != nil);

	/* We must return immediately, otherwise -detachItems:atIndexes: would
	   result in the item parent item being set to nil. */
	if ([[item parentItem] isEqual: self] == NO)
		return;

    // FIXME: For batch mutation, the indexes are invalid, because we don't
    // snapshot the item collection.
    NSIndexSet *indexes = [self removalIndexesForItem: item atIndex: index];

    [self willChangeValueForProperty: @"items"
                           atIndexes: indexes
                         withObjects: @[item]
                        mutationKind: ETCollectionMutationKindRemoval];
	_mutating = YES;

	/* Take note that -reload calls -removeAllItems. 
	   See -handleAdd:item: to know more. */	
	if ([self isReloading] == NO && [self isCoalescingModelMutation] == NO)
	{
		[self mutateRepresentedObjectForRemovedItem: item atIndex: index hint: hint];
	}

	[self beginCoalescingModelMutation];

	[self detachItems: @[item] atIndexes: indexes];
	[self didChangeContentWithMoreComing: moreComing];

	[self endCoalescingModelMutation];

	_mutating = NO;
    [self didChangeValueForProperty: @"items"
                          atIndexes: indexes
                        withObjects: @[item]
                       mutationKind: ETCollectionMutationKindRemoval];
	[self didDetachItem: item];
}

- (void) mutateRepresentedObjectForRemovedItem: (ETLayoutItem *)item
                                       atIndex: (NSUInteger)index 
                                          hint: (id)aHint
{
	id parentCollection = [self representedObject];

	if ([self isValidMutationForRepresentedObject: parentCollection] == NO)
		return;

	id value = [item representedObject];

	ETDebugLog(@"Remove %@ in %@ of %@", value, parentCollection, self);

	id insertedValue = value;
	id hint = aHint;
	
	if ([value isKeyValuePair])
	{
		insertedValue = [(ETKeyValuePair *)value value];
		hint = value;
	}
	if ([value isIndexValuePair])
	{
		insertedValue = [(ETIndexValuePair *)value value];
		hint = value;
		/* For -removeItem:, index is undetermined and doesn't match the value index */
		ETAssert(index == [(ETIndexValuePair *)value index] || index == ETUndeterminedIndex);
	}

	[parentCollection removeObject: insertedValue atIndex: index hint: hint];
}

/* Set Mutation Handlers */

- (void) handleAddItems: (NSArray *)items
{
	for (ETLayoutItem *item in items)
	{
		[self handleInsertItem: item atIndex: _items.count hint: nil moreComing: YES];
	}
	[self didChangeContentWithMoreComing: NO];
}

- (void) handleRemoveItems: (NSArray *)items
{
	for (ETLayoutItem *item in items)
	{
		[self handleRemoveItem: item atIndex: ETUndeterminedIndex hint: nil moreComing: YES];
	}
	[self didChangeContentWithMoreComing: NO];
}

/* Collection Protocol Backend */

/** Returns the object boxed into a layout item if needed.

If the object is a valid item, no boxing occurs and the item object is returned 
as is, otherwise the returned item uses the object as a represented object.

When boxingForced is YES, the boxing occurs in all cases, if the object is an 
item, it is used as a represented object bound to the returned item. */
- (ETLayoutItem *) boxObject: (id)object forced: (BOOL)boxingForced
{
	if (boxingForced == NO && [object isLayoutItem])
	{
	 	return object;
	}

	ETLayoutItem *item = [self itemWithObject: object isValue: [object isCommonObjectValue]];

	ETDebugLog(@"Boxed object %@ in item %@ to be inserted in %@", object, item, self);
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
	ETLayoutItemGroup *sourceItem = [self sourceItem];
	int nbOfItems = [[sourceItem source] baseItem: sourceItem
	                     numberOfItemsInItemGroup: self];
	NSMutableArray *itemsFromSource = [NSMutableArray arrayWithCapacity: nbOfItems];

	for (int i = 0; i < nbOfItems; i++)
	{
		ETLayoutItem *item = [[sourceItem source] baseItem: sourceItem
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
				@"nil", i, self, [sourceItem source]];
		}
	}
	[self didChangeContentWithMoreComing: NO];
	
	return itemsFromSource;
}

/** Makes the represented object returns layout items as a source would but only
turning immediate children into ETLayoutItem or ETLayoutItemGroup instances.

An empty array of items is returned when the represented object isn't a 
collection. 

This method is only invoked if the receiver item bound to the represented object 
is an item group. */
- (NSArray *) itemsFromRepresentedObject
{
	if ([[self representedObject] isCollection] == NO)
        return @[];

    NSMutableArray *items = nil;
    id collection = [self representedObject];

    /* Project the collection to get represented objects for future children */
    if ([collection isKeyed] || [collection isKindOfClass: [ETCollectionViewpoint class]])
    {
        // NOTE: This section must remains in sync with -[ETItemTemplate newItemWithURL:options:]
        if ([collection respondsToSelector: @selector(viewpointArray)])
        {
            collection = [collection viewpointArray];
        }
        else
        {
            collection = [collection arrayRepresentation];
        }
    }
    ETAssert([[self representedObject] count] == [collection count]);

    items = [NSMutableArray arrayWithCapacity: [collection count]];

    /* Don't enumerate the collection directly. For keyed collections, this 
       is critical since the enumeration applies to the keys or key-value 
       pairs (ETAspectCategory and ETAspectRepository whose -content is a 
       key-value pair array). Enumerating key-value pairs rather than 
       the keyed collection values is supported but must be decided at 
       projection time (see above). */
    for (id object in [collection objectEnumerator])
    {
        [items addObject: [self itemWithObject: object isValue: NO]];
        // NOTE: Would it be a good idea to use...
        //[self handleAddItem: [self itemWithObject: object isValue: NO]];
    }
	
	return items;
}

/** Returns 0 when the base item has no source or the source is invalid.

Returns 1 when the base item source conforms to ETLayoutItemGroupIndexSource 
protocol.

Returns 2 when the represented object is expected to provide the content 
(through the collection protocol). */
- (int) checkSourceProtocolConformance
{
	id source = [[self sourceItem] source];

	/* We test the receiver source to support that item groups returned by 
	   -baseItem:itemAtIndex:inItemGroup: can provide their content with 
	   -itemsFromRepresentedObject. 
	   In this case -itemsFromRepresentedObject has priority over 
	   -itemsFromSourceWithIndexProtocol. */ 
	if ([source isEqual: [self sourceItem]] || [[self source] isEqual: self])
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

/** Note: The receiver registers itself as an observer on the source object in 
-setSource:. 

See also ETSourceDidUpdateNotification.*/
- (void) sourceDidUpdate: (NSNotification *)notif
{
	NSParameterAssert([notif object] == [self source]);
	[self reloadIfNeeded];
}

/** Note: The receiver registers itself as an observer on the represented object 
in -setReprenstedObject:. 

See also ETCollectionDidUpdateNotification.*/
- (void) representedObjectCollectionDidUpdate: (NSNotification *)notif
{
	NSParameterAssert([notif object] == [self representedObject]);
	[self reloadIfNeeded];
}

/* Controller Coordination */

- (id <ETTemplateProvider>) lookUpTemplateProvider
{
	id <ETTemplateProvider> provider = [[self controllerItem] controller];

	// NOTE: If needed, we could introduce a overridable method 
	// -[ETController templateProviderFallback] (or -templateProvider that 
	// returns self) that makes possible to reuse parent controller templates.
	if (nil == provider || [provider objectGraphContext] != [self objectGraphContext])
	{
		provider = [ETController basicTemplateProviderForObjectGraphContext: [self objectGraphContext]];
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
	ETUTI *type = [object UTI];
	ETItemTemplate *template = [provider templateForType: type];

	if (template == nil)
	{
		type = ([object isCollection] ? [provider currentGroupType] : [provider currentObjectType]);
		template = [provider templateForType: type];
	}
	if (template == nil)
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"Found no template in %@ for %@", provider, type];
	}

	ETLayoutItem *item = [template newItemWithRepresentedObject: object options: nil];
	ETAssert(item != nil);
	return item;
}

@end
