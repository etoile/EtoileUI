/*
	Copyright (C) 2010 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2010
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETDocumentController.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETItemTemplate

- (id) templateWithItem: (ETLayoutItem *)anItem objectClass: (Class)aClass
{
	return AUTORELEASE([[self class] initWithItem: anItem objectClass: aClass]);
}

- (id) initWithItem: (ETLayoutItem *)anItem objectClass: (Class)aClass
{
	SUPERINIT;
	ASSIGN(_item, anItem);
	ASSIGN(_objectClass, aClass);
	return self;
}

- (void) dealloc
{
	DESTROY(_item);
	DESTROY(_objectClass);
	[super dealloc];
}

/** Returns the represented object template class

Can return Nil. 

See also -newItemWithURL:options:. */
- (Class) objectClass
{
	return _objectClass;
}

/** Returns the template item.

See also -newItemWithRepresentedObject:options:. */
- (ETLayoutItem *) item
{
	return _item;
}

/** Returns a new retained ETLayoutItem or ETLayoutItemGroup object with the 
given represented object and options.

The returned item is a copy of -item.

All arguments can be nil.

Can be overriden in subclasses. */
- (ETLayoutItem *) newItemWithRepresentedObject: (id)anObject options: (NSDictionary *)options
{
	ETLayoutItem *newItem = [[self item] copy];
	[newItem setRepresentedObject: anObject];
	return newItem;
}

/** Returns a new retained ETLayoutItem or ETLayoutItemGroup object for the 
given URL and options.

If -objectClass is not Nil, a represented object is instantiated with -init or 
-initWithURL:options: if the object class conforms to ETDocumentCreation protocol.

If the given URL is nil, the user action is a 'New' and not 'Open'.

All arguments can be nil.

Can be overriden in subclasses.

See also -newItemWithRepresentedObject:options:. */
- (id) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	if (Nil == [self objectClass])
	{
		[NSException raise: NSInvalidArgumentException 
		            format: @"-objectClass must not return Nil"];
	}

	id newInstance = [[self objectClass] alloc];

	if ([newInstance conformsToProtocol: @protocol(ETDocumentCreation)])
	{ 
		[newInstance initWithURL: aURL options: options];
	}
	else
	{
		[newInstance init];
	}

	return [self newItemWithRepresentedObject: AUTORELEASE(newInstance)];
}

/** <override-dummy />
Returns whether the same document can appear multiple times on screen for 
the given URL. 

By default, returns NO.

Can be overriden in a subclass to implement a web browser for example. */
- (BOOL) allowsMultipleInstancesForURL: (NSURL *)aURL
{
	return NO;
}

/** Returns the UTI that describes the content at the given URL.

Will call -[ETUTI typeWithPath:] to determine the type, can be overriden to 
implement a tailored behavior. */
- (ETUTI *) typeForURL: (NSURL *)aURL
{
	// TODO: If UTI is nil, set error.
	return [ETUTI typeWithPath: [aURL path]];
}

@end

