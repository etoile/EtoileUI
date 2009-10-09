/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  October 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"


@interface TestStyle: NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItem *item;
}

@end

@implementation TestStyle

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	item = [[ETLayoutItem alloc] init];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (void) testSharedInstance
{
	UKNotNil([ETBasicItemStyle sharedInstance]);
}

@end

