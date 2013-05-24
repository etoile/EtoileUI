/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETController.h"
#import "ETNibOwner.h"

@interface ETNibOwner (ModelDescription)
@end

@implementation ETNibOwner (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETNibOwner className]] == NO) 
		return entity;

	// TODO: Declare the property descriptions

	return entity;
}

@end

// NOTE: ETDocumentController uses ETController model description
@interface ETController (ModelDescription)
@end

@implementation ETController (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add 
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETController className]] == NO) 
		return entity;

	/* Persistent Properties */

	ETPropertyDescription *content = 
		[ETPropertyDescription descriptionWithName: @"content" type: (id)@"ETLayoutItemGroup"];
	[content setOpposite: (id)@"ETLayoutItemGroup.controller"];
	ETPropertyDescription *templates =
		[ETPropertyDescription descriptionWithName: @"templates" type: (id)@"ETItemTemplate"];
	[templates setMultivalued: YES];
	[templates setOrdered: NO];
	ETPropertyDescription *currentObjectType =
		[ETPropertyDescription descriptionWithName: @"currentObjectType" type: (id)@"ETUTI"];
	ETPropertyDescription *currentGroupType =
		[ETPropertyDescription descriptionWithName: @"currentGroupType" type: (id)@"ETUTI"];
	[currentGroupType setReadOnly: YES];
	// FIXME: Register a dummy class for the protocol COPersistentObjectContext
	ETPropertyDescription *persistentObjectContext =
		[ETPropertyDescription descriptionWithName: @"persistentObjectContext" type: (id)@"NSObject"];
	ETPropertyDescription *clearsFilterPredicate =
		[ETPropertyDescription descriptionWithName: @"clearsFilterPredicateOnInsertion" type: (id)@"BOOL"];
	ETPropertyDescription *selectsInsertedObjects =
		[ETPropertyDescription descriptionWithName: @"selectsInsertedObjects" type: (id)@"BOOL"];
	ETPropertyDescription *sortDescriptors =
		[ETPropertyDescription descriptionWithName: @"sortDescriptors" type: (id)@"NSSortDescriptor"];
	[sortDescriptors setMultivalued: YES];
	[sortDescriptors setOrdered: YES];
	ETPropertyDescription *filterPredicate =
		[ETPropertyDescription descriptionWithName: @"filterPredicate" type: (id)@"NSPredicate"];
	ETPropertyDescription *automaticallyRearranges =
		[ETPropertyDescription descriptionWithName: @"automaticallyRearrangesObjects" type: (id)@"BOOL"];
	ETPropertyDescription *allowedPickTypes =
		[ETPropertyDescription descriptionWithName: @"allowedPickTypes" type: (id)@"ETUTI"];
	[allowedPickTypes setMultivalued: YES];
	[allowedPickTypes setOrdered: YES];
	ETPropertyDescription *allowedDropTypes =
		[ETPropertyDescription descriptionWithName: @"allowedDropTypes" type: (id)@"ETUTI"];
	[allowedDropTypes setMultivalued: YES];
	[allowedDropTypes setOrdered: NO];

	/* Transient Properties */

	ETPropertyDescription *nibMainContent =
		[ETPropertyDescription descriptionWithName: @"nibMainContent" type: (id)@"NSObject"];
	ETPropertyDescription *builder =
		[ETPropertyDescription descriptionWithName: @"builder" type: (id)@"ETLayoutItemBuilder"];
	ETPropertyDescription *nextResponder =
		[ETPropertyDescription descriptionWithName: @"nextResponder" type: (id)@"NSObject"];
	[nextResponder setReadOnly: YES];
	ETPropertyDescription *defaultOptions =
		[ETPropertyDescription descriptionWithName: @"defaultOptions" type: (id)@"NSObject"];
	[defaultOptions setMultivalued: YES];
	[defaultOptions setOrdered: NO];
	[defaultOptions setReadOnly: YES];
	ETPropertyDescription *canMutate =
		[ETPropertyDescription descriptionWithName: @"canMutate" type: (id)@"BOOL"];
	[canMutate setReadOnly: YES];
	ETPropertyDescription *isContentMutable =
		[ETPropertyDescription descriptionWithName: @"isContentMutable" type: (id)@"BOOL"];
	[isContentMutable setReadOnly: YES];
	ETPropertyDescription *insertionIndex =
		[ETPropertyDescription descriptionWithName: @"insertionIndex" type: (id)@"NSInteger"];
	[insertionIndex setReadOnly: YES];
	ETPropertyDescription *insertionIndexPath =
		[ETPropertyDescription descriptionWithName: @"insertionIndexPath" type: (id)@"NSIndexPath"];
	[insertionIndexPath setReadOnly: YES];
	ETPropertyDescription *additionIndexPath =
		[ETPropertyDescription descriptionWithName: @"additionIndexPath" type: (id)@"NSIndexPath"];
	[additionIndexPath setReadOnly: YES];
	ETPropertyDescription *isEditing =
		[ETPropertyDescription descriptionWithName: @"isEditing" type: (id)@"BOOL"];
	[isEditing setReadOnly: YES];

	NSArray *transientProperties = A(nibMainContent, builder, currentGroupType,
		nextResponder, defaultOptions, canMutate, isContentMutable,
		insertionIndex, insertionIndexPath, additionIndexPath, isEditing);
	NSArray *persistentProperties = A(content);
	// FIXME: Using all persistent properties is not yet tested...
	NSArray *futurePersistentProperties = A(content, templates, currentObjectType,
		persistentObjectContext, clearsFilterPredicate,
		selectsInsertedObjects, sortDescriptors, filterPredicate,
		automaticallyRearranges, allowedPickTypes, allowedDropTypes);
	
	transientProperties = [transientProperties arrayByAddingObjectsFromArray: futurePersistentProperties];

	[entity setUIBuilderPropertyNames: (id)[[A(templates, currentObjectType,
		currentGroupType, persistentObjectContext, clearsFilterPredicate,
		selectsInsertedObjects, sortDescriptors, filterPredicate,
		automaticallyRearranges, allowedPickTypes, allowedDropTypes) mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
	 	[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

@end
