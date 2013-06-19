/*
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETEntityDescription.h>
#import <EtoileFoundation/ETPropertyDescription.h>
#import <EtoileFoundation/ETModelElementDescription.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETModelBuilderRelationshipController.h"
#import "ETController.h"
#import "ETItemValueTransformer.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETModelBuilderUI.h"
#import "ETObjectValueFormatter.h"
#import "ETCompatibility.h"


@implementation ETModelBuilderController

@synthesize relationshipValueTransformer = _relationshipValueTransformer;

- (ETModelDescriptionRepository *) repository
{
	return [ETModelDescriptionRepository mainRepository];
}

+ (ETItemValueTransformer *) newRelationshipValueTransformer
{
	ETItemValueTransformer *transformer = [ETItemValueTransformer new];

	[transformer setTransformBlock: ^id (id value, NSString *key, ETLayoutItem *item)
	{
		NSParameterAssert([value isKindOfClass: [ETModelElementDescription class]]);
		return [value fullName];
	}];

	[transformer setReverseTransformBlock: ^id (id value, NSString *key, ETLayoutItem *item)
	{
		NSParameterAssert([value isString]);

		if ([value isEqual: @""] || [value isEqual: @"nil"] || [value isEqual: @"Nil"])
			return nil;

		id controller = [[item controllerItem] controller];

		if ([self conformsToProtocol: @protocol(ETModelBuilderEditionCoordinator)] == NO)
			return nil;

		ETAssert([controller repository] != nil);
		return [[controller repository] descriptionForName: value];
	}];

	return transformer;
}

/* There is no need to implement -formatter:stringForObjectValue: because
   -[ETLayoutItem valueForProperty:] does the transformation through
   -[ETLayoutItem valueTransformerForProperty:]. */
- (NSString *) formatter: (ETObjectValueFormatter *)aFormatter stringValueForString: (id)aValue
{
	BOOL isEditing = ([self editedProperty] != nil);

	/* The empty string is a valid value so we don't return nil (the value represents nil) */
	if ([aValue isEqual: @""] || isEditing == NO)
		return aValue;

	return [[self relationshipValueTransformer] reverseTransformedValue: aValue
	                                                             forKey: [self editedProperty]
	                                                             ofItem: [self editedItem]];
}

- (NSSet *) modelElementKeysForRepositoryUpdate
{
	return S(@"name", @"parent", @"entityDescriptions", @"propertyDescriptions");
}

- (BOOL) shouldUpdateRepositoryForEditedObject: (id)editedObject key: (NSString *)aKey
{
	if ([editedObject isKindOfClass: [ETPropertyDescription class]] == NO
	 && [editedObject isKindOfClass: [ETEntityDescription class]] == NO)
	{
		return NO;
	}
	
	return [[self modelElementKeysForRepositoryUpdate] containsObject: aKey];
}

- (id) editedObjectForItem: (ETLayoutItem *)anItem
{
	BOOL isPropertyViewpoint =
		([[anItem representedObject] conformsToProtocol: @protocol(ETPropertyViewpoint)]);
	ETLayoutItem *editedObject = nil;
	
	if (isPropertyViewpoint)
	{
		editedObject = [[anItem representedObject] representedObject];
	}
	else
	{
		editedObject = [anItem representedObject];
	}
	return editedObject;
}

- (void) subjectDidEndEditingForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{
	ETAssert([self repository] != nil);
	[super subjectDidEndEditingForItem: anItem property: aKey];

	id editedObject = [self editedObjectForItem: anItem];
	ETAssert([editedObject isKindOfClass: [ETModelElementDescription class]]);

	if ([self shouldUpdateRepositoryForEditedObject: editedObject key: aKey])
	{
		[[self repository] addDescription: editedObject];
		ETAssert([[self repository] descriptionForName: [editedObject fullName]] == editedObject);
	}
}

@end


@implementation ETModelBuilderRelationshipController

- (IBAction) edit: (id)sender
{
	ETLayoutItem *item = [sender doubleClickedItem];
	ETLayoutItemGroup *entityItem = [[item representedObject] itemRepresentation];
	
	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
}

- (ETController *) parentController
{
	return [[[self content] controllerItem] controller];
}

- (void) subjectDidEndEditingForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{
	[super subjectDidEndEditingForItem: anItem property: aKey];
	ETAssert([[self parentController] isKindOfClass: [ETModelBuilderController class]]);
	[[self parentController] subjectDidEndEditingForItem: anItem property: aKey];
}

@end
