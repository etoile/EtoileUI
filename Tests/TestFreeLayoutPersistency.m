/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
    License:  Modified BSD (see COPYING)
 */

#import <CoreObject/COBranch.h>
#import "TestCommon.h"
#import "EtoileUIProperties.h"
#import "ETFreeLayout.h"
#import "ETSelectTool.h"
#import "ETCompatibility.h"

@interface TestFreeLayoutPersistency : TestCommon <UKTest>
{
    ETLayoutItemGroup *itemGroup;
    ETLayoutItem *item;
    ETLayoutItem *buttonItem;
    ETFreeLayout *layout;
}

@end

@implementation TestFreeLayoutPersistency

- (id) init
{
	SUPERINIT;
    ASSIGN(itemFactory, [ETLayoutItemFactory factoryWithObjectGraphContext:
        [COObjectGraphContext objectGraphContext]]);

	layout = [[ETFreeLayout alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];

    ASSIGN(item, [self basicItemWithRect: NSMakeRect(10, 10, 50, 50)]);
    ASSIGN(buttonItem, [itemFactory button]);
	ASSIGN(itemGroup, [itemFactory itemGroupWithItems: A(item, buttonItem)]);

    [itemGroup setShouldMutateRepresentedObject: YES];
    [itemGroup setLayout: layout];
    [itemGroup updateLayoutIfNeeded];

    ETAssert([itemGroup objectGraphContext] != [ETUIObject defaultTransientObjectGraphContext]);
    ETAssert([[itemGroup objectGraphContext] rootItemUUID] == nil);
	return self;
}

- (void) dealloc
{
    DESTROY(itemGroup);
    DESTROY(item);
    DESTROY(buttonItem);
	DESTROY(layout);
	[super dealloc];
}

- (void) testContextRelationship
{
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETFreeLayout *newLayout = [newItemGroup layout];

        UKValidateLoadedObjects(newLayout, layout, NO);

        UKNotNil(newLayout);
        UKObjectsEqual(newItemGroup, [newLayout layoutContext]);
    }];
}

- (void) testAttachedTool
{
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETFreeLayout *newLayout = [newItemGroup layout];
        ETSelectTool *newTool = [newLayout attachedTool];

        UKValidateLoadedObjects(newTool, [layout attachedTool], NO);

        UKObjectKindOf(newTool, ETSelectTool);
        UKTrue([newTool shouldProduceTranslateActions]);
    }];
}

// FIXME: UKFalse([ctxt hasChanges]);

- (void) testMakeSelectionFromItemTree
{
	[itemGroup setSelectionIndex: 1];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETFreeLayout *newLayout = [newItemGroup layout];
        ETLayoutItem *newItem = [newItemGroup firstItem];
        ETLayoutItem *newButtonItem = [newItemGroup itemAtIndex: 1];

        UKTrue([newButtonItem isSelected]);
        UKIntsEqual(1, [newItemGroup selectionIndex]);
    
        UKNotNil([newLayout handleGroupForItem: newButtonItem]);
        UKNil([newLayout handleGroupForItem: newItem]);
        UKIntsEqual(1, [[newLayout layerItem] numberOfItems]);
        
        // FIXME: the bounding box is damaged due to the selection
    }];
}

- (void) testChangeSelectionFromTool
{
	[itemGroup setSelectionIndex: 1];
	[[layout attachedTool] makeSingleSelectionWithItem: item];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETFreeLayout *newLayout = [newItemGroup layout];
        ETLayoutItem *newItem = [newItemGroup firstItem];
        ETLayoutItem *newButtonItem = [newItemGroup itemAtIndex: 1];
    
        UKFalse([newButtonItem isSelected]);
        UKIntsEqual(0, [newItemGroup selectionIndex]);
        UKNil([newLayout handleGroupForItem: newButtonItem]);
        UKNotNil([newLayout handleGroupForItem: newItem]);
        UKIntsEqual(1, [[newLayout layerItem] numberOfItems]);
        
        // FIXME: the bounding box is damaged due to the selection
    }];
}

- (void) testFreeLayoutAsPersistentRoot
{

}

@end
