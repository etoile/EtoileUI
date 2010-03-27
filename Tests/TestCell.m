/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2010
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETActionHandler.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETTableLayout.h"
#import "NSCell+EtoileUI.h"
#import "ETCompatibility.h"

@interface TestCell: NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItem *item;
}

@end

@implementation TestCell

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(item, [itemFactory item]);
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (void) testItemAsCellObjectValue
{
	NSCell *cell = AUTORELEASE([NSCell new]);
	[cell setObjectValue: [cell objectValueForObject: item]];

	UKStringsEqual([item stringValue], [cell objectValue]);
}

/* We must be sure NSCell doesn't copy objects unless they are value objects. 
e.g. For a 'decoratorItem' property we inspect, we don't want to show an item copy.

Moreover if -copyWithZone: temporarily alters properties on the receiver and 
their values are visible in the table/outline where the receiver is listed, 
once the KVO notifications have been processed, the redisplay (caused by 
-setNeedsDisplay:) results in an endless cycle: display, copy, notify, 
invalidate, display etc. */
- (void) testTableAndCellDoesNotCopyNonValueObject
{
	ETLayoutItem *observedItem = [itemFactory item];
	ETLayoutItemGroup *parentItem = [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 400, 300)];

	[parentItem setLayout: [ETTableLayout layout]];
	[[parentItem layout] setDisplayedProperties: A(@"value")];
	[item setRepresentedObject: [ETProperty propertyWithName: @"actionHandler"
	                                       representedObject: observedItem]];
	[parentItem addItem: item];

	NSCell *cell = [[[parentItem layout] tableView] preparedCellAtColumn: 0 row: 0];
	ETActionHandler *actionHandler = [observedItem valueForProperty: @"actionHandler"];

	UKStringsEqual([cell objectValue], [actionHandler stringValue]);
}

@end

