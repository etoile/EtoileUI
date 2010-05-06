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
	return AUTORELEASE([self newObject]);
}
- (id) makeGroup
{
	return AUTORELEASE([self newGroup]);
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
	UKObjectsNotSame(newObject2, newObject);
	// newObject2 not created by sending -copy but -alloc and -init, thereby
	// returns two different dates in time.
	UKObjectsNotEqual(newObject2, newObject); 

	UKNil([controller templateItem]);

	/* Test item template */

	id view = AUTORELEASE([DummyView new]);
	id templateItem = [[ETLayoutItemFactory factory] itemWithView: view];
	[controller setTemplateItem: templateItem];
	newObject = [controller makeObject];
	newObject2 = [controller makeObject];

	UKObjectKindOf(newObject, ETLayoutItem);
	UKObjectsNotEqual(templateItem, newObject);
	UKObjectKindOf([newObject view], DummyView);
	UKObjectsNotEqual(view, [newObject view]);
	UKObjectsNotEqual(newObject2, newObject);
	UKObjectsNotEqual([newObject2 view], [newObject view]);

	/* Test with object class */
	UKObjectKindOf([newObject representedObject], NSDate);
	// newObject2 not created by sending -copy but -alloc and -init
	UKObjectsNotSame([newObject2 representedObject], [newObject representedObject]);
	UKObjectsNotEqual([newObject2 representedObject], [newObject representedObject]);

	/* Test without object class */
	[controller setObjectClass: nil];
	newObject = [controller makeObject];
	newObject2 = [controller makeObject];
	UKNil([newObject representedObject]);
	UKNil([newObject2 representedObject]);

	/* Test with object prototype (-objectClass must be nil) */
	[[controller templateItem] setRepresentedObject: [NSIndexSet indexSetWithIndex: 5]];
	// FIXME: represented object is nil, we need to ensure -deepCopy called
	// by -newItem behaves correctly.
	//UKObjectKindOf([newObject representedObject], NSIndexSet);
	//UKObjectsNotSame([newObject2 representedObject], [newObject representedObject]);
	// newObject2 created by sending -copy
	//UKObjectsEqual([newObject2 representedObject], [newObject representedObject]);
}

- (void) testNewGroup
{
	UKNil([controller makeGroup]);

	[controller setGroupClass: [NSMutableArray class]];

	id newGroup = [controller makeGroup];
	id newGroup2 = [controller makeGroup];

	UKObjectKindOf(newGroup, NSMutableArray);
	// newGroup2 not created by sending -copy but -alloc and -init
	UKObjectsNotSame(newGroup2, newGroup);

	UKNil([controller templateItem]);

	/* Test item template */

	id view = AUTORELEASE([DummyView new]);
	id templateItem = AUTORELEASE([[ETLayoutItemGroup alloc] initWithView: view value: nil representedObject: nil]);
	[controller setTemplateItemGroup: templateItem];
	newGroup = [controller makeGroup];
	newGroup2 = [controller makeGroup];

	UKObjectKindOf(newGroup, ETLayoutItemGroup);
	UKObjectsNotEqual(templateItem, newGroup);
	UKObjectKindOf([newGroup view], DummyView);
	UKObjectsNotEqual(view, [newGroup view]);
	UKObjectsNotEqual(newGroup2, newGroup);
	UKObjectsNotEqual([newGroup2 view], [newGroup view]);

	/* Test with object class */
	UKObjectKindOf([newGroup representedObject], NSMutableArray);
	// newGroup2 not created by sending -copy but -alloc and -init
	UKObjectsNotSame([newGroup2 representedObject], [newGroup representedObject]);

	/* Test without object class */
	[controller setGroupClass: nil];
	newGroup = [controller makeGroup];
	newGroup2 = [controller makeGroup];
	UKNil([newGroup representedObject]);
	UKNil([newGroup2 representedObject]);

	/* Test with object prototype (-groupClass must be nil) */
	[[controller templateItemGroup] setRepresentedObject: [NSIndexSet indexSetWithIndex: 5]];
	// FIXME: represented object is nil, we need to ensure -deepCopy called
	// by -newItemGroup behaves correctly.
	//UKObjectKindOf([newGroup representedObject], NSIndexSet);
	//UKObjectsNotSame([newGroup2 representedObject], [newGroup representedObject]);
	// newGroup2 created by sending -copy
	//UKObjectsEqual([newGroup2 representedObject], [newGroup representedObject]);
}

- (void) testAdd
{
	[controller setObjectClass: [NSDate class]];
	[controller add: nil];
	id item = [[self contentArray] lastObject];

	UKIntsEqual(1, [[self contentArray] count]);
	UKObjectKindOf(item, ETLayoutItem);
	UKObjectKindOf([item representedObject], NSDate);

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

	UKIntsEqual(1, [[self contentArray] count]);
	UKObjectKindOf(item, ETLayoutItem);
	UKObjectKindOf([item representedObject], NSDate);

	[controller insert: nil];
	id item2 = [[self contentArray] lastObject];

	UKIntsEqual(2, [[self contentArray] count]);
	UKObjectsNotSame(item, item2);

	[[controller content] setSelectionIndex: 1];
	[controller insert: nil];
	id item3 = [[self contentArray] objectAtIndex: 1];

	UKIntsEqual(3, [[self contentArray] count]);
	UKObjectsNotSame(item, item3);
	UKObjectsNotSame(item2, item3);
}

- (void) testRemove
{
	[controller setObjectClass: [NSDate class]];
	[controller add: nil];
	[controller add: nil];
	id item2 = [[self contentArray] lastObject];

	[controller remove: nil];
	UKIntsEqual(2, [[self contentArray] count]);

	[[controller content] setSelectionIndex: 1];
	[controller remove: nil];
	UKIntsEqual(1, [[self contentArray] count]);
	UKFalse([[controller content] containsItem: item2]);

	[controller add: nil];
	item2 = [[self contentArray] objectAtIndex: 1];
	[controller add: nil];

	[[controller content] setSelectionIndex: 1];
	[controller remove: nil];
	UKIntsEqual(2, [[self contentArray] count]);
	UKFalse([[controller content] containsItem: item2]);
	UKObjectsNotSame(item2, [[self contentArray] firstObject]);
	UKObjectsNotSame(item2, [[self contentArray] lastObject]);

	[[controller content] setSelectionIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, 2)]];
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
