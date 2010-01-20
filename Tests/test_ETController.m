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
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"
#import <UnitKit/UnitKit.h>

/* NSView subclass for testing the cloning of item templates */
@interface DummyView : NSView { }
@end
@implementation DummyView
@end

@interface TestController : NSObject <UKTest>
{
	ETController *controller;
}

@end


@implementation TestController

- (id) init
{
	SUPERINIT
	controller = [[ETController alloc] init];
	[[[ETLayoutItemFactory factory] itemGroup] setController: controller];
	RETAIN([controller content]);
	return self;
}

- (void) dealloc
{
	RELEASE([controller content]);
	DESTROY(controller);
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
	UKNil([controller newObject]);

	/* Test model class */

	[controller setObjectClass: [NSDate class]];
	id newObject = [controller newObject];
	id newObject2 = [controller newObject];

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
	newObject = [controller newObject];
	newObject2 = [controller newObject];

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
	newObject = [controller newObject];
	newObject2 = [controller newObject];
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
	UKNil([controller newGroup]);

	[controller setGroupClass: [NSMutableArray class]];

	id newGroup = [controller newGroup];
	id newGroup2 = [controller newGroup];

	UKObjectKindOf(newGroup, NSMutableArray);
	// newGroup2 not created by sending -copy but -alloc and -init
	UKObjectsNotSame(newGroup2, newGroup);

	UKNil([controller templateItem]);

	/* Test item template */

	id view = AUTORELEASE([DummyView new]);
	id templateItem = AUTORELEASE([[ETLayoutItemGroup alloc] initWithView: view]);
	[controller setTemplateItemGroup: templateItem];
	newGroup = [controller newGroup];
	newGroup2 = [controller newGroup];

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
	newGroup = [controller newGroup];
	newGroup2 = [controller newGroup];
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

@end
