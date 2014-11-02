/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
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

- (COPersistentRoot *) editedPersistentRoot
{
    if ([_persistentObjectContext isObjectGraphContext] == NO)
        return nil;

    return [(COObjectGraphContext *)_persistentObjectContext persistentRoot];
}

- (COBranch *) editedBranch
{
    if ([_persistentObjectContext isObjectGraphContext] == NO)
        return nil;
    
    return [(COObjectGraphContext *)_persistentObjectContext branch];
}

- (NSString *) serializedPersistentObjectContext
{
    BOOL isTrackingCurrentBranch =
        ([[self editedPersistentRoot] objectGraphContext] == _persistentObjectContext);
    ETUUID *UUID = [[self editedBranch] UUID];

    if (isTrackingCurrentBranch)
    {
        UUID = [[self editedPersistentRoot] UUID];
    }
    return [UUID stringValue];
}

- (void) setSerializedPersistentObjectContext: (NSString *)aUUIDString
{
    if (aUUIDString == nil)
        return;

    ETUUID *UUID = [ETUUID UUIDWithString: aUUIDString];
    COPersistentRoot *persistentRoot =
        [[self editingContext] persistentRootForUUID: UUID];

    if (persistentRoot != nil)
    {
        ASSIGN(_persistentObjectContext, [persistentRoot objectGraphContext]);
        return;
    }

    COSQLiteStore *store = [[self editingContext] store];
    
    persistentRoot = [[self editingContext]
        persistentRootForUUID: [store persistentRootUUIDForBranchUUID: UUID]];

    COBranch *branch = [persistentRoot branchForUUID: UUID];

    ASSIGN(_persistentObjectContext, [branch objectGraphContext]);
}

- (void) recreateObservations
{
    for (ETObservation *observation in _observations)
    {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: [observation selector]
                                                     name: [observation name]
	                                               object: [observation object]];
    }
}

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];
	[self prepareTransientState];
}

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];
    [self recreateObservations];
}

@end


@interface ETItemTemplate (CoreObject)
@end

@implementation ETItemTemplate (CoreObject)
@end
