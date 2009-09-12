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
#import "ETInstrument.h"
#import "ETViewModelLayout.h"
#import "ETLayoutItem+Reflection.h"
#import "ETLayoutItemGroup.h"
#import "ETOutlineLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETUIItemFactory.h"
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

- (id) init
{
	return [self initWithView: nil value: nil representedObject: nil];
}

- (ETLayoutItem *) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	self = (ETInspector *)[super initWithView: view value: value representedObject: repObject];
	
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
	[[[ETUIItemFactory factory] windowGroup] addItem: 
		[[ETEtoileUIBuilder builder] renderWindow: window]];

	ASSIGN(masterViewItem, [itemGroupView layoutItem]);
	ASSIGN(detailViewItem, [propertyView layoutItem]);

	[layoutPopup removeAllItems];
	FOREACH([ETLayout registeredLayoutClasses], layoutClass, ETLayout *)
	{
		[layoutPopup addItemWithTitle: [layoutClass displayName]];
		[[layoutPopup lastItem] setRepresentedObject: layoutClass];
	}
	
	[instrumentPopup removeAllItems];
	FOREACH([ETInstrument registeredInstrumentClasses], instrumentClass, ETInstrument *)
	{
		[instrumentPopup addItemWithTitle: [instrumentClass displayName]];
		[[instrumentPopup lastItem] setRepresentedObject: instrumentClass];
	}

	[masterViewItem setLayout: [ETOutlineLayout layout]];
	// TODO: Figure out a nice way to restore the layout as is because 
	// displayed properties are lost on layout changes (happens only if the 
	// user wants to customize the inspector UI).
	[[masterViewItem layout] setDisplayedProperties: 
		A(kETIconProperty, kETDisplayNameProperty, kETUIMetalevelProperty)];
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
	[detailViewItem reloadAndUpdateLayout];
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

- (IBAction) changeInstrument: (id)sender
{
	Class instrumentClass = [[sender selectedItem] representedObject];
	
	[[(ETLayoutItem *)[[self selectedObject] ifResponds] layout] 
		setAttachedInstrument: [instrumentClass instrument]];
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
	NSString *inspectorTitle = nil;
	
	[self setRepresentedObject: inspectedItem];
	
	if ([name length] > 25)
		name = [[name substringToIndex: 25] stringByAppendingString: @"…"];
	inspectorTitle = [NSString stringWithFormat: @"%@ (M%d UI)", name,
		[self UIMetalayer]];
	[[self window] setTitle: inspectorTitle];
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
