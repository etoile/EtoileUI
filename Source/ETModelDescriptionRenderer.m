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
#import <EtoileFoundation/NSString+Etoile.h>
#import "ETModelDescriptionRenderer.h"
#import "ETColumnLayout.h"
#import "ETController.h"
#import "ETFormLayout.h"
#import "ETItemTemplate.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "EtoileUIProperties.h"
#import "ETTitleBarItem.h"
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
	DESTROY(_renderedPropertyNames);
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

/** Returns all the template items.

This can be used to customize properties on multiple template items at the same 
time. For example:
 
<example>
[[renderer templateItems] mappedCollection] setWidth: 150];
</example> */
- (NSArray *) templateItems
{
	return [_templateItems allValues];
}

- (NSSize) defaultItemSize
{
	return NSMakeSize(300, 100);
}

- (ETLayoutItem *) textFieldTemplateItem
{
	ETLayoutItem *item = [_itemFactory textField];
	[item setWidth: [self defaultItemSize].width];
	return item;
}

- (ETLayoutItemGroup *) collectionEditorTemplateItem
{
	ETLayoutItemGroup *editor = [_itemFactory collectionEditorWithSize: [self defaultItemSize]
							                         representedObject: nil
									                        controller: nil];
	return editor;
}

- (ETLayoutItem *) numberPickerTemplateItem
{
	ETLayoutItem *item = [_itemFactory numberPicker];
	[item setWidth: [self defaultItemSize].width];
	return item;
}

- (ETLayoutItem *) popUpMenuTemplateItem
{
	ETLayoutItem *item = [_itemFactory popUpMenu];
	[item setWidth: [self defaultItemSize].width];
	return item;
}

- (void) registerDefaultTemplateItems
{
	[self setTemplateItem: [_itemFactory checkBox] forIdentifier: @"checkBox"];
	[self setTemplateItem: [self textFieldTemplateItem] forIdentifier: @"textField"];
	[self setTemplateItem: [_itemFactory horizontalSlider] forIdentifier: @"slider"];
	[self setTemplateItem: [self numberPickerTemplateItem] forIdentifier: @"numberPicker"];
	[self setTemplateItem: [self popUpMenuTemplateItem] forIdentifier: @"popUpMenu"];
	[self setTemplateItem: [self collectionEditorTemplateItem] forIdentifier: @"collectionEditor"];
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
	[self setTemplateIdentifier: @"numberPicker" forRoleClass: [ETNumberRole class]];
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

- (void) setEntityItemFrame: (NSRect)aRect
{
	_entityItemFrame = aRect;
}

- (NSRect) entityItemFrame
{
	return _entityItemFrame;
}

- (BOOL) autoresizesEntityItem
{
	return NSIsEmptyRect([self entityItemFrame]);
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
	return [ETFormLayout layout];
}

- (ETLayoutItemGroup *)entityItemWithRepresentedObject: (id)anObject
{
	NSRect itemFrame = [self entityItemFrame];

	if (NSIsEmptyRect(itemFrame))
	{
		itemFrame = [self defaultFrameForEntityItem];
	}
	ETLayoutItemGroup *item = [[ETLayoutItemFactory factory] itemGroupWithFrame: itemFrame];

	[item setLayout: [[[self entityLayout] copy] autorelease]];
	[item setIdentifier: @"entity"];
	[item setRepresentedObject: anObject];
	//[item setController: [[ETEntityInspectorController new] autorelease]];
	//[item setShouldMutateRepresentedObject: NO];

	return item;
}

/** Returns the names of the property descriptions to render for an object 
passed to -renderObject: and related methods.
 
See also -renderedPropertyNames. */
- (void) setRenderedPropertyNames: (NSArray *)propertyNames
{
	ASSIGNCOPY(_renderedPropertyNames, propertyNames);
}

/** Returns the names of the property descriptions to render for an object 
passed to -renderObject: and related methods.

If an empty an array is returned, no property descriptions is rendered.
 
If nil is returned, all the property descriptions bound the entity description 
of the object are rendered
 
By default, returns nil. 
 
See also -setRenderedPropertyNames:. */
- (NSArray *) renderedPropertyNames
{
	return _renderedPropertyNames;
}

- (void) setGroupingKeyPath: (NSString *)aKeyPath
{
	ASSIGN(_groupingKeyPath, aKeyPath);
}

- (NSString *) groupingKeyPath
{
	return _groupingKeyPath;
}

- (ETLayoutItemGroup *)newItemGroupForGroupingName: (NSString *)aName width: (CGFloat)aWidth
{
	ETLayoutItemGroup *itemGroup = [[_itemFactory itemGroupWithSize: NSMakeSize(aWidth, 150)] retain];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setName: aName];
	[itemGroup setIdentifier: [[aName lowercaseString] stringByAppendingString: @" (grouping)"]];
	[itemGroup setLayout: [[[self entityLayout] copy] autorelease]];
	// TODO: Surely declare -setIsContentSizeLayout in ETPositionalLayout protocol
	[(ETLayout *)[[itemGroup layout] positionalLayout] setIsContentSizeLayout: _usesContentSizeLayout];
	//[itemGroup setUsesLayoutBasedFrame: YES];
	[itemGroup setDecoratorItem: [ETTitleBarItem item]];
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
                                        maxWidth: (CGFloat)anItemWidth
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
			[itemGroupsByName setObject: [[self newItemGroupForGroupingName: name width: anItemWidth] autorelease]
			                     forKey: name];
		}

		[(ETLayoutItemGroup *)[itemGroupsByName objectForKey: name] addItem: item];
	}
	return [itemGroupsByName allValues];
}

