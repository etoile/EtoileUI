/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>

@interface NSSortDescriptor (ModelDescription)
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
	ETPropertyDescription *selector = [ETPropertyDescription descriptionWithName: @"selector" type: (id)@"SEL"];

	/* NSSortDescriptor is persistent, but the properties are declared transient 
	   because we use keyed archiving to persist it (it is not a COObject). */
	NSArray *transientProperties = A(ascending, key, selector);

	[entity setUIBuilderPropertyNames: (id)[[transientProperties mappedCollection] name]];

	[entity setPropertyDescriptions: transientProperties];

	return entity;
}

@end
