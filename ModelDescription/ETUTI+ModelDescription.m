/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>

@interface ETUTI (ModelDescription)
@end

@implementation ETUTI (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETUTI className]] == NO)
		return entity;

	/* Transient Properties */

	/* ETUTI is persistent, but the properties are declared transient 
	   because we persist it as a simple string value (it is not a COObject). */
	ETPropertyDescription *stringValue = [ETPropertyDescription descriptionWithName: @"stringValue" type: (id)@"NSString"];
	[stringValue setDisplayName: @"UTI"];
	ETPropertyDescription *classValue = [ETPropertyDescription descriptionWithName: @"classValue" type: (id)@"NSObject"];
	[classValue setDisplayName: @"Class"];
	ETPropertyDescription *fileExtensions = [ETPropertyDescription descriptionWithName: @"fileExtensions" type: (id)@"NSString"];
	[fileExtensions setMultivalued: YES];
	[fileExtensions setOrdered: YES];
	ETPropertyDescription *MIMETypes = [ETPropertyDescription descriptionWithName: @"MIMETypes" type: (id)@"NSString"];
	[MIMETypes setMultivalued: YES];
	[MIMETypes setOrdered: YES];
	ETPropertyDescription *typeDescription = [ETPropertyDescription descriptionWithName: @"typeDescription" type: (id)@"NSString"];
	ETPropertyDescription *supertypes = [ETPropertyDescription descriptionWithName: @"supertypes" type: (id)@"ETUTI"];
	[supertypes setMultivalued: YES];
	[supertypes setOrdered: YES];
	ETPropertyDescription *allSupertypes = [ETPropertyDescription descriptionWithName: @"allSupertypes" type: (id)@"ETUTI"];
	[allSupertypes setMultivalued: YES];
	[allSupertypes setOrdered: YES];
	ETPropertyDescription *subtypes = [ETPropertyDescription descriptionWithName: @"subtypes" type: (id)@"ETUTI"];
	[subtypes setMultivalued: YES];
	[subtypes setOrdered: YES];
	ETPropertyDescription *allSubtypes = [ETPropertyDescription descriptionWithName: @"allSubtypes" type: (id)@"ETUTI"];
	[allSubtypes setMultivalued: YES];
	[allSubtypes setOrdered: YES];

	NSArray *transientProperties = A(stringValue, classValue, fileExtensions,
		MIMETypes, typeDescription, supertypes, allSupertypes, subtypes, allSubtypes);

	[entity setUIBuilderPropertyNames: (id)[[A(stringValue, classValue) mappedCollection] name]];

	[entity setPropertyDescriptions: transientProperties];

	return entity;
}

@end
