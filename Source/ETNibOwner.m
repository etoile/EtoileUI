/*
	Copyright (C) 2004-2006 M. Uli Kusterer, all rights reserved.

	Authors:  M. Uli Kusterer
	          Guenther Noack
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2004
	Licenses:  GPL, Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETRendering.h>
#import "ETNibOwner.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETNibOwner

/** <init />
Initializes and returns a new Nib owner for the Nib with the given name to be 
found in the given bundle.

The Nib name must not be a path. However it can be nil, but then -loadNib 
will look for a Nib whose name matches the receiver class name. See -nibName.

The Nib bundle will be to be the main bundle if you pass nil. */
- (id) initWithNibName: (NSString *)aNibName bundle: (NSBundle *)aBundle
{
	SUPERINIT;
	ASSIGN(_nibBundle, aBundle);
	ASSIGN(_nibName, aNibName);
	_topLevelObjects = [[NSMutableArray alloc] init];
	return self;
}

/** Initializes and returns a new Nib owner which uses the receiver class name 
as the nib name to be found in the main bundle. */
- (id) init
{
	return [self initWithNibName: nil bundle: nil];
}

- (void) dealloc
{
	DESTROY(_nibBundle);
	DESTROY(_nibName);
	DESTROY(_topLevelObjects);
	[super dealloc];
}

/*- (void) copyWithZone: (NSZone *)aZone
{
	ETController *newNibOwner = [[[self class] allocWithZone: aZone] init];

	ASSIGN(newNibOwner->_nibBundle, _nibBundle);
	ASSIGN(newNibOwner->_nibName, _nibName);

	return newNibOwner;
}*/

- (BOOL) isNibLoaded
{
	return ([_topLevelObjects isEmpty] == NO);
}

/** Loads the Nib file with the given object as the File's Owner and returns YES 
on success, otherwise returns NO and logs a failure message.

The owner must not be nil.

Raises an exception if the bundle or the Nib itself cannot be found. */
- (BOOL) loadNibWithOwner: (id)anOwner
{
	NILARG_EXCEPTION_TEST(anOwner);

    if ([self isNibLoaded] == YES)
        return YES;
    
    NSDictionary* nibContext = D(anOwner, NSNibOwner, _topLevelObjects, NSNibTopLevelObjects);

    NSAssert1([self nibBundle] != nil, @"Failed finding bundle for NibOwner %@", self);

    BOOL nibLoaded = [[self nibBundle] loadNibFile: [self nibName]
	                             externalNameTable: nibContext
	                                      withZone: [self zone]];

    if (nibLoaded == NO) 
	{
        ETLog(@"NibOwner %@ couldn't load Nib (Gorm) file %@.nib (~.gorm)", self, [self nibName]);
        return NO;
    }
	[_topLevelObjects makeObjectsPerformSelector: @selector(release)];
	[self didLoadNib];

    return YES;
}

/** Loads the Nib file with the receiver as the owner and returns YES on success, 
otherwise returns NO and logs a failure message.

Raises an exception if the bundle or the Nib itself cannot be found. */
- (BOOL) loadNib
{
	return [self loadNibWithOwner: self];
}

/** <override-dummy />
Will be immediately called when the Nib loading is finished.

By default, does nothing.

If you override this method, you must first call the superclass implementation. */
- (void) didLoadNib
{

}

/** Returns the filename (minus ".nib" suffix) for the Nib file to load.

Note that, if you subclass this and the receiver was initialized with a nil Nib 
name, it will use the subclass's name. So, you *may* want to override this to 
return a predetermined Nib name if you don't expect subclasses to use 
identically named Nib files.

If you override this method, you must first call the superclass implementation 
and returns its result immediately if not nil. */
- (NSString *) nibName
{
    return (nil != _nibName ? _nibName : NSStringFromClass([self class]));
}

/** Returns the bundle to load the Nib from.

See also -initWithNibName:bundle:. */
- (NSBundle *) nibBundle
{
    return (nil != _nibBundle ? _nibBundle : [NSBundle mainBundle]);
}

/** Returns the mutable array that stores the top level objects once the nib 
is loaded.

Only subclasses should use this method and mutate the array. */
- (NSMutableArray *) topLevelObjects
{
	return _topLevelObjects;
}

/** Returns the subset of the top-level objects which are layout items. */
- (NSArray *) topLevelItems
{
	NSMutableArray *topLevelItems = AUTORELEASE([_topLevelObjects mutableCopy]);
	[[topLevelItems filter] isLayoutItem];
	return topLevelItems;
}

/** Converts the top-level objects of the Nib into equivalent EtoileUI 
constructs if possible.

For example, views or windows become layout item trees owned by the Nib.

The conversion is delegated to the given builder with ETRendering protocol.<br />
The object returned by -render: replaces the original object. When 
-rebuiltObjectForObject:builder: returns nil, the original object is removed.  */
- (void) rebuildTopLevelObjectsWithBuilder: (id)aBuilder
{
	FOREACHI([NSArray arrayWithArray: _topLevelObjects], object)
	{
		id newObject = [self rebuiltObjectForObject: object 
		                                    builder: aBuilder];

		if (nil == newObject)
		{
			[_topLevelObjects removeObject: object];
		}
		else /* newObject can be identical to the object at i */
		{
			NSInteger i = [_topLevelObjects indexOfObject: object];
			[_topLevelObjects replaceObjectAtIndex: i withObject: newObject];
		}
	}
}

/** <override-dummy />
Invokes -render: on the builder with the given object as argument.<br />
When the builder returns nil, returns the original object, otherwise returns a 
new object.

Can be overriden to customize how each object is handed to the builder and how 
each object returned by the builder is handed back to 
-rebuildTopLevelObjectsWithBuilder:. */
- (id) rebuiltObjectForObject: (id)anObject builder: (id)aBuilder
{
	id newObject = [aBuilder render: anObject];
	return (nil != newObject ? newObject : anObject);
}

@end
