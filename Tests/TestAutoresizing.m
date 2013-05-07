/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2013
    License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETColumnLayout.h"
#import "ETFixedLayout.h"
#import "ETLayout.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItem.h"
#import "ETLineLayout.h"
#import "ETColumnLayout.h"
#import "ETUIItem.h"
#include <objc/runtime.h>

@interface TestAutoresizing : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *itemGroup;
}

@end


@implementation TestAutoresizing

- (NSRect) defaultItemRect
{
	return NSMakeRect(0, 0, 50, 50);
}

- (void) exchangeDefaultItemRectImplementations
{
	Method scopedRectMethod =
		class_getInstanceMethod([self class], NSSelectorFromString(@"defaultItemRect"));
	Method rectMethod =
		class_getClassMethod([ETLayoutItem class], NSSelectorFromString(@"defaultItemRect"));
	
	method_exchangeImplementations(scopedRectMethod, rectMethod);
}

- (id) init
{
	SUPERINIT
	[self exchangeDefaultItemRectImplementations];
	ETAssert(NSEqualRects(NSMakeRect(0, 0, 50, 50), [ETLayoutItem defaultItemRect]));
	
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	//ASSIGN(itemGroup, [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 500, 400)]);
	ASSIGN(itemGroup, [itemFactory itemGroup]);
	[itemGroup setSize: NSMakeSize(500, 400)];
	ETAssert([[itemGroup layout] isKindOfClass: [ETFixedLayout class]]);
	return self;
}

