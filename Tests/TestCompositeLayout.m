/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETCompositeLayout.h"
#import "ETGeometry.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETPaneLayout.h"
#import "ETTableLayout.h"
#import "ETUIItem.h"
#import "ETUIItemFactory.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))
#define S(...) [NSSet setWithObjects:__VA_ARGS__ , nil]
#define SA(x) [NSSet setWithArray: x]

@interface TestCompositeLayout : NSObject <UKTest>
{
	ETUIItemFactory *itemFactory;
	ETLayoutItemGroup *item;
}

@end


@implementation TestCompositeLayout

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETUIItemFactory factory]);
	item = [[ETLayoutItemGroup alloc] init];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (void) testSetUpCompositeLayout
{
	ETCompositeLayout *layout = AUTORELEASE([[ETCompositeLayout alloc] 
		initWithRootItem: [itemFactory itemGroup]]);
	NSArray *content = A([itemFactory verticalSlider], [itemFactory oval], [itemFactory textField]);

	[item addItems: content];
	[item setLayout: layout];

	ETLayoutItemGroup *proxyItem = [layout firstPresentationItem];
	UKObjectsEqual(proxyItem, [item firstItem]);
	UKObjectsEqual(content, [proxyItem items]);

	ETTableLayout *proxyLayout = (ETTableLayout *)[proxyItem layout];

	[item updateLayout];

	UKIntsEqual(3, [[proxyLayout tableView] numberOfRows]);
	UKNotNil([item supervisorView]);
	// TODO: Next line could be UKTrue([[item supervisorView] containsObject: [proxyItem supervisorView]]);
	UKTrue([[[item supervisorView] subviews] containsObject: [proxyItem supervisorView]]);
	UKObjectsEqual([proxyItem supervisorView], [[proxyLayout layoutView] superview]);

	// FIXME: UKRectsEqual(ETMakeRect(NSZeroPoint, [item size]), [proxyItem frame]);
}

@end


@interface TestPaneLayout : TestCompositeLayout
{
	ETPaneLayout *layout;
	ETLayoutItemGroup *barItem;
	ETLayoutItem *sliderItem;
	ETLayoutItem *textFieldItem;
	ETLayoutItem *ovalItem;
}

@end

@implementation TestPaneLayout

- (id) init
{
	SUPERINIT

	[item setAutolayout: NO];
	layout = [[ETPaneLayout alloc] init];
	barItem = [layout barItem]; /* layout will retains us */

	return self;	
}

DEALLOC(DESTROY(layout))

- (void) setUpLayout
{
	sliderItem = [itemFactory verticalSlider];
	textFieldItem = [itemFactory textField];
	ovalItem = [itemFactory oval];
	[item addItems: A(sliderItem, textFieldItem, ovalItem)];
	[item setLayout: layout];
}

- (void) testInit
{
	UKObjectsEqual(S(barItem, [layout contentItem]), SA([[layout rootItem] items]));
	UKObjectsEqual([layout firstPresentationItem], barItem);
}

- (void) testSetUp
{
	[self setUpLayout];

	UKTrue([[layout rootItem] isEmpty]);
	UKObjectsEqual(S(barItem, [layout contentItem]), SA([item items]));
	UKObjectsEqual([layout firstPresentationItem], barItem);

	UKIntsEqual(3, [barItem numberOfItems]);
	UKObjectsEqual(barItem, [[barItem firstItem] parentItem]);
	UKTrue([[layout contentItem] isEmpty]);
}

- (void) testUpdateLayout
{
	[self setUpLayout];

	 /* Forces layout update (currently disabled) but only in 'item' and not 
	    'contentItem' and 'barItem' children. Will invoke -goToItem:. */
	[layout render: nil];

	UKObjectsEqual(A(sliderItem), [[layout contentItem] items]);
	UKObjectsEqual([layout contentItem], [sliderItem parentItem]);
}

- (void) testVisitingItem
{
	[self setUpLayout];

	ETLayoutItem *sliderItemProxy = [layout beginVisitingItem: sliderItem];

	UKObjectsEqual(sliderItem, [sliderItemProxy representedObject]);
	UKObjectsEqual(A(sliderItemProxy, textFieldItem, ovalItem), [barItem items]);

	[layout endVisitingItem: sliderItemProxy];

	UKObjectsEqual(A(sliderItem, textFieldItem, ovalItem), [barItem items]);
	UKObjectsEqual(barItem, [sliderItem parentItem]);

	ETLayoutItem *ovalItemProxy = [layout beginVisitingItem: ovalItem];

	UKObjectsEqual(ovalItem, [ovalItemProxy representedObject]);
	UKObjectsEqual(A(sliderItem, textFieldItem, ovalItemProxy), [barItem items]);
	UKObjectsEqual(barItem, [ovalItemProxy parentItem]);
}

- (void) testInvalidGoToItem
{
	[self setUpLayout];

	UKTrue([layout goToItem: sliderItem]);
	UKTrue([layout goToItem: sliderItem]);
	UKTrue([layout goToItem: [layout currentItem]]);
	UKFalse([layout goToItem: [itemFactory item]]);
	UKFalse([layout goToItem: nil]);
}

- (void) testGoToItem
{
	[self setUpLayout];

	[layout goToItem: sliderItem];
	ETLayoutItem *sliderItemProxy = [barItem firstItem];

	UKObjectsEqual(sliderItemProxy, [layout currentItem]);
	UKObjectsEqual(A(sliderItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItemProxy, textFieldItem, ovalItem), [barItem items]);

	[layout goToItem: textFieldItem];
	ETLayoutItem *textFieldItemProxy = [barItem itemAtIndex: 1];

	UKObjectsEqual(textFieldItemProxy, [layout currentItem]);
	UKObjectsEqual(A(textFieldItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItem, textFieldItemProxy, ovalItem), [barItem items]);

	[layout goToItem: sliderItem];
	sliderItemProxy = [barItem firstItem];

	UKObjectsEqual(sliderItemProxy, [layout currentItem]);
	UKObjectsEqual(A(sliderItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItemProxy, textFieldItem, ovalItem), [barItem items]);

	[layout goToItem: ovalItem];
	ETLayoutItem *ovalItemProxy = [barItem lastItem];

	UKObjectsEqual(ovalItemProxy, [layout currentItem]);
	UKObjectsEqual(A(ovalItem), [[layout contentItem] items]);
	UKObjectsEqual(A(sliderItem, textFieldItem, ovalItemProxy), [barItem items]);
}

@end
