/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETController.h"
#import "ETItemTemplate.h"
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


@interface ETCompositePropertyDescription : ETPropertyDescription
@end

@implementation ETCompositePropertyDescription

- (BOOL) isComposite
{
	return YES;
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
	[content setDerived: YES];
	[content setOpposite: (id)@"ETLayoutItemGroup.controller"];
    ETPropertyDescription *observations =
        [ETCompositePropertyDescription descriptionWithName: @"observations" type: (id)@"ETObservation"];
    [observations setMultivalued: YES];
    [observations setOrdered: NO];
	ETPropertyDescription *templates =
		[ETPropertyDescription descriptionWithName: @"templates" type: (id)@"ETItemTemplate"];
	[templates setMultivalued: YES];
	[templates setOrdered: NO];
	[templates setKeyed: YES];
	// TODO: Display 'key' as 'Target UTI' or 'UTI'
	[templates setShowsItemDetails: YES];
	[templates setDetailedPropertyNames: @[@"item", @"objectClass", @"entityName"]];
	ETPropertyDescription *currentObjectType =
		[ETPropertyDescription descriptionWithName: @"currentObjectType" type: (id)@"ETUTI"];
    [currentObjectType setValueTransformerName: @"ETUTIToString"];
    [currentObjectType setPersistentTypeName: @"NSString"];
	ETPropertyDescription *currentGroupType =
		[ETPropertyDescription descriptionWithName: @"currentGroupType" type: (id)@"ETUTI"];
	[currentGroupType setReadOnly: YES];
	// FIXME: Register a dummy class for the protocol COPersistentObjectContext
	ETPropertyDescription *persistentObjectContextUUID =
		[ETPropertyDescription descriptionWithName: @"persistentObjectContextUUID" typeName: @"ETUUID"];
	[persistentObjectContextUUID setValueTransformerName: @"ETUUIDToString"];
    [persistentObjectContextUUID setPersistentTypeName: @"NSString"];
	ETPropertyDescription *initialFocusedItem =
		[ETPropertyDescription descriptionWithName: @"initialFocusedItem" type: (id)@"ETLayoutItem"];
	ETPropertyDescription *clearsFilterPredicate =
		[ETPropertyDescription descriptionWithName: @"clearsFilterPredicateOnInsertion" type: (id)@"BOOL"];
	ETPropertyDescription *selectsInsertedObjects =
		[ETPropertyDescription descriptionWithName: @"selectsInsertedObjects" type: (id)@"BOOL"];
	ETPropertyDescription *sortDescriptors =
		[ETPropertyDescription descriptionWithName: @"sortDescriptors" type: (id)@"NSSortDescriptor"];
	[sortDescriptors setMultivalued: YES];
	[sortDescriptors setOrdered: YES];
    [sortDescriptors setValueTransformerName: @"COObjectToArchivedData"];
    [sortDescriptors setPersistentTypeName: @"NSData"];
	[sortDescriptors setDetailedPropertyNames: @[@"key", @"ascending", @"selectorString"]];
	ETPropertyDescription *filterPredicate =
		[ETPropertyDescription descriptionWithName: @"filterPredicate" type: (id)@"NSPredicate"];
    [filterPredicate setValueTransformerName: @"ETPredicateToString"];
    [filterPredicate setPersistentTypeName: @"NSString"];
	ETPropertyDescription *automaticallyRearranges =
		[ETPropertyDescription descriptionWithName: @"automaticallyRearrangesObjects" type: (id)@"BOOL"];
	ETPropertyDescription *allowedPickTypes =
		[ETPropertyDescription descriptionWithName: @"allowedPickTypes" type: (id)@"ETUTI"];
	[allowedPickTypes setMultivalued: YES];
	[allowedPickTypes setOrdered: YES];
    [allowedPickTypes setValueTransformerName: @"ETUTIToString"];
    [allowedPickTypes setPersistentTypeName: @"NSString"];
	[allowedPickTypes setDetailedPropertyNames: @[@"stringValue", @"classValue"]];
	ETPropertyDescription *allowedDropTypes =
		[ETPropertyDescription descriptionWithName: @"allowedDropTypes" type: (id)@"ETUTITuple"];
	[allowedDropTypes setMultivalued: YES];
	[allowedDropTypes setOrdered: NO];
    [allowedDropTypes setKeyed: YES];
	// TODO: Display 'key' as 'Target UTI'
	[allowedDropTypes setDetailedPropertyNames: @[@"stringValue", @"classValue"]];

	/* Transient Properties */

	ETPropertyDescription *nibMainContent =
		[ETPropertyDescription descriptionWithName: @"nibMainContent" type: (id)@"NSObject"];
	ETPropertyDescription *builder =
		[ETPropertyDescription descriptionWithName: @"builder" type: (id)@"ETLayoutItemBuilder"];
	// FIXME: Register a dummy class for the protocol COPersistentObjectContext
	ETPropertyDescription *persistentObjectContext =
		[ETPropertyDescription descriptionWithName: @"persistentObjectContext" type: (id)@"NSObject"];
	ETPropertyDescription *nextResponder =
		[ETPropertyDescription descriptionWithName: @"nextResponder" type: (id)@"NSObject"];
	[nextResponder setReadOnly: YES];
	ETPropertyDescription *defaultOptions =
		[ETPropertyDescription descriptionWithName: @"defaultOptions" type: (id)@"NSObject"];
	[defaultOptions setMultivalued: YES];
	[defaultOptions setKeyed: YES];
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
		[ETPropertyDescription descriptionWithName: @"editing" type: (id)@"BOOL"];
	[isEditing setReadOnly: YES];
    ETPropertyDescription *editedItems =
        [ETPropertyDescription descriptionWithName: @"editedItems" type: (id)@"ETLayoutItem"];
    [editedItems setMultivalued: YES];
    [editedItems setOrdered: YES];
    [editedItems setReadOnly: YES];
    ETPropertyDescription *editedProperties =
        [ETPropertyDescription descriptionWithName: @"editedProperties" type: (id)@"NSArray"];
    [editedProperties setMultivalued: YES];
    [editedProperties setOrdered: YES];
    [editedProperties setReadOnly: YES];

	NSArray *transientProperties = @[content, nibMainContent, builder, persistentObjectContext,
        currentGroupType, nextResponder, defaultOptions, canMutate, isContentMutable,
		insertionIndex, insertionIndexPath, additionIndexPath, isEditing,
        editedItems, editedProperties];
	NSArray *persistentProperties = @[observations, templates, currentObjectType,
        initialFocusedItem, persistentObjectContextUUID, clearsFilterPredicate,
        selectsInsertedObjects, sortDescriptors, filterPredicate,
        automaticallyRearranges, allowedPickTypes, allowedDropTypes];

	[entity setUIBuilderPropertyNames: (id)[[@[templates, currentObjectType,
		currentGroupType, persistentObjectContext, clearsFilterPredicate,
		selectsInsertedObjects, sortDescriptors, filterPredicate,
		automaticallyRearranges, allowedPickTypes, allowedDropTypes] mappedCollection] name]];

	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
	 	[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];

	return entity;
}

