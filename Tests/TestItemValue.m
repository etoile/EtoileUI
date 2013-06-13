/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2013
    License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollectionViewpoint.h>
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

	UKObjectKindOf([item representedObject], ETMutableObjectViewpoint);
	UKObjectsEqual([person name], [item value]);
	/* -valueForProperty: exposes the viewpoint value properties and -[ETLayoutItem value] */
	UKNil([item valueForProperty: @"name"]);
	UKObjectsEqual([person name], [item valueForProperty: kETValueProperty]);
	UKObjectKindOf([item valueForProperty: @"self"], NSString);
}

- (void) testItemValueKeyForCollection
{
	[item setRepresentedObject: person];
	[item setValueKey: @"groupNames"];

	UKObjectKindOf([item representedObject], [ETMutableObjectViewpoint class]);
	UKObjectsEqual([person groupNames], [item value]);
	UKNil([item valueForProperty: @"groupNames"]);
	UKObjectsEqual([person groupNames], [item valueForProperty: kETValueProperty]);
	UKObjectKindOf([item valueForProperty: @"self"], NSArray);
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

	UKObjectKindOf([itemGroup representedObject], ETMutableObjectViewpoint);
	UKObjectsEqual([person name], [itemGroup value]);
	/* -valueForProperty: exposes the viewpoint value properties and -[ETLayoutItem value] */
	UKObjectsEqual([person name], [itemGroup valueForProperty: kETValueProperty]);
	UKNil([itemGroup valueForProperty: @"name"]);
	UKObjectKindOf([itemGroup valueForProperty: @"self"], NSString);
}

- (void) testItemGroupValueKeyForCollection
{
	[itemGroup setRepresentedObject: person];
	[itemGroup setValueKey: @"groupNames"];
	[itemGroup setSource: itemGroup];

	UKObjectKindOf([itemGroup representedObject], ETCollectionViewpoint);
	/* We call -content on the value in case -value returns a collection viewpoint.
	   Turning ETCollectionViewpoint into a proxy could be interesting, methods 
	   such as as -isEqual: , -objectAtIndex: etc. would work. */
	UKObjectsEqual([person groupNames], [[itemGroup value] content]);
	UKNil([itemGroup valueForProperty: @"groupNames"]);
	UKObjectsEqual([person groupNames], [itemGroup valueForProperty: kETValueProperty]);
	UKObjectKindOf([itemGroup valueForProperty: @"self"], NSArray);

	UKIntsEqual([[person groupNames] count], [itemGroup numberOfItems]);

	NSArray *pairs = [[person groupNames] viewpointArray];
	NSArray *pairValues = [person groupNames];
	NSArray *items = [itemGroup items];

	UKObjectsEqual(pairs, [[items mappedCollection] representedObject]);
	UKObjectsEqual(pairs, (id)[[items mappedCollection] value]);
	/* The represented object is a simple string that doesn't implement -value 
	   so -valueForProperty: retrieves the value from the item. */
	UKObjectsEqual(pairValues, [[items mappedCollection] valueForProperty: kETValueProperty]);

	ETLayoutItem *someItem = [itemGroup firstItem];
	
	UKNil([someItem valueForProperty: @"groupNames"]);
	
	NSUInteger pairIndex = [[someItem valueForProperty: @"index"] unsignedIntegerValue];
	NSString *pairValue = [someItem valueForProperty: @"value"];
	ETIndexValuePair *pair = AUTORELEASE([[ETIndexValuePair alloc]
		initWithIndex: pairIndex value: pairValue representedObject: [person groupNames]]);

	UKTrue([[person groupNames] containsObject: pairValue]);
	UKObjectsEqual(pairValue, [[person groupNames] objectAtIndex: pairIndex]);
	UKTrue([pairs containsObject: pair]);
}

- (void) testItemGroupValueKeyForCollectionMutation
{
	[itemGroup setRepresentedObject: person];
	[itemGroup setValueKey: @"groupNames"];
	[itemGroup setSource: itemGroup];
	
	NSUInteger count = [itemGroup count];
	ETIndexValuePair *pair = AUTORELEASE([[ETIndexValuePair alloc]
		initWithIndex: ETUndeterminedIndex value: @"Nowhere" representedObject: [itemGroup representedObject]]);

	/* No need to create a pair, because -mutateRepresentedForItem:atIndex:hint: 
	   would unbox it so -insertObject:atIndex:hint: is always called on 
	   ETCollectionViewPoint with @"Nowhere" as the inserted object. */
	// FIXME: ASSIGN(item, [itemFactory itemWithRepresentedObject: @"Nowhere"]);
	// This works but doesn't update the created item to use an index value pair
	// as its represented object. The solution is to provide a template provider
	// that creates ETIndexValuePair and ETKeyValuePair objects (if no controller
	// exists).
	ASSIGN(item, [itemFactory itemWithRepresentedObject: pair]);

	[itemGroup insertItem: item atIndex: 1];

	NSArray *pairs = [[person groupNames] viewpointArray];

	UKIntsEqual(count + 1, [[person groupNames] count]);
	UKObjectsEqual(@"Nowhere", [[person groupNames] objectAtIndex: 1]);
	UKObjectsEqual(@"Nowhere", [[[itemGroup value] content] objectAtIndex: 1]);
	// FIXME: The pair indexes are not updated
	//UKObjectsEqual(pairs, [[[itemGroup items] mappedCollection] representedObject]);

	[itemGroup removeItem: item];
	
	pairs = [[person groupNames] viewpointArray];
	
	UKIntsEqual(count, [[person groupNames] count]);
	UKFalse([[person groupNames] containsObject: @"Nowhere"]);
	UKFalse([[itemGroup value] containsObject: @"Nowhere"]);
	UKObjectsEqual(pairs, [[[itemGroup items] mappedCollection] representedObject]);
}

