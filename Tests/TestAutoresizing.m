/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2013
    License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETFixedLayout.h"
#import "ETLayout.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItem.h"

@interface TestAutoresizing : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *itemGroup;
}

@end


@implementation TestAutoresizing

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(itemGroup, [itemFactory itemGroup]);
	[itemGroup setSize: NSMakeSize(500, 400)];
	ETAssert([[itemGroup layout] isKindOfClass: [ETFixedLayout class]]);
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(itemGroup);
	[super dealloc];
}

- (void) testItemAutoresizingMaskFromView
{
	NSView *view = [[NSView alloc] initWithFrame: NSMakeRect(20, 40, 100, 200)];
	[view setAutoresizingMask: NSViewMinYMargin | NSViewHeightSizable];
	ETLayoutItem *item = [itemFactory itemWithView: view];

	UKIntsEqual(ETAutoresizingFlexibleBottomMargin | ETAutoresizingFlexibleHeight, [item autoresizingMask]);
}

- (void) testLayoutSizeForItemGroupWithFrame
{
	ASSIGN(itemGroup, [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 100, 200)]);

	UKSizesEqual(NSMakeSize(100, 200), [[itemGroup layout] layoutSize]);
}

- (void) testFixedLayoutWithoutAutoresizedItems
{
	ETLayoutItem *item = [itemFactory item];
	ETLayoutItem *textFieldItem = [itemFactory textField];
	NSRect itemFrame = [item frame];
	NSRect textFieldFrame = NSMakeRect(20, 40, 100, 200);

	[textFieldItem setFrame: textFieldFrame];
	[itemGroup addItems: A(item, textFieldItem)];
	[itemGroup updateLayout];

	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);

	[itemGroup setSize: NSMakeSize(700, 500)];

	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
	
	[itemGroup setSize: NSMakeSize(500, 400)];

	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
}

- (void) testFixedLayoutWithAutoresizedItems
{
	ETLayoutItem *item = [itemFactory item];
	ETLayoutItem *textFieldItem = [itemFactory textField];
	NSRect itemFrame = [item frame];
	NSRect textFieldFrame = NSMakeRect(20, 100, 100, 200);

	[item setAutoresizingMask: ETAutoresizingFlexibleLeftMargin];
	[textFieldItem setAutoresizingMask: ETAutoresizingFlexibleHeight | ETAutoresizingFlexibleTopMargin];
	
	[textFieldItem setFrame: textFieldFrame];

	[itemGroup addItems: A(item, textFieldItem)];
	[itemGroup updateLayout];
	
	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
	
	[itemGroup setSize: NSMakeSize(700, 700)];
	[itemGroup updateLayout];
	
	NSRect upItemFrame = NSMakeRect(itemFrame.origin.x + 200, itemFrame.origin.y,
		itemFrame.size.width, item.size.height);
	/* We add 300 to the item group height and the new y is going to be 
	   300 * 1/3, while the new height is going to be 300 * 2/3. 1/3 is the 
	   y amount in 'y + height', and 3/2 is the height amoung in "y + height'. */
	NSRect upTextFieldFrame = NSMakeRect(textFieldFrame.origin.x, textFieldFrame.origin.y + 100,
		textFieldFrame.size.width, textFieldFrame.size.height + 200);

	UKRectsEqual(upItemFrame, [item frame]);
	UKRectsEqual(upTextFieldFrame, [textFieldItem frame]);
	
	[itemGroup setSize: NSMakeSize(500, 400)];
	[itemGroup updateLayout];

	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
}

@end
