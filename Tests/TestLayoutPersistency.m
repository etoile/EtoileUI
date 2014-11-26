/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2014
	License:  Modified BSD (see COPYING)
 */
 
#import "TestCommon.h"
#import "ETLayout.h"
#import "ETDropIndicator.h"
#import "ETFixedLayout.h"
#import "ETPositionalLayout.h"
#import "ETCompatibility.h"

@interface ETCustomDropIndicator : ETDropIndicator
@end

@implementation ETCustomDropIndicator
@end


@implementation TestLayoutPersistency

- (Class) layoutClass
{
	return [ETLayout class];
}

- (BOOL) computesLayout
{
	return NO;
}

- (CGFloat) previousScaleFactorForLayout: (id)newLayout
{
	return [newLayout previousScaleFactor];
}

- (id) init
{
	SUPERINIT;
    ASSIGN(itemFactory, [ETLayoutItemFactory factoryWithObjectGraphContext:
        [COObjectGraphContext objectGraphContext]]);

	layout = [[[self layoutClass] alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];

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
	//DESTROY(buttonItem);
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

		UKIntsEqual(5.0, [self previousScaleFactorForLayout: newLayout]);
		
		NSSize layoutSize =
			([self computesLayout] ? [newLayout layoutSize] : [itemGroup visibleContentSize]);
	
		UKSizesEqual(layoutSize, [newLayout layoutSize]);
        UKSizesEqual([itemGroup visibleContentSize], [newLayout proposedLayoutSize]);
		
		ETLayoutItemGroup *newLayerItem = [newLayout layerItem];
		
		UKSizesEqual(layoutSize, [newLayerItem size]);
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


@interface TestPositionalLayoutPersistency : TestLayoutPersistency
@end

@implementation TestPositionalLayoutPersistency

- (Class) layoutClass
{
	return [ETPositionalLayout class];
}

- (void) testItemConstraints
{
	[layout setConstrainedItemSize: NSMakeSize(24, 48)];
	[layout setItemSizeConstraintStyle: ETSizeConstraintStyleHorizontal];
	[itemGroup updateLayout];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		UKSizesEqual(NSMakeSize(24, [newItem height]), [newItem size]);
		UKSizesEqual(NSMakeSize(24, [newButtonItem height]), [newButtonItem size]);
    }];
}

- (void) testIsContentSizeLayout
{
	[layout setIsContentSizeLayout: YES];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		UKTrue([[newItemGroup layout] isContentSizeLayout]);
    }];
}

@end


@interface TestFixedLayoutPersistency : TestLayoutPersistency
@end

@implementation TestFixedLayoutPersistency

- (Class) layoutClass
{
	return [ETFixedLayout class];
}

- (void) testAutoresizesItemsDisabled
{
	NSSize buttonSize = [buttonItem size];

	[layout setAutoresizesItems: NO];
	[item setAutoresizingMask: ETAutoresizingFlexibleWidth];

	[itemGroup setSize: NSMakeSize(1000, 2000)];
	[itemGroup updateLayout];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETFixedLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		UKFalse([newLayout autoresizesItems]);
		UKSizesEqual(NSMakeSize(50, 50), [newItem size]);
		UKSizesEqual(buttonSize, [newButtonItem size]);
    }];
}

- (void) testAutoresizesItemsEnabled
{
	NSSize buttonSize = [buttonItem size];

	[layout setAutoresizesItems: YES];
	[item setAutoresizingMask: ETAutoresizingFlexibleWidth];

	[itemGroup setSize: NSMakeSize(1000, 2000)];
	[itemGroup updateLayout];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETFixedLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];
	
		UKTrue([newLayout autoresizesItems]);
		UKTrue(50 < [newItemGroup width]);
		UKIntsEqual(50, [newItem height]);
		UKSizesEqual(buttonSize, [newButtonItem size]);
    }];
}


- (void) testItemConstraints
{
	NSSize buttonSize = [buttonItem size];

	[layout setAutoresizesItems: NO];
	[layout setConstrainedItemSize: NSMakeSize(24, 48)];
	[layout setItemSizeConstraintStyle: ETSizeConstraintStyleHorizontal];
	[item setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];

	[itemGroup setSize: NSMakeSize(1000, 2000)];
	[itemGroup updateLayout];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		UKIntsEqual(24, [newItem width]);
		UKTrue(50 > [newItem height]);
		UKIntsEqual(24, [newButtonItem width]);
		UKTrue(buttonSize.height > [newButtonItem height]);
    }];
}

- (void) testItemConstraintsOverrideAutoresizesItems
{
	NSSize buttonSize = [buttonItem size];

	[layout setAutoresizesItems: YES];
	[layout setConstrainedItemSize: NSMakeSize(24, 48)];
	[layout setItemSizeConstraintStyle: ETSizeConstraintStyleHorizontal];
	[item setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];

	[itemGroup setSize: NSMakeSize(1000, 2000)];
	[itemGroup updateLayout];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		// For the height, no autoresizing occurs, but the height is resized by
		// the item constraints although there is no constraint on it.
		// This is done to ensure the item aspect ratio (that relates width and
		// height) remains the same even when the width is constrained.
		UKIntsEqual(24, [newItem width]);
		UKTrue(50 > [newItem height]);
		UKIntsEqual(24, [newButtonItem width]);
		UKTrue(buttonSize.height > [newButtonItem height]);
    }];
}

@end
