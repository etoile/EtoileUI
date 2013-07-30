/*
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETPropertyDescription.h>
#import <EtoileFoundation/ETUnionViewpoint.h>
#import <EtoileFoundation/ETViewpoint.h>
#import <EtoileFoundation/ETModelElementDescription.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import <EtoileFoundation/NSObject+DoubleDispatch.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSString+Etoile.h>
#import "ETModelDescriptionRenderer.h"
#import "ETColumnLayout.h"
#import "ETController.h"
#import "ETFormLayout.h"
#import "ETGeometry.h"
#import "ETItemTemplate.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETPositionalLayout.h"
#import "ETModelBuilderUI.h" // FIXME: Remove
#import "ETObjectValueFormatter.h"
#import "EtoileUIProperties.h"
#import "ETTitleBarItem.h"
#import "ETOutlineLayout.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

@interface ETPopUpButtonTarget : NSObject
+ (id) sharedInstance;
@end

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
	_formattersByType = [NSMutableDictionary new];
	_valueTransformersByType = [NSMutableDictionary new];
	ASSIGN(_repository, [ETModelDescriptionRepository mainRepository]);
	ASSIGN(_itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(_entityLayout, [self defaultFormLayout]);
	/* See -setRendererPropertyNames: */
	_renderedPropertyNames = nil;
	_itemSize = [self defaultItemSize];

	[self registerDefaultTemplateItems];
	[self registerDefaultRoleTemplateIdentifiers];
	[self registerDefaultFormatters];

	return self;
}

- (void) dealloc
{
	DESTROY(_templateItems);
	DESTROY(_repository);
	DESTROY(_itemFactory);
	DESTROY(_formattersByType);
	DESTROY(_valueTransformersByType);
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

- (id) templateItemForIdentifier: (NSString *)anIdentifier
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
	// TODO: Perhaps support returning a derived item size
	//NSRect itemFrame = [self validFrameForEntityItem];
	//return NSMakeSize(itemFrame.size.width - 300, 100);
	return NSMakeSize(300, 100);
}

- (void) setItemSize: (NSSize)aSize
{
	_itemSize = aSize;
	[(ETLayoutItem *)[[self templateItems] mappedCollection] setWidth: [self itemSize].width];
}

- (NSSize) itemSize
{
	return _itemSize;
}

- (ETLayoutItem *) textFieldTemplateItem
{
	ETLayoutItem *item = [_itemFactory textField];
	[item setWidth: [self itemSize].width];
	[[[[item view] cell] ifResponds] setPlaceholderString: @"Nil"];
	return item;
}

- (ETLayoutItemGroup *) collectionEditorTemplateItem
{
	ETPropertyCollectionController *controller =
		AUTORELEASE([ETPropertyCollectionController new]);
	ETLayoutItemGroup *editor = [_itemFactory collectionEditorWithSize: [self defaultItemSize]
							                         representedObject: [NSArray array]
									                        controller: controller];
	NSFont *smallFont = [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]];
	[[[[editor itemForIdentifier: @"browser"] layout] ifResponds] setContentFont: smallFont];
	return editor;
}

- (ETLayoutItem *) numberPickerTemplateItem
{
	ETLayoutItem *item = [_itemFactory numberPicker];
	[item setWidth: [self itemSize].width];
	return item;
}

- (ETLayoutItem *) pointEditorTemplateItem
{
	ETLayoutItem *item = [_itemFactory pointEditorWithWidth: [self itemSize].width forXProperty: nil yProperty: nil ofModel: nil];
	return item;
}

- (ETLayoutItem *) sizeEditorTemplateItem
{
	ETLayoutItem *item = [_itemFactory sizeEditorWithWidth: [self itemSize].width forWidthProperty: nil heightProperty: nil ofModel: nil];
	return item;
}

- (ETLayoutItem *) rectEditorTemplateItem
{
	ETLayoutItem *pointEditor = [self pointEditorTemplateItem];
	ETLayoutItem *sizeEditor = [self sizeEditorTemplateItem];
	NSSize size = NSMakeSize([self itemSize].width,
		[pointEditor height] + [sizeEditor height]);
	ETLayoutItemGroup *editor = [_itemFactory itemGroupWithSize: size];

	[editor setIdentifier: @"rectEditor"];
	[editor setLayout: [ETColumnLayout layoutWithObjectGraphContext: [editor objectGraphContext]]];
	[editor addItems: A(pointEditor, sizeEditor)];

	return editor;
}

