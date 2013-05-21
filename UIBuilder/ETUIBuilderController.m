/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/Macros.h>
#import "ETUIBuilderController.h"
#import "ETApplication.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETUIBuilderItemFactory.h"

@implementation ETUIBuilderController

@synthesize itemFactory = _itemFactory, browserItem = _browserItem, aspectInspectorItem = _aspectInspectorItem, 
	viewPopUpItem = _viewPopUpItem, aspectPopUpItem = _aspectPopUpItem;

- (void) dealloc
{
	DESTROY(_itemFactory);
	DESTROY(_browserItem);
	DESTROY(_aspectInspectorItem);
	DESTROY(_viewPopUpItem);
	DESTROY(_aspectPopUpItem);
	[super dealloc];
}

- (ETLayoutItemGroup *) bodyItem
{
	return (id)[[self content] itemForIdentifier: @"inspectorBody"];
}

- (ETLayoutItemGroup *) aspectPaneItem
{
	return (id)[[self aspectInspectorItem] itemForIdentifier: @"basicInspectorContent"];
}

- (NSArray *) selectedObjects
{
	return [[[[self browserItem] selectedItemsInLayout] mappedCollection] representedObject];
}

- (id) inspectedObject
{
	NSArray *selectedObjects = [self selectedObjects];
	
	if ([selectedObjects isEmpty])
	{
		return [[self browserItem] representedObject];
	}
	return [selectedObjects firstObject];
}

- (void) showItem: (ETLayoutItem *)anItem
{
	if ([[self bodyItem] containsItem: anItem])
		return;

	[[self bodyItem] addItem: anItem];
}

- (void) hideItem: (ETLayoutItem *)anItem
{
	if ([[self bodyItem] containsItem: anItem] == NO)
		return;
	
	[[self bodyItem] removeItem: anItem];
}

- (void) changePresentationViewToMenuItem: (NSMenuItem *)aMenuItem
{
	ETAssert(_browserItem != nil);
	ETAssert(_aspectInspectorItem != nil);

	if ([[aMenuItem title] isEqual: _(@"Browser")])
	{
		[self showItem: _browserItem];
		[self hideItem: _aspectInspectorItem];
	}
	else if ([[aMenuItem title] isEqual: _(@"Inspector")])
	{
		[self hideItem: _browserItem];
		[self showItem: _aspectInspectorItem];
	}
	else if ([[aMenuItem title] isEqual: _(@"Browser and Inspector")])
	{
		[self showItem: _browserItem];
		[self showItem: _aspectInspectorItem];
	}
	else
	{
		ETAssertUnreachable();
	}
}

- (IBAction) changePresentationViewFromPopUp: (id)sender
{
	ETAssert(_viewPopUpItem != nil);
	[self changePresentationViewToMenuItem: [[_viewPopUpItem view] selectedItem]];
}

- (IBAction) changeAspectPaneFromPopUp: (id)sender
{
	ETAssert(_aspectPopUpItem != nil);
	ETAssert([self itemFactory] != nil);

	NSString *aspectName = [[[_aspectPopUpItem view] selectedItem] representedObject];
	ETLayoutItemGroup *newAspectPaneItem =
		[[self itemFactory] basicInspectorContentWithObject: [self inspectedObject]
		                                         controller: self
		                                         aspectName: aspectName];

	[[self aspectInspectorItem] removeItem: [self aspectPaneItem]];
	[[self aspectInspectorItem] addItem: newAspectPaneItem];
}

@end
