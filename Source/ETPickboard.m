/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  October 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSObject+Trait.h>
#import <EtoileFoundation/Macros.h>
#import "ETPickboard.h"
#import "EtoileUIProperties.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETOutlineLayout.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"

NSString *ETLayoutItemPboardType = @"ETLayoutItemPboardType"; // FIXME: replace by UTI

#define PALETTE_FRAME NSMakeRect([[NSScreen mainScreen] visibleFrame].size.width - 400, 30, 400, 200)
#define PICKBOARD_LAYOUT ETOutlineLayout
#define DEFAULT_PICKBOARD [self localPickboard]


@implementation ETPickboard

// TODO: Must be provided by UIServer (CoreObject backend)
static ETPickboard *systemPickboard = nil;

/** Returns the system-wide pickboard which is used by default accross Etoile 
environment. Also known as Shelf overlay. */
+ (ETPickboard *) systemPickboard
{
	if (systemPickboard == nil)
	{
		systemPickboard = [[ETPickboard alloc]
			initWithObjectGraphContext: [self defaultTransientObjectGraphContext]];
		[systemPickboard setName: _(@"Shelf")];
	}

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
	{
		localPickboard = [[ETPickboard alloc] init];
		[localPickboard setName: _(@"Local Pickboard")];
	}

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
	if (activePickboard == nil)
	{
		[self setActivePickboard: DEFAULT_PICKBOARD];
	}
	return activePickboard;
}

/* Sets the pickboard that should receive or provide objects when a
   a pick and drop operation in the responder chain. */
+ (void) setActivePickboard: (ETPickboard *)pboard
{
	ASSIGN(activePickboard, pboard);
}

/* Initialization */

- (void) setUpUI
{
	[self setLayout: [PICKBOARD_LAYOUT layoutWithObjectGraphContext: [self objectGraphContext]]];
	/* Moves the object browser into to the window layer
	   NOTE: The window item will be released on close. */
	[[self lastDecoratorItem] setDecoratorItem: [[ETWindowItem alloc] init]];
}

/** <init \> Initializes and returns a new pickboard. */
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self setFrame: PALETTE_FRAME];

	_pickedObjects = [[NSMutableDictionary alloc] init];
	_pickboardRef = 0;
	[self setName: _(@"Pickboard")];
	[self setUpUI];
	
	return self;
}

- (void) dealloc
{
	[self stopKVOObservationIfNeeded];
	DESTROY(_pickedObjects);
	[super dealloc];
}

- (void) checkPickboardValidity
{
	NSAssert3([_pickedObjects count] == [self numberOfItems], @"Picked "
		@"objects count %ld and number of items %ld for pickboard %@ must be "
		@"equal", (long)[_pickedObjects count], (long)[self numberOfItems], self);
}

/* Pickboard Interaction */

/** Removes the first element in the pickboard and returns it.

See also -popObjectAsPickCollection:. */
- (id) popObject
{
	return [self popObjectAsPickCollection: NO];
}

/** Removes the first element in the pickboard and returns it.

If boxed is YES, returns a pick collection in all cases. When the element is not 
a pick collection, it is boxed into one.
If boxed is NO, returns nil when the pickboard is empty. */
- (id) popObjectAsPickCollection: (BOOL)boxed
{
	[self checkPickboardValidity];

	if ([self isEmpty])
	{
		return (boxed ? [ETPickCollection pickCollectionWithCollection: [NSArray array]] : nil);
	}

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
	AUTORELEASE(pickedObject);

	if (boxed && [pickedObject isKindOfClass: [ETPickCollection class]] == NO)
	{
		pickedObject = [ETPickCollection pickCollectionWithCollection: A(pickedObject)];
	}
	return pickedObject;
}


/* Returns a layout item that wraps the object passed in parameter based on its 
type. 

If pickObject is an ETPickCollection, returns an ETLayoutItemGroup, otherwise 
returns an ETLayoutItem. */
- (ETLayoutItem *) pickboardItemWithObject: (id)pickObject metadata: (NSDictionary *)metadata
{
	ETLayoutItemFactory *itemFactory =
		[ETLayoutItemFactory factoryWithObjectGraphContext: [self objectGraphContext]];
	ETLayoutItem *item = nil;

	if ([pickObject isKindOfClass: [ETPickCollection class]])
	{
		item = [itemFactory itemGroupWithRepresentedObject: pickObject];

		FOREACHI([pickObject contentArray], pickedElement)
		{
			ETLayoutItemGroup *childItem = [itemFactory itemGroupWithRepresentedObject: pickedElement];
			[(ETLayoutItemGroup *)item addItem: childItem];
		}
	}
	else
	{
		item = [itemFactory itemWithRepresentedObject: pickObject];
	}

	[item setValue: metadata 
	   forProperty: kETPickMetadataProperty];

	return item;
}

