/*
	Copyright (C) 2016 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  August 2016
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETAspectCategory.h"
#import "ETAspectRepository.h"

@interface ETAspectCategory (ModelDescription)
@end

@interface ETAspectRepository (ModelDescription)
@end


@implementation ETAspectCategory (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([entity.name isEqual: [ETAspectCategory className]] == NO)
		return entity;

	// TODO: Turn into a CODictionary since COObject references turned into
	// strings will be ignored during diff/merge operattions.
	ETPropertyDescription *aspectEntries =
		[ETPropertyDescription descriptionWithName: @"aspectEntries" typeName: @"ETKeyValuePair"];
	aspectEntries.multivalued = YES;
	aspectEntries.ordered = YES;
	aspectEntries.persistent = YES;
	aspectEntries.persistentTypeName = @"NSString";
	ETPropertyDescription *aspectKeys =
		[ETPropertyDescription descriptionWithName: @"aspectKeys" typeName: @"NSString"];
	aspectKeys.multivalued = YES;
	aspectKeys.ordered = YES;
	aspectKeys.readOnly = YES;
	aspectKeys.derived = YES;
	ETPropertyDescription *aspects =
		[ETPropertyDescription descriptionWithName: @"aspects" typeName: @"NSObject"];
	aspects.multivalued = YES;
	aspects.ordered = YES;
	aspects.readOnly = YES;
	aspects.derived = YES;

	entity.propertyDescriptions = @[aspectEntries, aspectKeys, aspects];

	return entity;
}

@end


@implementation ETAspectRepository (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([entity.name isEqual: [ETAspectRepository className]] == NO)
		return entity;

	ETPropertyDescription *categoryNames =
		[ETPropertyDescription descriptionWithName: @"categoryNames" typeName: @"NSString"];
	categoryNames.derived = YES;

	entity.propertyDescriptions = @[categoryNames];

	return entity;
}

@end
