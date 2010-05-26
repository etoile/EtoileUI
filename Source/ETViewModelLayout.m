/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETViewModelLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItem+Reflection.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutItemGroup.h"
#import "ETNibOwner.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETLayoutItemFactory.h"
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

- (void) prepareUI
{
	[propertyViewItem setLayout: [self defaultPropertyViewLayout]];
	[propertyViewItem setDelegate: self];
	[propertyViewItem setDoubleAction: @selector(doubleClickInPropertyView:)];
	[propertyViewItem setTarget: self];
	[propertyViewItem setHasVerticalScroller: YES];
	[propertyViewItem setHasHorizontalScroller: YES];

	/* Update the content to match the selection in the display mode popup */
	[self switchDisplayMode: popup];
}

- (BOOL) loadNibAndPrepareUI
{
	NSBundle *etoileUIBundle = [NSBundle bundleForClass: [self class]];
	ETNibOwner *nibOwner = [[ETNibOwner alloc] initWithNibName:  @"ViewModelPrototype" 
	                                                    bundle: etoileUIBundle];
	BOOL nibLoaded = [nibOwner loadNibWithOwner: self];

	if (nibLoaded)
	{
		NSView *topLevelView = [propertyView superview];

		[self setLayoutView: topLevelView];
		[self setRootItem: [[ETEtoileUIBuilder builder] renderView: topLevelView]];

		// TODO: Remove by using propertyViewItem as outlet
		ASSIGN(propertyViewItem, [propertyView layoutItem]);
	}
	RELEASE(nibOwner);

	[self prepareUI];

	return nibLoaded;
}

- (id) initWithRootItem: (ETLayoutItemGroup *)rootItem 
  firstPresentationItem: (ETLayoutItemGroup *)targetItem

{
	self = [super initWithRootItem: rootItem firstPresentationItem: nil];
	if (self == nil)
		return nil;

	ASSIGN(_mirrorCache, [NSMapTable mapTableWithStrongToStrongObjects]);

	BOOL nibLoaded = [self loadNibAndPrepareUI];
	
	if (NO == nibLoaded)
	{
		DESTROY(self);
	}
	return self;
}

DEALLOC(DESTROY(_mirrorCache))

/* Adjusts the layout context flipping to match the our custom view converted 
into the root item at initialization time. 

The initial flipping will be automatically restored by 
-restoreInitialContextState on a layout switch.*/
- (void) prepareNewContextState
{
	[super prepareNewContextState];

	// FIXME: NSParameterAssert([[self rootItem] isFlipped] == NO);
	[_layoutContext setFlipped: NO];
}

/* Reloads and updates the property view layout when ETViewModelLayout becomes 
active. */
- (void) setUp
{
	[super setUp];
	[self setDisplayMode: ETLayoutDisplayModeViewProperties];
}

/* Prevents a scrollable area item to be visible on the layout context, because 
the property view item is scrollable. */
- (BOOL) isScrollable
{
	return NO;
}

/** Returns the item inspected as a view and whose represented object is 
inspected as model. */
- (ETLayoutItem *) inspectedItem
{
	// FIXME: Ugly cast
	ETLayoutItem *contentProxyItem = (ETLayoutItemGroup *)[self layoutContext];

	if ([self shouldInspectRepresentedObjectAsView] 
	 && [contentProxyItem isMetaLayoutItem])
	{
		contentProxyItem = [contentProxyItem representedObject];
	}

	return contentProxyItem;
}

- (id) modelForInspectedItem: (id)anItem
{
	if ([self shouldInspectItself] == NO && [anItem isEqual: _layoutContext])
	{
		return [anItem defaultValueForProperty: kETRepresentedObjectProperty];
	}
	else
	{
		return [anItem representedObject];
	}
}

/* When the inspected item is the layout context and -shouldInspectItself is NO, 
returns the items which were its children before the view model layout was 
applied to it, otherwise returns its current children. */
- (id) contentForInspectedItem: (id)anItem
{
	if ([anItem isGroup] == NO)
		return nil;

	if ([self shouldInspectItself] == NO && [anItem isEqual: _layoutContext])
	{
		NSArray *initialChildren = [anItem defaultValueForProperty: @"items"];
		NSParameterAssert(nil != initialChildren);
		return initialChildren;
	}
	else
	{
		return [anItem items];
	}
}

/** Returns whether the receiver should try to inspect the current layout 
context content, rather than inspecting its initial content before the view 
model layout was applied.

The value returned by this method is ignored when 
-shouldInspectRepresentedObjectAsView returns YES.

By default, NO is returned and in ETLayoutDisplayModeViewContent present the 
items that belonged to the layout context before the view model layout was 
applied. */
- (BOOL) shouldInspectItself
{
	return _shouldInspectItself;
}

/** Sets whether the receiver should try to inspect the current layout 
context content, rather than inspecting its initial content before the view 
model layout was applied.

See also -shouldInspectItself. */
- (void) setShouldInspectItself: (BOOL)inspectLayout
{
	_shouldInspectItself = inspectLayout;
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

- (id) entityViewPointForObject: (id)anObject
{
	NSArray *properties = [(NSObject *)anObject properties];
	NSMutableArray *propertyViewpoints = 
		[NSMutableArray arrayWithCapacity: [properties count]];

	FOREACH(properties, property, NSString *)
	{
		[propertyViewpoints addObject: [ETProperty propertyWithName: property 
		                                          representedObject: anObject]];
	}

	return propertyViewpoints;
}

- (void) makePropertyProviderWithObject: (id)anObject
{
	[propertyViewItem setRepresentedObject: [self entityViewPointForObject: anObject]];
	[propertyViewItem setSource: propertyViewItem];
	[[propertyViewItem layout] setDisplayedProperties: A(@"name", @"value")];
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
	[propertyViewItem setSource: propertyViewItem];
}

// FIXME: Remove
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if ([propertyViewItem canReload])
	{
		[propertyViewItem reloadAndUpdateLayout];
	}
	else
	{
		[propertyViewItem updateLayout];
	}
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
		case ETLayoutDisplayModeViewProperties:
			[self makePropertyProviderWithObject: [self inspectedItem]];
			break;
		case ETLayoutDisplayModeModelProperties:
			[self makePropertyProviderWithObject: [self modelForInspectedItem: [self inspectedItem]]];
			break;
		case ETLayoutDisplayModeViewObject:
			[self makeMirrorProviderWithObject: [self inspectedItem]];
			break;
		case ETLayoutDisplayModeModelObject:
			[self makeMirrorProviderWithObject: [self modelForInspectedItem: [self inspectedItem]]];
			break;
		case ETLayoutDisplayModeViewContent:
			[self makeContentProviderWithObject: [self contentForInspectedItem: [self inspectedItem]]];
			break;
		case ETLayoutDisplayModeModelContent:
			[self makeContentProviderWithObject: [self modelForInspectedItem: [self inspectedItem]]];
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

@end