- (ETLayoutItem *) popUpMenuTemplateItem
{
	ETLayoutItem *item = [_itemFactory popUpMenu];
	[item setWidth: [self itemSize].width];
	return item;
}

- (void) registerDefaultTemplateItems
{
	[self setTemplateItem: [_itemFactory checkBox] forIdentifier: @"checkBox"];
	[self setTemplateItem: [self textFieldTemplateItem] forIdentifier: @"textField"];
	[self setTemplateItem: [_itemFactory horizontalSlider] forIdentifier: @"slider"];
	[self setTemplateItem: [self numberPickerTemplateItem] forIdentifier: @"numberPicker"];
	[self setTemplateItem: [self pointEditorTemplateItem] forIdentifier: @"pointEditor"];
	[self setTemplateItem: [self sizeEditorTemplateItem] forIdentifier: @"sizeEditor"];
	[self setTemplateItem: [self rectEditorTemplateItem] forIdentifier: @"rectEditor"];
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

- (void) registerDefaultFormatters
{
	NSArray *numberTypeNames = A(@"NSNumber", @"NSInteger", @"NSUInteger",
		@"CGFloat", @"double", @"BOOL", @"Boolean", @"Number");

	[self setFormatter: AUTORELEASE([ETObjectValueFormatter new])
	           forType: [_repository descriptionForName: @"Object"]];

	for (NSString *typeName in numberTypeNames)
	{
		[self setFormatter: AUTORELEASE([NSNumberFormatter new])
		           forType: [_repository descriptionForName: typeName]];
	}
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

	// TODO: We should support something similar to the code below.
	// Perhaps add a delegate method -renderer:itemSizeForEntityItemFrame:, or
	// tell the user he can override this method in this way.
	//CGFloat newItemWidth = [self itemSize].width;
	//[(ETLayoutItem *)[[self templateItems] mappedCollection] setWidth: newItemWidth];
}

- (NSRect) entityItemFrame
{
	return _entityItemFrame;
}

- (BOOL) usesContentSizeLayout
{
	return _usesContentSizeLayout;
}

- (void) setUsesContentSizeLayout: (BOOL)isContentSizeLayout
{
	_usesContentSizeLayout = isContentSizeLayout;
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

- (NSRect) validFrameForEntityItem
{
	NSRect itemFrame = [self entityItemFrame];
	
	if (NSIsEmptyRect(itemFrame))
	{
		itemFrame = [self defaultFrameForEntityItem];
	}
	return itemFrame;
}

- (ETFormLayout *) defaultFormLayout
{
	return [ETFormLayout layoutWithObjectGraphContext: nil];
}

- (id) prepareEntityLayout: (ETLayout *)aLayout
{
	// TODO: Should use -isContentSizeLayout instead of just YES
	[[aLayout positionalLayout] setIsContentSizeLayout: YES];
	return aLayout;
}

- (ETLayoutItemGroup *)entityItemWithRepresentedObject: (id)anObject
{
	NSRect itemFrame = [self validFrameForEntityItem];
	ETLayoutItemGroup *item = [[ETLayoutItemFactory factory] itemGroupWithFrame: itemFrame];
	ETAssert(NSEqualRects([item frame], itemFrame));

	[item setLayout: [self prepareEntityLayout: [[[self entityLayout] copy] autorelease]]];
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
	NSParameterAssert(aName != nil);
	ETLayoutItemGroup *itemGroup = [[_itemFactory itemGroupWithSize: NSMakeSize(aWidth, 1000)] retain];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setName: aName];
	[itemGroup setIdentifier: [[aName lowercaseString] stringByAppendingString: @" (grouping)"]];
	[itemGroup setLayout: [self prepareEntityLayout: [[[self entityLayout] copy] autorelease]]];
	[itemGroup setDecoratorItem: [ETTitleBarItem item]];
	return itemGroup;
}

// TODO: Add a mechanism to return a display name for a grouping value either
// to the metamodel (e.g. ETPropertyDescription) or to ETModelDescriptionRenderer
// through registered blocks per value class.
- (NSString *)displayNameForGroupingValue: (id)aGroupingValue
{
	NSParameterAssert(aGroupingValue != nil);

	if ([aGroupingValue isEntityDescription])
	{
		// TODO: Support returning the full name too
		return [[_repository classForEntityDescription: aGroupingValue] displayName];
	}
	return [aGroupingValue displayName];
}

- (NSArray *) generateItemGroupsForPropertyItems: (NSArray *)propertyItems
                            propertyDescriptions: (NSArray *)propertyDescs
                                 groupingKeyPath: (NSString *)aKeyPath
                                        maxWidth: (CGFloat)anItemWidth
{
	NILARG_EXCEPTION_TEST(aKeyPath);
	NSParameterAssert([propertyItems count] == [propertyDescs count]);
	NSMutableDictionary *itemGroupsByName = [NSMutableDictionary dictionary];
	/* To ensure the grouping section ordering respect the property item ordering */
	NSMutableArray *groupNames = [NSMutableArray array];

	[propertyItems enumerateObjectsUsingBlock: ^ (id item, NSUInteger i, BOOL *stop)
	{
		id groupingValue = [[propertyDescs objectAtIndex: i] valueForKeyPath: aKeyPath];
		NSString *name = [self displayNameForGroupingValue: groupingValue];
		ETLayoutItemGroup *itemGroup = [itemGroupsByName objectForKey: name];

		if (itemGroup == nil)
		{
			itemGroup = [[self newItemGroupForGroupingName: name width: anItemWidth] autorelease];

			[itemGroupsByName setObject: itemGroup forKey: name];
			[groupNames addObject: name];
		}
		[itemGroup addItem: item];
	}];
	
	NSLog(@"Old size %@", NSStringFromSize([[[itemGroupsByName allValues] firstObject] size]));
	[[[itemGroupsByName allValues] mappedCollection] updateLayoutRecursively: YES];
	NSLog(@"New size %@", NSStringFromSize([[[itemGroupsByName allValues] firstObject] size]));

	for (NSString *name in groupNames)
	{
		ETLayoutItemGroup *itemGroup = [itemGroupsByName objectForKey: name];

		[[[itemGroup layout] positionalLayout] setIsContentSizeLayout: NO];
		[itemGroup setWidth: anItemWidth];
	}

	return [itemGroupsByName objectsForKeys: groupNames notFoundMarker: [NSNull null]];
}

- (ETLayout *) groupingLayout
{
	ETColumnLayout *layout = [ETColumnLayout layoutWithObjectGraphContext: nil];
	[layout setUsesAlignmentHint: YES];
	// TODO: Should use -isContentSizeLayout instead of just YES
	[layout setIsContentSizeLayout: YES];
	return layout;
}

- (NSFormatter *) formatterForType: (ETEntityDescription *)aType
{
	ETEntityDescription *type = aType;
	NSFormatter *formatter = nil;
	
	do
	{
		formatter = [_formattersByType objectForKey: [aType name]];
	}
	while ((type = [type parent]) != nil);

	return formatter;
}

- (void) setFormatter: (NSFormatter *)aFormatter forType: (ETEntityDescription *)aType
{
	[_formattersByType setObject: aFormatter forKey: [aType name]];
}

- (ETItemValueTransformer *) valueTransformerForType: (ETEntityDescription *)aType
{
	ETEntityDescription *type = aType;
	ETItemValueTransformer *transformer = nil;
	
	do
	{
		transformer = [_valueTransformersByType objectForKey: [aType name]];
	}
	while ((type = [type parent]) != nil);

	return transformer;
}

- (void) setValueTransformer: (ETItemValueTransformer *)aTransformer
                     forType: (ETEntityDescription *)aType
{
	[_valueTransformersByType setObject: aTransformer forKey: [aType name]];
}

- (NSString *) labelForPropertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	return [aPropertyDesc displayName];
}