- (void) dealloc
{
	[self exchangeDefaultItemRectImplementations];
	ETAssert(NSEqualRects(NSMakeRect(0, 0, 50, 50), [ETLayoutItem defaultItemRect]) == NO);

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

- (void) testWindowResize
{
	
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
	/* -updateLayout results in no autoresizing because of the new content (the 
	   old layout size is ignored) */
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

- (void) testFlexibleSeparatorInLineLayout
{
	[itemGroup setLayout: [ETLineLayout layout]];
	[[itemGroup layout] setSeparatorTemplateItem: [itemFactory flexibleSpaceSeparator]];

	ETLayoutItem *item = [itemFactory item];
	ETLayoutItem *textFieldItem = [itemFactory textField];
	ETLayoutItem *textViewItem = [itemFactory textView];
	CGFloat length = [item width] + [textFieldItem width] + [textViewItem width];
	CGFloat separatorWidth = (([itemGroup width] - length) / 2);

	[itemGroup addItems: A(item, textFieldItem, textViewItem)];
	[itemGroup updateLayout];
	
	UKIntsEqual(0, [item x]);
	UKIntsEqual(NSMaxX([item frame]) + separatorWidth, [textFieldItem x]);
	UKIntsEqual(NSMaxX([textFieldItem frame]) + separatorWidth, [textViewItem x]);

	// FIXME: The height should [itemGroup height] and not 50
	NSSize separatorSize = NSMakeSize(separatorWidth, 50);

	UKSizesEqual(separatorSize, [[[[itemGroup layout] layerItem] firstItem] size]);
	UKSizesEqual(separatorSize, [[[[itemGroup layout] layerItem] lastItem] size]);
}

- (void) testLineLayout
{
	[itemGroup setLayout: [ETLineLayout layout]];

	ETLayoutItem *item = [itemFactory item];
	ETLayoutItem *textFieldItem = [itemFactory textField];
	ETLayoutItem *textViewItem = [itemFactory textView];
	ETLayoutItemGroup *otherItem = [itemFactory itemGroup];
	NSRect itemFrame = [item frame];
	NSRect textFieldFrame = NSMakeRect(20, 100, 100, 200);
	NSRect textViewFrame = NSMakeRect(20, 50, 100, 200);
	NSRect otherItemFrame = [otherItem frame];

	[item setAutoresizingMask: ETAutoresizingFlexibleLeftMargin | ETAutoresizingFlexibleWidth];
	[textFieldItem setAutoresizingMask: ETAutoresizingFlexibleHeight | ETAutoresizingFlexibleTopMargin];
	[textViewItem setAutoresizingMask:
	 	ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleRightMargin | ETAutoresizingFlexibleTopMargin];
	[otherItem setAutoresizingMask: ETAutoresizingFlexibleHeight];

	[textFieldItem setFrame: textFieldFrame];
	[textViewItem setFrame: textViewFrame];

	[itemGroup addItems: A(item, textFieldItem, textViewItem, otherItem)];
	[itemGroup updateLayout];
	
	CGFloat rigidWidth = [textFieldItem width] + [otherItem width];
	CGFloat flexibleItemWidth = ([itemGroup width] - rigidWidth) / 2;

	/* For textFieldItem and otherItem that uses ETAutoresizingFlexibleHeight,
	   -addItems: implies the content is new and no autoresizing occurs using 
	   -resizeItems:forNewLayoutSize:oldSize:. */
	itemFrame = NSMakeRect(0, 0, flexibleItemWidth, itemFrame.size.height);
	textFieldFrame.origin = NSMakePoint(NSMaxX(itemFrame), 0);
	textViewFrame = NSMakeRect(NSMaxX(textFieldFrame), 0, flexibleItemWidth, textViewFrame.size.height);
	otherItemFrame.origin = NSMakePoint(NSMaxX(textViewFrame), 0);

	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
	UKRectsEqual(textViewFrame, [textViewItem frame]);
	UKRectsEqual(otherItemFrame, [otherItem frame]);

	[itemGroup setSize: NSMakeSize(700, 600)];
	[itemGroup updateLayout];
	
	NSRect upItemFrame = itemFrame;
	upItemFrame.size.width += 100;
	NSRect upTextFieldFrame = textFieldFrame;
	upTextFieldFrame.origin.x = NSMaxX(upItemFrame);
	upTextFieldFrame.size.height += 200;
	NSRect upTextViewFrame = textViewFrame;
	upTextViewFrame.origin.x = NSMaxX(upTextFieldFrame);
	upTextViewFrame.size.width += 100;
	NSRect upOtherItemFrame = otherItemFrame;
	upOtherItemFrame.origin.x = NSMaxX(upTextViewFrame);
	upOtherItemFrame.size.height += 200;

	UKRectsEqual(upItemFrame, [item frame]);
	UKRectsEqual(upTextFieldFrame, [textFieldItem frame]);
	UKRectsEqual(upTextViewFrame, [textViewItem frame]);
	UKRectsEqual(upOtherItemFrame, [otherItem frame]);

	[itemGroup setSize: NSMakeSize(500, 400)];
	[itemGroup updateLayout];
	
	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
	UKRectsEqual(textViewFrame, [textViewItem frame]);
	UKRectsEqual(otherItemFrame, [otherItem frame]);
}

- (void) testColumnLayout
{
	[itemGroup setLayout: [ETColumnLayout layout]];

	ETLayoutItem *item = [itemFactory item];
	ETLayoutItem *textFieldItem = [itemFactory textField];
	ETLayoutItem *textViewItem = [itemFactory textView];
	ETLayoutItemGroup *otherItem = [itemFactory itemGroup];
	NSRect itemFrame = [item frame];
	NSRect textFieldFrame = NSMakeRect(20, 100, 100, 200);
	NSRect textViewFrame = NSMakeRect(20, 50, 100, 200);
	NSRect otherItemFrame = [otherItem frame];

	[item setAutoresizingMask: ETAutoresizingFlexibleLeftMargin | ETAutoresizingFlexibleHeight];
	[textFieldItem setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleTopMargin];
	[textViewItem setAutoresizingMask:
	 	ETAutoresizingFlexibleHeight | ETAutoresizingFlexibleRightMargin | ETAutoresizingFlexibleTopMargin];
	[otherItem setAutoresizingMask: ETAutoresizingFlexibleWidth];

	[textFieldItem setFrame: textFieldFrame];
	[textViewItem setFrame: textViewFrame];

	[itemGroup addItems: A(item, textFieldItem, textViewItem, otherItem)];
	[itemGroup updateLayout];
	
	CGFloat rigidHeight = [textFieldItem height] + [otherItem height];
	CGFloat flexibleItemHeight = ([itemGroup height] - rigidHeight) / 2;

	/* For textFieldItem and otherItem that uses ETAutoresizingFlexibleWidth, 
	   -addItems: implies the content is new and no autoresizing occurs using 
	   -resizeItems:forNewLayoutSize:oldSize:. */
	itemFrame = NSMakeRect(0, 0, itemFrame.size.width, flexibleItemHeight);
	textFieldFrame.origin = NSMakePoint(0, NSMaxY(itemFrame));
	textViewFrame = NSMakeRect(0, NSMaxY(textFieldFrame), textViewFrame.size.width, flexibleItemHeight);
	otherItemFrame.origin = NSMakePoint(0, NSMaxY(textViewFrame));

	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
	UKRectsEqual(textViewFrame, [textViewItem frame]);
	UKRectsEqual(otherItemFrame, [otherItem frame]);

	[itemGroup setSize: NSMakeSize(700, 600)];
	[itemGroup updateLayout];

	NSRect upItemFrame = itemFrame;
	upItemFrame.size.height += 100;
	NSRect upTextFieldFrame = textFieldFrame;
	upTextFieldFrame.origin.y = NSMaxY(upItemFrame);
	upTextFieldFrame.size.width += 200;
	NSRect upTextViewFrame = textViewFrame;
	upTextViewFrame.origin.y = NSMaxY(upTextFieldFrame);
	upTextViewFrame.size.height += 100;
	NSRect upOtherItemFrame = otherItemFrame;
	upOtherItemFrame.origin.y = NSMaxY(upTextViewFrame);
	upOtherItemFrame.size.width += 200;

	UKRectsEqual(upItemFrame, [item frame]);
	UKRectsEqual(upTextFieldFrame, [textFieldItem frame]);
	UKRectsEqual(upTextViewFrame, [textViewItem frame]);
	UKRectsEqual(upOtherItemFrame, [otherItem frame]);

	[itemGroup setSize: NSMakeSize(500, 400)];
	[itemGroup updateLayout];
	
	UKRectsEqual(itemFrame, [item frame]);
	UKRectsEqual(textFieldFrame, [textFieldItem frame]);
	UKRectsEqual(textViewFrame, [textViewItem frame]);
	UKRectsEqual(otherItemFrame, [otherItem frame]);
}

@end
