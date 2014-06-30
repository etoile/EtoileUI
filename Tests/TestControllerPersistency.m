/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
    License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "EtoileUIProperties.h"
#import "ETController.h"
#import "ETItemTemplate.h"
#import "ETCompatibility.h"

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

	controller = [[ETController alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];
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
                                    inBlock: ^(COObjectGraphContext *context, BOOL isNew, BOOL isCopy)
    {
        ETLayoutItemGroup *newItemGroup = [context loadedObjectForUUID: [itemGroup UUID]];
        ETController *newController = [context loadedObjectForUUID: [controller UUID]];

        UKNotNil(newController);
        UKObjectsEqual(newController, [newItemGroup controller]);
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
                                    inBlock: ^(COObjectGraphContext *context, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [context loadedObjectForUUID: [controller UUID]];
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
                                    inBlock: ^(COObjectGraphContext *context, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [context loadedObjectForUUID: [controller UUID]];
 
        UKObjectsEqual(predicate, [newController filterPredicate]);
        UKObjectsEqual(A(sortDescriptor1, sortDescriptor2), [newController sortDescriptors]);
        UKObjectsEqual(predicate, [newController filterPredicate]);
         
    }];
}

- (void) testPickAndDropTypes
{
	[controller setAllowedPickTypes: A([self URLType])];
	[controller setAllowedDropTypes: A([self URLType]) forTargetType: [controller currentGroupType]];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(COObjectGraphContext *context, BOOL isNew, BOOL isCopy)
    {
        ETController *newController = [context loadedObjectForUUID: [controller UUID]];
 
        UKObjectsEqual(A([self URLType]), [newController allowedPickTypes]);
        UKObjectsEqual(A([self URLType]), [newController allowedDropTypesForTargetType: [newController currentGroupType]]);
    }];
}

@end
