/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  January 2012
	License: Modified BSD (see COPYING)
 */


#import "ETCompatibility.h"
#import <CoreObject/COBranch.h>
#import <CoreObject/COObject.h>
#import <CoreObject/COGroup.h>
#import <CoreObject/COLibrary.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/CORevision.h>
#import <CoreObject/COTag.h>
#import <CoreObject/COTrack.h>
#import <IconKit/IconKit.h>
#import "CoreObjectUI.h"
#import "ETLayoutItemGroup.h"
#import "ETColumnLayout.h"
#import "ETItemTemplate.h"
#import "ETItemValueTransformer.h"
#import "ETLineLayout.h"
#import "ETOutlineLayout.h"
#include <objc/runtime.h>

@interface COObject (EtoileUI)
@property (nonatomic, readonly, copy) NSImage *icon;
@end

@interface COLibrary (EtoileUI)
@property (nonatomic, readonly, copy) NSImage *icon;
@end

@interface COGroup (EtoileUI)
@property (nonatomic, readonly, copy) NSImage *icon;
@end

@interface COTag (EtoileUI)
@property (nonatomic, readonly, copy) NSImage *icon;
@end

@interface COTagGroup (EtoileUI)
@property (nonatomic, readonly, copy) NSImage *icon;
@end

@implementation COObject (EtoileUI)

+ (NSArray *) menuItems
{
	return [NSArray array];
}

- (NSImage *) icon
{
	return [[IKIcon iconWithIdentifier: @"document-x-generic"] image];
}

@end

@implementation COLibrary (EtoileUI)

- (NSImage *) icon
{
	return [NSImage imageNamed: @"box"];
}

@end

@implementation COGroup (EtoileUI)

- (NSImage *) icon
{
	return [NSImage imageNamed: @"category"];
}

@end

@implementation COTag (EtoileUI)

- (NSImage *) icon
{
	return [NSImage imageNamed: @"price-tag"];
}

@end

@implementation COTagGroup (EtoileUI)

- (NSImage *) icon
{
	return [NSImage imageNamed: @"tags-label"];
}

@end


@implementation ETLayoutItemFactory (CoreObjectUI)

- (ETLayoutItemGroup *) historyBrowserTopBarWithController: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	ETLayoutItem *undoItem = [self buttonWithIconNamed: @"edit-undo" 
	                                                   target: aController
	                                                   action: @selector(selectiveUndo:)];
	ETLayoutItem *moveBackItem = [self buttonWithIconNamed: @"go-previous" 
	                                                   target: aController
	                                                   action: @selector(moveBackTo:)];
	ETLayoutItem *moveForwardItem = [self buttonWithIconNamed: @"go-next" 
	                                                   target: aController
	                                                   action: @selector(moveForwardTo:)];
	ETLayoutItem *restoreItem = [self buttonWithIconNamed: @"system-restart" 
	                                              target: aController
	                                              action: @selector(restoreTo:)];
	ETLayoutItem *openItem = [self buttonWithIconNamed: @"media-playback-start" 
	                                              target: aController
	                                              action: @selector(open:)];
	ETLayoutItem *searchFieldItem = [self searchFieldWithTarget: aController 
	                                                     action: @selector(search:)];
	ETLayoutItem *showDetailsItem = [self buttonWithIconNamed: @"toolbar-flexiblespace" 
	                                              target: aController
	                                              action: @selector(toggleDetails:)];
	//ETLayoutItemGroup *searchItemGroup = [self itemGroupWithItem: searchFieldItem];

	[[(NSSearchField *)[searchFieldItem view] cell] setSendsSearchStringImmediately: YES];

	[itemGroup setHeight: [self defaultIconAndLabelBarHeight]];
	[itemGroup setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	// FIXME: [[itemGroup layout] setSeparatorTemplateItem: [self flexibleSpaceSeparator]];
	[itemGroup addItems: 
		A([self barElementFromItem: undoItem withLabel: _(@"Undo")],
		[self barElementFromItem: moveBackItem withLabel: _(@"Move Back To")],
		[self barElementFromItem: moveForwardItem withLabel: _(@"Move Forward To")],
		[self barElementFromItem: restoreItem withLabel: _(@"Restore To")],
		[self barElementFromItem: openItem withLabel: _(@"Open")],
		[self barElementFromItem: showDetailsItem withLabel: _(@"Show Details")],
		[self barElementFromItem: searchFieldItem withLabel: _(@"Search")]
		)];

	return itemGroup;
}

- (NSDateFormatter *) historyBrowserDateFormatter
{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] 
		initWithDateFormat: @"%1m %B %Y %H:%M" allowNaturalLanguage: YES];
	[formatter setFormatterBehavior: NSDateFormatterBehavior10_0];
	return formatter;
}

