/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2014
	License:  Modified BSD (see COPYING)
 */
 
#import "TestCommon.h"
#import "ETColumnLayout.h"
#import "ETLineLayout.h"
#import "ETCompatibility.h"

@interface TestColumnLayoutPersistency : TestLayoutPersistency
@end

// NOTE: When changing properties such as borderMargin, separatorTemplateItem,
// etc., there is no need to update the layout explicitly, since
// -renderAndInvalidateDisplay is called by these property setters.
@implementation TestColumnLayoutPersistency

- (Class) layoutClass
{
	return [ETColumnLayout class];
}

- (id) init
{
	SUPERINIT;
	[layout setBorderMargin: 20];
	[layout setItemMargin: 10];
	return self;
}

- (void) testLayoutGeometry
{
	NSSize itemSize = [item size];
	NSSize buttonSize = [buttonItem size];

	// If the scale factor is too big, the items cannot fit in the layout size
	// based on -[ETLayoutItemGroup visibleContentSize], unless we enable 
	// -isContentSizeLayout or set a -customLayoutSize.
	[itemGroup setItemScaleFactor: 2.0];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETLayout *newLayout = [newItemGroup layout];

		UKTrue(2.0 == [newLayout previousScaleFactor]);

		/* Final layout size is smaller than the initial visible content size */
		CGFloat layoutHeight =
			20 + 10 + itemSize.height * 2 + 10 + buttonSize.height * 2 + 10 + 20;
		CGFloat layoutWidth =
			20 + 10 + MAX(itemSize.width, buttonSize.width) * 2 + 10 + 20;
		NSSize layoutSize = NSMakeSize(layoutWidth, layoutHeight);
		BOOL recomputesLayoutSize = (isNew || isCopy);
	
		if (recomputesLayoutSize)
		{
			/* For the copy case, don't update the original item tree with ETLayoutExecutor */
			[newItemGroup updateLayout];
		}
	
		UKSizesEqual(layoutSize, [newLayout layoutSize]);
        UKSizesNotEqual(layoutSize, [newLayout proposedLayoutSize]);
		UKSizesNotEqual(layoutSize, [itemGroup visibleContentSize]);

		ETLayoutItemGroup *newLayerItem = [newLayout layerItem];

		UKSizesEqual(layoutSize, [newLayerItem size]);
		UKTrue([itemGroup isFlipped] == [[newLayout layerItem] isFlipped]);
    }];
}

- (void) testMargins
{
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETColumnLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		UKIntsEqual(20, [newLayout borderMargin]);
		UKIntsEqual(10, [newLayout itemMargin]);
		UKIntsEqual(20 + 10, [newItem x]);
		UKIntsEqual(20 + 10, [newItem y]);
		UKIntsEqual(20 + 10, [newButtonItem x]);
		UKIntsEqual(NSMaxY([newItem frame]) + 10, [newButtonItem y]);
    }];
}

- (void) testAutoresizesItemToFill
{
	NSSize buttonSize = [buttonItem size];
	int maxWidth = MAX([item width], [buttonItem width]);

	[layout setAutoresizesItemToFill: YES];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETComputedLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		UKTrue([newLayout autoresizesItemToFill]);
		UKSizesEqual(NSMakeSize(maxWidth, 50), [newItem size]);
		UKSizesEqual(NSMakeSize(maxWidth, buttonSize.height), [newButtonItem size]);
    }];
}

- (void) testHorizontalAlignment
{
	[layout setHorizontalAlignment: ETLayoutHorizontalAlignmentGuided];
	[layout setHorizontalAlignmentGuidePosition: 100];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETComputedLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];
		
		UKTrue(ETLayoutHorizontalAlignmentGuided == [newLayout horizontalAlignment]);
		UKIntsEqual(100, [newLayout horizontalAlignmentGuidePosition]);
		UKIntsEqual(20 + 100 + 10, [newItem x]);
		UKIntsEqual(20 + 10, [newItem y]);
		UKIntsEqual(20 + 100 + 10, [newButtonItem x]);
		UKIntsEqual(NSMaxY([newItem frame]) + 10, [newButtonItem y]);
    }];
}

- (void) testComputesItemRectFromBoundingBox
{
	NSRect boundingBox = NSInsetRect([item contentBounds], -5, -15);

	[item setBoundingBox: boundingBox];
	[layout setComputesItemRectFromBoundingBox: YES];
	
	[self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETColumnLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		UKTrue([newLayout computesItemRectFromBoundingBox]);
		UKRectsEqual(boundingBox, [newItem boundingBox]);
		UKRectsEqual([buttonItem contentBounds], [newButtonItem contentBounds]);
	
		UKIntsEqual(20 + 10 + 5, [newItem x]);
		UKIntsEqual(20 + 10 + 15, [newItem y]);
		UKIntsEqual(20 + 10, [newButtonItem x]);
		UKIntsEqual(NSMaxY([newItem frame]) + 15 + 10, [newButtonItem y]);
    }];
}

- (void) testSeparators
{
	[layout setSeparatorTemplateItem: [itemFactory lineSeparator]];
	[layout setSeparatorItemEndMargin: 25];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		// Will ensure the separators are recreated by executing the layout
		// update scheduled in -didLoadObjectGraph
		[[ETLayoutExecutor sharedInstance] execute];

		ETComputedLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];
		ETLayoutItemGroup *newLayerItem = [newLayout layerItem];
		ETLayoutItem *newSeparatorItem = [newLayerItem firstItem];

		// The separator item is a template, the layer item contains a copy
		// created during the layout update.
		UKValidateLoadedObjects([newLayout separatorTemplateItem], [layout separatorTemplateItem], YES);
		UKIntsEqual(25, [newLayout separatorItemEndMargin]);

		UKIntsEqual(1, [newLayerItem count]);
		UKStringsEqual(kETLineSeparatorItemIdentifier, [newSeparatorItem identifier]);

		UKIntsEqual(25, [newSeparatorItem x]);
		UKIntsEqual(NSMaxY([newItem frame]) + 10, [newSeparatorItem y]);
		UKIntsEqual(NSMaxY([newSeparatorItem frame]) + 10, [newButtonItem y]);
    }];
}

@end
