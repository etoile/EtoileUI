/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETViewModelLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItem+Reflection.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutItemGroup.h"
#import "ETOutlineLayout.h"
#import "ETUIItemFactory.h"
#import "ETView.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETInstanceVariableMirror (TraversableIvars)

- (BOOL) isCollection
{
	return [self isObjectType];
}

/* Collection protocol */

- (BOOL) isOrdered
{
	return NO;
}

- (BOOL) isEmpty
{
	if ([self isObjectType] == NO)
		return NO;

	return ([[[self valueMirror] allInstanceVariableMirrors] count] == 0);
}

- (id) content
{
	return [self contentArray];
}

- (NSArray *) contentArray
{
	return [[self valueMirror] allInstanceVariableMirrors];
}

- (NSEnumerator *) objectEnumerator
{
	return [[self contentArray] objectEnumerator];
}

@end


@implementation ETViewModelLayout

- (id) initWithRootItem: (ETLayoutItemGroup *)rootItem 
  firstPresentationItem: (ETLayoutItemGroup *)targetItem

{
	/* Will load the nib and call -awakeFromNib */
	self = [super initWithRootItem: rootItem firstPresentationItem: nil];

	if (self == nil)
		return nil;

	/* Don't set these in -awakeFromNib otherwise ETCompositeLayout initializer
	   will erase them */
	NSView *topLevelView = [propertyView superview];
	[self setRootItem: [[ETEtoileUIBuilder builder] renderView: topLevelView]];
	 /* Now we retain it through a layout item, the nib can release it */
	DESTROY(topLevelView);
	ASSIGN(_mirrorCache, [NSMapTable mapTableWithStrongToStrongObjects]);

	return self;
}

DEALLOC(DESTROY(_mirrorCache))

- (ETLayout *) defaultPropertyViewLayout
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];
	
	[layout setContentFont: [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]]];
	[layout setDisplayName: @"Value" forProperty: @"value"];
	[layout setDisplayName: @"Property" forProperty: @"property"];
	[layout setDisplayName: @"Identifier" forProperty: @"identifier"];
	[layout setDisplayName: @"Description" forProperty: @"description"];
	[layout setDisplayName: @"Name" forProperty: @"name"];
	[layout setDisplayName: @"Type" forProperty: @"typeName"];
	[layout setEditable: YES forProperty: @"value"];

	return layout;
}

/* Configures propertyView outlet. 

Will be called before the receiver is fully initialized. */
- (void) awakeFromNib
{
	ETDebugLog(@"Awaking from nib for %@", self);

	ASSIGN(propertyViewItem, [propertyView layoutItem]);

	[propertyViewItem setLayout: [self defaultPropertyViewLayout]];
	[propertyViewItem setSource: self];
	[propertyViewItem setDelegate: self];
	[propertyViewItem setDoubleAction: @selector(doubleClickInPropertyView:)];
	[propertyViewItem setTarget: self];
	[propertyViewItem setHasVerticalScroller: YES];
	[propertyViewItem setHasHorizontalScroller: YES];
}

- (NSString *) nibName
{
	return @"ViewModelPrototype";
}

/* Reloads and updates the property view layout when ETViewModelLayout becomes 
active. */
- (void) setUp
{
	[super setUp];
	[self setDisplayMode: ETLayoutDisplayModeViewProperties];
}

/* Temporary hack. ETCompositeLayout needs to be reworked to support using an 
invisible first presentation item transparently. */
- (ETLayoutItemGroup *) presentationProxyWithContext: (id)layoutCtxt
{
	if (presentationProxy != nil)
		return presentationProxy;

	NSArray *items = [layoutCtxt defaultValueForProperty: @"items"];
	ASSIGN(presentationProxy, [[ETUIItemFactory factory] itemGroupWithItems: items]);
	return presentationProxy;
}

/** Returns the item inspected as a view and whose represented object is 
inspected as model. */
- (ETLayoutItem *) inspectedItem
{
	ETLayoutItem *contentProxyItem = [self presentationProxyWithContext: [self layoutContext]];

	if ([self shouldInspectRepresentedObjectAsView] 
	 && [contentProxyItem isMetaLayoutItem])
	{
		contentProxyItem = [contentProxyItem representedObject];
	}

	return contentProxyItem;
}

/** Returns whether the receiver should try to inspect the represented object of 
the layout context item as view; this is only possible if the represented object 
is a layout item, otherwise the value returned by this method is ignored. 

By default, NO is returned and the layout context item itself is inspected as 
view.

If YES is returned, [[[self layoutContext] representedObject] representedObject]
will be inspected as model. */
- (BOOL) shouldInspectRepresentedObjectAsView
{
	return _shouldInspectRepresentedObjectAsView;
}

