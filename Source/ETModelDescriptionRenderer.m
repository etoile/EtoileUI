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
#import <EtoileFoundation/NSObject+Model.h>
#import "ETModelDescriptionRenderer.h"
#import "ETTemplateItemLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETCompatibility.h"


@implementation ETModelDescriptionRenderer

+ (id) renderer
{
	return AUTORELEASE([[self alloc] init]);
}

- (id) init
{
	SUPERINIT
	_templateItems = [[NSMutableDictionary alloc] init];
	return self;
}

- (void) dealloc
{
	DESTROY(_templateItems);
	[super dealloc];
}

- (void) setTemplateItem: (ETLayoutItem *)anItem forIdentifier: (NSString *)anIdentifier
{
	[_templateItems setObject: anItem forKey: anIdentifier];
}

- (ETLayoutItem *) templateItemForIdentifier: (NSString *)anIdentifier
{
	return [_templateItems objectForKey: anIdentifier];
}

- (id) newItemForIdentifier: (NSString *)anIdentifier isGroupRequired: (BOOL)mustBeGroup
{
	ETLayoutItem *templateItem = [self templateItemForIdentifier: anIdentifier];
	ETLayoutItem *item = AUTORELEASE([templateItem copy]);

	if (nil == templateItem)
	{
		item = [[ETLayoutItemFactory factory] textField];
	}
	if (mustBeGroup && [item isGroup] == NO)
	{
		item = [[ETLayoutItemFactory factory] itemGroup];
	}

	return item;
}

- (id) renderModel: (id)anObject
{
	//ETEntityDescription *entityDesc = [ETReflection reflectModel: anObject];
	return [self renderModel: anObject description: [[anObject class] newEntityDescription]];
}

- (id) renderModel: (id)anObject description: (ETEntityDescription *)entityDesc
{
	//NSString *identifier = [entityDesc itemIdentifier];
	//ETLayoutItemGroup *itemGroup = [self newItemForIdentifier: identifier isGroupRequired: YES];

	return [self renderProperties: [entityDesc propertyDescriptionNames] 
	                  description: entityDesc
	                      ofModel: anObject];
}

- (id) renderProperties: (NSArray *)properties
            description: (ETEntityDescription *)entityDesc  
                ofModel: (id)anObject
{
	NSMutableArray *items = [NSMutableArray array];

	FOREACH(properties, property, NSString *)
	{
		[items addObject: [self renderProperty: property description: entityDesc ofModel: anObject]];
	}

	return items;
}

- (id) renderProperty: (NSString *)aProperty
          description: (ETEntityDescription *)entityDesc  
              ofModel: (id)anObject
{
	ETPropertyDescription *propertyDesc = [entityDesc propertyDescriptionForName: aProperty];
	ETLayoutItem *item = nil;

	if ([propertyDesc isRelationship])
	{
		//ETEntityDescription *destinationEntityDesc = [propertyDesc type];
		id value = [anObject valueForProperty: aProperty];

		// TODO: When 'value' is nil, build the UI with destinationEntityDesc.
		item = [self renderModel: value];
		[item setName: [propertyDesc name]];
	}
	else /* isAttribute */
	{
		NSString *identifier = [propertyDesc itemIdentifier];

		item = [self newItemForIdentifier: identifier isGroupRequired: NO];
		[item setName: [propertyDesc name]];
		[item setRepresentedObject: [ETProperty propertyWithName: aProperty representedObject: anObject]];
	}

	return item;
}

#if 0
- (id) renderModel: (id)anObject 
            inLayoutItem: (ETLayoutItem *)anItem 
              withLayout: (ETLayout *)aLayout;
{
	// FIXME: lookup description for anObject
	ETEntityDescription *desc = nil;
	ETLayoutItem *builtItem = (anItem != nil ? anItem : [self render: desc]);
	ETLayout *layout = (aLayout != nil ? aLayout : [ETFormLayout layout]);

	if ([builtItem isGroup])
		[(ETLayoutItemGroup *)builtItem setLayout: layout];

	return builtItem;
}
#endif

- (id) renderEntityDescription: (ETEntityDescription *)aDescription
{
	ETLayoutItemGroup *entityItem = [[ETLayoutItemFactory factory] itemGroup];

	FOREACHI([aDescription propertyDescriptions], propertyDescription)
	{
		[entityItem addItem: [self render: propertyDescription]];
	}	
	[entityItem setName: [aDescription name]];

	return entityItem;
}

- (id) renderPropertyDescription: (ETPropertyDescription *)aDescription
{
	// TODO: we need a mapping from UTI to "layout item for editing that type"

	ETLayoutItem *item = [[ETLayoutItemFactory factory] textField];
	[item setName: [aDescription name]];
	return item;
}

/** Returns a dictionary mapping value classes to editor object prototypes. 
	These editor objects are UI elements like NSSlider, NSStepper, NSTextField, 
	NSButton. */
- (NSDictionary *) editorObjects
{
	/*NSButton *checkBox = [[NSButton alloc] ini

	return [NSDictionary dictionaryWithObjectsAndKeys: 
		[NS*/
	return nil;
}

@end


@implementation ETEntityDescription (EtoileUI)

- (void) view: (id)sender
{
	ETLayoutItem *entityItem = [[ETModelDescriptionRenderer renderer] renderModel: self];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
}

@end
