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
#import "ETTableLayout.h"
#import "ETUIItem.h"
#import "ETUIItemFactory.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

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
	ETCompositeLayout *layout = [[ETCompositeLayout alloc] initWithRootItem: [itemFactory itemGroup]];
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

	UKRectsEqual(ETMakeRect(NSZeroPoint, [item size]), [proxyItem frame]);
}

@end
