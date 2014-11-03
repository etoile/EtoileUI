/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2014
	License:  Modified BSD (see COPYING)
 */
 
#import "TestCommon.h"
#import "ETLayout.h"
#import "ETDropIndicator.h"
#import "ETCompatibility.h"

@interface ETLayout (Private)
- (NSSize) proposedLayoutSize;
@end

@implementation ETLayout (Private)

- (NSSize) proposedLayoutSize
{
	return _proposedLayoutSize;
}

- (CGFloat) previousScaleFactor
{
	return _previousScaleFactor;
}

@end

@interface ETCustomDropIndicator : ETDropIndicator
@end

@implementation ETCustomDropIndicator
@end


@interface TestLayoutPersistency : TestCommon <UKTest>
{
    ETLayoutItemGroup *itemGroup;
    ETLayoutItem *item;
    ETLayoutItem *buttonItem;
    ETLayout *layout;
}

@end

@implementation TestLayoutPersistency

- (id) init
{
	SUPERINIT;
    ASSIGN(itemFactory, [ETLayoutItemFactory factoryWithObjectGraphContext:
        [COObjectGraphContext objectGraphContext]]);

	layout = [[ETLayout alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];

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
        ETLayout *newLayout = [newItemGroup layout];

        UKValidateLoadedObjects(newLayout, layout, NO);
        UKNotNil(newLayout);
        UKObjectsEqual(newItemGroup, [newLayout layoutContext]);
    }];
}

- (void) testLayoutGeometry
{
	[itemGroup setItemScaleFactor: 5.0];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETLayout *newLayout = [newItemGroup layout];

		UKTrue([layout usesCustomLayoutSize] == [newLayout usesCustomLayoutSize]);
		UKTrue(5.0 == [newLayout previousScaleFactor]);

		UKSizesEqual([itemGroup visibleContentSize], [newLayout layoutSize]);
        UKSizesEqual([itemGroup visibleContentSize], [newLayout proposedLayoutSize]);
		
		ETLayoutItemGroup *newLayerItem = [newLayout layerItem];
		
		UKSizesEqual([itemGroup visibleContentSize], [newLayerItem size]);
		UKTrue([itemGroup isFlipped] == [[newLayout layerItem] isFlipped]);
    }];
}

- (void) testAttachedTool
{
	ETTool *tool = [ETTool toolWithObjectGraphContext: [layout objectGraphContext]];

	[layout setAttachedTool: tool];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETTool *newTool = [[newItemGroup layout] attachedTool];

        UKValidateLoadedObjects(newTool, tool, NO);
        UKObjectKindOf(newTool, ETTool);
    }];
}

- (void) testDropIndicator
{
	ETDropIndicator *indicator =
		[ETCustomDropIndicator sharedInstanceForObjectGraphContext: [layout objectGraphContext]];

	[layout setDropIndicator: indicator];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETDropIndicator *newIndicator = [[newItemGroup layout] dropIndicator];

        UKValidateLoadedObjects(newIndicator, indicator, YES);
		if (isNew == NO && isCopy)
		{
			UKObjectsSame(indicator, newIndicator);
		}
        UKObjectKindOf(newIndicator, ETCustomDropIndicator);
    }];
}

@end