- (ETLayout *) groupingLayout
{
	ETColumnLayout *layout = [ETColumnLayout layout];
	[layout setUsesAlignmentHint: YES];
	[layout setIsContentSizeLayout: _usesContentSizeLayout];
	return layout;
}

- (NSString *) labelForPropertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	return [[[aPropertyDesc name] stringByCapitalizingFirstLetter] stringBySpacingCapitalizedWords];
}

- (NSArray *) renderedPropertyDescriptionsForEntityDescription: (ETEntityDescription *)anEntityDesc
{
	if ([self renderedPropertyNames] == nil)
		return [anEntityDesc allPropertyDescriptions];

	NSMutableArray *propertyDescs = [NSMutableArray array];
	
	for (NSString *property in [self renderedPropertyNames])
	{
		[propertyDescs addObject: [anEntityDesc propertyDescriptionForName: property]];
	}
	return propertyDescs;
}

/** To render a subset of the property descriptions, just call 
-renderObject:displayName:propertyDescriptions: directly. */
- (id) renderObject: (id)anObject entityDescription: (ETEntityDescription *)anEntityDesc
{
	NSArray *propertyDescs = [self renderedPropertyDescriptionsForEntityDescription: anEntityDesc];
	return [self renderObject: anObject displayName: [anEntityDesc name] propertyDescriptions: propertyDescs];
}

