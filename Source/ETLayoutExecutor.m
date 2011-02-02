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
			// NOTE: Queued item is moved to i + 1
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

- (void) scheduleParentItem: (ETLayoutItemGroup *)parentItem 
                  processed: (BOOL)hasBeenProcessed
        inFlexibleItemQueue: (NSMutableArray *)flexibleItemQueue
                 dirtyItems: (NSMutableSet *)dirtyItems
{
	/* If the parent item has already been processed as a dirty item */
	if (hasBeenProcessed)
	{
		// Same as [flexibleFrameItems containsObject: parentItem]
		if ([parentItem usesLayoutBasedFrame] == NO)
			return;

		[self insertItem: parentItem inFlexibleItemQueue: flexibleItemQueue];
	}
	else
	{
		// If parent item uses a layout based frame, it must come afterits child 
		// in the flexibleFrameItems array because there is a dependency on  its 
		// child frame to compute its own.
		// We can ensure that by adding it the dirty items not yet processed.
		[dirtyItems addObject: parentItem];
	}
}

- (void) executeWithDirtyItems: (NSSet *)scheduledItems
{
	NSMutableSet *dirtyItems = [NSMutableSet setWithSet: scheduledItems];
	NSMutableSet *nonFlexibleItems = [NSMutableSet set];
	NSMutableArray *flexibleItemQueue = [NSMutableArray array];
	NSMutableSet *processedItems = [NSMutableSet set];

	while ([dirtyItems count] > 0)
	{
		ETLayoutItem *item = [dirtyItems anyObject];

		if ([[item ifResponds] usesLayoutBasedFrame])
		{
			[self insertItem: item inFlexibleItemQueue: flexibleItemQueue];

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
