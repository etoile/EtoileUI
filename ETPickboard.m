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
#import <EtoileUI/ETOutlineLayout.h>
#import <EtoileUI/ETCollection.h>
#import <EtoileUI/ETCompatibility.h>

#define PALETTE_FRAME NSMakeRect(200, 200, 400, 200)
#define PICKBOARD_LAYOUT ETOutlineLayout


@implementation ETPickboard

/* Factory methods */

// TODO: Must be provided by UIServer (CoreObject backend)
static ETPickboard *systemPickboard = nil;

/** Returns the system-wide pickboard which is used by default accross Etoile
    environment. Also known as Shelf overlay. */
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
	// FIXME: Implement
	return nil;
}

static ETPickboard *localPickboard = nil;

/** Returns the local pickboard which only exists in the process where it had 
	been initially requested. This pickboard isn't available externally to other
	processes. 
	Local pickboards are non-persistent, they expire when the lifetime of their
	owner process ends. */
+ (ETPickboard *) localPickboard
{
	if (localPickboard == nil)
		localPickboard = [[ETPickboard alloc] init];

	return localPickboard; 
}

static ETPickboard *activePickboard = nil;

/** Returns the pickboard which should receive or provide objects if you 
	invoke a pick and drop operation (copy, paste, cut, drag, drop etc.)
	in the responder chain.
	If you manipulate the pickboard directly, most of time you shouldn't bother 
	of deciding whether to use system, project, local or some other pickboards 
	but simply use the active pickboard. For example, your code will be:
	[[ETPickboard activePickboard] pushObject: myObject] */
+ (ETPickboard *) activePickboard
{
	return activePickboard;
}

/* Sets the pickboard that should receive or provide objects when a
   a pick and drop operation in the responder chain. */
+ (void) setActivePickboard: (ETPickboard *)pboard
{
	ASSIGN(activePickboard, pboard);
}

/* Initialization */

/** <init \> Initializes and returns a new pickboard. */
- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		_pickedObjects = [[NSMutableDictionary alloc] init];
		_pickboardRef = 0;
		
		/* UI set up */
		ETContainer *pickView = [[ETContainer alloc] initWithFrame: PALETTE_FRAME layoutItem: self];
		
		// FIXME: Update this code when a layout item representation exists for NSWindow instances.
		_pickPalette = [[NSWindow alloc] initWithContentRect: PALETTE_FRAME
		                                           styleMask: NSTitledWindowMask 
												     backing: NSBackingStoreBuffered
													   defer: YES];
		[pickView setLayout: [PICKBOARD_LAYOUT layout]];
		[_pickPalette setContentView: pickView];
		[_pickPalette setTitle: _(@"Pickboard")];
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

/** Removes the first element in the pickboard and returns it. */
- (id) popObject
{
	[self checkPickboardValidity];
	
	if ([self numberOfItems] == 0)
		return nil;

	// NOTE: pickedObject is represented by topItem in the pickboard. Take note 
	// that pickedObject can be a layout item.
	ETLayoutItem *topItem = [self itemAtIndex: 0];
	id pickedObject = [topItem representedObject];
	NSArray *pickRefs = nil;
	
	NSAssert3([[_pickedObjects allValues] containsObject: pickedObject], 
		@"Pickboard %@ is in an invalid state, it should contain object %@ "
		@"referenced by item %@", self, pickedObject, topItem);
		
	pickRefs = [_pickedObjects allKeysForObject: pickedObject];
	
	NSAssert3([pickRefs count] == 1, @"Pickboard %@ is in an invalid state, it "
		"should have only one pickboard reference %@ for object %@ ", self, 
		pickedObject, pickRefs);
	
	RETAIN(pickedObject);
	[self removeItemAtIndex: 0];
	[_pickedObjects removeObjectForKey: [pickRefs objectAtIndex: 0]];
	
	return AUTORELEASE(pickedObject);
}