- (NSArray *) renderedPropertyDescriptionsForEntityDescription: (ETEntityDescription *)anEntityDesc
{
	NSArray *propertyNames = [self renderedPropertyNames];

	if (propertyNames == nil)
		return [anEntityDesc allPropertyDescriptions];

	NSMutableArray *propertyDescs = [NSMutableArray array];
	
	for (NSString *property in propertyNames)
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
		                            propertyDescriptions: propertyDescs
		                                 groupingKeyPath: [self groupingKeyPath]
		                                        maxWidth: [entityItem width]];
		[entityItem setLayout: [self groupingLayout]];
	}

	NSRect entityItemFrame = [entityItem frame];

	[entityItem addItems: items];

	/* If -groupingLayout or -entityLayout returns YES for -isContentSizeLayout, 
	   this layout update resizes the entity item to enclose its content.
	   This is needed until we can apply -isContentSizeLayout to the height 
	   without touching the width. */
	[entityItem updateLayoutRecursively: YES];
	/* At this point, if -isContentSizeLayout was YES but -usesContentSizeLayout 
	   is NO, it means we just wanted to adjust the height to the content size. */
	if ([self usesContentSizeLayout] == NO)
	{
		/* This applies to detail view items too, but for a detail view we 
		   reset the height. For an entity item, we don't resize the height, 
		   in case we want to show a vertical scroller (see below).
		   See also -editorForRelationshipDescription:ofObject: and 
		   -rendererForItemDetailsInSize:. */
		[[[entityItem layout] positionalLayout] setIsContentSizeLayout: NO];
		[entityItem setWidth: [self entityItemFrame].size.width];
	}
	/* If we have adjusted the height and no items are clipped horizontally, 
	   all items should be visible at this point. */
	ETAssert([[entityItem visibleItems] isEqual: [entityItem items]]);

	if ([entityItem height] > entityItemFrame.size.height || ([self groupingKeyPath] != nil))
	{
		[entityItem setHasVerticalScroller: YES];
		// TODO: Should handle that more cleanly... Could use 
		//[[entityItem scrollableAreaItem] setEnsuresContentFillsVisibleArea: YES];
		[[[[entityItem scrollableAreaItem] scrollView] documentView] setAutoresizesSubviews: YES];
		[entityItem setHeight: entityItemFrame.size.height];
		[entityItem updateLayoutRecursively: YES];
	}
	if ([[entityItem layout] isComputedLayout])
	{
		// FIXME: Disable if grouping is used
		//[(ETLayoutItem *)[propertyItems mappedCollection] setAutoresizingMask: ETAutoresizingFlexibleWidth];
	}

	[entityItem setName: aName];
	
	return entityItem;
}

