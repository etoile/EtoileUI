/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileFoundation/NSString+Etoile.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/Macros.h>
#import "ETInspector.h"
#import "EtoileUIProperties.h"
#import "ETTool.h"
#import "ETViewModelLayout.h"
#import "ETLayoutItemGroup.h"
#import "ETOutlineLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItemFactory.h"
#import "ETView.h"
#import "ETCompatibility.h"

@interface ETInspector (EtoilePrivate)
- (void) updateInspectorWindowTitle;
@end


@implementation ETInspectorLayout

- (id) inspectedObject
{
	return [(ETLayoutItem *)[self layoutContext] representedObject];
}

@end


@implementation ETInspector

- (id) initWithView: (NSView *)view 
         coverStyle: (ETStyle *)aStyle 
      actionHandler: (ETActionHandler *)aHandler
{
	self = [super initWithView: view coverStyle: aStyle actionHandler: aHandler];
	
	if (self != nil)
	{
		_inspectedObjects = nil;
		
		BOOL nibLoaded = [NSBundle loadNibNamed: @"Inspector" owner: self];
		
		if (nibLoaded == NO)
		{
			NSLog(@"Failed to load nib Inspector");
			RELEASE(self);
			return nil;
		}
	}
	
	return self;
}

- (void) dealloc
{
	[self stopKVOObservationIfNeeded];
	DESTROY(_inspectedObjects);
	DESTROY(masterViewItem);
	DESTROY(detailViewItem);
	[super dealloc];
}

- (void) awakeFromNib
{
	// TODO: Next line shouldn't be needed, ETEtoileUIBuilder should be invoked 
	// transparently on nib loading.
	// FIXME: item implies a memory leak, the container bound to this item must
	// be assigned to self and this item discarded.
	//id item = [[ETEtoileUIBuilder builder] renderWindow: window];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: 
		[[ETEtoileUIBuilder builder] renderWindow: window]];

	ASSIGN(masterViewItem, [itemGroupView layoutItem]);
	ASSIGN(detailViewItem, [propertyView layoutItem]);

	[layoutPopup removeAllItems];
	FOREACH([ETLayout registeredLayoutClasses], layoutClass, Class)
	{
		[layoutPopup addItemWithTitle: [layoutClass displayName]];
		[[layoutPopup lastItem] setRepresentedObject: layoutClass];
	}
	
	[toolPopup removeAllItems];
	FOREACH([ETTool registeredToolClasses], toolClass, Class)
	{
		[toolPopup addItemWithTitle: [toolClass displayName]];
		[[toolPopup lastItem] setRepresentedObject: toolClass];
	}

	[masterViewItem setLayout: [ETOutlineLayout layout]];
	// TODO: Figure out a nice way to restore the layout as is because 
	// displayed properties are lost on layout changes (happens only if the 
	// user wants to customize the inspector UI).
	[[masterViewItem layout] setDisplayedProperties: 
		A(kETIconProperty, kETDisplayNameProperty, kETIdentifierProperty)];
	[[masterViewItem layout] setDisplayName: @"Identifier" forProperty: kETIdentifierProperty];
	[[[masterViewItem layout] columnForProperty: kETDisplayNameProperty] setWidth: 140];
	[[[masterViewItem layout] columnForProperty: kETIdentifierProperty] setWidth: 120];
	[masterViewItem setSource: masterViewItem];
	[masterViewItem setDelegate: self];
	[masterViewItem setDoubleAction: @selector(doubleClickInItemGroupView:)];
	[masterViewItem setTarget: self];

	[detailViewItem setLayout: [ETViewModelLayout layout]];
	[(id)[detailViewItem layout] setShouldInspectRepresentedObjectAsView: YES];
}

- (void) itemGroupSelectionDidChange: (NSNotification *)notif
{
	ETDebugLog(@"Selection did change for %@ received in %@", [notif object], self);

	ETLayoutItem *selectedItem = [[masterViewItem selectedItemsInLayout] firstObject];
	ETLayoutItem *inspectedItem = [selectedItem representedObject];

	[detailViewItem setRepresentedObject: inspectedItem];
	[detailViewItem updateLayout];
}

- (id) selectedObject
{
	return [[[masterViewItem selectedItemsInLayout] firstObject] representedObject];
}

- (IBAction) changeLayout: (id)sender
{
	Class layoutClass = [[sender selectedItem] representedObject];

	[[[self selectedObject] ifResponds] setLayout: [layoutClass layout]];
}

- (IBAction) changeTool: (id)sender
{
	Class toolClass = [[sender selectedItem] representedObject];
	
	[[(ETLayoutItem *)[[self selectedObject] ifResponds] layout] 
		setAttachedTool: [toolClass tool]];
}

- (NSArray *) inspectedObjects
{
	return _inspectedObjects;
}

- (void) setInspectedObjects: (NSArray *)objects
{
	if ([objects isEmpty])
	{
		ASSIGN(_inspectedObjects, nil);
	}
	else
	{
		ASSIGN(_inspectedObjects, objects);
		[masterViewItem setRepresentedObject: _inspectedObjects];
		[masterViewItem reloadAndUpdateLayout];
	}
	[self setRepresentedObject: nil];
	
	[self updateInspectorWindowTitle];
}

- (void) updateInspectorWindowTitle
{
	id inspectedItem = [[self inspectedObjects] firstObject];
	
	if (inspectedItem == nil)
		return;

	NSString *name = [inspectedItem displayName];
	
	[self setRepresentedObject: inspectedItem];
	
	if ([name length] > 25)
		name = [[name substringToIndex: 25] stringByAppendingString: @"…"];

	[[self window] setTitle: name];
}

- (NSWindow *) window
{
	return window;
}

- (NSPanel *) panel
{
	return (NSPanel *)window;
}

- (IBAction) inspect: (id)sender
{
	[[NSApplication sharedApplication] sendAction: @selector(inspect:) to: nil from: sender];
}

@end



@implementation NSObject (ETInspector)

- (id <ETInspector>) inspector
{
	ETInspector *inspector = [[ETInspector alloc] init];

	return AUTORELEASE(inspector);
}

@end
