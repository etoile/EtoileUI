/*
	Copyright (C) 2013 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/NSString+Etoile.h>
#import <EtoileFoundation/Macros.h>
#import <IconKit/IconKit.h>
#import "ETUIBuilderItemFactory.h"
#import "EtoileUIProperties.h"
#import "ETColumnLayout.h"
#import "ETController.h"
#import "ETFormLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLineLayout.h"
#import "ETModelDescriptionRenderer.h"
#import "ETOutlineLayout.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETUIBuilderItemFactory

- (id) init
{
	SUPERINIT;
	ASSIGN(renderer, [ETModelDescriptionRenderer renderer]);
	[renderer setGroupingKeyPath: @"owner"];
	return self;
}

- (void) dealloc
{
	DESTROY(renderer);
	[super dealloc];
}

- (ETLayoutItem *) buttonWithIconNamed: (NSString *)aName target: (id)aTarget action: (SEL)anAction
{
	NSImage *icon = [[IKIcon iconWithIdentifier: aName] image];
	return [self buttonWithImage: icon target: aTarget action: anAction];
}

- (ETLayout *) defaultMasterViewLayout
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];

	[layout setContentFont: [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]]];

	// TODO: Figure out a nice way to restore the layout as is because
	// displayed properties are lost on layout changes (happens only if the
	// user wants to customize the inspector UI).
	[layout setDisplayedProperties: A(kETIconProperty, @"UIBuilderName",
		@"UIBuilderIdentifier", @"UIBuilderAction", @"UIBuilderTarget",
		@"UIBuilderModel", @"UIBuilderController")];

	/* Actions are stored as strings in ETLayoutItem variable storage. So we
	   don't need to use a custom property unlike for expressing targets as
	   strings. To do so, we introduce a targetIdentifier property and
	   -[ETLayoutItem target] checks whether this property is set just before
	   returning the target. */
	[layout setDisplayName: @"Name" forProperty: @"UIBuilderName"];
	[layout setDisplayName: @"Identifier" forProperty: @"UIBuilderIdentifier"];
	[layout setDisplayName: @"Action" forProperty: @"UIBuilderAction"];
	[layout setDisplayName: @"Target" forProperty: @"UIBuilderTarget"];
	[layout setDisplayName: @"Model" forProperty: @"UIBuilderModel"];
	[layout setDisplayName: @"Controller" forProperty: @"UIBuilderController"];
	
	[[layout columnForProperty: @"UIBuilderName"] setWidth: 140];
	[[layout columnForProperty: @"UIBuilderIdentifier"] setWidth: 120];
	[[layout columnForProperty: @"UIBuilderTarget"] setWidth: 100];
	[[layout columnForProperty: @"UIBuilderAction"] setWidth: 100];
	[[layout columnForProperty: @"UIBuilderModel"] setWidth: 100];
	[[layout columnForProperty: @"UIBuilderController"] setWidth: 120];

	[layout setEditable: YES forProperty: @"UIBuilderName"];
	[layout setEditable: YES forProperty: @"UIBuilderIdentifier"];
	[layout setEditable: YES forProperty: @"UIBuilderAction"];
	[layout setEditable: YES forProperty: @"UIBuilderTarget"];
	[layout setEditable: YES forProperty: @"UIBuilderModel"];
	[layout setEditable: YES forProperty: @"UIBuilderController"];

	return layout;
}

- (NSSize) defaultInspectorSize
{
	return NSMakeSize(400, 800);
}

- (NSSize) defaultInspectorBodySize
{
	NSSize size = [self defaultInspectorSize];
	size.height -= [self defaultIconAndLabelBarHeight];
	return size;
}

- (NSSize) defaultBrowserSize
{
	NSSize size = [self defaultInspectorBodySize];
	size.height -= [self defaultBasicInspectorSize].height;
	return size;
}

- (NSSize) defaultBasicInspectorSize
{
	NSSize size = [self defaultInspectorBodySize];
	size.height = 500;
	return size;
}

