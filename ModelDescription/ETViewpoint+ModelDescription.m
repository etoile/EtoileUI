/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>

@interface ETMutableObjectViewpoint (ModelDescription)
@end

@interface ETCollectionViewpoint (ModelDescription)
@end

@interface ETUnionViewpoint (ModelDescription)
@end

@implementation ETMutableObjectViewpoint (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETMutableObjectViewpoint className]] == NO)
		return entity;

	/* Transient Properties */

	/* ETMutableObjectViewpoint is persistent, but the properties are declared 
	   transient because we persist it as a property list (it is not a COObject). */
	ETPropertyDescription *name = [ETPropertyDescription descriptionWithName: @"name" type: (id)@"NSString"];
	ETPropertyDescription *repObject =
		[ETPropertyDescription descriptionWithName: @"representedObject" type: (id)@"NSObject"];
	ETPropertyDescription *value =
		[ETPropertyDescription descriptionWithName: @"value" type: (id)@"NSObject"];

	NSArray *transientProperties = A(name, repObject, value);

	[entity setUIBuilderPropertyNames: (id)[[A(name) mappedCollection] name]];

	[entity setPropertyDescriptions: transientProperties];

	return entity;
}

@end

@implementation ETCollectionViewpoint (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETCollectionViewpoint className]] == NO)
		return entity;
	
	/* Transient Properties */
	
	/* ETCollectionViewpoint is persistent, but the properties are declared
	   transient because we persist it as a property list (it is not a COObject). */
	ETPropertyDescription *content = [ETPropertyDescription descriptionWithName: @"content" type: (id)@"NSObject"];
	// TODO: Whether the content collection is ordered or keyed is unknown, so
	// we need to relax the constraint checks. We could subclass ETPropertyDescription
	// and override -checkConstraints:.
	[content setMultivalued: YES];
	
	NSArray *transientProperties = A(content);
	
	[entity setUIBuilderPropertyNames: (id)[[A(content) mappedCollection] name]];
	
	[entity setPropertyDescriptions: transientProperties];
	
	return entity;
}

@end

@implementation ETUnionViewpoint (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETUnionViewpoint className]] == NO)
		return entity;
	
	/* Transient Properties */
	
	/* ETUnionViewpoint is persistent, but the properties are declared
	   transient because we persist it as a property list (it is not a COObject). */
	ETPropertyDescription *contentKeyPath = [ETPropertyDescription descriptionWithName: @"contentKeyPath" type: (id)@"NSString"];
	
	NSArray *transientProperties = A(contentKeyPath);
	
	[entity setUIBuilderPropertyNames: (id)[[A(contentKeyPath) mappedCollection] name]];
	
	[entity setPropertyDescriptions: transientProperties];
	
	return entity;
}

@end
