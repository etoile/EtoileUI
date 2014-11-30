/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2014
	License:  Modified BSD (see COPYING)
 */
 
#import "TestCommon.h"
#import "ETTemplateItemLayout.h"
#import "ETBasicItemStyle.h"
#import "ETColumnLayout.h"
#import "ETFlowLayout.h"
#import "ETCompatibility.h"

@interface TestTemplateItemLayoutPersistency : TestLayoutPersistency
@end

@implementation TestTemplateItemLayoutPersistency

- (Class) layoutClass
{
	return [ETTemplateItemLayout class];
}

- (BOOL) computesLayout
{
	return YES;
}

- (CGFloat) previousScaleFactorForLayout: (id)newLayout
{
	if ([newLayout ignoresItemScaleFactor])
		return [[newLayout layoutContext] itemScaleFactor];
	
	return [(id)[newLayout positionalLayout] previousScaleFactor];
}

- (void) testTemplate
{
	ETLayoutItem *templateItem = [itemFactory horizontalSlider];

	[templateItem setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[[templateItem coverStyle] setLabelMargin: 50];

	[layout setTemplateItem: templateItem];
	[layout setTemplateKeys: A(@"autoresizingMask", @"coverStyle", @"view")];
	
	// The initializer updated the layout previously, and -setTemplate:
	// and -setTemplateKeys: don't call -renderAndInvalidateDisplay.
	[itemGroup setNeedsLayoutUpdate];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		// Will ensure the rendered items are recreated by executing the layout
		// update scheduled in -[ETLayoutItemGroup didLoadObjectGraph]
		[[ETLayoutExecutor sharedInstance] execute];

        ETTemplateItemLayout *newLayout = [newItemGroup layout];
		ETLayoutItem *newTemplateItem = [newLayout templateItem];
		ETLayoutItem *newItem = [newItemGroup firstItem];
		ETLayoutItem *newButtonItem = [newItemGroup lastItem];

		UKValidateLoadedObjects(newItemGroup, itemGroup, NO);
		UKValidateLoadedObjects(newLayout, layout, NO);
		UKValidateLoadedObjects(newTemplateItem, templateItem, YES);
		UKValidateLoadedObjects(newItem, item, NO);
		UKValidateLoadedObjects(newButtonItem, buttonItem, NO);

		UKObjectsEqual([layout templateKeys], [newLayout templateKeys]);

		UKIntsEqual(ETAutoresizingFlexibleWidth, [newTemplateItem autoresizingMask]);
		if (isNew)
		{
			UKObjectUUIDsEqual([templateItem coverStyle], [newTemplateItem coverStyle]);
		}
		else
		{
			UKObjectsEqual([templateItem coverStyle], [newTemplateItem coverStyle]);
		}
		UKIntsEqual(50, [[newTemplateItem coverStyle] labelMargin]);
		UKObjectKindOf([newTemplateItem view], NSSlider);
		
		if (isCopy == NO)
		{
			UKCollectionUUIDsEqual([itemGroup items], [newItemGroup items]);
		}

		UKIntsEqual(ETAutoresizingFlexibleWidth, [newItem autoresizingMask]);
		if (isNew)
		{
			UKObjectUUIDsEqual([templateItem coverStyle], [newItem coverStyle]);
		}
		else
		{
			UKObjectsSame([templateItem coverStyle], [newItem coverStyle]);
		}
		UKIntsEqual(50, [[newItem coverStyle] labelMargin]);
		UKObjectKindOf([newItem view], NSSlider);

		UKIntsEqual(ETAutoresizingFlexibleWidth, [newButtonItem autoresizingMask]);
		if (isNew)
		{
			UKObjectUUIDsEqual([templateItem coverStyle], [newButtonItem coverStyle]);
		}
		else
		{
			UKObjectsSame([templateItem coverStyle], [newButtonItem coverStyle]);
		}
		UKIntsEqual(50, [[newButtonItem coverStyle] labelMargin]);
		UKObjectKindOf([newButtonItem view], NSSlider);
    }];
}

- (void) testLocalBindings
{
	// TODO: Implement
}

- (void) testPositionalLayout
{
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETTemplateItemLayout *newLayout = [newItemGroup layout];
		id <ETComputableLayout> newPositionalLayout = [newLayout positionalLayout];
	
		UKValidateLoadedObjects(newLayout, layout, NO);
		UKValidateLoadedObjects((id)newPositionalLayout, (id)[layout positionalLayout], NO);

		UKObjectsEqual(newLayout, [[newLayout positionalLayout] layoutContext]);
		UKObjectKindOf([newLayout positionalLayout], ETFlowLayout);

		NSPoint positionInFlow = [[newItemGroup lastItem] position];
		ETColumnLayout *otherLayout =
			[ETColumnLayout layoutWithObjectGraphContext: [newItemGroup objectGraphContext]];

		[newLayout setPositionalLayout: otherLayout];

		UKObjectsEqual(newLayout, [otherLayout layoutContext]);
		UKObjectKindOf(otherLayout, ETColumnLayout);
		
		UKPointsNotEqual(positionInFlow, [[newItemGroup lastItem] position]);
		
		[newLayout setPositionalLayout: newPositionalLayout];
		
		UKPointsEqual(positionInFlow, [[newItemGroup lastItem] position]);
    }];
}

@end
