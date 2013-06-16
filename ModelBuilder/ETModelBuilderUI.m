/*
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETModelBuilderUI.h"
#import "ETColumnLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETModelBuilderRelationshipController.h"
#import "ETModelDescriptionRenderer.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETCompatibility.h"

@implementation ETModelElementDescription (EtoileUI)

- (ETModelDescriptionRepository *) repository
{
	return [ETModelDescriptionRepository mainRepository];
}

- (ETLayoutItemGroup *) collectionEditorTemplateItemForRenderer: (ETModelDescriptionRenderer *)aRenderer
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETPropertyCollectionController *controller =
		AUTORELEASE([ETModelBuilderRelationshipController new]);
	ETLayoutItemGroup *editor = [itemFactory collectionEditorWithSize: [aRenderer defaultItemSize]
							                         representedObject: [NSArray array]
									                        controller: controller];
	return editor;
}

- (ETOutlineLayout *)defaultOutlineLayoutForInspector
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];
	
	[layout setDisplayedProperties: A(kETIconProperty, kETDisplayNameProperty, kETValueProperty)];
	[[layout columnForProperty: kETDisplayNameProperty] setWidth: 250];
	[[layout columnForProperty: kETValueProperty] setWidth: 250];
	
	return layout;
}

- (ETModelDescriptionRenderer *) rendererWithController: (ETController *)aController
{
	ETModelDescriptionRenderer *renderer = [ETModelDescriptionRenderer renderer];
	ETItemValueTransformer *transformer = [ETModelBuilderController newRelationshipValueTransformer];
	ETEntityDescription *metaEntityDesc =
		[[self repository] entityDescriptionForClass: [ETEntityDescription class]];
	ETEntityDescription *metaPropertyEntityDesc =
		[[self repository] entityDescriptionForClass: [ETPropertyDescription class]];
	ETEntityDescription *rootEntityDesc = [[renderer repository] descriptionForName: @"Object"];

	[renderer setTemplateItem: [self collectionEditorTemplateItemForRenderer: renderer]
	            forIdentifier: @"collectionEditor"];

	[renderer setValueTransformer: transformer forType: metaEntityDesc];
	[renderer setValueTransformer: transformer forType: metaPropertyEntityDesc];
	[[renderer formatterForType: rootEntityDesc] setDelegate: aController];

	return renderer;
}

- (ETLayoutItemGroup *) itemRepresentation
{
	ETModelBuilderController *controller = AUTORELEASE([ETModelBuilderController new]);
	ETLayoutItemGroup *entityItem = [[self rendererWithController: controller] renderObject: self];

	// FIXME: Keep or remove...
	//[[entityItem layout] setAutoresizesItemToFill: YES];
	[entityItem setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[entityItem setController: controller];

	return entityItem;
}

- (void) view: (id)sender
{
	[[[ETLayoutItemFactory factory] windowGroup] addItem: [self itemRepresentation]];
}

@end

@implementation ETEntityDescription (EtoileUI)

- (ETLayoutItemGroup *) itemRepresentation
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *entityItem = [super itemRepresentation];
	ETLayoutItem *buttonItem =
		[itemFactory buttonWithTitle: _(@"Instantiate") target: self action:@selector(instantiate:)];
	// FIXME: ETLayoutItemFactory should provide the exact margin
	CGFloat barBorderMargin = 10;
	NSSize barSize = NSMakeSize([entityItem width], [buttonItem height] + barBorderMargin * 2);
	ETLayoutItemGroup *bottomBar = [itemFactory horizontalBarWithSize: barSize];

	
	[bottomBar addItems: A(buttonItem)];
	[[bottomBar layout] setBorderMargin: barBorderMargin];

	NSSize size = NSMakeSize([entityItem width], [entityItem height] + barSize.height);
	ETLayoutItemGroup *editorItem = [itemFactory itemGroupWithSize: size];

	ETAssert([entityItem autoresizingMask] & ETAutoresizingFlexibleWidth);
	ETAssert([bottomBar autoresizingMask] & ETAutoresizingFlexibleWidth);

	[editorItem addItems: A(entityItem, bottomBar)];
	[editorItem setLayout: [ETColumnLayout layout]];
	// FIXME: Implement horizontal alignment support
	[[editorItem layout] setHorizontalAligment: ETLayoutHorizontalAlignmentRight];

	return editorItem;
}

- (id) newInstance
{
	// FIXME: Support providing a custom repository
	ETModelDescriptionRepository *repo = [ETModelDescriptionRepository mainRepository];
	Class entityClass = [repo classForEntityDescription: self];
	
	if (entityClass == Nil || [entityClass isSubclassOfClass: [COObject class]] == NO)
	{
		// TODO: Show alert
		ETAssertUnreachable();
	}
	return [[entityClass alloc] initWithEntityDescription: self];
}

- (void) instantiate: (id)sender
{
	[AUTORELEASE([self newInstance]) view: sender];
}

@end
