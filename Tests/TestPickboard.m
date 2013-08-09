/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import "ETPickboard.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"

@interface ETPickboard (TestPickboard)
@end

@implementation ETPickboard (TestPickboard)

- (id) pushObject: (id)anObject
{
	return [self pushObject: anObject metadata: nil];
}

- (id) appendObject: (id)anObject
{
	return [self appendObject: anObject metadata: nil];
}

@end

@interface TestPickboard : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETPickboard *pickboard;
}

@end

@implementation TestPickboard

- (id) init
{
	SUPERINIT;
	itemFactory = [ETLayoutItemFactory factory];
	pickboard = [[ETPickboard alloc] initWithObjectGraphContext:
		[ETUIObject defaultTransientObjectGraphContext]];
	return self;
}

- (void) dealloc
{
	DESTROY(pickboard);
	[super dealloc];
}

- (void) testPushObject
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [itemFactory item];
	id pickRef = nil;
	
	pickRef = [pickboard pushObject: string];
	UKNotNil(pickRef);
	UKIntsEqual(1, [pickboard numberOfItems]);
	UKObjectsSame(string, [[pickboard itemAtIndex: 0] representedObject]);
	
	pickRef = [pickboard pushObject: array];
	UKNotNil(pickRef);
	UKIntsEqual(2, [pickboard numberOfItems]);
	UKObjectsSame(array, [[pickboard itemAtIndex: 0] representedObject]);
	
	pickRef = [pickboard pushObject: item];
	UKNotNil(pickRef);
	UKIntsEqual(3, [pickboard numberOfItems]);
	UKObjectsNotSame(item, [pickboard itemAtIndex: 0]);
	UKObjectsSame(item, [[pickboard itemAtIndex: 0] representedObject]);
	
	UKIntsEqual(3, [[pickboard allObjects] count]);
}

- (void) testPopObject
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [itemFactory item];
	id pickRef = nil;
	id object = nil;
	
	pickRef = [pickboard pushObject: string];
	pickRef = [pickboard pushObject: array];
	pickRef = [pickboard appendObject: item];
	
	object = [pickboard popObject];
	UKNotNil(object);
	UKObjectsSame(array, object);
	UKIntsEqual(2, [pickboard numberOfItems]);

	object = [pickboard popObject];
	UKNotNil(object);
	UKObjectsSame(string, object);
	UKIntsEqual(1, [pickboard numberOfItems]);
	
	object = [pickboard popObject];
	UKNotNil(pickRef);
	UKObjectsSame(item, object);
	UKIntsEqual(0, [pickboard numberOfItems]);
	
	object = [pickboard popObject];
	UKNil(object);
	
	UKIntsEqual(0, [[pickboard allObjects] count]);
}

- (void) testAddObject
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [itemFactory item];
	id pickRef = nil;
	
	pickRef = [pickboard appendObject: string];
	UKNotNil(pickRef);
	UKIntsEqual(1, [pickboard numberOfItems]);
	UKObjectsSame(string, [[pickboard itemAtIndex: 0] representedObject]);
	
	pickRef = [pickboard appendObject: array];
	UKNotNil(pickRef);
	UKIntsEqual(2, [pickboard numberOfItems]);
	UKObjectsSame(array, [[pickboard itemAtIndex: 1] representedObject]);
	
	pickRef = [pickboard appendObject: item];
	UKNotNil(pickRef);
	UKIntsEqual(3, [pickboard numberOfItems]);
	UKObjectsNotSame(item, [pickboard itemAtIndex: 2]);
	UKObjectsSame(item, [[pickboard itemAtIndex: 2] representedObject]);
	
	UKIntsEqual(3, [[pickboard allObjects] count]);
}

- (void) testRemoveObjectForPickboardRef
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [itemFactory item];
	id pickRef1 = nil;
	id pickRef2 = nil;
	id pickRef3 = nil;
	
	pickRef1 = [pickboard pushObject: string];
	pickRef2 = [pickboard pushObject: array];
	pickRef3 = [pickboard appendObject: item];
	
	[pickboard removeObjectForPickboardRef: pickRef3];
	UKFalse([[pickboard allObjects] containsObject: item]);
	UKIntsEqual(2, [[pickboard allObjects] count]);
	UKIntsEqual(2, [pickboard numberOfItems]);
	
	[pickboard removeObjectForPickboardRef: pickRef2];
	UKFalse([[pickboard allObjects] containsObject: array]);
	UKIntsEqual(1, [[pickboard allObjects] count]);
	UKIntsEqual(1, [pickboard numberOfItems]);
	
	[pickboard removeObjectForPickboardRef: pickRef1];
	UKFalse([[pickboard allObjects] containsObject: string]);
	UKIntsEqual(0, [[pickboard allObjects] count]);
	UKIntsEqual(0, [pickboard numberOfItems]);
}

@end
