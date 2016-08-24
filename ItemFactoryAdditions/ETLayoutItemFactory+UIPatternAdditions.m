/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2013
	License:  Modified BSD (see COPYING)
 */

#import "ETLayoutItemFactory+UIPatternAdditions.h"
#import "ETAspectRepository.h"
#import "ETController.h"
#import "ETItemTemplate.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutItemGroup.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETSelectTool.h"
#import "ETWindowItem.h"

@interface ETObjectPickerController : ETController
@end

@implementation ETLayoutItemFactory (ETUIPatternAdditions)

// TODO: Remove duplication in ETUIBuilderItemFactory
- (ETTool *) pickerTool
{
	ETSelectTool *tool = [ETSelectTool toolWithObjectGraphContext: [self objectGraphContext]];
	
	[tool setAllowsMultipleSelection: YES];
	[tool setAllowsEmptySelection: NO];
	[tool setShouldRemoveItemsAtPickTime: NO];

	return tool;
}

// TODO: Remove duplication in ETUIBuilderItemFactory
- (ETLayoutItemGroup *) objectPicker
{
	ETLayoutItemGroup *picker = [self itemGroupWithRepresentedObject: [ETAspectRepository mainRepository]];
	ETController *controller =
		[[ETObjectPickerController alloc] initWithObjectGraphContext: [self objectGraphContext]];
	ETItemTemplate *template = [controller templateForType: [controller currentObjectType]];

	[[template item] setActionHandler:
	 	[ETAspectTemplateActionHandler sharedInstanceForObjectGraphContext: [self objectGraphContext]]];
	[picker setActionHandler:
	 	[ETAspectTemplateActionHandler sharedInstanceForObjectGraphContext: [self objectGraphContext]]];

	[controller setAllowedPickTypes: A([ETUTI typeWithClass: [NSObject class]])];

	// TODO: Retrieve the size as ETUIBuilderItemFactory does it
	[picker setSize: NSMakeSize(300, 400)];
	[picker setController: controller];
	[picker setDelegate: controller];
	[picker setSource: picker];
	[picker setLayout: [ETOutlineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[picker layout] setAttachedTool: [self pickerTool]];
	[[picker layout] setDisplayedProperties: A(kETIconProperty, kETDisplayNameProperty)];
	[picker setHasVerticalScroller: YES];
	[picker reloadAndUpdateLayout];

	return picker;
}

@end


@implementation ETObjectPickerController

- (ETWindowItem *) provideWindowItemForItemGroup: (ETLayoutItemGroup *)itemGroup
{
	return [ETWindowItem panelItemWithObjectGraphContext: [self objectGraphContext]];
}

@end