- (ETPickboardRef *) insertObject: (id)object metadata: (NSDictionary *)metadata atIndex: (NSUInteger)index 
{
	if (object == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			@"-pushObject argument must never be nil", self];
		
	}
	[self checkPickboardValidity];

	NSString *pickRef = [NSString stringWithFormat: @"%d", ++_pickboardRef];

	[_pickedObjects setObject: object forKey: pickRef];

	[self insertItem: [self pickboardItemWithObject: object metadata: metadata] 
	         atIndex: index];

	return pickRef;
}

/** Inserts an object as the first element in the pickboard and returns a 
pickboard transaction reference that uniquely identifies the pick and drop
operation underway. 

You can later retrieve the pushed object by keeping around the pickboard reference. 

Don't push a nil value, otherwise an invalid argument exception will be thrown. */
- (ETPickboardRef *) pushObject: (id)object metadata: (NSDictionary *)metadata
{
	return [self insertObject: object metadata: metadata atIndex: 0];
}

/** Adds an object as the last element in the pickboard and returns a pickboard
transaction reference that uniquely identifies the pick and dropoperation 
underway. 
 
You can later retrieve the added object by keeping around the pickboard reference. 

Don't add a nil value, otherwise an invalid argument exception will be thrown. */
- (ETPickboardRef *) appendObject: (id)object metadata: (NSDictionary *)metadata
{
	return [self insertObject: object metadata: metadata atIndex: [self count]];
}

/** Removes a previously picked object identified by 'ref' from the pickboard. 

Every time you put an object on a pickboard, the target pickboard returns a 
reference making later operations on this object more convenient. 

Throws an invalid argument exception when ref is nil or no object is identified 
by ref in the pickboard. */
- (void) removeObjectForPickboardRef: (ETPickboardRef *)ref
{
	if (ref == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			@"-removeObjectForPickboardRef: argument must never be nil", self];
		
	}

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

/** Returns the first element on the pickboard.

See also -firstObjectAsPickCollection:. */
- (id) firstObject
{
	return [self firstObjectAsPickCollection: NO];
}

/** Returns the first element on the pickboard.

The first element is the one which will be inserted on the next drop operation 
unless another object gets picked in the meantime.

If boxed is YES, returns a pick collection in all cases. When the element is not 
a pick collection, it is boxed into one.<br />
If boxed is NO, returns nil when the pickboard is empty. */
- (id) firstObjectAsPickCollection: (BOOL)boxed
{
	if ([self isEmpty])
	{
		return (boxed ? [ETPickCollection pickCollectionWithCollection: [NSArray array]] : nil);
	}

	id firstObject = [[self firstItem] representedObject];

	if (boxed == YES && [firstObject isKindOfClass: [ETPickCollection class]] == NO)
	{
		firstObject = [ETPickCollection pickCollectionWithCollection: A(firstObject)];
	}
	return firstObject;
}

/** Returns the pick metadata attached to the first element on the pickboard. */
- (NSDictionary *) firstObjectMetadata
{
	return [[self firstItem] valueForProperty: kETPickMetadataProperty];
}

/* Pick & Drop Palette */

/** Returns the window embedding the UI representation of the receiver. */
- (NSWindow *) pickPalette
{
	return [[self windowItem] window];
}

/** Brings the pickboard window to the front and makes it the first responder. */
- (void) showPickPalette
{
	[[[self windowItem] window] makeKeyAndOrderFront: self];
}

@end


#pragma GCC diagnostic ignored "-Wprotocol"

@implementation ETPickCollection

+ (void) initialize
{
	if (self != [ETPickCollection class])
		return;

	[self applyTraitFromClass: [ETCollectionTrait class]];
}

+ (id) pickCollectionWithCollection: (id <ETCollection>)objects
{
	return AUTORELEASE([(ETPickCollection *)[[self class] alloc] initWithCollection: objects]);
}

/** <init \> Initializes and returns a picked object set (known as a pick 
collection) with the objects of the collection passed in parameter. */
- (id) initWithCollection: (id <ETCollection>)objects
{
	SUPERINIT
	ASSIGN(_pickedObjects, [objects contentArray]);
	ASSIGN(_type, [ETUTI transientTypeWithSupertypes: [(NSObject *)objects valueForKey: @"UTI"]]);
	return self;
}

- (void) dealloc
{
	DESTROY(_pickedObjects);
	DESTROY(_type);

	[super dealloc];
}

/** Returns a transient union type of the receiver type and all its element 
type. */
- (ETUTI *) type
{
	return _type;
}

/* Collection protocol */

- (id) content
{
	return _pickedObjects;
}

- (NSArray *) contentArray
{
	return [_pickedObjects contentArray];
}

- (BOOL) isOrdered
{
	return YES;
}

@end