- (void) testItemGroupValueKeyForDictionary
{
	[itemGroup setRepresentedObject: person];
	[itemGroup setValueKey: @"emails"];
	[itemGroup setSource: itemGroup];

	/* We call -content on the value in case -value returns a collection viewpoint.
	   Turning ETCollectionViewpoint into a proxy could be interesting, methods 
	   such as as -isEqual: , -objectAtIndex: etc. would work. */
	UKObjectsEqual([person emails], [[itemGroup value] content]);
	UKNil([itemGroup valueForProperty: @"emails"]);
	UKObjectsEqual([person emails], [[itemGroup valueForProperty: kETValueProperty] content]);
	UKObjectKindOf([itemGroup valueForProperty: @"self"], NSDictionary);

	UKIntsEqual([[person emails] count], [itemGroup numberOfItems]);

	NSArray *pairs = [[person emails] arrayRepresentation];
	NSArray *pairValues = [[person emails] allValues];
	NSArray *items = [itemGroup items];

	UKObjectsEqual(SA(pairs), SA([[items mappedCollection] representedObject]));
	UKObjectsEqual(SA(pairs), SA((id)[[items mappedCollection] value]));
	/* The represented object is a key-value pair that implements -value so 
	   -valueForProperty: retrieves the value from the represented object. */
	UKObjectsEqual(SA(pairValues), SA([[items mappedCollection] valueForProperty: kETValueProperty]));

	ETLayoutItem *someItem = [itemGroup firstItem];
	
	UKNil([someItem valueForProperty: @"emails"]);

	NSString *pairKey = [someItem valueForProperty: @"key"];
	NSString *pairValue = [someItem valueForProperty: @"value"];

	UKTrue([[person emails] containsKey: pairKey]);
	UKTrue([[person emails] containsObject: pairValue]);
	UKObjectsEqual(pairValue, [[person emails] objectForKey: pairKey]);
	UKTrue([pairs containsObject: [ETKeyValuePair pairWithKey: pairKey value: pairValue]]);
}

- (void) testItemGroupValueKeyForDictionaryMutation
{
	[itemGroup setRepresentedObject: person];
	[itemGroup setValueKey: @"emails"];
	[itemGroup setSource: itemGroup];
	
	NSUInteger count = [itemGroup count];
	ETKeyValuePair *pair = [ETKeyValuePair pairWithKey: @"Cave" value: @"john@timetravel.com"];

	ASSIGN(item, [itemFactory itemWithRepresentedObject: pair]);

	[itemGroup insertItem: item atIndex: 1];

	NSArray *pairs = [[person emails] arrayRepresentation];
	
	UKIntsEqual(count + 1, [[person emails] count]);
	UKObjectsEqual([pair value], [[person emails] objectForKey: [pair key]]);
	UKTrue([pairs containsObject: pair]);
	UKObjectsEqual([pair value], [[[itemGroup value] content] objectForKey: [pair key]]);
	UKObjectsEqual(SA(pairs), SA([[[itemGroup items] mappedCollection] representedObject]));

	[itemGroup removeItem: item];

	pairs = [[person emails] arrayRepresentation];
	
	UKIntsEqual(count, [[person emails] count]);
	UKNil([[person emails] objectForKey: [pair key]]);
	UKFalse([pairs containsObject: pair]);
	UKNil([[[itemGroup value] content] objectForKey: [pair key]]);
	UKObjectsEqual(SA(pairs), SA([[[itemGroup items] mappedCollection] representedObject]));
}

- (void) testItemGroupValueForItemAsRepresentedObject
{
	[[itemFactory windowGroup] addItem: item];
	// FIXME: Fix missing reload if -setSource: precedes -setRepresentedObject:
	//[itemGroup setSource: itemGroup];
	//[itemGroup setRepresentedObject: [itemFactory windowGroup]];
	[itemGroup setRepresentedObject: [itemFactory windowGroup]];
	[itemGroup setSource: itemGroup];

	UKObjectsSame(item, [[itemGroup lastItem] representedObject]);
	
	[[itemFactory windowGroup] removeItem: item];
}

- (void) testItemGroupValueForItemSubject
{
	ETLayoutItemGroup *otherItemGroup = [itemFactory itemGroupWithItems: A(item)];

	[itemGroup setSource: itemGroup];
	[itemGroup setRepresentedObject: otherItemGroup];
	/* Expose -[otherItemGroup subject] */
	[itemGroup setValueKey: @"subject"];

	/* Detect that no collection viewpoint is created (see -mutableCollectionForKey:value:) */
	UKObjectsSame(otherItemGroup, [itemGroup value]);
}

@end
