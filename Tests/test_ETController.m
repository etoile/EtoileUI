/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
    License:  Modified BSD (see COPYING)
 */

 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETController.h"
#import "EtoileUIProperties.h"
#import "ETItemTemplate.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"
#import <UnitKit/UnitKit.h>

/* NSView subclass for testing the cloning of item templates */
@interface DummyView : NSView { }
@end
@implementation DummyView
@end

@interface ETController (Test)
- (id) makeObject;
- (id) makeGroup;
@end
@implementation ETController (Test)
- (id) makeObject
{
	return AUTORELEASE([[[self templateForType: kETTemplateObjectType] objectClass] new]);
}
- (id) makeGroup
{
	return AUTORELEASE([[[self templateForType: kETTemplateGroupType] objectClass] new]);
}
- (id) makeItem
{
	return AUTORELEASE([self newItemWithURL: nil ofType: kETTemplateObjectType options: nil]);
}
- (id) makeItemGroup
{
	return AUTORELEASE([self newItemWithURL: nil ofType: kETTemplateGroupType options: nil]);
}
- (void) setObjectClass: (Class)aClass
{
	id oldTemplate = [self templateForType: kETTemplateObjectType];
	id newTemplate = [ETItemTemplate templateWithItem: [oldTemplate item] objectClass: aClass];
	[self setTemplate: newTemplate forType: kETTemplateObjectType];
}
- (void) setGroupClass: (Class)aClass
{
	id oldTemplate = [self templateForType: kETTemplateGroupType];
	id newTemplate = [ETItemTemplate templateWithItem: [oldTemplate item] objectClass: aClass];
	[self setTemplate: newTemplate forType: kETTemplateGroupType];
}
- (void) setTemplateItem: (ETLayoutItem *)anItem
{
	id oldTemplate = [self templateForType: kETTemplateObjectType];
	id newTemplate = [ETItemTemplate templateWithItem: anItem objectClass: [oldTemplate objectClass]];
	[self setTemplate: newTemplate forType: kETTemplateObjectType];
}
- (void) setTemplateItemGroup: (ETLayoutItemGroup *)anItem
{
	id oldTemplate = [self templateForType: kETTemplateGroupType];
	id newTemplate = [ETItemTemplate templateWithItem: anItem objectClass: [oldTemplate objectClass]];
	[self setTemplate: newTemplate forType: kETTemplateGroupType];
}
@end

@interface TestController : NSObject <UKTest>
{
	ETController *controller;
	ETLayoutItemGroup *content;
	ETLayoutItemFactory *itemFactory;
}

@end


@implementation TestController

- (id) init
{
	SUPERINIT

	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(content, [itemFactory itemGroup]);
	controller = [[ETController alloc] init];

	[content setController: controller];

	return self;
}

- (void) dealloc
{
	DESTROY(content);
	DESTROY(controller);
	DESTROY(itemFactory);
	[super dealloc];
}

- (NSArray *) contentArray
{
	return [[controller content] contentArray];
}

- (void) testInit
{
	UKTrue([[controller content] isEmpty]);
}

- (void) testNewObject
{
	UKNil([controller makeObject]);

	/* Test model class */

	[controller setObjectClass: [NSDate class]];
	id newObject = [controller makeObject];
	id newObject2 = [controller makeObject];

	UKObjectKindOf(newObject, NSDate);
	// newObject2 is created with -alloc and -init, thereby returns two different dates in time.
	UKObjectsNotEqual(newObject2, newObject); 

	/* Test item template */

	id view = AUTORELEASE([DummyView new]);
	id templateItem = [itemFactory itemWithView: view];
	[controller setTemplateItem: templateItem];
	id newItem = [controller makeItem]; 
	id newItem2 = [controller makeItem];

	UKObjectKindOf(newItem, ETLayoutItem);
	UKObjectsNotEqual(templateItem, newItem);
	UKObjectKindOf([newItem view], DummyView);
	UKObjectsNotEqual(view, [newItem view]);
	UKObjectsNotEqual(newItem2, newItem);
	UKObjectsNotEqual([newItem2 view], [newItem view]);

	/* Test with object class */

	UKObjectKindOf([newItem representedObject], NSDate);
	// newObject2 is created with -alloc and -init and not -copy
	UKObjectsNotEqual([newItem2 representedObject], [newItem representedObject]);

	/* Test without object class */

	[controller setObjectClass: nil];
	newItem = [controller makeItem];
	newItem2 = [controller makeItem];
	UKNil([newItem representedObject]);
	UKNil([newItem2 representedObject]);

	/* Test with object prototype */

	// TODO: Tweak ETItemTemplate and update the code below.
	//[[controller templateItem] setRepresentedObject: [NSIndexSet indexSetWithIndex: 5]];
	//UKObjectKindOf([newItem representedObject], NSIndexSet);
	//UKObjectsNotSame([newItem2 representedObject], [newItem representedObject]);
	//UKObjectsEqual([newItem2 representedObject], [newItem representedObject]);
}