- (id) renderObject: (id)anObject displayName: (NSString *)aName propertyDescriptions: (NSArray *)propertyDescs
{
	ETLayoutItemGroup *entityItem = [self entityItemWithRepresentedObject: anObject];
	NSMutableArray *propertyItems = [NSMutableArray array];

	for (ETPropertyDescription *description in propertyDescs)
	{
		//if ([description isMultivalued] == NO || [description isRelationship] == NO)
		//	continue;

		[propertyItems addObject: [self renderObject: anObject propertyDescription: description]];
	}

	NSArray *items = propertyItems;

	if ([self groupingKeyPath] != nil)
	{
		items = [self generateItemGroupsForPropertyItems: propertyItems
		                                 groupingKeyPath: [self groupingKeyPath]
		                                        maxWidth: [entityItem width]];
		[entityItem setLayout: [self groupingLayout]];
		[entityItem setUsesLayoutBasedFrame: YES];
	}
	[entityItem addItems: items];
	[entityItem setName: aName];
	
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
	[item setName: [self labelForPropertyDescription: aPropertyDesc]];

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

#ifdef AVOID_COLLECTION_EDITOR_TEMPLATE_COPY
- (ETLayoutItemGroup *) editorForRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                ofObject: (id)anObject
{
	id collection = [self representedObjectForToManyRelationshipDescription: aPropertyDesc
	                                                               ofObject: anObject];
	Class relationshipClass = [_repository classForEntityDescription: [aPropertyDesc type]];
	ETAssert(relationshipClass != Nil);
	ETItemTemplate *template = [ETItemTemplate templateWithItem: [_itemFactory item]
	                                                objectClass: relationshipClass];
	ETPropertyCollectionController *controller = [[ETPropertyCollectionController new] autorelease];
	
	[controller setTemplate: template forType: [controller currentObjectType]];

	ETLayoutItemGroup *editor = [_itemFactory collectionEditorWithSize: [self defaultItemSize]
							                         representedObject: collection
									                        controller: controller];

	[[controller content] setDoubleAction: @selector(edit:)];
	[[controller content] setTarget: controller];

	return editor;
}
#else
- (ETLayoutItemGroup *) editorForRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                ofObject: (id)anObject
{

	ETLayoutItemGroup *editor = [[self templateItemForIdentifier: @"collectionEditor"] deepCopy];
	ETLayoutItemGroup *browser = (id)[editor itemForIdentifier: @"browser"];
	id collection = [self representedObjectForToManyRelationshipDescription: aPropertyDesc
	                                                               ofObject: anObject];

	[browser setRepresentedObject: collection];

	ETPropertyCollectionController *controller = (id)[browser controller];
	Class relationshipClass = [_repository classForEntityDescription: [aPropertyDesc type]];
	ETAssert(relationshipClass != Nil);
	ETItemTemplate *template = [ETItemTemplate templateWithItem: [_itemFactory item]
	                                                objectClass: relationshipClass];

	[controller setTemplate: template forType: [controller currentObjectType]];

	[[controller content] setDoubleAction: @selector(edit:)];
	[[controller content] setTarget: controller];

	return editor;
}
#endif

- (ETLayoutItemGroup *) newItemForRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                 ofObject: (id)anObject
{
	id value = [anObject valueForProperty: [aPropertyDesc name]];
	ETLayoutItemGroup *item = nil;

	if ([self rendersRelationshipAsAttributeForPropertyDescription: aPropertyDesc])
	{
		ETLayoutItem *templateItem = [self templateItemForPropertyDescription: aPropertyDesc];
		BOOL isToManyRelationship = [aPropertyDesc isMultivalued];

		if (isToManyRelationship)
		{

			item = [self editorForRelationshipDescription: aPropertyDesc ofObject: anObject];
		}
		else
		{
			id repObject = [self representedObjectForToOneRelationshipDescription: aPropertyDesc ofObject: anObject];
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

- (BOOL)isNumberType: (ETEntityDescription *)aType
{
	return [S(@"NSInteger", @"NSUInteger", @"float", @"CGFloat") containsObject: [aType name]];
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
	else if ([self isNumberType: [aPropertyDesc type]])
	{
		return [self templateItemForIdentifier: @"numberPicker"];
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

- (BOOL) isPopUpMenuItem: (ETLayoutItem *)anItem
{
	// TODO: Move to ETLayoutItemFactory or ETLayoutItem
	return ([[anItem view] isKindOfClass: [NSPopUpButton class]]);
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
	else if ([self isPopUpMenuItem: item])
	{
		NSArray *options = [[aPropertyDesc role] allowedOptions];
		NSArray *entryTitles = (id)[[options mappedCollection] key];
		NSArray *entryModels = (id)[[options mappedCollection] value];
		NSPopUpButton *popUpView = [item view];

		// TODO: Pop up set up to be removed once ETPopUpMenuLayout is available
		[popUpView addItemsWithTitles: entryTitles];
		
		for (int i = 0; i < [popUpView numberOfItems] && i < [entryModels count]; i++)
		{
			id repObject = [entryModels objectAtIndex: i];
			
			if ([repObject isEqual: [NSNull null]])
			{
				repObject = nil;
			}
			[[popUpView itemAtIndex: i] setRepresentedObject: repObject];
		}

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
	ETModelDescriptionRenderer *renderer = [ETModelDescriptionRenderer renderer];

	[renderer setGroupingKeyPath: @"owner"];

	[ETLayoutItem disablesAutolayout];

	ETLayoutItemGroup *entityItem = [renderer renderObject: self];

	[[entityItem layout] setAutoresizesItemToFill: YES];
	[(id)[entityItem itemAtIndex: 0] updateLayoutRecursively: NO];
	[(id)[entityItem itemAtIndex: 1] updateLayoutRecursively: NO];
	[entityItem updateLayoutRecursively: NO];

	//[entityItem setLayout: [self defaultOutlineLayoutForInspector]];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
	
	[ETLayoutItem enablesAutolayout];
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
