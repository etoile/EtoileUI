/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
    License:  Modified BSD (see COPYING)
 */

#import <CoreObject/COBranch.h>
#import "TestCommon.h"
#import "EtoileUIProperties.h"
#import "ETController.h"
#import "ETItemTemplate.h"
#import "ETCompatibility.h"

@interface CustomController : ETController
{
    @public
    BOOL firstItemSelectionChanged;
    BOOL notificationPosted;
}

@end

@implementation CustomController

- (void) firstItemSelectionDidChange: (NSNotification *)notif
{
    firstItemSelectionChanged = YES;
}

- (void) didPostNotification: (NSNotification *)notif
{
	/* Filter out other notifications such as ETLayoutItemLayoutDidChangeNotification */
	if ([[notif name] isEqual: ETItemGroupSelectionDidChangeNotification] == NO)
		return;

    notificationPosted = YES;
}

@end

@interface TestControllerPersistency : TestCommon <UKTest>
{
    ETLayoutItemGroup *itemGroup;
    ETController *controller;
}

@end

@implementation TestControllerPersistency

- (id) init
{
	SUPERINIT;
    ASSIGN(itemFactory, [ETLayoutItemFactory factoryWithObjectGraphContext:
        [COObjectGraphContext objectGraphContext]]);

	controller = [[CustomController alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];
	ASSIGN(itemGroup, [itemFactory itemGroup]);

    [itemGroup setShouldMutateRepresentedObject: YES];
    [itemGroup setController: controller];

    ETAssert([itemGroup objectGraphContext] != [ETUIObject defaultTransientObjectGraphContext]);
    ETAssert([[itemGroup objectGraphContext] rootItemUUID] == nil);
	return self;
}

- (void) dealloc
{
	DESTROY(controller);
	DESTROY(itemGroup);
	[super dealloc];
}

- (void) testContentRelationship
{
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];

        UKValidateLoadedObjects(newController, controller, NO);

        UKNotNil(newController);
        UKObjectsEqual(newItemGroup, [newController content]);
    }];
}

- (ETUTI *) URLType
{
    return [ETUTI typeWithString: @"public.url"];
}

- (ETItemTemplate *) objectTemplate
{
    return [controller templateForType: [controller currentObjectType]];
}

- (ETItemTemplate *) groupTemplate
{
    return [controller templateForType: [controller currentGroupType]];
}

- (void) prepareTemplates
{
	ETItemTemplate *objectTemplate =
		[ETItemTemplate templateWithItem: [itemFactory textField]
		                      entityName: @"COBookmark"
		              objectGraphContext: [itemFactory objectGraphContext]];
	ETItemTemplate *groupTemplate =
		[ETItemTemplate templateWithItem: [itemFactory itemGroup]
		                     objectClass: [NSMutableArray class]
		              objectGraphContext: [itemFactory objectGraphContext]];

	[controller setCurrentObjectType: [self URLType]];
	[controller setTemplate: objectTemplate forType: [self URLType]];
	[controller setTemplate: groupTemplate forType: [controller currentGroupType]];
}

- (void) testTemplates
{
    [self prepareTemplates];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];
        ETItemTemplate *newObjectTemplate = [newController templateForType: [newController currentObjectType]];
        ETItemTemplate *newGroupTemplate = [newController templateForType: [newController currentGroupType]];

        UKObjectsEqual([self URLType], [newController currentObjectType]);
        UKObjectsEqual([controller currentGroupType], [newController currentGroupType]);
        UKObjectsEqual([[self objectTemplate] UUID], [newObjectTemplate UUID]);
        UKObjectsEqual([[self groupTemplate] UUID], [newGroupTemplate UUID]);

        UKObjectKindOf([[newObjectTemplate item] view], NSTextField);
        UKNil([newObjectTemplate objectClass]);
        UKStringsEqual([[self objectTemplate] entityName], [newObjectTemplate entityName]);
        
        UKTrue([[newGroupTemplate item] isGroup]);
        UKTrue([(ETLayoutItemGroup *)[newGroupTemplate item] isEmpty]);
        UKTrue([[newGroupTemplate objectClass] isSubclassOfClass: [NSMutableArray class]]);
        UKNil([newGroupTemplate entityName]);
    }];
}

- (void) testInitialFocusedItem
{
    [itemGroup addItem: [itemFactory item]];
    [controller setInitialFocusedItem: [itemGroup firstItem]];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];
        ETLayoutItem *newInitialFocusedItem = [newController initialFocusedItem];

        UKObjectsEqual([newItemGroup firstItem], newInitialFocusedItem);
    }];

}

