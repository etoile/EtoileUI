/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
	License:  Modified BSD  (see COPYING)
 */
 
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import "ETPaneLayout.h"
#import "ETCompatibility.h"
#import "NSView+Etoile.h"
#import "ETSelectTool.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETLayoutItemGroup.h"
#import "ETLineLayout.h"
#import "ETTableLayout.h"
#import "ETContainer.h"

@implementation ETPaneLayout

- (id) init
{
	SUPERINIT
	
	// FIXME: Should be -itemGroupWithView...
	ASSIGN(_rootItem, [ETLayoutItem itemGroupWithContainer]);
	[_rootItem setActionHandler: nil];
	ASSIGN(_contentItem, [ETLayoutItem itemGroupWithContainer]);
	[_contentItem setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[_rootItem addItem: _contentItem];
	
	// Move to subclass
	[self setBarItem: [ETLayoutItem itemGroupWithContainer]];
	[_barItem setAutoresizingMask: NSViewWidthSizable];
	[_barItem setLayout: [ETTableLayout layout]];
	[[_barItem layout] setAttachedInstrument: [ETSelectTool instrument]];
	
	[self tile];

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	DESTROY(_contentItem);
	[super dealloc];
}

- (float) barHeightOrWidth
{
	return 50;
}

- (void) tile
{
	//[[self contentItem] setFrame: ETMakeRect(NSZeroPoint, [[self rootItem] size])];
	
	NSSize rootSize = [[self rootItem] size];
	[[self contentItem] setFrame: NSMakeRect(0, [self barHeightOrWidth], rootSize.width, rootSize.height - [self barHeightOrWidth])];
	[[self barItem] setFrame: NSMakeRect(0, 0, rootSize.width, [self barHeightOrWidth])];
}

/** Returns the root item supervisor view. */
- (NSView *) layoutView
{
	return [[self rootItem] supervisorView];
}

/** Returns the main area item where panes are inserted and shown. */
- (ETLayoutItemGroup *) contentItem
{
	return _contentItem;
}

/** Returns the bar area item which can be used to interact with the receiver. */
- (ETLayoutItemGroup *) barItem
{
	return _barItem;
}

/** Sets the bar area item which can be used to interact with the receiver. */
- (void) setBarItem: (ETLayoutItemGroup *)anItem
{
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: _barItem];

	ASSIGN(_barItem, anItem);
	[[self rootItem] addItem: anItem];
	[self tile];

	[[NSNotificationCenter defaultCenter] 
		   addObserver: self
	          selector: @selector(itemGroupSelectionDidChange:)
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: anItem];
}

- (NSView *) contentView
{
	return [[self contentItem] supervisorView];
}

- (BOOL) canGoBack
{
	return ([self backItem] != nil);
}

- (BOOL) canGoForward
{
	return ([self forwardItem] != nil);
}

- (void) goBack
{
	[self goToItem: [self backItem]];
}

- (void) goForward
{
	[self goToItem: [self forwardItem]];
}

/** Returns the current item which is currently displayed inside the content 
item. The current item represents the active pane element. */
- (id) currentItem
{
	return _currentItem;
}

/** Returns the item that comes before to the current item in its parent ite, or 
nil if the current item is the first item. */
- (id) backItem
{
	ETLayoutItem *currentItem = [self currentItem];

	if ([currentItem isEqual: [[currentItem parentItem] firstItem]])
		return nil;

	int currentIndex = [[currentItem parentItem] indexOfItem: currentItem];

	return [[currentItem parentItem] itemAtIndex: currentIndex - 1];
}

/** Returns the item that comes next to the current item in its parent item, or 
nil if the current item is the last item. */
- (id) forwardItem
{
	ETLayoutItem *currentItem = [self currentItem];

	if ([currentItem isEqual: [[currentItem parentItem] lastItem]])
		return nil;

	int currentIndex = [[currentItem parentItem] indexOfItem: currentItem];

	return [[currentItem parentItem] itemAtIndex: currentIndex + 1];
}

// TODO: Allows a default pane to be shown with -goToItem: -setStartItem: 
// and -startItem.
- (void) goToItem: (ETLayoutItem *)anItem
{
	if (anItem == nil)
		return;

	if ([[self currentItem] supervisorView] != nil)
	{
		NSAssert1([[[[self currentItem] supervisorView] superview] isEqual: [self contentView]], 
			@"The current item view is expected to have the content view as superview in %@", self);
		[[[self currentItem] supervisorView] removeFromSuperview];
	}

	ASSIGN(_currentItem, anItem);

	if ([anItem supervisorView] != nil)
	{
		NSSize contentSize = [[self contentView] frame].size;
		NSSize itemSize = [anItem size];
		ETView *itemView = [anItem supervisorView];

		/* Temporarily insert the supervisor view in the content view, will 
		   be moved back when the layout is tear down or we go to another pane. */
		[[self contentView] addSubview: itemView];
		[itemView setFrameOrigin: NSMakePoint(contentSize.width / 2. + itemSize.width / 2,
			contentSize.height / 2. + itemSize.height / 2.)];
	}
}

/* Propagates pane switch done in bar to content. */
- (void) itemGroupSelectionDidChange: (NSNotification *)notif
{
	ETLog(@"Pane layout %@ receives selection change from %@", self, [notif object]);
	
	NSAssert1([[notif object] isEqual: [self barItem]], @"Selection "
		"notification must be posted by the bar item in %@", self);
	NSAssert1([[[self barItem] selectedItems] count] == 1, @"Only a single "
		"item  at a time must be selected in the bar item in %@", self);

	ETLayoutItem *barElementItem = [[[self barItem] selectedItems] firstObject];
	[self goToItem: [barElementItem representedObject]];
	[(ETLayoutItemGroup *)[self layoutContext] updateLayout]; /* Will trigger -[ETLayout render] */
}

- (NSArray *) tabItemsWithItems: (NSArray *)items
{
	NSMutableArray *tabItems = [NSMutableArray array];
	
	FOREACH(items, paneItem, ETLayoutItem *)
	{
		ETLayoutItem *tabItem = [paneItem copy];
		NSImage *img = [tabItem valueForProperty: @"icon"];

		if (img == nil)
			img = [tabItem valueForProperty: @"image"];	

		if (img == nil)
		{
			ETLog(@"WARNING: Pane item  %@ has no image or icon available to "
				  @"be displayed in switcher of %@", paneItem, self);
		}
		[tabItem setRepresentedObject: paneItem];

		[tabItems addObject: tabItem];
	}
	
	return tabItems;
}

- (void) rebuildBarWithItems: (NSArray *)items
{
	[_barItem removeAllItems];
	[_barItem addItems: [self tabItemsWithItems: items]];
	[_barItem updateLayout];
}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if (isNewContent)
	{
		[self rebuildBarWithItems: items];
	}
	
	[self setUpLayoutView];
	if (isNewContent)
	{
		[self goToItem: [items firstObject]];
	}
	[self mapRootItemIntoLayoutContext];
}

- (void) tearDown
{
	[super tearDown];

	FOREACH([[self layoutContext] arrangedItems], item, ETLayoutItem *)
	{
	
	}
}

@end
