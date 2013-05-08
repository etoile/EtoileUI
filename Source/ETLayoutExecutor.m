/*
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETLayout.h"
#import "ETCompatibility.h"


@implementation ETLayoutExecutor

static ETLayoutExecutor *sharedInstance = nil;

+ (void) initialize
{
	if ([self isEqual: [ETLayoutExecutor class]] == NO)
		return;

	sharedInstance = [[self alloc] init];
}

/** Returns the shared layout executor. */
+ (id) sharedInstance
{
	return sharedInstance;
}

/* <init />
Initializes and returns a new layout executor. */
- (id) init
{
	SUPERINIT;
	_scheduledItems = [[NSMutableSet alloc] init];
	return self;
}

- (void) dealloc
{
	DESTROY(_scheduledItems);
	[super dealloc];
}

/** Schedules the given item to have its layout updated when the control returns 
to the run loop (in other words when the current event has been handled). */
- (void) addItem: (ETLayoutItem *)anItem
{
	[_scheduledItems addObject: anItem];
}

/** Unschedules the given item as needing a layout update.

See also -addItem:. */
- (void) removeItem: (ETLayoutItem *)anItem
{
	[_scheduledItems removeObject: anItem];
}

/** Unschedules the given items as needing a layout update.

See also -removeItem: and -addItem:. */
- (void) removeItems: (NSSet *)items
{
	[_scheduledItems minusSet: items];
}

/** Unschedules all the items previously added as needing a layout update. */
- (void) removeAllItems
{
	[_scheduledItems removeAllObjects];
}

/** Returns whether the item is scheduled to have its layout updated when 
the control returns to the run loop. */
- (BOOL) containsItem: (ETLayoutItem *)anItem
{
	return [_scheduledItems containsObject: anItem];
}

/** Returns YES when no layout update is scheduled (no dirty items). */
- (BOOL) isEmpty
{
	return[_scheduledItems isEmpty];
}

/** Returns whether the parent layout depends on the given item layout result. */
- (BOOL) isFlexibleItem: (ETLayoutItem *)anItem
{
	return ([anItem usesLayoutBasedFrame] || [[anItem layout] isContentSizeLayout] || [[[anItem parentItem] layout] isLayoutExecutionItemDependent]);
}

/** Inserts the item in the queue, in a way that ensures flexible items have 
their layout updated before their parent item if the latter is flexible.

A flexible item is a item which returns YES to -isFlexibleItem:. */
- (void) insertItem: (ETLayoutItem *)anItem 
inFlexibleItemQueue: (NSMutableArray *)flexibleItemQueue
{
	RETAIN(anItem);
	[flexibleItemQueue removeObject: anItem];

	int nbOfQueuedItems = [flexibleItemQueue count];

	for (int i = 0; i < nbOfQueuedItems; i++)
	{
		ETLayoutItem *queuedItem = [flexibleItemQueue objectAtIndex: i];
		/* The item to insert is a valid predecessor of the queued item.

		   Note: [[queuedItem parentItem] isEqual: anItem] would mean anItem 
		   is the queued item successor, because the queued item is its child. */
		BOOL isQueuedItemPredecessor = [queuedItem isEqual: [anItem parentItem]];

		if (isQueuedItemPredecessor)
		{
			// NOTE: queuedItem is moved to i + 1
			[flexibleItemQueue insertObject: anItem atIndex: i];
			break;
		}
	}
	
	BOOL wasInserted = ([flexibleItemQueue count] > nbOfQueuedItems);

	if (wasInserted == NO)
	{
		[flexibleItemQueue addObject: anItem];
	}

	RELEASE(anItem);
}

