/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2013
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayer.h"
#import "ETApplication.h"
#import "ETBrowserLayout.h"
#import "ETFreeLayout.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "ETWindowItem.h"

@interface TestWindowLayout : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *itemGroup;
	ETLayoutItem *item;
}

@end


@implementation TestWindowLayout

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(itemGroup, [itemFactory itemGroup]);
	ASSIGN(item, [itemFactory item]);
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(itemGroup);
	DESTROY(item);
	[super dealloc];
}

- (void) checkSwitchBackToWindowLayoutFromLayout: (ETLayout *)aLayout
{
	ETLayoutItemGroup *windowGroup = [itemFactory windowGroup];

	[windowGroup addItems: A(item, itemGroup)];

	NSWindow *itemWindow = [[item windowItem] window];
	NSWindow *itemGroupWindow = [[itemGroup windowItem] window];

	UKNotNil([item windowItem]);
	UKNotNil([itemGroup windowItem]);
	UKTrue([itemWindow isVisible]);
	UKTrue([itemGroupWindow isVisible]);
	UKNil([windowGroup windowItem]);

	[windowGroup setLayout: aLayout];

	NSWindow *rootWindow = [[windowGroup windowItem] window];

	UKNil([item windowItem]);
	UKNil([itemGroup windowItem]);
	UKFalse([itemWindow isVisible]);
	UKFalse([itemGroupWindow isVisible]);
	UKNotNil([windowGroup windowItem]);
	UKTrue([rootWindow isVisible]);

	[windowGroup setLayout: [ETWindowLayout layout]];

	UKNotNil([item windowItem]);
	UKNotNil([itemGroup windowItem]);
	UKTrue([itemWindow isVisible]);
	UKTrue([itemGroupWindow isVisible]);
	UKFalse([rootWindow isVisible]);
	UKTrue([S(itemWindow, itemGroupWindow) isSubsetOfSet: [NSSet setWithArray: [ETApp windows]]]);
}
			 
- (void) testSwitchBackToWindowLayoutFromFreeLayout
{
	[self checkSwitchBackToWindowLayoutFromLayout: [ETFreeLayout layout]];
}
			 
- (void) testSwitchBackToWindowLayoutFromWidgetLayout
{
	[self checkSwitchBackToWindowLayoutFromLayout: [ETBrowserLayout layout]];
}

@end

