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
#import "ETNibOwner.h"
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

- (void) dealloc
{
	DESTROY(_nibBundle);
	DESTROY(_nibName);
	DESTROY(_topLevelObjects);
	[super dealloc];
}

- (BOOL) isNibLoaded
{
	return ([_topLevelObjects isEmpty] == NO);
}

/** Loads the Nib file with the receiver as the owner and returns YES on success, 
otherwise returns NO and logs a failure message.

Raises an exception if the bundle or the Nib itself cannot be found. */
- (BOOL) loadNib
{
    if ([self isNibLoaded] == YES)
        return YES;
    
    NSDictionary* nibContext = D(self, NSNibOwner, _topLevelObjects, NSNibTopLevelObjects);

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

@end