/** Inserts an object as the first element in the pickboard and returns a 
	pickboard transaction reference that uniquely identifies the pick and drop
	operation underway. You can later retrieve the pushed object by keeping 
	around the pickboard reference. */
- (ETPickboardRef *) pushObject: (id)object
{
	[self checkPickboardValidity];
	
	/* Use -addObject: instead of -pushObject: if necessary */
	if ([_pickedObjects count] == 0)
		return [self addObject: object];
		
	/* Push Object */
	NSString *pickRef = [NSString stringWithFormat: @"%d", ++_pickboardRef];
	
	[_pickedObjects setObject: object forKey: pickRef];

	ETLayoutItem *item = [[ETLayoutItem alloc] initWithRepresentedObject: object];

	[self insertItem: item atIndex: 0];
	RELEASE(item);
	
	return pickRef;
}

/** Adds an object as the last element in the pickboard and returns a 
	pickboard transaction reference that uniquely identifies the pick and drop
	operation underway. You can later retrieve the added object by keeping 
	around the pickboard reference. */
- (ETPickboardRef *) addObject: (id)object
{
	[self checkPickboardValidity];

	NSString *pickRef = [NSString stringWithFormat: @"%d", ++_pickboardRef];

	[_pickedObjects setObject: object forKey: pickRef];

	ETLayoutItem *item = [[ETLayoutItem alloc] initWithRepresentedObject: object];
	
	[self addItem: item];
	RELEASE(item);
	
	return pickRef;
}

/** Removes a previously picked object identified by 'ref' from the pickboard. 
	Every time you put an object on a pickboard, the target pickboard returns a 
	reference making later operations on this object more convenient. 
	Throws an invalid argument exception when no object is identified by ref in
	the pickboard. */
- (void) removeObjectForPickboardRef: (ETPickboardRef *)ref
{
	id object = [_pickedObjects objectForKey: ref];
	
	if (object == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"Pickboard %@ "
			"received an invalid pickboard ref %@ to remove an object.", self, ref];
	}
	
	ETLayoutItem *item = [[self items] 
			firstObjectMatchingValue: object forKey: @"representedObject"];
			
	[self removeItem: item];
	[_pickedObjects removeObjectForKey: ref];
}

/** Returns a previously picked object bound to the pickboard transaction
	reference 'ref'. Every time you put an object on a pickboard, the 
	target pickboard returns a reference making later retrieval more 
	convenient. */
- (id) objectForPickboardRef: (ETPickboardRef *)ref
{
	return [_pickedObjects objectForKey: ref];
}

/** Returns all picked objects still on the pickboard. */
- (NSArray *) allObjects
{
	return [_pickedObjects allValues];
}

/* Pick & Drop Palette */

/** Returns the window embedding the UI representation of the receiver. */
- (NSWindow *) pickPalette
{
	return _pickPalette;
}

/** Brings the pickboard window to the front and makes it the first responder. */
- (void) showPickPalette
{
	[[self pickPalette] makeKeyAndOrderFront: self];
}

@end

/* Picked Object Set */

@implementation ETPickCollection

+ (id) pickCollectionWithObjects: (id <ETCollection>)objects
{
	return AUTORELEASE([(ETPickCollection *)[[self class] alloc] initWithObjects: objects]);
}

/** <init \> Initializes and returns a picked object set (known as a pick 
	collection) with the objects of the collection passed in parameter. */
- (id) initWithObjects: (id <ETCollection>)objects
{
	self = [super init];
	
	if (self != nil)
	{
		ASSIGN(_pickedObjects, [NSArray arrayWithArray: (id)objects]);
	}
	
	return self;
}

- (void) dealloc
{
	DESTROY(_pickedObjects);
	
	[super dealloc];
}

/* ETCollection protocol */

- (id) content
{
	return _pickedObjects;
}

- (NSArray *) contentArray
{
	return [_pickedObjects contentArray];
}

@end