- (id) renderObject: (id)anObject propertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	ETLayoutItem *item = nil;

	// FIXME: Support four cases: attribute, collection/multivalued attribute,
	// to-one relationship, to-many relationship
	if ([aPropertyDesc isRelationship] || [aPropertyDesc isMultivalued])
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
	// TODO: Provide basic alternative as an option
	//return [NSString stringWithFormat: @"To-one Relationship (%@)", [[aPropertyDesc type] name]];;
	id relationshipValue =
		[ETMutableObjectViewpoint viewpointWithName: [aPropertyDesc name]representedObject: anObject];
	return relationshipValue;
}

- (id) representedObjectForToManyRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                ofObject: (id)anObject
{
	// TODO: Provide basic alternative as an option
	//return [NSString stringWithFormat: @"To-many Relationship (%@)", [[aPropertyDesc type] name]];
	// TODO: Detect dominant collection
	//return [anObject valueForProperty: [aPropertyDesc name]];
	id relationshipValue =
		[ETCollectionViewpoint viewpointWithName: [aPropertyDesc name]representedObject: anObject];
	return relationshipValue;
}

- (ETModelDescriptionRenderer *) rendererForItemDetailsInSize: (NSSize)aSize
{
	// TODO: Use -copy if possible. But this wouldn't work well for
	// -newValueTransformerRender that alters the entity item layout and the
	// collection editor size.
	ETModelDescriptionRenderer *renderer = AUTORELEASE([ETModelDescriptionRenderer new]);

	renderer->_formattersByType = [_formattersByType mutableCopy];
	[renderer setEntityItemFrame: NSMakeRect(0, 0, aSize.width, aSize.height)];
	[renderer setItemSize: NSMakeSize(aSize.width - 200, [self itemSize].height)];
	// TODO: Should use ETContentSizeLayoutVertical or similar
	//[renderer setUsesContentSizeLayout: YES];

	return renderer;
}

- (NSArray *) displayedPropertiesForRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                   ofObject: (id)anObject
{
	NSArray *properties = [aPropertyDesc detailedPropertyNames];
	return properties;
}

