/*
	test_ETController.m

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETContainer+Controller.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

/* NSView subclass for testing the cloning of item templates */
@interface DummyView : NSView { }
@end
@implementation DummyView
@end

@interface ETContainer (ControllerTests) <UKTest>
@end


@implementation ETContainer (ControllerTests)

- (void) testInit
{
	UKTrue([[self content] isEmpty]);
}

- (void) testNewObject
{
	UKNil([self newObject]);

	/* Test model class */

	[self setObjectClass: [NSDate class]];
	id newObject = [self newObject];
	id newObject2 = [self newObject];

	UKObjectKindOf(newObject, NSDate);
	UKObjectsNotSame(newObject2, newObject);
	// newObject2 not created by sending -copy but -alloc and -init, thereby
	// returns two different dates in time.
	UKObjectsNotEqual(newObject2, newObject); 

	UKNil([self templateItem]);

	/* Test item template */

	id view = AUTORELEASE([DummyView new]);
	id templateItem = [ETLayoutItem layoutItemWithView: view];
	[self setTemplateItem: templateItem];
	newObject = [self newObject];
	newObject2 = [self newObject];

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
	[self setObjectClass: nil];
	newObject = [self newObject];
	newObject2 = [self newObject];
	UKNil([newObject representedObject]);
	UKNil([newObject2 representedObject]);

	/* Test with object prototype (-objectClass must be nil) */
	[[self templateItem] setRepresentedObject: [NSIndexSet indexSetWithIndex: 5]];
	// FIXME: represented object is nil, we need to ensure -deepCopy called
	// by -newItem behaves correctly.
	//UKObjectKindOf([newObject representedObject], NSIndexSet);
	//UKObjectsNotSame([newObject2 representedObject], [newObject representedObject]);
	// newObject2 created by sending -copy
	//UKObjectsEqual([newObject2 representedObject], [newObject representedObject]);
}

- (void) testNewGroup
{
	UKNil([self newGroup]);

	[self setGroupClass: [NSMutableArray class]];

	id newGroup = [self newGroup];
	id newGroup2 = [self newGroup];

	UKObjectKindOf(newGroup, NSMutableArray);
	// newGroup2 not created by sending -copy but -alloc and -init
	UKObjectsNotSame(newGroup2, newGroup);

	UKNil([self templateItem]);

	/* Test item template */

	id view = AUTORELEASE([DummyView new]);
	id templateItem = [ETLayoutItem layoutItemGroupWithView: view];
	[self setTemplateItemGroup: templateItem];
	newGroup = [self newGroup];
	newGroup2 = [self newGroup];

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
	[self setGroupClass: nil];
	newGroup = [self newGroup];
	newGroup2 = [self newGroup];
	UKNil([newGroup representedObject]);
	UKNil([newGroup2 representedObject]);

	/* Test with object prototype (-groupClass must be nil) */
	[[self templateItemGroup] setRepresentedObject: [NSIndexSet indexSetWithIndex: 5]];
	// FIXME: represented object is nil, we need to ensure -deepCopy called
	// by -newItemGroup behaves correctly.
	//UKObjectKindOf([newGroup representedObject], NSIndexSet);
	//UKObjectsNotSame([newGroup2 representedObject], [newGroup representedObject]);
	// newGroup2 created by sending -copy
	//UKObjectsEqual([newGroup2 representedObject], [newGroup representedObject]);
}

- (void) testAdd
{
	[self setObjectClass: [NSDate class]];
	[self add: nil];
	id item = [[self contentArray] lastObject];

	UKIntsEqual(1, [[self contentArray] count]);
	UKObjectKindOf(item, ETLayoutItem);
	UKObjectKindOf([item representedObject], NSDate);

	[self add: nil];
	id item2 = [[self contentArray] lastObject];

	UKIntsEqual(2, [[self contentArray] count]);
	UKObjectsNotSame(item, item2);
}

- (void) testInsert
{
	[self setObjectClass: [NSDate class]];
	[self insert: nil];
	id item = [[self contentArray] lastObject];

	UKIntsEqual(1, [[self contentArray] count]);
	UKObjectKindOf(item, ETLayoutItem);
	UKObjectKindOf([item representedObject], NSDate);

	[self insert: nil];
	id item2 = [[self contentArray] lastObject];

	UKIntsEqual(2, [[self contentArray] count]);
	UKObjectsNotSame(item, item2);

	[self setSelectionIndex: 1];
	[self insert: nil];
	id item3 = [[self contentArray] objectAtIndex: 1];

	UKIntsEqual(3, [[self contentArray] count]);
	UKObjectsNotSame(item, item3);
	UKObjectsNotSame(item2, item3);
}

- (void) testRemove
{
	[self setObjectClass: [NSDate class]];
	[self add: nil];
	[self add: nil];
	id item1 = [[self contentArray] firstObject];
	id item2 = [[self contentArray] lastObject];

	[self remove: nil];
	UKIntsEqual(2, [[self contentArray] count]);

	[self setSelectionIndex: 1];
	[self remove: nil];
	UKIntsEqual(1, [[self contentArray] count]);
	UKFalse([self containsItem: item2]);

	[self add: nil];
	item2 = [[self contentArray] objectAtIndex: 1];
	[self add: nil];
	id item3 = [[self contentArray] lastObject];

	[self setSelectionIndex: 1];
	[self remove: nil];
	UKIntsEqual(2, [[self contentArray] count]);
	UKFalse([self containsItem: item2]);
	UKObjectsNotSame(item2, [[self contentArray] firstObject]);
	UKObjectsNotSame(item2, [[self contentArray] lastObject]);

	[self setSelectionIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, 2)]];
	[self remove: nil];
	UKTrue([[self contentArray] isEmpty]);
}

@end
