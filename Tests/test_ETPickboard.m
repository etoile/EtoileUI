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

@interface ETPickboard (UnitKitTests) <UKTest>
@end


@implementation ETPickboard (UnitKitTests)

- (void) testPushObject
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [[ETLayoutItemFactory factory] item];
	id pickRef = nil;
	
	pickRef = [self pushObject: string];
	UKNotNil(pickRef);
	UKIntsEqual(1, [self numberOfItems]);
	UKObjectsSame(string, [[self itemAtIndex: 0] representedObject]);
	
	pickRef = [self pushObject: array];
	UKNotNil(pickRef);
	UKIntsEqual(2, [self numberOfItems]);
	UKObjectsSame(array, [[self itemAtIndex: 0] representedObject]);
	
	pickRef = [self pushObject: item];
	UKNotNil(pickRef);
	UKIntsEqual(3, [self numberOfItems]);
	UKObjectsNotSame(item, [self itemAtIndex: 0]);
	UKObjectsSame(item, [[self itemAtIndex: 0] representedObject]);
	
	UKIntsEqual(3, [[self allObjects] count]);
}

- (void) testPopObject
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [[ETLayoutItemFactory factory] item];
	id pickRef = nil;
	id object = nil;
	
	pickRef = [self pushObject: string];
	pickRef = [self pushObject: array];
	pickRef = [self appendObject: item];
	
	object = [self popObject];
	UKNotNil(object);
	UKObjectsSame(array, object);
	UKIntsEqual(2, [self numberOfItems]);

	object = [self popObject];
	UKNotNil(object);
	UKObjectsSame(string, object);
	UKIntsEqual(1, [self numberOfItems]);
	
	object = [self popObject];
	UKNotNil(pickRef);
	UKObjectsSame(item, object);
	UKIntsEqual(0, [self numberOfItems]);
	
	object = [self popObject];
	UKNil(object);
	
	UKIntsEqual(0, [[self allObjects] count]);
}

- (void) testAddObject
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [[ETLayoutItemFactory factory] item];
	id pickRef = nil;
	
	pickRef = [self appendObject: string];
	UKNotNil(pickRef);
	UKIntsEqual(1, [self numberOfItems]);
	UKObjectsSame(string, [[self itemAtIndex: 0] representedObject]);
	
	pickRef = [self appendObject: array];
	UKNotNil(pickRef);
	UKIntsEqual(2, [self numberOfItems]);
	UKObjectsSame(array, [[self itemAtIndex: 1] representedObject]);
	
	pickRef = [self appendObject: item];
	UKNotNil(pickRef);
	UKIntsEqual(3, [self numberOfItems]);
	UKObjectsNotSame(item, [self itemAtIndex: 2]);
	UKObjectsSame(item, [[self itemAtIndex: 2] representedObject]);
	
	UKIntsEqual(3, [[self allObjects] count]);
}

- (void) testRemoveObjectForPickboardRef
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [[ETLayoutItemFactory factory] item];
	id pickRef1 = nil;
	id pickRef2 = nil;
	id pickRef3 = nil;
	
	pickRef1 = [self pushObject: string];
	pickRef2 = [self pushObject: array];
	pickRef3 = [self appendObject: item];
	
	[self removeObjectForPickboardRef: pickRef3];
	UKFalse([[self allObjects] containsObject: item]);
	UKIntsEqual(2, [[self allObjects] count]);
	UKIntsEqual(2, [self numberOfItems]);
	
	[self removeObjectForPickboardRef: pickRef2];
	UKFalse([[self allObjects] containsObject: array]);
	UKIntsEqual(1, [[self allObjects] count]);
	UKIntsEqual(1, [self numberOfItems]);
	
	[self removeObjectForPickboardRef: pickRef1];
	UKFalse([[self allObjects] containsObject: string]);
	UKIntsEqual(0, [[self allObjects] count]);
	UKIntsEqual(0, [self numberOfItems]);
}

@end