- (void) testNewGroup
{
	UKNil([controller makeGroup]);

	[controller setGroupClass: [NSMutableArray class]];

	id newGroup = [controller makeGroup];
	id newGroup2 = [controller makeGroup];

	UKObjectKindOf(newGroup, NSMutableArray);
	// newGroup2 is created with -alloc and -init and not -copy
	UKObjectsNotSame(newGroup2, newGroup);

	/* Test item template */

	id view = AUTORELEASE([DummyView new]);
	id templateItem = AUTORELEASE([[ETLayoutItemGroup alloc] initWithView: view value: nil representedObject: nil]);
	[controller setTemplateItemGroup: templateItem];
	id newItemGroup = [controller makeItemGroup];
	id newItemGroup2 = [controller makeItemGroup];

	UKObjectKindOf(newItemGroup, ETLayoutItemGroup);
	UKObjectsNotEqual(templateItem, newItemGroup);
	UKObjectKindOf([newItemGroup view], DummyView);
	UKObjectsNotEqual(view, [newItemGroup view]);
	UKObjectsNotEqual(newItemGroup2, newItemGroup);
	UKObjectsNotEqual([newItemGroup2 view], [newItemGroup view]);

	/* Test with object class */

	UKObjectKindOf([newItemGroup representedObject], NSMutableArray);
	// newGroup2 not created by sending -copy but -alloc and -init
	UKObjectsNotSame([newItemGroup2 representedObject], [newItemGroup representedObject]);

	/* Test without object class */

	[controller setGroupClass: nil];
	newItemGroup = [controller makeItemGroup];
	newItemGroup2 = [controller makeItemGroup];
	UKNil([newItemGroup representedObject]);
	UKNil([newItemGroup2 representedObject]);

	/* Test with object prototype */

	// TODO: Tweak ETItemTemplate and update the code below.
	//[[controller templateItemGroup] setRepresentedObject: [NSIndexSet indexSetWithIndex: 5]];
	//UKObjectKindOf([newItemGroup representedObject], NSIndexSet);
	//UKObjectsNotSame([newItemGroup2 representedObject], [newItemGroup representedObject]);
	//UKObjectsEqual([newGroup2 representedObject], [newGroup representedObject]);
}

- (void) testAdd
{
	[controller setObjectClass: [NSDate class]];
	[controller add: nil];
	id item = [[self contentArray] lastObject];

	/* Right Item and Represented Object */

	UKIntsEqual(1, [[self contentArray] count]);
	UKObjectKindOf(item, ETLayoutItem);
	UKObjectKindOf([item representedObject], NSDate);

	/* Custom Selection (last place insert)  */

	[content setSelectionIndex: 0];
	[controller add: nil];
	id item2 = [[self contentArray] lastObject];

	UKIntsEqual(2, [[self contentArray] count]);
	UKObjectsNotSame(item, item2);
}

- (void) testInsert
{
	[controller setObjectClass: [NSDate class]];
	[controller insert: nil];
	id item = [[self contentArray] lastObject];

	/* Right Item and Represented Object */

	UKIntsEqual(1, [[self contentArray] count]);
	UKObjectKindOf(item, ETLayoutItem);
	UKObjectKindOf([item representedObject], NSDate);

	/* Default Selection (last place insert) */

	[controller insert: nil];
	id item2 = [[self contentArray] lastObject];

	UKIntsEqual(2, [[self contentArray] count]);
	UKObjectsNotSame(item, item2);

	/* Custom Selection */

	[content setSelectionIndex: 1];
	[controller insert: nil];
	id item3 = [[self contentArray] objectAtIndex: 2];

	UKIntsEqual(3, [[self contentArray] count]);
	UKObjectsNotSame(item, item3);
	UKObjectsNotSame(item2, item3);
}

- (void) testRemove
{
	[controller setObjectClass: [NSDate class]];
	[controller add: nil];
	[controller add: nil];
	id item = [[self contentArray] lastObject];

	/* Default Selection (aka selects last inserted object) */

	[controller remove: nil];
	UKIntsEqual(1, [[self contentArray] count]);
	UKObjectsNotEqual(item, [[self contentArray] lastObject]);

	/* No Selection */

	[content setSelectionIndex: 1];
	[controller remove: nil];
	UKIntsEqual(1, [[self contentArray] count]);

	/* Valid Single Selection */

	[controller add: nil];
	[controller add: nil];
	item = [[self contentArray] objectAtIndex: 1];

	[content setSelectionIndex: 1];
	[controller remove: nil];
	UKIntsEqual(2, [[self contentArray] count]);
	UKObjectsNotEqual(item, [[self contentArray] firstObject]);
	UKObjectsNotEqual(item, [[self contentArray] lastObject]);

	/* Valid Multiple Selection (batch removal) */

	[content setSelectionIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, 2)]];
	[controller remove: nil];
	UKTrue([[self contentArray] isEmpty]);
}

