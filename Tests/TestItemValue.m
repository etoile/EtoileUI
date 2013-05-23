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
#import "ETWidget.h"
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

- (void) testItemWidgetValue
{
	ASSIGN(item, [itemFactory textField]);

	UKObjectsEqual(@"", [[item widget] objectValue]);
	UKNil([item value]);
}

- (void) testItemValueSynchronizationWithTextFiedWidget
{
	ASSIGN(item, [itemFactory textField]);

	/* Setting an item value allows the item to react to widget object value changes */
	[item setValue: @"Bird"];
	
	UKObjectsEqual(@"Bird", [[item widget] objectValue]);
	UKObjectsEqual(@"Bird", [item value]);

	[[item widget] setObjectValue: @"Wi"];
	
	UKObjectsEqual(@"Wi", [[item widget] objectValue]);
	UKObjectsEqual(@"Wi", [item value]);
}

- (void) testItemValueSynchronizationWithSliderWidget
{
	ASSIGN(item, [itemFactory horizontalSlider]);

	UKObjectKindOf([[item widget] objectValue], NSNumber);
	UKNil([item value]);

	/* Setting an item value allows the item to react to widget object value changes */
	[item setValue: [NSNumber numberWithInt: 5]];
	
	UKObjectsEqual([NSNumber numberWithInt: 5], [[item widget] objectValue]);
	UKObjectsEqual([NSNumber numberWithInt: 5], [item value]);

	[[item widget] setObjectValue: [NSNumber numberWithInt: 3]];
	
	UKObjectsEqual([NSNumber numberWithInt: 3], [[item widget] objectValue]);
	UKObjectsEqual([NSNumber numberWithInt: 3], [item value]);
}

- (void) testItemValueNotSynchronizedFromWidget
{
	ASSIGN(item, [itemFactory textField]);

	[[item widget] setObjectValue: @"Wi"];
	
	UKObjectsEqual(@"Wi", [[item widget] objectValue]);
	/* If the represented object was nil, it remains nil */
	UKNil([item value]);
}

- (void) testButtonTitleForItemValue
{
	ASSIGN(item, [itemFactory buttonWithTitle: @"Bop" target: nil action: NULL]);
	
	UKObjectsEqual(@"Bop", [(NSButton *)[item view] title]);
	UKNil([item value]);
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
