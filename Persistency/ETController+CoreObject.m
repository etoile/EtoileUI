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

- (void) becomePersistentInContext: (COPersistentRoot *)aContext
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext];
	
	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these aspects 
	// are already used as embedded objects in another root object.
	ETAssert([_templates isPersistent] == NO || [_templates isRoot]);
	[_templates becomePersistentInContext: aContext];
	for (ETItemTemplate *template in [_templates objectEnumerator])
	{
		ETAssert([template isPersistent] == NO || [template isRoot]);
		[template becomePersistentInContext: aContext];
	}
}

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

- (void) becomePersistentInContext: (COPersistentRoot *)aContext
{
	if ([self isPersistent])
		return;
	
	[super becomePersistentInContext: aContext];
	
	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these aspects
	// are already used as embedded objects in another root object.
	ETAssert([[self item] isPersistent] == NO || [[self item] isRoot]);
	[[self item] becomePersistentInContext: aContext];
}

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