- (NSSortDescriptor *) descriptorWithKey: (NSString *)aKey
{
	return AUTORELEASE([[NSSortDescriptor alloc] initWithKey: aKey ascending: YES]);
}

- (void) testBasicSort
{
	id item1 = [itemFactory itemWithRepresentedObject: @"a"];
	id item2 = [itemFactory itemWithRepresentedObject: @"b"];
	id item3 = [itemFactory itemWithRepresentedObject: @"c"];
	NSArray *initialItems = A(item3, item1, item2);

	[content addItems: initialItems];
	[controller setSortDescriptors: A([self descriptorWithKey: kETRepresentedObjectProperty])];

	UKObjectsEqual(A(item1, item2, item3), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKTrue([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);
	
	[controller setSortDescriptors: 
		A([[[controller sortDescriptors] firstObject] reversedSortDescriptor])];

	UKObjectsEqual(A(item3, item2, item1), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKTrue([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);

	[controller setSortDescriptors: [NSArray array]];

	UKObjectsEqual(initialItems, [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);
}

- (void) testRecursiveSort
{
	id item1 = [itemFactory itemGroupWithRepresentedObject: @"a"];
	id item2 = [itemFactory itemWithRepresentedObject: @"b"];
	id item3 = [itemFactory itemGroupWithRepresentedObject: @"c"];
	id item11 = [itemFactory itemWithRepresentedObject: @"A"];
	id item12 = [itemFactory itemGroupWithRepresentedObject: @"B"];
	id item13 = [itemFactory itemWithRepresentedObject: @"C"];
	id item121 = [itemFactory itemWithRepresentedObject: [NSNumber numberWithInt: 8]];
	id item122 = [itemFactory itemGroupWithRepresentedObject: [NSNumber numberWithInt: 9]];

	NSArray *initialItems = A(item3, item1, item2);
	NSArray *initialCapitalItems = A(item12, item11, item13);
	NSArray *initialNumberItems = A(item121, item122);

	[item12 addItems: initialNumberItems];
	[item3 addItems: initialCapitalItems];
	[content addItems: initialItems];
	[controller setSortDescriptors: A([self descriptorWithKey: kETRepresentedObjectProperty])];

	UKObjectsEqual(A(item1, item2, item3), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKTrue([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);
	UKObjectsEqual(A(item11, item12, item13), [item3 arrangedItems]);
	UKObjectsEqual(initialCapitalItems, [item3 items]);
	UKTrue([item3 isSorted]);
	UKFalse([item3 isFiltered]);
	UKFalse([item3 hasNewContent]);
	UKObjectsEqual(A(item121, item122), [item12 arrangedItems]);
	UKObjectsEqual(initialNumberItems, [item12 items]);
	UKTrue([item12 isSorted]);
	UKFalse([item12 isFiltered]);
	UKFalse([item12 hasNewContent]);
	
	[controller setSortDescriptors: 
		A([[[controller sortDescriptors] firstObject] reversedSortDescriptor])];

	UKObjectsEqual(A(item3, item2, item1), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKTrue([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);
	UKObjectsEqual(A(item13, item12, item11), [item3 arrangedItems]);
	UKObjectsEqual(initialCapitalItems, [item3 items]);
	UKTrue([item3 isSorted]);
	UKFalse([item3 isFiltered]);
	UKFalse([item3 hasNewContent]);
	UKObjectsEqual(A(item122, item121), [item12 arrangedItems]);
	UKObjectsEqual(initialNumberItems, [item12 items]);
	UKTrue([item12 isSorted]);
	UKFalse([item12 isFiltered]);
	UKFalse([item12 hasNewContent]);

	[controller setSortDescriptors: [NSArray array]];

	UKObjectsEqual(initialItems, [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);
	UKObjectsEqual(initialCapitalItems, [item3 arrangedItems]);
	UKObjectsEqual(initialCapitalItems, [item3 items]);
	UKFalse([item3 isSorted]);
	UKFalse([item3 isFiltered]);
	UKFalse([item3 hasNewContent]);
	UKObjectsEqual(initialNumberItems, [item12 arrangedItems]);
	UKObjectsEqual(initialNumberItems, [item12 items]);
	UKFalse([item12 isSorted]);
	UKFalse([item12 isFiltered]);
	UKFalse([item12 hasNewContent]);
}

- (void) testBasicFilter
{
	id item1 = [itemFactory itemWithRepresentedObject: @"a"];
	id item2 = [itemFactory itemWithRepresentedObject: @"b"];
	id item3 = [itemFactory itemWithRepresentedObject: @"c"];
	NSArray *initialItems = A(item3, item1, item2);

	[content addItems: initialItems];
	[controller setFilterPredicate: 
		[NSPredicate predicateWithFormat: @"representedObject contains %@", @"c"]];

	UKObjectsEqual(A(item3), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKTrue([content isFiltered]);
	UKFalse([content hasNewContent]);
	
	[controller setFilterPredicate: 
		[NSPredicate predicateWithFormat: @"representedObject contains %@", @"b"]];

	UKObjectsEqual(A(item2), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKTrue([content isFiltered]);
	UKFalse([content hasNewContent]);

	[controller setFilterPredicate: nil];

	UKObjectsEqual(initialItems, [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);
}

- (void) testRecursiveFilter
{
	id item1 = [itemFactory itemGroupWithRepresentedObject: @"a"];
	id item2 = [itemFactory itemWithRepresentedObject: @"b"];
	id item3 = [itemFactory itemGroupWithRepresentedObject: @"c"];
	id item11 = [itemFactory itemWithRepresentedObject: @"A"];
	id item12 = [itemFactory itemGroupWithRepresentedObject: @"B"];
	id item13 = [itemFactory itemWithRepresentedObject: @"C"];
	id item121 = [itemFactory itemWithRepresentedObject: [NSNumber numberWithInt: 8]];
	id item122 = [itemFactory itemGroupWithRepresentedObject: [NSNumber numberWithInt: 9]];

	NSArray *initialItems = A(item3, item1, item2);
	NSArray *initialCapitalItems = A(item12, item11, item13);
	NSArray *initialNumberItems = A(item121, item122);

	[item12 addItems: initialNumberItems];
	[item3 addItems: initialCapitalItems];
	[content addItems: initialItems];
	/* We cannot use 'contains[c]' operator here since we are going to evaluate 
	   numbers too and not just strings.
	   Note: what we do could be rewritten with 'IN'. */
	[controller setFilterPredicate: [NSPredicate predicateWithFormat: 
		@"(representedObject == %@) OR (representedObject == %@)", @"b", @"B"]];

	UKObjectsEqual(A(item3, item2), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKTrue([content isFiltered]);
	UKFalse([content hasNewContent]);
	UKObjectsEqual(A(item12), [item3 arrangedItems]);
	UKObjectsEqual(initialCapitalItems, [item3 items]);
	UKFalse([item3 isSorted]);
	UKTrue([item3 isFiltered]);
	UKFalse([item3 hasNewContent]);
	UKObjectsEqual([NSArray array], [item12 arrangedItems]);
	UKObjectsEqual(initialNumberItems, [item12 items]);
	UKFalse([item12 isSorted]);
	UKTrue([item12 isFiltered]);
	UKFalse([item12 hasNewContent]);

	[controller setFilterPredicate: [NSPredicate predicateWithFormat: 
		@"representedObject IN %@", S(@"C", @"A", @"b", [NSNumber numberWithInt: 8])]];

	UKObjectsEqual(A(item3, item2), [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKTrue([content isFiltered]);
	UKFalse([content hasNewContent]);
	UKObjectsEqual(initialCapitalItems, [item3 arrangedItems]);
	UKObjectsEqual(initialCapitalItems, [item3 items]);
	UKFalse([item3 isSorted]);
	UKTrue([item3 isFiltered]);
	UKFalse([item3 hasNewContent]);
	UKObjectsEqual(A(item121), [item12 arrangedItems]);
	UKObjectsEqual(initialNumberItems, [item12 items]);
	UKFalse([item12 isSorted]);
	UKTrue([item12 isFiltered]);
	UKFalse([item12 hasNewContent]);

	[controller setFilterPredicate: nil];

	UKObjectsEqual(initialItems, [content arrangedItems]);
	UKObjectsEqual(initialItems, [content items]);
	UKFalse([content isSorted]);
	UKFalse([content isFiltered]);
	UKFalse([content hasNewContent]);
	UKObjectsEqual(initialCapitalItems, [item3 arrangedItems]);
	UKObjectsEqual(initialCapitalItems, [item3 items]);
	UKFalse([item3 isSorted]);
	UKFalse([item3 isFiltered]);
	UKFalse([item3 hasNewContent]);
	UKObjectsEqual(initialNumberItems, [item12 arrangedItems]);
	UKObjectsEqual(initialNumberItems, [item12 items]);
	UKFalse([item12 isSorted]);
	UKFalse([item12 isFiltered]);
	UKFalse([item12 hasNewContent]);
}

@end
