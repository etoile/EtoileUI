/*
	test_ETObjectChain.m

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
#import <EtoileUI/ETObjectChain.h>
#import <EtoileUI/ETCompatibility.h>
#import <UnitKit/UnitKit.h>

@interface ETObjectChain (UnitKitTests) <UKTest>
@end


@implementation ETObjectChain (UnitKitTests)

- (void) testInitWithObjects
{
	id node1 = AUTORELEASE([[ETObjectChain alloc] init]);
	id node2 = AUTORELEASE([[ETObjectChain alloc] init]);
	id nextObject = nil;
	
	self = [self initWithObjects: [NSArray arrayWithObjects: node1, node2, nil]];
	
	nextObject = [self nextObject];
	UKObjectsSame(node1, nextObject);
	nextObject = [nextObject nextObject];
	UKObjectsSame(node2, nextObject);
	UKNil([nextObject nextObject]);	
}

- (void) testNextObject
{
	UKNil([self nextObject]);

	id node1 = AUTORELEASE([[ETObjectChain alloc] init]);
	id node2 = AUTORELEASE([[ETObjectChain alloc] init]);
	id node3 = AUTORELEASE([[ETObjectChain alloc] init]);
	
	[node1 setNextObject: node2];
	[node2 setNextObject: node3];
	
	[self setNextObject: node2];
	UKObjectsSame(node2, [self nextObject]);
	UKObjectsSame(node3, [[self nextObject] nextObject]);
	UKNil([[[self nextObject] nextObject] nextObject]);
	
	[self setNextObject: nil];
	UKNil([self nextObject]);
	
	UKObjectsSame(node2, [node1 nextObject]);
	UKObjectsSame(node3, [node2 nextObject]);
}

- (void) testLastObject
{
	NSLog(@"myself %@", self);
	UKObjectsSame(self, [self lastObject]);
	
	id node1 = AUTORELEASE([[ETObjectChain alloc] init]);
	id node2 = AUTORELEASE([[ETObjectChain alloc] init]);
	
	[self setNextObject: node1];
	UKObjectsSame(node1, [self lastObject]);
	UKObjectsSame([self nextObject], [self lastObject]);
	
	[node1 setNextObject: node2];
	UKObjectsSame(node2, [self lastObject]);
	UKObjectsNotSame([self nextObject], [self lastObject]);

	UKObjectsSame([node1 lastObject], [node2 lastObject]);
	UKObjectsSame([node1 nextObject], [node2 lastObject]);
}

- (void) testContentArray
{
	id node3 = AUTORELEASE([[ETObjectChain alloc] init]);
	id node2 = AUTORELEASE([[ETObjectChain alloc] initWithObject: node3]);
	id node1 = AUTORELEASE([[ETObjectChain alloc] init]);
	
	[node1 setNextObject: node2];
	[self setNextObject: node2];
	
	id nodeArray = [self contentArray];
	
	UKIntsEqual(3, [nodeArray count]);
	UKObjectsSame(self, [nodeArray objectAtIndex: 0]);
	UKObjectsSame(node2, [nodeArray objectAtIndex: 1]);
	UKObjectsSame(node3, [nodeArray objectAtIndex: 2]);
}

@end
