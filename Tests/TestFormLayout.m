/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETFormLayout.h"
#import "ETBasicItemStyle.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"


@interface TestFormLayout : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *mainItem;
	ETLayoutItem *textItem;
	NSString *placeName;
}

@end

@implementation TestFormLayout

- (id) init
{
	SUPERINIT;
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(mainItem, [itemFactory itemGroup]);
	[self prepareMainItemAsForm];
	ASSIGN(placeName, @"Kyoto");
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(mainItem);
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
	   smaller mainItem width. */
	[textItem setName: @"Place"];
	[mainItem addItem: textItem];
	[mainItem setLayout: [ETFormLayout layout]];
}

- (NSUInteger) sizableViewMask
{
	return (NSViewWidthSizable | NSViewHeightSizable);
}

- (void) testFormItemGeometryForCustomWidth
{
	CGFloat height = [textItem height];

	[[[mainItem layout] templateItem] setWidth: 5000];
	[[mainItem layout] setTemplateKeys: [[[mainItem layout] templateKeys] arrayByAddingObject: @"width"]];
	[mainItem updateLayout];

	UKIntsEqual(ETAutoresizingNone, [textItem autoresizingMask]);
	UKSizesEqual(NSMakeSize(5000, height), [textItem size]);
	UKIntsEqual([self sizableViewMask], [(NSView *)[textItem view] autoresizingMask]);
	UKSizesEqual(NSMakeSize(5000, height), [[textItem view] frame].size);
}

- (void) testFormItemGeometryForLayoutUpdate
{
	NSSize textItemSize = [textItem size];

	[mainItem updateLayout];

	UKSizesEqual(textItemSize, [textItem size]);
	UKTrue(NSContainsRect([mainItem contentBounds], [textItem frame]));
}

- (void) testTextItemValueSynchronization
{
	[textItem setRepresentedObject:
		[ETPropertyViewpoint viewpointWithName: @"placeName" representedObject: self]];

	UKStringsEqual(@"Kyoto", [[textItem view] stringValue]);

	[self setPlaceName: @"Vancouver"];

	UKStringsEqual(@"Vancouver", [[textItem view] stringValue]);
}

- (void) testCopy
{
	[textItem setRepresentedObject:
	 	[ETPropertyViewpoint viewpointWithName: @"placeName" representedObject: self]];

	/* Prepare the form UI now (don't wait the layout executor) */
	[mainItem updateLayout];
	
	ETLayoutItemGroup *mainItemCopy = [mainItem deepCopy];
	ETLayoutItem *textItemCopy = [mainItemCopy lastItem];
	ETLayoutItem *templateItem = [[mainItem layout] templateItem];
	ETLayoutItem *templateItemCopy = [[mainItemCopy layout] templateItem];
	
	/* Force a layout update to ensure the copy respects the original geometry */
	[mainItemCopy updateLayout];

	UKObjectsEqual([[mainItem layout] templateKeys], [[mainItemCopy layout] templateKeys]);
	UKIntsEqual([[templateItem coverStyle] labelPosition], [[templateItemCopy coverStyle] labelPosition]);
	UKIntsEqual([[templateItem coverStyle] labelMargin], [[templateItemCopy coverStyle] labelMargin]);
																
	UKIntsEqual((int)[[textItem coverStyle] labelPosition], (int)[[textItemCopy coverStyle] labelPosition]);
	UKIntsEqual((int)[[textItem coverStyle] labelMargin], (int)[[textItemCopy coverStyle] labelMargin]);

	/* Test textItem geometry (will implicitly check the positional layout copy) */

	UKRectsEqual([textItem frame], [textItemCopy frame]);
	UKPointsEqual([textItem position], [textItemCopy position]);
	UKRectsEqual([textItem contentBounds], [textItemCopy contentBounds]);
	UKRectsEqual([textItem boundingBox], [textItemCopy boundingBox]);
	
	/* Test KVO is properly set up in the copy */
	
	UKStringsEqual(@"Kyoto", [[textItemCopy view] stringValue]);
	[self setPlaceName: @"Vancouver"];
	UKStringsEqual(@"Vancouver", [[textItemCopy view] stringValue]);
}

@end
