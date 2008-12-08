/*
	test_ETPickboard.m

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
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

@interface ETPickboard (UnitKitTests) <UKTest>
@end


@implementation ETPickboard (UnitKitTests)

- (void) testPushObject
{
	id string = [NSString string];
	id array = [NSArray array];
	id item = [ETLayoutItem item];
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
	id item = [ETLayoutItem item];
	id pickRef = nil;
	id object = nil;
	
	pickRef = [self pushObject: string];
	pickRef = [self pushObject: array];
	pickRef = [self addObject: item];
	
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
	id item = [ETLayoutItem item];
	id pickRef = nil;
	
	pickRef = [self addObject: string];
	UKNotNil(pickRef);
	UKIntsEqual(1, [self numberOfItems]);
	UKObjectsSame(string, [[self itemAtIndex: 0] representedObject]);
	
	pickRef = [self addObject: array];
	UKNotNil(pickRef);
	UKIntsEqual(2, [self numberOfItems]);
	UKObjectsSame(array, [[self itemAtIndex: 1] representedObject]);
	
	pickRef = [self addObject: item];
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
	id item = [ETLayoutItem item];
	id pickRef1 = nil;
	id pickRef2 = nil;
	id pickRef3 = nil;
	
	pickRef1 = [self pushObject: string];
	pickRef2 = [self pushObject: array];
	pickRef3 = [self addObject: item];
	
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
