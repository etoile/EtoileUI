/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "ETItemTemplate.h"

@interface NSSortDescriptor (ModelDescription) <ETDocumentCreation>
@end

@interface NSSortDescriptorMutableViewpointTrait : NSObject
@end

@interface NSSortDescriptorMutableViewpointTrait (ETViewpoint)
- (id) value;
- (void) setValue: (id)aValue;
@end


@implementation NSSortDescriptor (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [NSSortDescriptor className]] == NO)
		return entity;

	/* Transient Properties */

	ETPropertyDescription *ascending = [ETPropertyDescription descriptionWithName: @"ascending" type: (id)@"BOOL"];
	ETPropertyDescription *key = [ETPropertyDescription descriptionWithName: @"key" type: (id)@"NSString"];
	/* Key-Value Coding doesn't support SEL, so we expose a custom property */
	ETPropertyDescription *selectorString = [ETPropertyDescription descriptionWithName: @"selectorString" type: (id)@"NSString"];
	[selectorString setDerived: YES];
	[selectorString setDisplayName: @"Selector"];

	/* NSSortDescriptor is persistent, but the properties are declared transient 
	   because we use keyed archiving to persist it (it is not a COObject). */
	NSArray *transientProperties = A(ascending, key, selectorString);

	[entity setUIBuilderPropertyNames: (id)[[transientProperties mappedCollection] name]];

	[entity setPropertyDescriptions: transientProperties];

	return entity;
}

+ (Class) mutableViewpointClass
{
	return [NSSortDescriptorMutableViewpointTrait class];
}

/* ETItemTemplate uses ETDocumentCreation protocol to instantiate a new sort descriptor. */
- (id) initWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	return [self initWithKey: @"unknown" ascending: YES];
}

- (NSString *)selectorString
{
	return NSStringFromSelector([self selector]);
}
@end

#ifdef GNUSTEP
@interface NSSortDescriptor (EtoileUI)
+ (id) sortDescriptorWithKey: (NSString *)aKey ascending: (BOOL)ascending selector: (SEL)aSelector;
@end

@implementation NSSortDescriptor (EtoileUI)
+ (id) sortDescriptorWithKey: (NSString *)aKey ascending: (BOOL)ascending selector: (SEL)aSelector
{
	return AUTORELEASE([[self alloc] initWithKey: aKey ascending: ascending selector: aSelector]);
}
@end
#endif

@implementation NSSortDescriptorMutableViewpointTrait

- (void) setAscending: (BOOL)ascending
{
	NSSortDescriptor *sortDescriptor =
		[NSSortDescriptor sortDescriptorWithKey: [[self value] key]
		                              ascending: ascending
	                                   selector: [[self value] selector]];
	[self setValue: sortDescriptor];
}

- (void) setKey: (NSString *)aKey
{
	NSSortDescriptor *sortDescriptor =
		[NSSortDescriptor sortDescriptorWithKey: aKey
		                              ascending: [[self value] ascending]
	                                   selector: [[self value] selector]];
	[self setValue: sortDescriptor];
}

- (void) setSelector: (SEL)aSelector
{
	NSSortDescriptor *sortDescriptor =
		[NSSortDescriptor sortDescriptorWithKey: [[self value] key]
		                              ascending: [[self value] ascending]
	                                   selector: aSelector];
	[self setValue: sortDescriptor];
}

- (void) setSelectorString: (NSString *)aString
{
	[self setSelector: NSSelectorFromString(aString)];
}

@end