/** Schedules a parent item to have its layout updated.

If the item hasn't been processed as a dirty item (not in the dirty items or not 
checked by the iteration in -executeWithDirtyItems: yet), then it is marked as 
dirty.<br />
Otherwise the item might have to be moved to a new position in the flexible item 
queue (if it uses a layout based frame), to ensure its will receive its layout 
update once all its children have receive their own.   */
- (void) scheduleParentItem: (ETLayoutItemGroup *)parentItem 
                  processed: (BOOL)hasBeenProcessed
        inFlexibleItemQueue: (NSMutableArray *)flexibleItemQueue
                 dirtyItems: (NSMutableSet *)dirtyItems
{
	/* If the parent item has already been processed as a dirty item */
	if (hasBeenProcessed)
	{
		// Same as [flexibleFrameItems containsObject: parentItem]
		if ([self isFlexibleItem: parentItem] == NO)
			return;

		[self insertItem: parentItem inFlexibleItemQueue: flexibleItemQueue];
	}
	else
	{
		// If parent item uses a layout based frame, it must come after its child 
		// in the flexibleFrameItems array because there is a dependency on  its 
		// child frame to compute its own.
		// We can ensure that by adding it the dirty items not yet processed.
		[dirtyItems addObject: parentItem];
	}
}

/** Marks the opaque item as having new content to get hierarchical widget 
layouts such as ETOutlineLayout calls -reloadData. 
 
-reloadData will show any mutation on a descendant item content.

We let the descendant item marked as having new content, although most widget 
layouts won't use that. Future layout updates involving non-opaque layouts on 
this item will reset hasNewContent (the layout update extra work due to 
hasNewContent is going to be minimal). */
- (void)updateHasNewContentForOpaqueItem: (ETLayoutItem *)opaqueItem
                          descendantItem: (ETLayoutItem *)item
{
	if ([opaqueItem isGroup] == NO || [item isGroup] == NO)
		return;

	BOOL hasNewContent = ([(ETLayoutItemGroup *)opaqueItem hasNewContent]
		|| [(ETLayoutItemGroup *)item hasNewContent]);

	[(ETLayoutItemGroup *)opaqueItem setHasNewContent: hasNewContent];
}

/** Reorders the dirty items and marks additional items as dirty to respect the 
layout update constraints, then tells the reordered items to update their layout. */
- (void) executeWithDirtyItems: (NSSet *)scheduledItems
{
	NSMutableSet *dirtyItems = [NSMutableSet setWithSet: scheduledItems];
	NSMutableSet *nonFlexibleItems = [NSMutableSet set];
	NSMutableArray *flexibleItemQueue = [NSMutableArray array];
	NSMutableSet *processedItems = [NSMutableSet set];

	while ([dirtyItems count] > 0)
	{
		ETLayoutItem *item = [dirtyItems anyObject];
		ETLayoutItem *opaqueItem = [item ancestorItemForOpaqueLayout];
		BOOL hasOpaqueAncestorItem = (opaqueItem != item && opaqueItem != nil);

		if (hasOpaqueAncestorItem)
		{
			[dirtyItems addObject: opaqueItem];
			[self updateHasNewContentForOpaqueItem: opaqueItem descendantItem: item];
		}
		else if ([self isFlexibleItem: item])
		{
			[self insertItem: item inFlexibleItemQueue: flexibleItemQueue];

			/* When a dirty item uses a layout based frame, its parent 
			   needs a layout update, in other words to be marked as dirty. */
			[self scheduleParentItem: [item parentItem]
			               processed: [processedItems containsObject: [item parentItem]]
			     inFlexibleItemQueue: flexibleItemQueue
			              dirtyItems: dirtyItems];
		}
		else
		{
			[nonFlexibleItems addObject: item];
		}

		[dirtyItems removeObject: item];
		[processedItems addObject: item];
	}

	//ETLog(@"UPDATE LAYOUT -- Flexible items %i -- Non flexible items %i", 
	//	[flexibleItemQueue count], [nonFlexibleItems count]);
	[[flexibleItemQueue mappedCollection] updateLayoutRecursively: NO];
	[[nonFlexibleItems mappedCollection] updateLayoutRecursively: NO];
}

- (void) resetDirtyItems
{
	RELEASE(_scheduledItems);
	_scheduledItems = [[NSMutableSet alloc] init];
}

/** Executes the layout updates previously scheduled.

Additional layout updates that might be scheduled while running this method 
will be executed too.

On return, no scheduled items remain. */
- (void) execute
{
	while ([_scheduledItems isEmpty] == NO)
	{
		[self executeWithDirtyItems: _scheduledItems];
		[self resetDirtyItems];
	}
}

@end