- (ETLayoutItemGroup *) inspectorWithObject: (id)anObject
                                 controller: (id)aController
{
	ETLayoutItemGroup *topBar = [self inspectorTopBarWithController: aController];
	ETLayoutItemGroup *body = [self inspectorBodyWithObject: anObject controller: aController];
	ETLayoutItemGroup *inspector = [self itemGroupWithItems: A(topBar, body)];

	[inspector setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[inspector setLayout: [ETColumnLayout layout]];
	[inspector setSize: [self defaultInspectorSize]];
	[inspector setController: aController];

	ETLog(@"\n%@\n", [inspector descriptionWithOptions: [NSMutableDictionary dictionaryWithObjectsAndKeys: 
		A(@"frame", @"autoresizingMask"), kETDescriptionOptionValuesForKeyPaths,
		@"items", kETDescriptionOptionTraversalKey, nil]]);

	return inspector;
}

- (ETLayoutItem *) viewPopUpWithController: (id)aController
{
	NSArray *choices = A(_(@"Browser"), _(@"Inspector"), _(@"Browser and Inspector"));
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: choices
		                                 representedObjects: [NSArray array]
		                                             target: aController 
		                                             action: @selector(changePresentationViewFromPopUp:)];

	// FIXME: [aController setViewPopUpItem: popUpItem];
	[[popUpItem view] selectItemAtIndex: 2];
	return popUpItem;
}

- (ETLayoutItem *) aspectRepositoryPopUpWithController: (id)aController
{
	NSArray *choices = A(_(@"Browser"), _(@"Inspector"), _(@"Browser and Inspector"));
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: choices
		                                 representedObjects: [NSArray array]
		                                             target: aController 
		                                             action: @selector(changePresentationViewFromPopUp:)];

	// FIXME: [aController setViewPopUpItem: popUpItem];
	[[popUpItem view] selectItemAtIndex: 2];
	return popUpItem;
}

- (ETLayoutItemGroup *) inspectorTopBarWithController: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	ETLayoutItem *inspectItem = [self buttonWithIconNamed: @"list-add"
	                                               target: aController
	                                               action: @selector(inspectSelection:)];
	ETLayoutItem *searchItem = [self searchFieldWithTarget: aController
	                                                action: @selector(filter:)];
	ETLayoutItem *viewItem = [self viewPopUpWithController: aController];
	ETLayoutItem *repoItem = [self aspectRepositoryPopUpWithController: aController];
	ETLayoutItemGroup *rightItemGroup = [self itemGroup];

	[(NSSearchFieldCell *)[[searchItem view] cell] setSendsSearchStringImmediately: YES];

	[itemGroup setIdentifier: @"inspectorTopBar"];
	[itemGroup setWidth: [self defaultBrowserSize].width];
	[itemGroup setHeight: [self defaultIconAndLabelBarHeight]];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setLayout: [ETLineLayout layout]];
	[[itemGroup layout] setSeparatorTemplateItem: [self flexibleSpaceSeparator]];

	[rightItemGroup setLayout: [ETLineLayout layout]];
	[[rightItemGroup layout] setIsContentSizeLayout: YES];

	[rightItemGroup addItems:
	 	A([self barElementFromItem: viewItem withLabel: _(@"View")],
		  [self barElementFromItem: repoItem withLabel: _(@"Aspect Repository")],
		  [self barElementFromItem: searchItem withLabel: _(@"Filter")])];

	[itemGroup addItems:
		A([self barElementFromItem: inspectItem withLabel: _(@"Inspect")],
		  rightItemGroup)];

	return itemGroup;
}

- (ETLayoutItemGroup *) inspectorBodyWithObject: (id)anObject
                                     controller: (id)aController
{
	ETLayoutItemGroup *body = [self itemGroupWithRepresentedObject: anObject];
	ETLayoutItemGroup *browser = [self browserWithObject: anObject
	                                          controller: aController];
	ETLayoutItemGroup *basicInspector = [self basicInspectorWithObject: anObject
	                                                              size: [self defaultBasicInspectorSize]
	                                                        controller: aController];

	[body setIdentifier: @"inspectorBody"];
	[body setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[body setSize: [self defaultInspectorBodySize]]; // FIXME: Avoid negative size if -setSize: is not called
	[body setLayout: [ETColumnLayout layout]];
	[body addItems: A(browser, basicInspector)];

	return body;
}

- (ETLayoutItemGroup *) browserWithObject: (id)anObject
                               controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithRepresentedObject: anObject];
	
	[itemGroup setIdentifier: @"browser"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setSize: [self defaultBrowserSize]];
	[itemGroup setLayout: [self defaultMasterViewLayout]];
	[itemGroup setSource: itemGroup];
	[itemGroup setDelegate: aController];
	[itemGroup setDoubleAction: @selector(doubleClickInItemGroupView:)];
	[itemGroup setTarget: aController];
	[itemGroup setSelectionIndex: 0];

	return itemGroup;
}