/** Sets whether the receiver should try to inspect the represented object of 
the layout context item as view; this is only possible if the represented object 
is a layout item, otherwise the value returned by this method is ignored. 

See also -shouldInspectRepresentedObjectAsView. */
- (void) setShouldInspectRepresentedObjectAsView: (BOOL)flag
{
	_shouldInspectRepresentedObjectAsView = flag;
}

/** Returns the mirror object that corresponds to the given object.

When the mirror isn't yet cached, it is created and immediately cached, before 
being returned. */
- (id <ETObjectMirror>) cachedMirrorForObject: (id)anObject
{
	id <ETObjectMirror> mirror = [_mirrorCache objectForKey: anObject];

	if (mirror == nil)
	{
		mirror = [ETReflection reflectObject: anObject];
		[_mirrorCache setObject: mirror forKey: anObject];
	}

	return mirror;
}

- (void) makeContentProviderWithObject: (id)anObject
{
	id <ETCollection> collection = ([anObject isCollection] ? anObject : nil);

	[propertyViewItem setRepresentedObject: collection];
	[propertyViewItem setSource: propertyViewItem];
	[[propertyViewItem layout] setDisplayedProperties: A(@"identifier", @"description")];
}

- (void) makeMirrorProviderWithObject: (id)anObject
{
	[propertyViewItem setRepresentedObject: [self cachedMirrorForObject: anObject]];
	[propertyViewItem setSource: propertyViewItem];
	[[propertyViewItem layout] setDisplayedProperties: A(@"name", @"typeName", @"value")];
}

- (void) resetProvider
{
	[propertyViewItem setRepresentedObject: nil];
	[propertyViewItem setSource: self];
}

/** Returns the active display mode. */ 
- (ETLayoutDisplayMode) displayMode
{
	return _displayMode;
}

/** Sets the active display mode and update the receiver layout to use it 
immediately.

The display mode describes what is currently inspected: 
<list>
<item>view</item>
<item>model</item>
</list>. 
And which perspective is taken to inspect it: 
<list>
<item>properties</item>
<item>raw object (ivars, methods)</item>
<item>structured content(in case the object is a collection)</item>
</list> */
- (void) setDisplayMode: (ETLayoutDisplayMode)mode
{
	_displayMode = mode;
	// TODO: Implement -selectItemItemWithTag: in GNUstep
	[popup selectItemAtIndex: [popup indexOfItemWithTag: mode]];
	
	switch (mode)
	{
		case ETLayoutDisplayModeViewObject:
			[self makeMirrorProviderWithObject: [self inspectedItem]];
			break;
		case ETLayoutDisplayModeModelObject:
			[self makeMirrorProviderWithObject: [[self inspectedItem] representedObject]];
			break;
		case ETLayoutDisplayModeViewContent:
			[self makeContentProviderWithObject: [self inspectedItem]];
			break;
		case ETLayoutDisplayModeModelContent:
			[self makeContentProviderWithObject: [[self inspectedItem] representedObject]];
			break;
		default:
			[self resetProvider];
	}

	[propertyViewItem reloadAndUpdateLayout];
}

/** Action used by the receiver to switch the display mode when the user changes 
the selection in the display mode popup menu. 

You must never use this method. */
- (void) switchDisplayMode: (id)sender
{
	NSAssert1([sender isKindOfClass: [NSPopUpButton class]], 
		@"-switchDisplayMode: must be sent by an instance of NSPopUpButton class "
		@"kind unlike %@", sender);
	[self setDisplayMode: [[sender selectedItem] tag]];
}

- (void) doubleClickInPropertyView: (id)sender
{
	ETLayoutItem *clickedItem = [propertyViewItem doubleClickedItem];

	switch ([self displayMode])
	{
		case ETLayoutDisplayModeViewProperties:
		case ETLayoutDisplayModeModelProperties:
		{
			// TODO: Should probably be... ETProperty property = repObject;
			ETProperty *property = [clickedItem valueForProperty: @"value"];
			[[property objectValue] explore: nil];
			break;
		}
		case ETLayoutDisplayModeViewContent:
		case ETLayoutDisplayModeModelContent:
		{
			// TODO: Should probably be... ETLayoutItem *childItem = repObject;
			ETLayoutItem *childItem = [clickedItem valueForProperty: @"value"];
			[childItem explore: nil];
			break;
		}
		case ETLayoutDisplayModeViewObject:
		case ETLayoutDisplayModeModelObject:
		{
			id ivarMirror = [clickedItem representedObject];
			[[ivarMirror value] explore: nil];
			break;
		}
		default:
			ASSERT_INVALID_CASE;
	}
}

