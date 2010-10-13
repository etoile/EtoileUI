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
#import "ETItemTemplate.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETItemTemplate

/** Returns a new autoreleased template based on the given item and 
represented object class. */
+ (id) templateWithItem: (ETLayoutItem *)anItem objectClass: (Class)aClass
{
	return AUTORELEASE([[self alloc] initWithItem: anItem objectClass: aClass]);
}

/** <init />
Initializes and returns a new template based on the given item and 
represented object class.

Raises an NSInvalidArgumentException if the item is nil. */
- (id) initWithItem: (ETLayoutItem *)anItem objectClass: (Class)aClass
{
	NILARG_EXCEPTION_TEST(anItem);
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
	ETLayoutItem *newItem = [[self item] deepCopy];

	/* We don't set the object as model when it is nil, so any existing value 
	   or represented object already provided with the item won't be overwritten 
	   in such case. 
	   Value and represented object are copied when -deepCopy is called on the 
	   template items in -[ETItemTemplate newItemWithRepresentedObject:options]. */
	if (nil != anObject)
	{
		[newItem setRepresentedObject: anObject];
	}
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
- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	id newInstance = [[self objectClass] alloc];

	if ([newInstance conformsToProtocol: @protocol(ETDocumentCreation)])
	{ 
		[newInstance initWithURL: aURL options: options];
	}
	else
	{
		[newInstance init];
	}

	return [self newItemWithRepresentedObject: AUTORELEASE(newInstance) options: nil];
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

@end