- (ETLayoutItemGroup *) basicInspectorWithObject: (id)anObject
                                            size: (NSSize)aSize
                                      controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	ETLayoutItemGroup *header = [self basicInspectorHeaderWithObject: anObject controller: aController];
	ETLayoutItemGroup *pane = [self basicInspectorContentWithObject: anObject controller: aController];

	[itemGroup setIdentifier: @"basicInspector"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setSize: aSize];
	[itemGroup setLayout: [ETColumnLayout layout]];
	[itemGroup addItems: A(header, pane)];

	return itemGroup;
}

- (ETLayoutItem *) aspectPopUpWithController: (id)aController
{
	NSArray *choices = A(_(@"Browser"), _(@"Inspector"), _(@"Browser and Inspector"));
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: choices
		                                 representedObjects: [NSArray array]
		                                             target: aController 
		                                             action: @selector(changePresentationViewFromPopUp:)];

	[popUpItem setName: _(@"Aspect")];
	// FIXME: [aController setViewPopUpItem: popUpItem];
	[[popUpItem view] selectItemAtIndex: 2];
	return popUpItem;
}

- (ETLayoutItem *) typeField
{
	ETLayoutItem *typeField = [self textField];
	[typeField setName: _(@"Type")];
	return typeField;
}

- (ETLayoutItemGroup *) basicInspectorHeaderWithObject: (id)anObject controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	ETFormLayout *formLayout = [ETFormLayout layout];
	ETLayoutItem *aspectPopUpItem = [self aspectPopUpWithController: aController];
	ETLayoutItem *typeFieldItem = [self typeField];
	
	// TODO: Perhaps use aspectInspector
	[itemGroup setIdentifier: @"basicInspectorHeader"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setSize: NSMakeSize([self defaultBasicInspectorSize].width, 80)];
	// TODO: Remove -setSize: and just uses -setIsContentSizeLayout:
	//[formLayout setIsContentSizeLayout: YES];
	[itemGroup setLayout: formLayout];
	[itemGroup addItems: A(aspectPopUpItem, typeFieldItem)];

	return itemGroup;
}

- (NSArray *) presentedPropertyNamesForAspectName: (NSString *)anAspectName ofObject: (id)anObject
{
	return [[(ETLayoutItem *)anObject entityDescription] allUIBuilderPropertyNames];
}

- (ETLayoutItemGroup *) basicInspectorContentWithObject: (id)anObject
                                             controller: (id)aController
{
	[renderer setRenderedPropertyNames: [self presentedPropertyNamesForAspectName: _(@"Layout")
	                                                                     ofObject: [(ETLayoutItem *)anObject layout]]];

	ETLayoutItemGroup *itemGroup = [renderer renderObject: [(ETLayoutItem *)anObject layout]];
	NSSize size = [self defaultBasicInspectorSize];
	
	size.height -= 80;

	// TODO: Perhaps use aspectInspector
	[itemGroup setIdentifier: @"basicInspectorContent"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setSize: size];

	return itemGroup;
}
	 
- (ETLayoutItemGroup *) inspectorPaneWithObject: (id)anObject forAspectName: (NSString *)anAspectName
{
	return nil;
}

@end


@implementation NSObject (UIBuilder)

- (IBAction) inspectUI: (id)sender
{
	ETLayoutItemGroup *inspector = [[ETUIBuilderItemFactory factory]
		inspectorWithObject: self controller: nil];

	[[[ETUIBuilderItemFactory factory] windowGroup] addItem: inspector];
}

@end

