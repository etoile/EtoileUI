/*
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETPropertyDescription.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/ETModelElementDescription.h>
#import <EtoileFoundation/NSObject+DoubleDispatch.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETModelDescriptionRenderer.h"
#import "ETTemplateItemLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"


@implementation ETModelDescriptionRenderer

- (NSString *) doubleDispatchPrefix
{
	return @"render";
}

+ (id) renderer
{
	return AUTORELEASE([[self alloc] init]);
}

- (id) init
{
	SUPERINIT
	_templateItems = [NSMutableDictionary new];
	_additionalTemplateIdentifiers = [NSMutableDictionary new];
	ASSIGN(_repository, [ETModelDescriptionRepository mainRepository]);
	ASSIGN(_itemFactory, [ETLayoutItemFactory factory]);

	[self registerDefaultTemplateItems];
	[self registerDefaultRoleTemplateIdentifiers];

	return self;
}

- (void) dealloc
{
	DESTROY(_templateItems);
	DESTROY(_repository);
	DESTROY(_itemFactory);
	[super dealloc];
}

- (ETModelDescriptionRepository *) repository
{
	return _repository;
}

- (void) setTemplateItem: (ETLayoutItem *)anItem forIdentifier: (NSString *)anIdentifier
{
	[_templateItems setObject: anItem forKey: anIdentifier];
}

- (ETLayoutItem *) templateItemForIdentifier: (NSString *)anIdentifier
{
	return [_templateItems objectForKey: anIdentifier];
}

- (ETLayoutItem *) textFieldTemplateItem
{
	ETLayoutItem *item = [_itemFactory textField];
	[item setWidth: 300];
	return item;
}

- (void) registerDefaultTemplateItems
{
	[self setTemplateItem: [_itemFactory checkBox] forIdentifier: @"checkBox"];
	[self setTemplateItem: [self textFieldTemplateItem] forIdentifier: @"textField"];
	[self setTemplateItem: [_itemFactory horizontalSlider] forIdentifier: @"slider"];
	// TODO: Implement -textFieldAndStepper first
	//[self setTemplateItem: [_itemFactory textFieldAndStepper] forIdentifier: @"stepper"];
}

- (void) setTemplateIdentifier: (NSString *)anIdentifier forRoleClass: (Class)aClass
{
	[_additionalTemplateIdentifiers setObject: anIdentifier forKey: [aClass className]];
}

- (NSString *) templateIdentifierForRoleClass: (Class)aClass
{
	return [_additionalTemplateIdentifiers objectForKey: [aClass className]];
}

- (void) registerDefaultRoleTemplateIdentifiers
{
	[self setTemplateIdentifier: @"slider" forRoleClass: [ETNumberRole class]];
	[self setTemplateIdentifier: @"popUpMenu" forRoleClass: [ETMultiOptionsRole class]];
}

- (ETEntityDescription *) entityDescriptionForObject: (id)anObject
{
	return [[self repository] entityDescriptionForClass: [anObject class]];
}

- (id) renderObject: (id)anObject
{
	return [self renderObject: anObject entityDescription: [self entityDescriptionForObject: anObject]];
}

- (NSRect) defaultFrameForEntityItem
{
	return NSMakeRect(0, 0, 500, 600);
}

- (ETFormLayout *) defaultFormLayout
{
	ETFormLayout *layout = [ETFormLayout layout];
	return layout;
}

- (ETLayoutItemGroup *)entityItemWithRepresentedObject: (id)anObject
{
	ETLayoutItemGroup *item = [[ETLayoutItemFactory factory] itemGroupWithFrame: [self defaultFrameForEntityItem]];

	[item setLayout: [self defaultFormLayout]];
	[item setIdentifier: @"entity"];
	[item setRepresentedObject: anObject];

	return item;
}

/** To render a subset of the property descriptions, just call 
-renderObject:propertyDescriptions: directly. */
- (id) renderObject: (id)anObject entityDescription: (ETEntityDescription *)anEntityDesc
  
{
	ETLayoutItemGroup *entityItem = [self entityItemWithRepresentedObject: anObject];
	
	for (ETPropertyDescription *description in [anEntityDesc allPropertyDescriptions])
	{
		//if ([description isMultivalued] == NO || [description isRelationship] == NO)
		//	continue;

		[entityItem addItem: [self renderObject: anObject propertyDescription: description]];
	}
	[entityItem setName: [anEntityDesc name]];
	
	return entityItem;
}