- (void) testEditingContextAsPersistentObjectContext
{
    [controller setPersistentObjectContext: editingContext];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];

        if (isNew == NO && isCopy == NO)
            return;
        
        ETAssert([[[editingContext store] UUID] isEqual: [[[newController editingContext] store] UUID]]);

        UKNil([newController persistentObjectContext]);
    }];
}

- (void) testObjectGraphContextOfTrackingBranchAsPersistentObjectContext
{
    COPersistentRoot *editedPersistentRoot =
        [editingContext insertNewPersistentRootWithEntityName: @"COContainer"];
    ETAssert([editedPersistentRoot commit]);

    [controller setPersistentObjectContext: [editedPersistentRoot objectGraphContext]];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];
        COPersistentRoot *newEditedPersistentRoot =
            [[newController editingContext] persistentRootForUUID: [editedPersistentRoot UUID]];

        if (isNew == NO && isCopy == NO)
            return;

        UKObjectsSame([newEditedPersistentRoot objectGraphContext], [newController persistentObjectContext]);
    }];
}

- (void) testObjectGraphContextOfNonTrackingBranchAsPersistentObjectContext
{
    COPersistentRoot *editedPersistentRoot =
        [editingContext insertNewPersistentRootWithEntityName: @"COContainer"];
    ETAssert([editedPersistentRoot commit]);

    COBranch *editedBranch =
        [[editedPersistentRoot currentBranch] makeBranchWithLabel: @"Test"];
    ETAssert([editedPersistentRoot commit]);

    [controller setPersistentObjectContext: [editedBranch objectGraphContext]];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];
        COPersistentRoot *newEditedPersistentRoot =
            [[newController editingContext] persistentRootForUUID: [editedPersistentRoot UUID]];
        COBranch *newEditedBranch = [newEditedPersistentRoot branchForUUID: [editedBranch UUID]];
    
        if (isNew == NO && isCopy == NO)
            return;

        UKObjectsSame([newEditedBranch objectGraphContext], [newController persistentObjectContext]);
    }];
}

- (void) testSortDescriptorsAndFilterPredicate
{
	NSSortDescriptor *sortDescriptor1 =
		[NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
	NSSortDescriptor *sortDescriptor2 =
		[NSSortDescriptor sortDescriptorWithKey: @"creationDate" ascending: NO selector: @selector(compare:)];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"URL.absoluteString CONTAINS 'etoile-project.org'"];

	[controller setSortDescriptors: A(sortDescriptor1, sortDescriptor2)];
	[controller setFilterPredicate: predicate];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];
 
        UKObjectsEqual(predicate, [newController filterPredicate]);
        UKObjectsEqual(A(sortDescriptor1, sortDescriptor2), [newController sortDescriptors]);
        UKObjectsEqual(predicate, [newController filterPredicate]);
		
		UKTrue([newItemGroup isSorted]);
		UKTrue([newItemGroup isFiltered]);
    }];
}

- (void) testPickAndDropTypes
{
	[controller setAllowedPickTypes: A([self URLType])];
	[controller setAllowedDropTypes: A([self URLType]) forTargetType: [controller currentGroupType]];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [newItemGroup controller];
 
        UKObjectsEqual(A([self URLType]), [newController allowedPickTypes]);
        UKObjectsEqual(A([self URLType]), [newController allowedDropTypesForTargetType: [newController currentGroupType]]);
    }];
}

- (void) testObservations
{
    [itemGroup addItem: [itemFactory itemGroup]];
    [(ETLayoutItemGroup *)[itemGroup firstItem] addItem: [itemFactory item]];

    [controller startObserveObject: [itemGroup firstItem]
               forNotificationName: ETItemGroupSelectionDidChangeNotification
                          selector: @selector(firstItemSelectionDidChange:)];
    [controller startObserveObject: itemGroup
               forNotificationName: nil
                          selector: @selector(didPostNotification:)];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        CustomController *newController = (CustomController *)[newItemGroup controller];

        [(ETLayoutItemGroup *)[newItemGroup firstItem] setSelectionIndex: 0];
        
        UKTrue(newController->firstItemSelectionChanged);
        UKFalse(newController->notificationPosted);
    
        [newItemGroup setSelectionIndex: 0];

        UKTrue(newController->notificationPosted);
    }];
}

@end