- (ETLayoutItemGroup *) editorForRelationshipDescription: (ETPropertyDescription *)aRelationshipDesc
                                                ofObject: (id)anObject
{
	ETLayoutItemGroup *editor = [[self templateItemForIdentifier: @"collectionEditor"] deepCopy];
	ETLayoutItemGroup *browser = (id)[editor itemForIdentifier: @"browser"];
	ETAssert(browser != nil);
	
	// NOTE:  We could add -representedObjectForToManyRelationshipDescription:ofObject:
	[browser setRepresentedObject: anObject];
	[browser setValueKey: [aRelationshipDesc name]];
	[browser reload];

	ETPropertyCollectionController *controller = (id)[browser controller];
	ETAssert(controller != nil);
	ETItemTemplate *template = [ETItemTemplate templateWithItem: [_itemFactory item]
	                                                 entityName: [[aRelationshipDesc type] name]
	                                         objectGraphContext: nil];

	[controller setTemplate: template forType: [controller currentObjectType]];
	[controller setModelDescriptionRepository: [self repository]];
	[[controller content] setDoubleAction: @selector(edit:)];
	[[controller content] setTarget: controller];

	BOOL isKeyedCollection = [[browser representedObject] isKeyed];
	BOOL isMutableCollection = [[browser representedObject] isMutableCollection];
	
	[[browser layout] setDisplayedProperties: A(@"value")];
	[[browser layout] setDisplayName: @"Value" forProperty: @"value"];
	[[browser layout] setEditable: isMutableCollection forProperty: @"value"];

	if ([aRelationshipDesc showsItemDetails])
	{
		NSSize detailedItemSize = NSMakeSize([editor width], 200);
		ETModelDescriptionRenderer *renderer =
			[self rendererForItemDetailsInSize: detailedItemSize];
		id relationshipValue = [anObject valueForProperty: [aRelationshipDesc name]];
		ETAssert([relationshipValue isCollection]);
		// TODO: Use UI Builder property names to look up
		NSArray *detailedPropertyDescs = [[aRelationshipDesc type]
			propertyDescriptionsForNames: [aRelationshipDesc detailedPropertyNames]];
		ETLayoutItemGroup *detailedItem =
			[renderer renderObject: nil displayName: nil propertyDescriptions: detailedPropertyDescs];

		/* The width has already been reset
		[detailedItem setHeight: [renderer entityItemFrame].size.height];*/
		for (ETLayoutItem *propertyItem in detailedItem)
		{
			/* -newItemForAttributeDescription:ofObject: has set a property 
			   viewpoint but without a represented object */
			NSString *propertyName = [[propertyItem representedObject] name];
			ETAssert(propertyName != nil);
			// TODO: Should be 'arrangedItems'
			ETUnionViewpoint *unionViewpoint = [ETUnionViewpoint viewpointWithName: @"selectedItemsInLayout" representedObject: browser];
	
			[unionViewpoint setContentKeyPath:
			 	[NSString stringWithFormat: @"subject.%@", propertyName]];
			[propertyItem setRepresentedObject: unionViewpoint];
		}
	
		[detailedItem setIdentifier: @"details"];
		[detailedItem setAutoresizingMask: ETAutoresizingFlexibleWidth];

		[editor addItem: detailedItem];
		[editor setHeight: [editor height] + [detailedItem height]];
	}
	else if ([[aRelationshipDesc detailedPropertyNames] isEmpty] == NO)
	{
		[[browser layout] setDisplayedProperties: [aRelationshipDesc detailedPropertyNames]];

		for (NSString *property in [[browser layout] displayedProperties])
		{
			ETPropertyDescription *propertyDesc =
				[[aRelationshipDesc type] propertyDescriptionForName: property];
			ETAssert(propertyDesc != nil);
			
			[[browser layout] setDisplayName: [propertyDesc displayName]
			                     forProperty: property];
			[[browser layout] setEditable: ([propertyDesc isReadOnly] == NO)
			                  forProperty: property];
			[[browser layout] setFormatter: [self formatterForType: [propertyDesc type]]
			                   forProperty: property];
		}
	}

	/* For a keyed-collection, the 'key' columns is always visible, if you 
	   don't want it, add a transient property to the model that returns 
	   the objects from the keyed collection e.g. [NSDictionary allValues]. */
	if (isKeyedCollection)
	{
		NSArray *properties = [[browser layout] displayedProperties];
		[[browser layout] setDisplayedProperties: [A(@"key") arrayByAddingObjectsFromArray: properties]];
		[[browser layout] setDisplayName: @"Key" forProperty: @"key"];
		[[browser layout] setEditable: isMutableCollection forProperty: @"key"];
	}

	return editor;
}