- (id) renderObject: (id)anObject propertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	ETLayoutItem *item = nil;
	
	if ([aPropertyDesc isRelationship])
	{
		item = [self newItemForRelationshipDescription: aPropertyDesc ofObject: anObject];
	}
	else
	{
		item = [self newItemForAttributeDescription: aPropertyDesc ofObject: anObject];
	}
	[item setName: [aPropertyDesc name]];

	return item;
}

- (id) renderPropertyDescription: (ETPropertyDescription *)aDescription
{
	// TODO: we need a mapping from UTI to "layout item for editing that type"
	
	ETLayoutItem *item = [[ETLayoutItemFactory factory] textField];
	[item setName: [aDescription name]];
	return item;
}

- (BOOL) rendersRelationshipAsAttributeForPropertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	return YES;
}

- (id) representedObjectForToOneRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                               ofObject: (id)anObject
{
	// TODO: Possibility to edit the type to override the existing object
	// with a new entity/class object.
	return [NSString stringWithFormat: @"To-one Relationship (%@)", [[aPropertyDesc type] name]];
}

- (id) representedObjectForToManyRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                ofObject: (id)anObject
{
	// TODO: Provide basic alternative as an option
	//return [NSString stringWithFormat: @"To-many Relationship (%@)", [[aPropertyDesc type] name]];
	return [anObject valueForProperty: [aPropertyDesc name]];
}

- (ETLayoutItemGroup *) relationshipEditorForCollection: (id <ETCollection>)aCollection
                                               ofObject: (id)anObject
{
	NSSize size = NSMakeSize(300, 100);//[self defaultFrameForEntityItem].size;
	ETLayoutItemGroup *editor = [_itemFactory collectionEditorWithSize: size
							                         representedObject: aCollection
									                        controller: nil];
	return editor;
}

- (ETLayoutItemGroup *) newItemForRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                 ofObject: (id)anObject
{
	id value = [anObject valueForProperty: [aPropertyDesc name]];
	ETLayoutItemGroup *item = nil;

	if ([self rendersRelationshipAsAttributeForPropertyDescription: aPropertyDesc])
	{
		ETLayoutItem *templateItem = [self templateItemForPropertyDescription: aPropertyDesc];
		BOOL isToManyRelationship = [aPropertyDesc isMultivalued];
		id repObject = nil;

		if (isToManyRelationship)
		{
			repObject = [self representedObjectForToManyRelationshipDescription: aPropertyDesc ofObject: anObject];
			item = [self relationshipEditorForCollection: repObject ofObject: anObject];
		}
		else
		{
			repObject = [self representedObjectForToOneRelationshipDescription: aPropertyDesc ofObject: anObject];
			item = AUTORELEASE([templateItem copy]);
			[item setRepresentedObject: repObject];
		}
		return item;
	}
	
	if (value != nil)
	{
		item = [self renderObject: value];
	}
	else
	{
		item = [self renderObject: value entityDescription: [aPropertyDesc type]];
	}
	return item;
}

- (NSString *) templateIdentifierForPropertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	NSString *templateId = [aPropertyDesc itemIdentifier];

	if (templateId != nil)
		return templateId;

	return [self templateIdentifierForRoleClass: [[aPropertyDesc role] class]];
}

- (BOOL)isBooleanType: (ETEntityDescription *)aType
{
	NSParameterAssert(aType != nil);
	// FIXME: Should use [_repository descriptionForName: @"Boolean"]
	return [aType isEqual: [_repository descriptionForName: @"BOOL"]];
}

- (ETLayoutItem *) templateItemForPropertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	ETLayoutItem *templateItem = [self templateItemForIdentifier:
		[self templateIdentifierForPropertyDescription: aPropertyDesc]];

	if (templateItem != nil)
		return templateItem;

	if ([self isBooleanType: [aPropertyDesc type]])
	{
		return [self templateItemForIdentifier: @"checkBox"];
	}
	else
	{
		return [self templateItemForIdentifier: @"textField"];
	}
}

- (ETLayoutItem *) newItemForAttributeDescription: (ETPropertyDescription *)aPropertyDesc ofObject: (id)anObject
{
	ETLayoutItem *templateItem = [self templateItemForPropertyDescription: aPropertyDesc];
	ETAssert(templateItem != nil);
	ETLayoutItem *item = AUTORELEASE([templateItem copy]);

	[item setRepresentedObject: [ETPropertyViewpoint viewpointWithName: [aPropertyDesc name]
													 representedObject: anObject]];
	return item;
}

@end


@implementation ETEntityDescription (EtoileUI)

- (void) view: (id)sender
{
	//ETLayoutItem *entityItem = [[ETModelDescriptionRenderer renderer] renderObject: self];
	ETLayoutItem *entityItem = [[ETModelDescriptionRenderer renderer] renderObject: self];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
}

@end
