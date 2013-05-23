/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2013
    License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"

@interface TestItemValue : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *itemGroup;
	ETLayoutItem *item;
	Person *person;
}

@end

@implementation TestItemValue

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(item, [itemFactory item]);
	ASSIGN(itemGroup, [itemFactory itemGroup]);
	person = [Person new];
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(item);
	DESTROY(itemGroup);
	DESTROY(person);
	[super dealloc];
}

- (void) testNoValue
{
	UKNil([item value]);
	UKNil([item valueForProperty: kETValueProperty]);
	UKNil([itemGroup value]);
	UKNil([itemGroup valueForProperty: kETValueProperty]);
}

- (void) testItemRepresentedObjectAsValue
{
	[item setRepresentedObject: person];

	UKObjectsSame(person, [item value]);
	UKObjectsSame(person, [item valueForProperty: kETValueProperty]);
}

- (void) testItemValueKey
{
	[item setRepresentedObject: person];
	[item setValueKey: @"name"];
	
	UKObjectsEqual([person name], [item value]);
	UKObjectsEqual([person name], [item valueForProperty: @"name"]);
	UKObjectsEqual([person name], [item valueForProperty: kETValueProperty]);
}

- (void) testItemValueKeyForCollection
{
	[item setRepresentedObject: person];
	[item setValueKey: @"groupNames"];
	
	UKObjectsEqual([person groupNames], [item value]);
	UKObjectsEqual([person groupNames], [item valueForProperty: @"groupNames"]);
	UKObjectsEqual([person groupNames], [item valueForProperty: kETValueProperty]);
}

- (void) testItemGroupRepresentedObjectAsValue
{
	[itemGroup setRepresentedObject: person];
	[itemGroup setSource: itemGroup];
	
	UKObjectsSame(person, [itemGroup value]);
	UKObjectsSame(person, [itemGroup valueForProperty: kETValueProperty]);
}

- (void) testItemGroupValueKey
{
	[itemGroup setRepresentedObject: person];
	[itemGroup setValueKey: @"name"];
	[itemGroup setSource: itemGroup];
	
	UKObjectsEqual([person name], [itemGroup value]);
	UKObjectsEqual([person name], [itemGroup valueForProperty: @"name"]);
	UKObjectsEqual([person name], [itemGroup valueForProperty: kETValueProperty]);
}

- (void) testItemGroupValueKeyForCollection
{
	[itemGroup setRepresentedObject: person];
	[itemGroup setValueKey: @"groupNames"];
	[itemGroup setSource: itemGroup];

	UKObjectsEqual([person groupNames], [itemGroup value]);
	UKObjectsEqual([person groupNames], [itemGroup valueForProperty: @"groupNames"]);
	UKObjectsEqual([person groupNames], [itemGroup valueForProperty: kETValueProperty]);

	UKIntsEqual([[person groupNames] count], [itemGroup numberOfItems]);

	UKObjectsEqual([person groupNames], [[[itemGroup items] mappedCollection] representedObject]);
	UKObjectsEqual([person groupNames], [[[itemGroup items] mappedCollection] value]);
	UKObjectsEqual([person groupNames], [[[itemGroup items] mappedCollection] valueForProperty: kETValueProperty]);
	UKNil([[itemGroup firstItem] valueForProperty: @"groupNames"]);
}

@end