#pragma mark Viewpoint Integration for Editing Controller Properties
#pragma mark -

- (NSDictionary *) templates
{
	NSMutableDictionary *editableTemplates = [NSMutableDictionary dictionary];

	[[_templates content] enumerateKeysAndObjectsUsingBlock: ^ (id UTIString, id itemTemplate, BOOL *stop)
	{
		editableTemplates[[ETUTI typeWithString: UTIString]] = itemTemplate;
	}];
	return [editableTemplates copy];
}

- (void) setTemplates: (NSDictionary *)editedTemplates
{
	[self willChangeValueForProperty: @"templates"];
	[_templates removeAllObjects];

	[editedTemplates enumerateKeysAndObjectsUsingBlock: ^ (id UTI, id itemTemplate, BOOL *stop)
	{
		_templates[[UTI stringValue]] = itemTemplate;
	}];
	[self didChangeValueForProperty: @"templates"];
}

// TODO: For the UI, 'allowedDropTypes' accessors should expose a ETKeyValuePair array.

- (NSDictionary *) allowedDropTypes
{
	NSMutableDictionary *editableDropTypes = [NSMutableDictionary dictionary];

	[[_allowedDropTypes content] enumerateKeysAndObjectsUsingBlock: ^ (id targetUTIString, id UTIs,  BOOL *stop)
	{
		editableDropTypes[[ETUTI typeWithString: targetUTIString]] = UTIs;
	}];
	return [editableDropTypes copy];
}

- (void) setAllowedDropTypes: (NSDictionary *)editedDropTypes
{
	[self willChangeValueForProperty: @"allowedDropTypes"];
	[_allowedDropTypes removeAllObjects];

	[editedDropTypes enumerateKeysAndObjectsUsingBlock: ^ (id targetUTI, id UTIs, BOOL *stop)
	{
		_allowedDropTypes[[targetUTI stringValue]] = UTIs;
	}];
	[self didChangeValueForProperty: @"allowedDropTypes"];
}

@end


@interface ETItemTemplate (ModelDescription)
@end

@implementation ETItemTemplate (ModelDescription)

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [ETItemTemplate className]] == NO)
		return entity;
	
	/* Persistent Properties */

	ETPropertyDescription *objectClass =
		[ETPropertyDescription descriptionWithName: @"objectClass" type: (id)@"NSObject"];
	[objectClass setReadOnly: YES];
    [objectClass setValueTransformerName: @"COClassToString"];
    [objectClass setPersistentTypeName: @"NSString"];
	ETPropertyDescription *entityName =
		[ETPropertyDescription descriptionWithName: @"entityName" type: (id)@"NSString"];
	[entityName setReadOnly: YES];
	ETPropertyDescription *item =
		[ETPropertyDescription descriptionWithName: @"item" type: (id)@"ETLayoutItem"];
	[item setReadOnly: YES];

	/* Transient Properties */
	
	ETPropertyDescription *contentItem =
		[ETPropertyDescription descriptionWithName: @"contentItem" type: (id)@"ETLayoutItem"];
	[contentItem setReadOnly: YES];
	ETPropertyDescription *baseName =
		[ETPropertyDescription descriptionWithName: @"baseName" type: (id)@"NSString"];
	[baseName setReadOnly: YES];
	ETPropertyDescription *supportedTypes =
		[ETPropertyDescription descriptionWithName: @"supportedTypes" type: (id)@"ETUTI"];
	[supportedTypes setMultivalued: YES];
	[supportedTypes setOrdered: YES];
	[supportedTypes setReadOnly: YES];
	
	NSArray *transientProperties = @[contentItem, baseName, supportedTypes];
	NSArray *persistentProperties =  @[objectClass, entityName, item];
	
	[entity setUIBuilderPropertyNames: (id)[[@[objectClass, entityName, item] mappedCollection] name]];
	
	[[persistentProperties mappedCollection] setPersistent: YES];
	[entity setPropertyDescriptions:
		[persistentProperties arrayByAddingObjectsFromArray: transientProperties]];
	
	return entity;
}

@end
