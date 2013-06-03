/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/Macros.h>
#import <CoreObject/COEditingContext.h>
#import "ETUIBuilderController.h"
#import "ETApplication.h"
#import "ETAspectRepository.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem+CoreObject.h"
#import "ETLayoutItem+UIBuilder.h"
#import "ETObjectValueFormatter.h"
#import "ETUIBuilderItemFactory.h"
#import "ETUIStateRestoration.h"

@implementation ETUIBuilderController

@synthesize itemFactory = _itemFactory, documentContentItem = _documentContentItem, browserItem = _browserItem,
	aspectInspectorItem = _aspectInspectorItem, viewPopUpItem = _viewPopUpItem,
	aspectPopUpItem = _aspectPopUpItem, aspectRepository = _aspectRepository;

- (void) dealloc
{
	DESTROY(_itemFactory);
	DESTROY(_documentContentItem);
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

- (void) presentTransientEditingAlertIfNeededForItem: (ETLayoutItem *)anItem
{
	if ([anItem persistentUIItem] != nil)
		return;

	NSString *msg = _(@"This UI item doesn't support persisting UI editing "
		"for the current application.");
	NSString *extra = _(@"You can explicitly save UI changes in a new document, "
						"but the changes won't be visible on the next application launch.");

	NSAlert *alert = [NSAlert alertWithMessageText: msg defaultButton: nil
		alternateButton: nil otherButton: nil informativeTextWithFormat: @""];
	[alert setInformativeText: extra];

	[alert runModal];
}

- (void) preparePersistentItemForDocumentContentItem: (ETLayoutItem *)anItem
{
	if ([anItem isPersistent])
		return;

	ETLayoutItem *persistentUIItem = [anItem persistentUIItem];

	ETLog(@" === Turned %@ into a persistent UI === ", [persistentUIItem shortDescription]);

	[(id)[self persistentObjectContext]
		insertNewPersistentRootWithRootObject: persistentUIItem];
	[[ETApp UIStateRestoration] setPersistentItemUUID: [persistentUIItem UUID]
	                                          forName: [persistentUIItem persistentUIName]];
}

- (void) setDocumentContentItem: (ETLayoutItem *)anItem
{
	[self presentTransientEditingAlertIfNeededForItem: anItem];

	if (_documentContentItem != nil)
	{
		[self stopObserveObject: _documentContentItem
		    forNotificationName: ETItemGroupSelectionDidChangeNotification];		
	}
	ASSIGN(_documentContentItem, anItem);
	[self preparePersistentItemForDocumentContentItem: anItem];

	if (anItem != nil)
	{
		[self startObserveObject: [self documentContentItem]
		     forNotificationName: ETItemGroupSelectionDidChangeNotification
		                selector: @selector(documentContentItemSelectionDidChange:)];
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

	[(ETLayoutItemGroup *)[[self documentContentItem] ifResponds] setSelectionIndexPaths: selectionIndexPaths];
	[self didChangeSelectionToIndexPaths: selectionIndexPaths];
	
	_isChangingSelection = NO;
}

- (void) documentContentItemSelectionDidChange: (NSNotification *)aNotif
{
	ETLog(@"Did change selection in %@", [aNotif object]);

	if (_isChangingSelection)
		return;

	_isChangingSelection = YES;

	NSArray *selectionIndexPaths = [[[self documentContentItem] ifResponds] selectionIndexPaths];

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
	[self changePresentationViewToMenuItem: (NSMenuItem *)[[_viewPopUpItem view] selectedItem]];
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

// NOTE: This method isn't needed if we use a ETItemValueTransformer
- (NSString *) formatter: (ETObjectValueFormatter *)aFormatter stringForObjectValue: (id)aValue
{
	if ([[self editedProperty] isEqual: @"target"])
	{
		return [aValue identifier];
	}
	else
	{
		return [[aValue ifResponds] instantiatedAspectName];
	}
}

- (NSString *) formatter: (ETObjectValueFormatter *)aFormatter stringValueForString: (id)aValue
{
	BOOL isEditing = ([self editedProperty] != nil);

	/* The empty string is a valid value so we don't return nil (the value represents nil) */
	if ([aValue isEqual: @""] || isEditing == NO)
		return aValue;

	if ([[self editedProperty] isEqual: @"target"])
	{
		if ([[self documentContentItem] isGroup] == NO)
			return nil;

		if ([(ETLayoutItemGroup *)[self documentContentItem] itemForIdentifier: aValue] == nil)
			return nil;

		return aValue;
	}
	else
	{
		ETAspectCategory *category =
			[[self aspectRepository] aspectCategoryNamed: [self editedProperty]];

		return([category aspectForKey: aValue] != nil ? aValue : nil);
	}
}

- (ETPropertyDescription *)propertyDescriptionForName: (NSString *)aName
                                           editedItem: (ETLayoutItem *)anItem
{
	ETModelDescriptionRepository *repo = [[[self persistentObjectContext] editingContext] modelRepository];
	ETEntityDescription *entityDesc = [repo entityDescriptionForClass: [anItem subject]];
	
	return [entityDesc propertyDescriptionForName: aName];
}

- (void) subjectDidEndEditingForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{
	// TODO: For the inspector, detect if the item argument is not a meta-item.
	[super subjectDidEndEditingForItem: anItem property: aKey];

	ETLayoutItem *editedObject = ([[anItem subject] conformsToProtocol: @protocol(ETPropertyViewpoint)] ? [[anItem subject] representedObject] : [anItem representedObject]);

	if ([editedObject isPersistent] == NO)
		return;

	NSString *description = [NSString stringWithFormat: @"Edited property %@", aKey];

	[[[self persistentObjectContext] editingContext] commitWithType: @"Property Change"
	                                               shortDescription: description];
}

@end