- (ETLayoutItemGroup *) historyBrowserTrackViewWithRepresentedObject: (id <COTrack>)aTrack controller: (id)aController
{

	ETLayoutItemGroup *browser = [[ETLayoutItemFactory factory] itemGroupWithRepresentedObject: aTrack];
	ETOutlineLayout *layout = [ETOutlineLayout layoutWithObjectGraphContext: [self objectGraphContext]];

	[layout setContentFont: [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]]];
	[layout setDisplayedProperties: A(@"icon", @"UUID", @"localizedTypeDescription", @"localizedShortDescription", @"date")];
	[layout setDisplayName: @"Revision Number" forProperty: @"revisionNumber"];
	[layout setDisplayName: @"Revision UUID" forProperty: @"UUID"];
	[layout setDisplayName: @"Date" forProperty: @"date"];
	[layout setDisplayName: @"Type" forProperty: @"localizedTypeDescription"];
	[layout setDisplayName: @"Short Description" forProperty: @"localizedShortDescription"];
	[layout setDisplayName: @"Object UUID" forProperty: @"objectUUID"];
	[layout setDisplayName: @"Properties" forProperty: @"properties"];

	[[layout columnForProperty: @"localizedShortDescription"] setWidth: 200];
	[[layout columnForProperty: @"properties"] setWidth: 200];
	[[layout columnForProperty: @"date"] setWidth: 160];
	[layout setFormatter: [self historyBrowserDateFormatter] forProperty: @"date"];

	[browser setController: aController];
	[browser setSource: browser];
	[browser setShouldMutateRepresentedObject: NO];
	[browser setLayout: layout];
	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[browser setSize: NSMakeSize(700, 400)];
	[browser reload];

	return browser;
}

- (NSString *) titleForTrack: (id <COTrack>)aTrack
{
	NSString *trackName = ([aTrack isKindOfClass: [COBranch class]] ? [(NSObject *)aTrack displayName] : _(@"Undo"));

	return [NSString stringWithFormat: _(@"%@ History"), trackName];
}

- (ETLayoutItemGroup *) historyBrowserWithRepresentedObject: (id <COTrack>)aTrack
                                                      title: (NSString *)aTitle
{
	/* We set the controller on the track view so it can access the track nodes */
	ETController *controller = [[ETHistoryBrowserController alloc] initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
	ETLayoutItemGroup *topBar = [self historyBrowserTopBarWithController: controller];
	ETLayoutItemGroup *trackView = [self historyBrowserTrackViewWithRepresentedObject: aTrack controller: controller];
	ETLayoutItemGroup *browser = [self itemGroupWithItems: A(topBar, trackView)];
	
	[browser setName: (aTitle != nil ? aTitle : [self titleForTrack: aTrack])];
	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[browser setLayout: [ETColumnLayout layoutWithObjectGraphContext: [self objectGraphContext]]];

	/* Resize subitems once the layout is set, otherwise their resizing masks  
	   are interpreted based on ETFixedLayout semantics */ 
	[topBar setWidth: [trackView width]];
	[browser setHeight: [trackView height] + [topBar height]];
	[browser setWidth: [trackView width]];

	return browser;
}

@end


@implementation ETHistoryBrowserController

- (instancetype) initWithNibName: (NSString *)aNibName
                bundle: (NSBundle *)aBundle
    objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithNibName: aNibName bundle: aBundle objectGraphContext: aContext];
	if (nil == self)
		return nil;

	ETItemTemplate *template = [self templateForType: [self currentObjectType]];
	ETItemTemplate *groupTemplate = [self templateForType: [self currentGroupType]];

	[[template item] setValueTransformer: [self iconValueTransformer]
	                         forProperty: @"icon"];
	[[groupTemplate item] setValueTransformer: [self iconValueTransformer]
	                              forProperty: @"icon"];

	ETAssert([[[template item] copy] valueTransformerForProperty: @"icon"]
		== [ETItemValueTransformer valueTransformerForName: @"HistoryBrowserIcon"]);

	return self;
}

- (id <COTrack>) track
{
	return [[self content] representedObject];
}

- (ETItemValueTransformer *) iconValueTransformer
{
	ETItemValueTransformer *transformer =
		(id)[ETItemValueTransformer valueTransformerForName: @"HistoryBrowserIcon"];
	
	if (transformer != nil)
		return transformer;

	transformer = [[ETItemValueTransformer alloc] initWithName: @"HistoryBrowserIcon"];

	[transformer setTransformBlock: ^id (id value, NSString *key, ETLayoutItem *item)
	{
		BOOL representsCurrentNode =
			[[item representedObject] isEqual: [[self track] currentNode]];

		return (representsCurrentNode ? [NSImage imageNamed: @"status"] : nil);
	}];

	return transformer;
}

- (NSArray *) selectedTrackNodes
{
	return [[[[self content] selectedItems] mappedCollection] representedObject];
}

- (IBAction) selectiveUndo: (id)sender
{
	for (id <COTrackNode> node in [self selectedTrackNodes])
	{
		[[self track] undoNode: node];
	}
}

- (IBAction) moveBackTo: (id)sender
{
	id <COTrack> track = [self track];
	id <COTrackNode> prevNode = [track nextNodeOnTrackFrom: [track currentNode]
	                                             backwards: YES];
	
	if (prevNode == nil)
		return;

	[track setCurrentNode: prevNode];
}

- (IBAction) moveForwardTo: (id)sender
{
	id <COTrack> track = [self track];
	id <COTrackNode> nextNode = [track nextNodeOnTrackFrom: [track currentNode]
	                                             backwards: NO];
	
	if (nextNode == nil)
		return;

	[track setCurrentNode: nextNode];
}

- (IBAction) restoreTo: (id)sender
{
	NSArray *selectedItems = [[self content] selectedItems];
	// NOTE: For multiple selection, the action must be disabled in the UI
	ETAssert([selectedItems count] == 1);

	id <COTrackNode> node = [[selectedItems firstObject] representedObject];

	if (node == nil)
		return;

	[[self track] setCurrentNode: node];
}

- (IBAction) open: (id)sender
{
	ETLog(@"WARNING: Open at revision is not yet implemented.");
}

@end
