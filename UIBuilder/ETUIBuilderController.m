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
#import "ETAspectRepository.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETObjectValueFormatter.h"
#import "ETUIBuilderItemFactory.h"

@implementation ETUIBuilderController

@synthesize itemFactory = _itemFactory, editedItem = _editedItem, browserItem = _browserItem,
	aspectInspectorItem = _aspectInspectorItem, viewPopUpItem = _viewPopUpItem,
	aspectPopUpItem = _aspectPopUpItem, aspectRepository = _aspectRepository;

- (void) dealloc
{
	DESTROY(_itemFactory);
	DESTROY(_editedItem);
	DESTROY(_browserItem);
	DESTROY(_aspectInspectorItem);
	DESTROY(_viewPopUpItem);
	DESTROY(_aspectPopUpItem);
	DESTROY(_aspectRepository);
	[super dealloc];
}

- (void) setContent: (ETLayoutItemGroup *)anItem
{
	if ([self content] != nil)
	{
		[self stopObserveObject: [[self content] itemForIdentifier: @"browser"]
		    forNotificationName: ETItemGroupSelectionDidChangeNotification];
	}
	[super setContent: anItem];

	if (anItem != nil)
	{
		[self startObserveObject: [anItem itemForIdentifier: @"browser"]
		     forNotificationName: ETItemGroupSelectionDidChangeNotification
		                selector: @selector(browserSelectionDidChange:)];
	}
}

- (ETLayoutItemGroup *) bodyItem
{
	return (id)[[self content] itemForIdentifier: @"inspectorBody"];
}

- (ETLayoutItemGroup *) objectPickerItem
{
	return (id)[[self content] itemForIdentifier: @"objectPicker"];
}

- (ETLayoutItemGroup *) contentAreaItem
{
	return (id)[[self content] itemForIdentifier: @"contentArea"];
}

- (void) setEditedItem: (ETLayoutItem *)anItem
{
	if (_editedItem != nil)
	{
		[self stopObserveObject: _editedItem
		    forNotificationName: ETItemGroupSelectionDidChangeNotification];		
	}
	ASSIGN(_editedItem, anItem);

	if (anItem != nil)
	{
		[self startObserveObject: [self editedItem]
		     forNotificationName: ETItemGroupSelectionDidChangeNotification
		                selector: @selector(editedItemSelectionDidChange:)];
	}
}

- (ETLayoutItemGroup *) aspectPaneItem
{
	return (id)[[self aspectInspectorItem] itemForIdentifier: @"basicInspectorContent"];
}

- (NSArray *) selectedObjects
{
	return [[[[self browserItem] selectedItemsInLayout] mappedCollection] representedObject];
}

- (void) browserSelectionDidChange: (NSNotification *)aNotif
{
	ETLog(@"Did change selection in %@", [aNotif object]);

	if (_isChangingSelection)
		return;

	_isChangingSelection = YES;

	NSArray *selectionIndexPaths = [[self browserItem] selectionIndexPaths];

	[(ETLayoutItemGroup *)[[self editedItem] ifResponds] setSelectionIndexPaths: selectionIndexPaths];
	[self didChangeSelectionToIndexPaths: selectionIndexPaths];
	
	_isChangingSelection = NO;
}

- (void) editedItemSelectionDidChange: (NSNotification *)aNotif
{
	ETLog(@"Did change selection in %@", [aNotif object]);

	if (_isChangingSelection)
		return;

	_isChangingSelection = YES;

	NSArray *selectionIndexPaths = [[[self editedItem] ifResponds] selectionIndexPaths];

	if (selectionIndexPaths == nil)
	{
		selectionIndexPaths = [NSArray array];
	}
	[[self browserItem] setSelectionIndexPaths: selectionIndexPaths];
	[self didChangeSelectionToIndexPaths: selectionIndexPaths];

	_isChangingSelection = NO;
}

- (void) didChangeSelectionToIndexPaths: (NSArray *)indexPaths
{
	NSParameterAssert(indexPaths != nil);
	[self changeAspectPaneFromPopUp: nil];
}

- (id) inspectedObject
{
	NSArray *selectedObjects = [self selectedObjects];
	BOOL isSingleSelection = ([selectedObjects count] == 1);
	BOOL isMultipleSelection = ([selectedObjects count] > 1);
	
	if (isSingleSelection)
	{
		return [selectedObjects firstObject];
	}
	else if (isMultipleSelection)
	{
		// TODO: Implement a proxy that provides an union view over several
		// model objects for editing
		return [selectedObjects firstObject];
	}
	else
	{
		return [[self browserItem] representedObject];
	}
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

- (IBAction) changeAspectRepositoryFromPopUp: (id)sender
{
	
}

- (NSString *) formatter: (ETObjectValueFormatter *)aFormatter stringValueForString: (id)aValue
{
	/*BOOL isAspectFromRepository = ([aValue respondsToSelector: @selector(instantiatedAspectName)]
		&& [aValue instantiatedAspectName] != nil);

	if (isAspectFromRepository)
	{
		return [aValue instantiatedAspectName];
	}*/
	return nil;
}

- (id) formatter: (ETObjectValueFormatter *)aFormatter objectValueForString: (NSString *)aString
{
	/*BOOL isAspectFromRepository = ([aValue respondsToSelector: @selector(instantiatedAspectName)]
		&& [aValue instantiatedAspectName] != nil);

	if (isAspectFromRepository)
	{
		return [aValue instantiatedAspectName];
	}*/
	return nil;
}

@end
