/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETFormLayout.h"
#import "ETBasicItemStyle.h"
#import "ETCompatibility.h"

@interface TestFormLayoutPersistency : TestLayoutPersistency <UKTest>
{
	ETLayoutItem *textItem;
	NSString *placeName;
}

@end

@implementation TestFormLayoutPersistency

- (Class) layoutClass
{
	return [ETFormLayout class];
}

- (BOOL) computesLayout
{
	return YES;
}

- (CGFloat) previousScaleFactorForLayout: (id)newLayout
{
	// FIXME: This is a bit silly since we don't scale the items currently.
	return [newLayout previousScaleFactor];
}

- (id) init
{
	SUPERINIT;
	[self prepareMainItemAsForm];
	ASSIGN(placeName, @"Kyoto");
	return self;
}

- (void) dealloc
{
	DESTROY(textItem);
	DESTROY(placeName);
	[super dealloc];
}

- (NSString *) placeName
{
	return placeName;
}

- (void) setPlaceName: (NSString *)aPlaceName
{
	ASSIGN(placeName, aPlaceName);
}

- (NSArray *) propertyNames
{
	return [[super propertyNames] arrayByAddingObject: @"placeName"];
}

- (void) prepareMainItemAsForm
{
	ASSIGN(textItem, [itemFactory textField]);
	
	/* We must set a name, otherwise the lengthy -description is used and can  
	   result in a 1000px label width. This puts us in trouble because of the 
	   bounding size in -[ETFormLayout resizeLayoutItems:toScaleFactor:] and the 
	   smaller itemGroup width. */
	[textItem setName: @"Place"];
	[itemGroup addItem: textItem];
}

- (NSUInteger) sizableViewMask
{
	return (NSViewWidthSizable | NSViewHeightSizable);
}

- (void) testFormItemGeometryForCustomWidth
{
	CGFloat height = [textItem height];

	[[[itemGroup layout] templateItem] setWidth: 5000];
	[[itemGroup layout] setTemplateKeys: [[[itemGroup layout] templateKeys] arrayByAddingObject: @"width"]];
	[itemGroup updateLayout];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
		ETLayoutItem *newTextItem = [newItemGroup lastItem];

		UKIntsEqual(ETAutoresizingNone, [newTextItem autoresizingMask]);
		UKSizesEqual(NSMakeSize(5000, height), [newTextItem size]);
		UKIntsEqual([self sizableViewMask], [(NSView *)[newTextItem view] autoresizingMask]);
		UKSizesEqual(NSMakeSize(5000, height), [[newTextItem view] frame].size);
	}];
}

- (void) testFormItemGeometryForLayoutUpdate
{
	NSSize textItemSize = [textItem size];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
	{
		ETLayoutItem *newTextItem = [newItemGroup lastItem];

		[newItemGroup updateLayout];

		UKSizesEqual(textItemSize, [newTextItem size]);
		UKTrue(NSContainsRect([itemGroup contentBounds], [newTextItem frame]));
	}];
}

- (void) testTextItemValueSynchronization
{
	[textItem setRepresentedObject:
		[ETMutableObjectViewpoint viewpointWithName: @"placeName" representedObject: self]];

	UKStringsEqual(@"Kyoto", [[textItem view] stringValue]);

	[self setPlaceName: @"Vancouver"];

	UKStringsEqual(@"Vancouver", [[textItem view] stringValue]);
}

#if 0
- (void) testFormItemGeometry
{
	ETLayoutItem *templateItem = [[itemGroup layout] templateItem];

	[textItem setRepresentedObject:
	 	[ETMutableObjectViewpoint viewpointWithName: @"placeName" representedObject: self]];

	[self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
	{
		// Will ensure the rendered items are recreated by executing the layout
		// update scheduled in -[ETLayoutItemGroup didLoadObjectGraph]
		[[ETLayoutExecutor sharedInstance] execute];

		ETLayoutItem *newTextItem = [newItemGroup lastItem];
		ETLayoutItem *newTemplateItem = [[newItemGroup layout] templateItem];

		UKIntsEqual([[templateItem coverStyle] labelPosition], [[newTemplateItem coverStyle] labelPosition]);
		UKIntsEqual([[templateItem coverStyle] labelMargin], [[newTemplateItem coverStyle] labelMargin]);
		UKIntsEqual((int)[[textItem coverStyle] labelPosition], (int)[[newTextItem coverStyle] labelPosition]);
		UKIntsEqual((int)[[textItem coverStyle] labelMargin], (int)[[newTextItem coverStyle] labelMargin]);

		/* Test textItem geometry (will implicitly check the positional layout) */

		UKRectsEqual([textItem frame], [newTextItem frame]);
		UKPointsEqual([textItem position], [newTextItem position]);
		UKRectsEqual([textItem contentBounds], [newTextItem contentBounds]);
		UKRectsEqual([textItem boundingBox], [newTextItem boundingBox]);
	}];
}
	 
- (void) testFormItemKVO
{
	[textItem setRepresentedObject:
	 	[ETMutableObjectViewpoint viewpointWithName: @"placeName" representedObject: self]];

	[itemGroup updateLayout];

	[self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
	{
		ETLayoutItem *newTextItem = [newItemGroup lastItem];
	
		UKStringsEqual(@"Kyoto", [[newTextItem view] stringValue]);
		[self setPlaceName: @"Vancouver"];
		UKStringsEqual(@"Vancouver", [[newTextItem view] stringValue]);
		[self setPlaceName: @"Kyoto"];
	}];
}
#endif

@end
