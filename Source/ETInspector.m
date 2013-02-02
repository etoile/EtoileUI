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
#import "ETController.h"
#import "ETTool.h"
#import "ETViewModelLayout.h"
#import "ETLayoutItem+UIBuilder.h"
#import "ETLayoutItemGroup.h"
#import "ETOutlineLayout.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItemFactory.h"
#import "ETView.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"
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

- (ETLayout *)defaultMasterViewLayout
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];

	[layout setContentFont: [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]]];

	// TODO: Figure out a nice way to restore the layout as is because
	// displayed properties are lost on layout changes (happens only if the
	// user wants to customize the inspector UI).
	[layout setDisplayedProperties: A(kETIconProperty, @"UIBuilderName",
		kETIdentifierProperty, @"UIBuilderAction", @"UIBuilderTarget",
		@"UIBuilderModel", @"UIBuilderController")];

	/* Actions are stored as strings in ETLayoutItem variable storage. So we
	 don't need to use a custom property unlike for expressing targets as
	 strings. To do so, we introduce a targetIdentifier property and
	 -[ETLayoutItem target] checks whether this property is set just before
	 returning the target. */
	[layout setDisplayName: @"Name" forProperty: @"UIBuilderName"];
	[layout setDisplayName: @"Identifier" forProperty: kETIdentifierProperty];
	[layout setDisplayName: @"Action" forProperty: @"UIBuilderAction"];
	[layout setDisplayName: @"Target" forProperty: @"UIBuilderTarget"];
	[layout setDisplayName: @"Model" forProperty: @"UIBuilderModel"];
	[layout setDisplayName: @"Controller" forProperty: @"UIBuilderController"];
	
	[[layout columnForProperty: @"UIBuilderName"] setWidth: 140];
	[[layout columnForProperty: kETIdentifierProperty] setWidth: 120];
	[[layout columnForProperty: @"UIBuilderTarget"] setWidth: 100];
	[[layout columnForProperty: @"UIBuilderAction"] setWidth: 100];
	[[layout columnForProperty: @"UIBuilderModel"] setWidth: 100];
	[[layout columnForProperty: @"UIBuilderController"] setWidth: 120];

	[layout setEditable: YES forProperty: @"UIBuilderName"];
	[layout setEditable: YES forProperty: kETIdentifierProperty];
	[layout setEditable: YES forProperty: @"UIBuilderAction"];
	[layout setEditable: YES forProperty: @"UIBuilderTarget"];
	[layout setEditable: YES forProperty: @"UIBuilderModel"];
	[layout setEditable: YES forProperty: @"UIBuilderController"];

	return layout;
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

	[masterViewItem setLayout: [self defaultMasterViewLayout]];
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

- (IBAction) editController: (id)sender
{
	[[[self selectedObject] controller] editCode: sender];
}

- (IBAction) editModel: (id)sender
{
	[[[self selectedObject] representedObject] editCode: sender];
}

@end



@implementation NSObject (ETInspector)

- (id <ETInspector>) inspector
{
	ETInspector *inspector = [[ETInspector alloc] init];

	return AUTORELEASE(inspector);
}

@end
