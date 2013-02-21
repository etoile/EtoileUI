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
#import "ETController.h"
#import "ETTemplateItemLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
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
	ASSIGN(_entityLayout, [self defaultFormLayout]);

	[self registerDefaultTemplateItems];
	[self registerDefaultRoleTemplateIdentifiers];

	return self;
}

- (void) dealloc
{
	DESTROY(_templateItems);
	DESTROY(_repository);
	DESTROY(_itemFactory);
	DESTROY(_entityLayout);
	DESTROY(_groupingKeyPath);
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

- (void) setEntityLayout: (ETLayout *)aLayout
{
	ASSIGN(_entityLayout, aLayout);
}

- (ETLayout *) entityLayout
{
	return _entityLayout;
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

	// TODO: Finish to implement ETTemplateItemLayout and ETFormLayout copy
	//[item setLayout: [[[self entityLayout] copy] autorelease]];
	[item setLayout: [self defaultFormLayout]];
	[item setIdentifier: @"entity"];
	[item setRepresentedObject: anObject];
	//[item setController: [[ETEntityInspectorController new] autorelease]];
	//[item setShouldMutateRepresentedObject: NO];

	return item;
}

- (void) setGroupingKeyPath: (NSString *)aKeyPath
{
	ASSIGN(_groupingKeyPath, aKeyPath);
}

- (NSString *) groupingKeyPath
{
	return _groupingKeyPath;
}

- (ETLayoutItemGroup *)newItemGroupForGroupingName: (NSString *)aName
{
	ETLayoutItemGroup *itemGroup = [[_itemFactory itemGroup] retain];
	[itemGroup setName: aName];
	return itemGroup;
}

- (ETPropertyDescription *)propertyDescriptionForItem: (ETLayoutItem *)aPropertyItem
{
	id repObject = [aPropertyItem representedObject];
	ETPropertyDescription *propertyDesc = repObject;

	if ([repObject isKindOfClass: [ETPropertyViewpoint class]])
	{
		ETEntityDescription *entityDesc = [self entityDescriptionForObject: [repObject representedObject]];
		propertyDesc = [entityDesc propertyDescriptionForName: [repObject name]];
	}
	
	if ([propertyDesc isKindOfClass: [ETPropertyDescription class]] == NO)
	{
		return nil;
	}
	return propertyDesc;
}

// TODO: Add a mechanism to return a display name for a grouping value either
// to the metamodel (e.g. ETPropertyDescription) or to ETModelDescriptionRenderer
// through registered blocks per value class.
- (NSString *)displayNameForGroupingValue: (id)aGroupingValue
{
	if ([aGroupingValue isEntityDescription])
	{
		// TODO: Support returning the full name too
		return [[_repository classForEntityDescription: aGroupingValue] displayName];
	}
	return [aGroupingValue displayName];
}

- (NSArray *) generateItemGroupsForPropertyItems: (NSArray *)propertyItems
                                 groupingKeyPath: (NSString *)aKeyPath
{
	NILARG_EXCEPTION_TEST(aKeyPath);
	// FIXME: Use a ordered NSMutableDictionary (for now we depend on NSMapTable implicit ordering)
	NSMapTable *itemGroupsByName = [NSMapTable mapTableWithStrongToStrongObjects];
	
	for (ETLayoutItem *item in propertyItems)
	{
		ETPropertyDescription *propertyDesc = [self propertyDescriptionForItem: item];

		if (propertyDesc == nil)
			continue;

		NSString *name = [self displayNameForGroupingValue: [propertyDesc valueForKeyPath: aKeyPath]];

		if ([itemGroupsByName objectForKey: name] == nil)
		{
			[itemGroupsByName setObject: [[self newItemGroupForGroupingName: name] autorelease]
			                     forKey: name];
		}

		[(ETLayoutItemGroup *)[itemGroupsByName objectForKey: name] addItem: item];
	}
	return [itemGroupsByName allValues];
}

/** To render a subset of the property descriptions, just call 
-renderObject:propertyDescriptions: directly. */
- (id) renderObject: (id)anObject entityDescription: (ETEntityDescription *)anEntityDesc
  
{
	ETLayoutItemGroup *entityItem = [self entityItemWithRepresentedObject: anObject];
	NSMutableArray *propertyItems = [NSMutableArray array];

	for (ETPropertyDescription *description in [anEntityDesc allPropertyDescriptions])
	{
		//if ([description isMultivalued] == NO || [description isRelationship] == NO)
		//	continue;

		[propertyItems addObject: [self renderObject: anObject propertyDescription: description]];
	}

	NSArray *items = propertyItems;

	if ([self groupingKeyPath] != nil)
	{
		items = [self generateItemGroupsForPropertyItems: propertyItems
		                                 groupingKeyPath: [self groupingKeyPath]];
	}
	[entityItem addItems: items];
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
	ETPropertyCollectionController *controller = [[ETPropertyCollectionController new] autorelease];
	ETLayoutItemGroup *editor = [_itemFactory collectionEditorWithSize: size
							                         representedObject: aCollection
									                        controller: controller];
	[editor setDoubleAction: @selector(edit:)];
	[editor setTarget: controller];

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

- (BOOL) isTextItem: (ETLayoutItem *)anItem
{
	// TODO: Move to ETLayoutItemFactory or ETLayoutItem
	return ([[anItem view] isKindOfClass: [NSTextField class]] || [[anItem view] isKindOfClass: [NSTextView class]]);
}

- (void) prepareViewOfNewItem: (ETLayoutItem *)item forAttributeDescription: (ETPropertyDescription *)aPropertyDesc
{
	[[[item view] ifResponds] setEditable: ([aPropertyDesc isReadOnly] == NO)];
	if ([self isTextItem: item])
	{
		[[[item view] ifResponds] setSelectable: YES];
		// FIXME: On Mac OS X, resigning the first responder status in a cell
		// that is selectable causes -setStringValue: on the cell to be called
		// even in case -isEditable is NO.
		// A possible workaround is to check whether the old value is the same
		// than the new value for the KVO poster or observer (see NSCell+Etoile
		// and ETLayoutItem)
		[[[item view] ifResponds] setEnabled: ([aPropertyDesc isReadOnly] == NO)];
	}
	else
	{
		[[[item view] ifResponds] setEnabled: ([aPropertyDesc isReadOnly] == NO)];
	}
}

- (ETLayoutItem *) newItemForAttributeDescription: (ETPropertyDescription *)aPropertyDesc ofObject: (id)anObject
{
	ETLayoutItem *templateItem = [self templateItemForPropertyDescription: aPropertyDesc];
	ETAssert(templateItem != nil);
	ETLayoutItem *item = AUTORELEASE([templateItem copy]);

	[item setRepresentedObject: [ETPropertyViewpoint viewpointWithName: [aPropertyDesc name]
													 representedObject: anObject]];

	[self prepareViewOfNewItem: item forAttributeDescription: aPropertyDesc];

	return item;
}

@end


@implementation ETEntityDescription (EtoileUI)

- (ETOutlineLayout *)defaultOutlineLayoutForInspector
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];

	[layout setDisplayedProperties: A(kETIconProperty, kETDisplayNameProperty, kETValueProperty)];
	[[layout columnForProperty: kETDisplayNameProperty] setWidth: 250];
	[[layout columnForProperty: kETValueProperty] setWidth: 250];

	return layout;
}

- (void) view: (id)sender
{
	//ETLayoutItem *entityItem = [[ETModelDescriptionRenderer renderer] renderObject: self];
	ETLayoutItem *entityItem = [[ETModelDescriptionRenderer renderer] renderObject: self];
	//[entityItem setLayout: [self defaultOutlineLayoutForInspector]];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
}

@end

@implementation ETPropertyCollectionController

- (IBAction) edit: (id)sender
{
	ETLayoutItem *item = [sender doubleClickedItem];
	ETLayoutItemGroup *entityItem = [[ETModelDescriptionRenderer renderer] renderObject: [item representedObject]];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
}

@end
