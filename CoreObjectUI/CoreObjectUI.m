/**
	Copyright (C) 2012 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  January 2012
	License: Modified BSD (see COPYING)
 */


#import "ETCompatibility.h"

#ifdef COREOBJECT

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
#import "ETLineLayout.h"
#import "ETOutlineLayout.h"

@interface COObject (EtoileUI)
- (NSImage *) icon;
@end

@interface COLibrary (EtoileUI)
- (NSImage *) icon;
@end

@interface COGroup (EtoileUI)
- (NSImage *) icon;
@end

@interface COTag (EtoileUI)
- (NSImage *) icon;
@end

@interface COTagGroup (EtoileUI)
- (NSImage *) icon;
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

@implementation CORevision (EtoileUI)

- (COBranch *) branch
{
	COPersistentRoot *persistentRoot =
		[[self editingContext] persistentRootForUUID: [self persistentRootUUID]];

	return [persistentRoot branchForUUID: [self branchUUID]];
}

- (NSImage *) icon
{
	return ([self isEqual: [[self branch] currentNode]] ? [NSImage imageNamed: @"status"] : nil);
}

@end


@implementation ETLayoutItemFactory (CoreObjectUI)

- (ETLayoutItem *) buttonWithIconNamed: (NSString *)aName target: (id)aTarget action: (SEL)anAction
{
	NSImage *icon = [[IKIcon iconWithIdentifier: aName] image];
	return [self buttonWithImage: icon target: aTarget action: anAction];
}

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
	NSDateFormatter *formatter = AUTORELEASE([[NSDateFormatter alloc] 
		initWithDateFormat: @"%1m %B %Y %H:%M" allowNaturalLanguage: YES]);
	[formatter setFormatterBehavior: NSDateFormatterBehavior10_0];
	return formatter;
}

- (ETLayoutItemGroup *) historyBrowserTrackViewWithRepresentedObject: (id <ETCollection>)trackOrRevs controller: (id)aController
{

	ETLayoutItemGroup *browser = [[ETLayoutItemFactory factory] itemGroupWithRepresentedObject: trackOrRevs];
	ETOutlineLayout *layout = [ETOutlineLayout layoutWithObjectGraphContext: [self objectGraphContext]];

	[layout setContentFont: [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]]];
	[layout setDisplayedProperties: A(@"icon", @"UUID", @"type", @"shortDescription", @"date")];
	[layout setDisplayName: @"Revision Number" forProperty: @"revisionNumber"];
	[layout setDisplayName: @"Revision UUID" forProperty: @"UUID"];
	[layout setDisplayName: @"Date" forProperty: @"date"];
	[layout setDisplayName: @"Type" forProperty: @"type"];
	[layout setDisplayName: @"Short Description" forProperty: @"shortDescription"];
	[layout setDisplayName: @"Object UUID" forProperty: @"objectUUID"];
	[layout setDisplayName: @"Properties" forProperty: @"properties"];

	[[layout columnForProperty: @"shortDescription"] setWidth: 200];
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

- (NSString *) trackTitleForRepresentedObject: (id)trackOrRevs
{
	if ([trackOrRevs conformsToProtocol: @protocol(COTrack)])
	{
		return [NSString stringWithFormat: _(@"%@ History"),[trackOrRevs displayName]];
	}
	else
	{
		return _(@"Undetermined Revision or Track Node Collection");
	}
}

- (ETLayoutItemGroup *) historyBrowserWithRepresentedObject: (id <ETCollection>)trackOrRevs
                                                      title: (NSString *)aTitle
{
	/* We set the controller on the track view so it can access the track nodes */
	ETController *controller = AUTORELEASE([[ETHistoryBrowserController alloc] initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]);
	ETLayoutItemGroup *topBar = [self historyBrowserTopBarWithController: controller];
	ETLayoutItemGroup *trackView = [self historyBrowserTrackViewWithRepresentedObject: trackOrRevs controller: controller];
	ETLayoutItemGroup *browser = [self itemGroupWithItems: A(topBar, trackView)];
	
	[browser setName: (aTitle != nil ? aTitle : [self trackTitleForRepresentedObject: trackOrRevs])];
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

- (NSArray *) selectedTrackNodes
{
	return [[[[self content] selectedItems] mappedCollection] representedObject];
}

- (IBAction) selectiveUndo: (id)sender
{
	id <COTrack> track = [[self content] representedObject];

	for (id <COTrackNode> node in [self selectedTrackNodes])
	{
		[track undoNode: node];
	}
}

- (IBAction) moveBackTo: (id)sender
{
	id <COTrack> track = [[self content] representedObject];
	// FIXME: [track undo];
}

- (IBAction) moveForwardTo: (id)sender
{
	id <COTrack> track = [[self content] representedObject];
	// FIXME: [track redo];
}

- (IBAction) restoreTo: (id)sender
{
	id <COTrack> track = [[self content] representedObject];
	id <COTrackNode> node = [[[[self content] selectedItems] firstObject] representedObject];

	if (node == nil)
		return;

	[track setCurrentNode: node];
}

- (IBAction) open: (id)sender
{
	ETLog(@"WARNING: Open at revision is not yet implemented.");
}

@end

#endif
