/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <CoreObject/COBranch.h>
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObjectGraphContext.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/COSQLiteStore.h>
#import "ETController.h"
#import "ETItemTemplate.h"
#import "ETObservation.h"

@interface ETController (CoreObject)
@end

@implementation ETController (CoreObject)

COPersistentRoot *editedPersistentRoot(id aPersistentObjectContext)
{
    if ([aPersistentObjectContext isObjectGraphContext] == NO)
        return nil;

    return [(COObjectGraphContext *)aPersistentObjectContext persistentRoot];
}

COBranch *editedBranch(id aPersistentContext)
{
    if ([aPersistentContext isObjectGraphContext] == NO)
        return nil;
    
    return [(COObjectGraphContext *)aPersistentContext branch];
}

- (ETUUID *) UUIDFromPersistentObjectContext: (id)aPersistentContext
{
	if (aPersistentContext == nil)
        return nil;

    BOOL isTrackingCurrentBranch =
        ([editedPersistentRoot(aPersistentContext) objectGraphContext] == aPersistentContext);
    ETUUID *UUID = [editedBranch(aPersistentContext) UUID];

    if (isTrackingCurrentBranch)
    {
        UUID = [editedPersistentRoot(aPersistentContext) UUID];
    }
    return UUID;
}

- (void) recreatePersistentObjectContext
{
	[self willChangeValueForProperty: @"persistentObjectContext"];

    if (_persistentObjectContextUUID == nil)
	{
		_persistentObjectContext = nil;
        return;
	}

    COPersistentRoot *persistentRoot =
        [[self editingContext] persistentRootForUUID: _persistentObjectContextUUID];

    if (persistentRoot != nil)
    {
        _persistentObjectContext = [persistentRoot objectGraphContext];
        return;
    }

    COSQLiteStore *store = [[self editingContext] store];
    
    persistentRoot = [[self editingContext]
        persistentRootForUUID: [store persistentRootUUIDForBranchUUID: _persistentObjectContextUUID]];

    COBranch *branch = [persistentRoot branchForUUID: _persistentObjectContextUUID];

    _persistentObjectContext = [branch objectGraphContext];
	
	[self didChangeValueForProperty: @"persistentObjectContext"];
}

- (void) recreateObservations
{
	[self willChangeValueForProperty: @"observations"];

    for (ETObservation *observation in _observations)
    {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: [observation selector]
                                                     name: [observation name]
	                                               object: [observation object]];
    }

	[self didChangeValueForProperty: @"observations"];
}

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];
	[self prepareTransientState];
}

/**
 * Will prevent notifications to be received during the reloading.
 *
 * Unused items are retained by the object graph context until the next GC phase 
 * (e.g. on commit), so if we just wanted to discard invalid/outdated observed 
 * objects, we could do it in -didLoadObjectGraph.
 */
- (void) willLoadObjectGraph
{
	[super willLoadObjectGraph];
	[self stopObservation];
}

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];
	[self recreatePersistentObjectContext];
    [self recreateObservations];
	/* At this point, the item tree should be ready to be sorted and filtered.
	   For the items and their aspects, the current property values are ready, 
	   further -didLoadObjectGraph calls won't alter the persistent state 
	   (we normally evaluate sort descriptors and predicates against properties 
	   derived from this persistent state).
	   For example, finishing to set up a layout touches some internal transient 
	   state that doesn't matter.
	   If a reload is planned, executing the realoading will call -setContent:, 
	   and trigger -rearrangeObjects once more. */
	[self rearrangeObjects];
}

@end
