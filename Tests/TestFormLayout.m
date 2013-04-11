/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETTemplateItemLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"


@interface TestFormLayout : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *mainItem;
	ETLayoutItem *textItem;
}

@end

@implementation TestFormLayout

- (id) init
{
	SUPERINIT;
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(mainItem, [itemFactory itemGroup]);
	[self prepareMainItemAsForm];
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(mainItem);
	DESTROY(textItem);
	[super dealloc];
}

- (void) prepareMainItemAsForm
{
	ASSIGN(textItem, [itemFactory textField]);
	
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

@end