/* Object Inspection */

- (int) numberOfItemsInItemGroup: (ETLayoutItemGroup *)baseItem
{
	/* Verify the layout is currently bound to a layout context like a container */
	if ([self layoutContext] == nil)
	{
		ETLog(@"WARNING: Layout context is missing for -numberOfItemsInItemGroup: in %@", self);
		return 0;
	}

	id inspectedItem = [self inspectedItem];
	id inspectedModel = [inspectedItem representedObject];
	/* Always generate a meta layout item to simplify introspection code */
	ETLayoutItem *metaItem = 
		[ETLayoutItem layoutItemWithRepresentedItem: inspectedItem snapshot: NO];
	int nbOfItems = 0;

	if ([self displayMode] == ETLayoutDisplayModeViewProperties)
	{
		/* By using a meta layout item, the inspected item ivars which are 
		   implicit properties get transparently reified into properties. This 
		   happens when the inspected item becomes the model (or represented 
		   object) of the meta item. 
		   See -[ETLayoutItem properties] to know which ivars/accessors are 
		   reified into properties. */
		nbOfItems = [[metaItem properties] count];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelProperties)
	{
		nbOfItems = [[inspectedModel properties] count];
	}
	else
	{
		ETLog(@"WARNING: Unknown display mode %d in -numberOfItemsInItemGroup: "
			"of %@", [self displayMode], self);
	}
	
	//ETLog(@"Returns %d as number of property or slot items in %@", nbOfItems, container);
	
	return nbOfItems;
}

- (ETLayoutItem *) itemGroup: (ETLayoutItemGroup *)baseItem itemAtIndex: (int)index
{
	id inspectedItem = [self layoutContext];
	id inspectedModel = [inspectedItem representedObject];
	/* Always generate a meta layout item to simplify introspection code */
	// FIXME: Regenerating a meta layout item for the same layout context/item 
	// on each -itemGroup:itemAtIndex: call is expansive (see 
	// -[ETLayoutItemGroup copyWithZone:]. ... Caching the meta layout item is
	// probably worth to do.
	ETLayoutItem *metaItem =
		[ETLayoutItem layoutItemWithRepresentedItem: inspectedItem snapshot: NO];
	ETLayoutItem *propertyItem = AUTORELEASE([[ETLayoutItem alloc] init]);
	
	/* Inspected item is used as model */
	if (inspectedModel == nil)
		inspectedModel = inspectedItem;
	
	NSAssert1(inspectedModel != nil, @"Layout context of % must not be nil.", self);
	
	if ([self displayMode] == ETLayoutDisplayModeViewProperties)
	{
		NSString *property = [[metaItem properties] objectAtIndex: index];

		[propertyItem setValue: property forProperty: @"property"];
		// FIXME: Instead using -description, write a generic ETObjectFormatter
		// For example, on table view display, the value is copied when passed 
		// in parameter to -[NSCell setObjectValue:]. If the value like an 
		// NSView instance doesn't implement -copyWithZone:, it leads to a 
		// crash. That's why having a generic formatter or always passing the
		// object description string is critical.
		[propertyItem setValue: [[metaItem valueForProperty: property] stringValue] forProperty: @"value"];
	}
	else if ([self displayMode] == ETLayoutDisplayModeModelProperties)
	{
		NSString *property = [(NSArray *)[inspectedModel properties] objectAtIndex: index];

		[propertyItem setValue: property forProperty: @"property"];
		[propertyItem setValue: [inspectedModel valueForProperty: property] forProperty: @"value"];
	}
	else
	{
		ETLog(@"WARNING: Unknown display mode %d in -itemGroup:itemAtIndex: "
			"of %@", [self displayMode], self);
	}

	//ETLog(@"Returns property or slot item %@ at index %d in %@", propertyItem, index, container);
	
	return propertyItem;
}

- (NSArray *) displayedItemPropertiesInItemGroup: (ETLayoutItemGroup *)baseItem
{
	NSArray *displayedProperties = nil;

	switch ([self displayMode])
	{
		case ETLayoutDisplayModeViewProperties:
		case ETLayoutDisplayModeModelProperties:
			displayedProperties = A(@"property", @"value");
			break;
		case ETLayoutDisplayModeViewContent:
		case ETLayoutDisplayModeModelContent:
			displayedProperties = A(@"content", @"value");
			break;
		default:
			break;
	}
	
	return displayedProperties;
}

@end