- (ETLayoutItemGroup *) newItemForRelationshipDescription: (ETPropertyDescription *)aPropertyDesc
                                                 ofObject: (id)anObject
{
	id value = [anObject valueForProperty: [aPropertyDesc name]];
	ETLayoutItemGroup *item = nil;
	ETLayoutItem *templateItem = [self templateItemForPropertyDescription: aPropertyDesc];
	BOOL isToManyRelationship = [aPropertyDesc isMultivalued];

	if (isToManyRelationship)
	{
		if ([self rendersRelationshipAsAttributeForPropertyDescription: aPropertyDesc])
		{
			item = [self editorForRelationshipDescription: aPropertyDesc ofObject: anObject];
		}
		else
		{
			/* If we have a value that is a subtype of the property description 
			   type, -renderObject: returns an editor that allows to edit all 
			   properties unlike -renderObject:entityDescription:. */
			if (value != nil)
			{
				item = [self renderObject: value];
			}
			else
			{
				item = [self renderObject: value entityDescription: [aPropertyDesc type]];
			}
		}
	}
	else
	{
		if ([self rendersRelationshipAsAttributeForPropertyDescription: aPropertyDesc])
		{
			id repObject = [self representedObjectForToOneRelationshipDescription: aPropertyDesc ofObject: anObject];
			item = AUTORELEASE([templateItem copy]);
			[item setRepresentedObject: repObject];
			ETAssert([[item valueKey] isEqual: [aPropertyDesc name]]);
			[self prepareViewOfNewItem: item forAttributeDescription: aPropertyDesc];
		}
		else
		{
			/* If we have a value that is a subtype of the property description 
			   type, -renderObject: returns an editor that allows to edit all 
			   properties unlike -renderObject:entityDescription:. */
			if (value != nil)
			{
				item = [self renderObject: value];
			}
			else
			{
				item = [self renderObject: value entityDescription: [aPropertyDesc type]];
			}
		}
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
	return [S(@"NSInteger", @"NSUInteger", @"CGFloat", @"CGFloat") containsObject: [aType name]];
}

- (BOOL)isPointType: (ETEntityDescription *)aType
{
	NSParameterAssert(aType != nil);
	return [aType isEqual: [_repository descriptionForName: @"NSPoint"]];
}

- (BOOL)isSizeType: (ETEntityDescription *)aType
{
	NSParameterAssert(aType != nil);
	return [aType isEqual: [_repository descriptionForName: @"NSSize"]];
}

- (BOOL)isRectType: (ETEntityDescription *)aType
{
	NSParameterAssert(aType != nil);
	return [aType isEqual: [_repository descriptionForName: @"NSRect"]];
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
	else if ([self isPointType: [aPropertyDesc type]])
	{
		return [self templateItemForIdentifier: @"pointEditor"];
	}
	else if ([self isSizeType: [aPropertyDesc type]])
	{
		return [self templateItemForIdentifier: @"sizeEditor"];
	}
	else if ([self isRectType: [aPropertyDesc type]])
	{
		return [self templateItemForIdentifier: @"rectEditor"];
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

- (BOOL) isPointEditorItem: (ETLayoutItem *)anItem
{
	return ([[anItem identifier] isEqual: @"pointEditor"]);
}

- (BOOL) isSizeEditorItem: (ETLayoutItem *)anItem
{
	return ([[anItem identifier] isEqual: @"sizeEditor"]);
}

- (BOOL) isRectEditorItem: (ETLayoutItem *)anItem
{
	return ([[anItem identifier] isEqual: @"rectEditor"]);
}

- (BOOL) isPopUpMenuItem: (ETLayoutItem *)anItem
{
	// TODO: Move to ETLayoutItemFactory or ETLayoutItem
	return ([[anItem view] isKindOfClass: [NSPopUpButton class]]);
}

- (void) prepareViewpointWithRepresentedObject: (id)anObject
                                        onItem: (ETLayoutItem *)item
                       forAttributeDescription: (ETPropertyDescription *)aPropertyDesc
                               scalarFieldName: (NSString *)aFieldName
{
	NSParameterAssert(anObject != nil);
	NSParameterAssert(item != nil);
	NSString *synthesizedName = [anObject synthesizeAccessorsForFieldName: aFieldName
	                                                     ofScalarProperty: [aPropertyDesc name]
	                                                                 type: [[aPropertyDesc type] name]
	                                                         inRepository: [self repository]];
	ETAssert(synthesizedName != nil);

	// TODO: Ugly -[ETLayoutItem frame] hack to remove
	if ([[aPropertyDesc name] isEqual: @"frame"])
	{
		synthesizedName = aFieldName;
	}

	[item setRepresentedObject: [ETMutableObjectViewpoint viewpointWithName: synthesizedName
	                                                      representedObject: anObject]];
}

- (void) prepareViewOfNewItem: (ETLayoutItem *)item forAttributeDescription: (ETPropertyDescription *)aPropertyDesc
{
	[[[item view] ifResponds] setEditable: ([aPropertyDesc isReadOnly] == NO)];
	if ([self isTextItem: item])
	{
		ETItemValueTransformer *transformer =
			[self valueTransformerForType: [aPropertyDesc type]];

		if (transformer != nil)
		{
			[item setValueTransformer: transformer forProperty: kETValueProperty];
		}

		[[[item view] ifResponds] setFormatter: [self formatterForType: [aPropertyDesc type]]];
		[[[item view] ifResponds] setSelectable: YES];
		// FIXME: On Mac OS X, resigning the first responder status in a cell
		// that is selectable causes -setStringValue: on the cell to be called
		// even in case -isEditable is NO.
		// A possible workaround is to check whether the old value is the same
		// than the new value for the KVO poster or observer (see NSCell+Etoile
		// and ETLayoutItem)
		[[[item view] ifResponds] setEnabled: ([aPropertyDesc isReadOnly] == NO)];
	}
	else if ([self isPointEditorItem: item])
	{
		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [(ETLayoutItemGroup *)item firstItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"x"];
		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [(ETLayoutItemGroup *)item lastItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"y"];
	}
	else if ([self isSizeEditorItem: item])
	{
		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [(ETLayoutItemGroup *)item firstItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"width"];
		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [(ETLayoutItemGroup *)item lastItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"height"];
	}
	else if ([self isRectEditorItem: item])
	{
		ETLayoutItemGroup *pointEditor = (id)[(ETLayoutItemGroup *)item firstItem];
		ETLayoutItemGroup *sizeEditor = (id)[(ETLayoutItemGroup *)item lastItem];

		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [pointEditor firstItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"x"];
		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [pointEditor lastItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"y"];
		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [sizeEditor firstItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"width"];
		[self prepareViewpointWithRepresentedObject: [[item representedObject] representedObject]
		                                     onItem: [sizeEditor lastItem]
		                    forAttributeDescription: aPropertyDesc
		                            scalarFieldName: @"height"];
	}
	else if ([self isPopUpMenuItem: item])
	{
		NSArray *options = [[aPropertyDesc role] allowedOptions];
		NSArray *entryTitles = (id)[[options mappedCollection] key];
		NSArray *entryModels = (id)[[options mappedCollection] value];
		NSPopUpButton *popUpView = [item view];
		id currentValue = [item valueForProperty: kETValueProperty];

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

			if ([currentValue isEqual: repObject])
			{
				[popUpView selectItemAtIndex: i];
			}
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
	ETLayoutItem *item = AUTORELEASE([templateItem deepCopy]);

	[item setRepresentedObject: [ETMutableObjectViewpoint viewpointWithName: [aPropertyDesc name]
													      representedObject: anObject]];

	[self prepareViewOfNewItem: item forAttributeDescription: aPropertyDesc];

	return item;
}

@end

@implementation ETPropertyCollectionController

@synthesize modelDescriptionRepository = _modelDescriptionRepository;

- (void) dealloc
{
	DESTROY(_modelDescriptionRepository);
	[super dealloc];
}

- (NSDictionary *)defaultOptions
{
	NSMutableDictionary *options = AUTORELEASE([[super defaultOptions] mutableCopy]);

	ETAssert([self modelDescriptionRepository] != nil);
	
	[options setObject: [self modelDescriptionRepository]
				forKey: kETTemplateOptionModelDescriptionRepository];

	return AUTORELEASE([options copy]);
}

- (IBAction) edit: (id)sender
{
	ETLayoutItem *item = [sender doubleClickedItem];
	ETLayoutItemGroup *entityItem = [[[item representedObject] ifResponds] itemRepresentation];

	if (entityItem == nil)
	{
		entityItem = [[ETModelDescriptionRenderer renderer] renderObject: self];
	}

	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
}

@end
