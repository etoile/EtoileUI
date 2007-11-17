/*
	ETPickboard.m
	
	Pick & Drop class
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  October 2007
 
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


#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/ETCollection.h>
#ifndef GNUSTEP
#import <EtoileUI/GNUstep.h>
#endif

#define PALETTE_FRAME NSMakeRect(200, 200, 400, 200) 


@implementation ETPickboard

/* Factory methods */

static ETPickboard *systemPickboard = nil;

/** Returns the system-wide pickboard which is used by default accross Etoile
    environment. */
+ (ETPickboard *) systemPickboard
{
	if (systemPickboard == nil)
		systemPickboard = [[ETPickboard alloc] init];

	return systemPickboard; 
}

/** Returns a pickboard restricted to the active project. This pickboard isn't
    accessible in another project. */
+ (ETPickboard *) projectPickboard
{
	return nil;
}

/** Returns the local pickboard which only exists in the process where it had 
	been initially requested. This pickboard isn't available externally to other
	processes. 
	Local pickboards are non-persistent, they expire when the lifetime of their
	owner process ends. */
+ (ETPickboard *) localPickboard
{
	return nil;
}

/* Initialization */

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		ETContainer *pickView = [[ETContainer alloc] initWithFrame: PALETTE_FRAME layoutItem: self];
		
		// FIXME: Update this code when a layout item representation exists for NSWindow instances.
		_pickPalette = [[NSWindow alloc] initWithContentRect: PALETTE_FRAME
		                                           styleMask: NSTitledWindowMask 
												     backing: NSBackingStoreBuffered
													   defer: YES];
		[pickView setLayout: [ETFlowLayout layout]];
		[_pickPalette setContentView: pickView];
		RELEASE(pickView);
	}
	
	return self;
}

- (void) dealloc
{
	DESTROY(_pickedObjects);
	DESTROY(_pickPalette);
	
	[super dealloc];
}

- (void) checkPickboardValidity
{
	NSAssert3([_pickedObjects count] == [self numberOfItems], @"Picked "
		@"objects count %d and number of items %d for pickboard %@ must be "
		@"equal", [_pickedObjects count], [self numberOfItems], self);
}

/* Pickboard Interaction */

- (id) popObject
{
	[self checkPickboardValidity];

	ETLayoutItem *topItem = nil;
	id topObject = nil;
	
	if ([self numberOfItems] > 0)
		topItem = [self itemAtIndex: 0];
		
	if ([[_pickedObjects allValues] containsObject: topItem])
	{
		RETAIN(topItem);
		[self removeItemAtIndex: 0];

		topObject = AUTORELEASE(topItem);
	}
	else
	{
		id pickedObject = [topItem representedObject];
		
		NSAssert3([[_pickedObjects allValues] containsObject: pickedObject], 
			@"Pickboard %@ is in an invalid state, it should object %@ "
			@"referenced by item %@", self, pickedObject, topItem);
		
		RETAIN(pickedObject);
		[self removeItemAtIndex: 0];
			
		topObject = AUTORELEASE(pickedObject);
	}
	
	return topObject;
}

- (ETPickboardRef *) pushObject: (id)object
{
	[self checkPickboardValidity];
		
	if ([_pickedObjects count] == 0)
		return [self addObject: object];

	NSString *pickRef = [NSString stringWithFormat: @"%d", ++_pickboardRef];
	
	[_pickedObjects setObject: object forKey: pickRef];
	if ([object isKindOfClass: [ETLayoutItem class]])
	{
		[self insertItem: object atIndex: 0];
	}
	else
	{
		ETLayoutItem *item = [[ETLayoutItem alloc] initWithRepresentedObject: object];
		
		AUTORELEASE(item);
		[self insertItem: item atIndex: 0];	
	}
	
	return pickRef;
}

- (ETPickboardRef *) addObject: (id)object
{
	[self checkPickboardValidity];

	NSString *pickRef = [NSString stringWithFormat: @"%d", ++_pickboardRef];
	
	[_pickedObjects setObject: object forKey: pickRef];
	if ([object isKindOfClass: [ETLayoutItem class]])
	{
		[self addItem: object];
	}
	else
	{
		ETLayoutItem *item = [[ETLayoutItem alloc] initWithRepresentedObject: object];
		
		AUTORELEASE(item);
		[self addItem: item];	
	}
	
	return pickRef;
}

- (void) removeObjectForPickboardRef: (ETPickboardRef *)ref
{
	id object = [_pickedObjects objectForKey: ref];
	
	if ([[self items] containsObject: object])
	{
		[self removeItem: object];
	}
	else
	{
		ETLayoutItem *item = [[self items] 
			firstObjectMatchingValue: object forKey: @"representedObject"];
		
		[self removeItem: item];
	}
}

- (id) objectForPickboardRef: (ETPickboardRef *)ref
{
	return [_pickedObjects objectForKey: ref];
}

/* Pick & Drop Palette */

- (NSWindow *) pickPalette
{
	return _pickPalette;
}

- (void) showPickPalette
{
	[[self pickPalette] makeKeyAndOrderFront: self];
}

@end
