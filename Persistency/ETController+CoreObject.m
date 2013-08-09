/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef COREOBJECT

#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETController+CoreObject.h"

@implementation ETController (CoreObject)

- (NSString *) serializedCurrentObjectType
{
	return [_currentObjectType stringValue];
}

- (void) setSerializedCurrentObjectType: (NSString *)aUTIString
{
	ASSIGN(_currentObjectType, [ETUTI typeWithString: aUTIString]);
}

- (NSString *) serializedFilterPredicate
{
	return [[self filterPredicate] predicateFormat];
}

- (void) setSerializedFilterPredicate: (NSString *)aPredicateFormat
{
	[self setFilterPredicate: [NSPredicate predicateWithFormat: aPredicateFormat]];
}

- (NSArray *) serializedAllowedPickTypes
{
	return (id)[[_allowedPickTypes mappedCollection] stringValue];
}

- (void) setSerializedAllowedPickTypes: (NSArray *)serializedPickTypes
{
	NSMutableArray *pickTypes = [NSMutableArray new];

	for (NSString *UTIString in serializedPickTypes)
	{
		[pickTypes addObject: [ETUTI typeWithString: UTIString]];
	}
	ASSIGNCOPY(_allowedPickTypes, pickTypes);
}

@end

@implementation ETItemTemplate (CoreObject)

- (NSString *) serializedObjectClass
{
	return NSStringFromClass([self objectClass]);
}

- (void) setSerializedObjectClass: (NSString *)aClassName
{
	if (aClassName == nil)
		return;

	ASSIGN(_objectClass, NSClassFromString(aClassName));
	ETAssert(_objectClass != Nil);
}

@end

#endif
