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
#import "ETLayoutItem+Reflection.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutItemGroup.h"
#import "ETLineLayout.h"
#import "ETTableLayout.h"
#import "ETOutlineLayout.h"
#import "ETBrowserLayout.h"
#import "ETUIItemFactory.h"

@interface ETPaneLayout (Private)
- (void) setContentItem: (ETLayoutItemGroup *)anItem;
@end


@implementation ETPaneLayout

/** Returns a new autoreleased pane layout.<br />
See -initWithBarItem:contentItem:. */
+ (id) layoutWithBarItem: (ETLayoutItemGroup *)barItem contentItem: (ETLayoutItemGroup *)contentItem
{
	return AUTORELEASE([[[self class] alloc] initWithBarItem: barItem contentItem: contentItem]);
}

/** <init />Initializes and returns a new pane layout.

If barItem is nil, a default bar item will be created.
If contentItem is nil, a default content item will be created. */
- (id) initWithBarItem: (ETLayoutItemGroup *)barItem contentItem: (ETLayoutItemGroup *)contentItem
{
	SUPERINIT

	if (nil != contentItem)
	{
		[self setContentItem: contentItem];
	}
	else
	{
		[self setContentItem: [[ETUIItemFactory factory] itemGroup]];
	}

	if (nil != barItem)
	{
		[self setBarItem: barItem];
	}
	else
	{
		[self setBarItem: [[ETUIItemFactory factory] itemGroup]];
	}
	[_barItem setAutoresizingMask: NSViewWidthSizable];
	[_barItem setLayout: [ETTableLayout layout]];
	_barPosition = ETPanePositionTop;
	
	[[_barItem layout] setAttachedInstrument: [ETSelectTool instrument]];
	
	[self tile];

	return self;
}

// TODO: Remove and clean the initialization chain in ETCompositeLayout class hierarchy.
- (id) init
{
	return [self initWithBarItem: nil contentItem: nil];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	DESTROY(_contentItem);
	DESTROY(_barItem);
	DESTROY(_currentItem);
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETPaneLayout *layoutCopy = [super copyWithZone: aZone layoutContext: ctxt];

	/* We figure out the bar item, content item and current item index path in 
	   the original to look up the same items in the copy.
	   We could simply look up the index, we look up the index path in case 
	   subclasses want to place those items elsewhere than in the holder item 
	   itself (e.g. in a descendant). */
	NSIndexPath *barIndexPath = [[self holderItem] indexPathForItem: [self barItem]];
	NSIndexPath *contentIndexPath = [[self holderItem] indexPathForItem: [self contentItem]];
	NSIndexPath *currentIndexPath = [[self holderItem] indexPathForItem: [self currentItem]];
	ETLayoutItemGroup *barItemCopy = (id)[[layoutCopy holderItem] itemAtIndexPath: barIndexPath];
	ETLayoutItemGroup *contentItemCopy = (id)[[layoutCopy holderItem] itemAtIndexPath: contentIndexPath];
	/* The current item will be a proxy (as a tab item) on the item displayed 
	   in the content in some subclasses such as ETMasterDetailPaneLayout. 
	   See -beginVisitingItem: */
	ETLayoutItem *currentItemCopy = (id)[[layoutCopy holderItem] itemAtIndexPath: currentIndexPath];

	ASSIGN(layoutCopy->_barItem, barItemCopy);
	ASSIGN(layoutCopy->_contentItem, contentItemCopy);
	ASSIGN(layoutCopy->_currentItem, currentItemCopy);
	layoutCopy->_barPosition = _barPosition;

	/* Replicate the observer set up in -setBarItem: */
	[[NSNotificationCenter defaultCenter] 
		   addObserver: layoutCopy
	          selector: @selector(itemGroupSelectionDidChange:)
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: layoutCopy->_barItem];

	return layoutCopy;
}

- (float) barHeightOrWidth
{
	return 150;
}

- (void) tileContent
{
	if ([[self contentItem] isEmpty])
		return;

	ETLayoutItem *anItem = [[self contentItem] firstItem];
	NSSize contentSize = [[self contentItem] size];
	NSSize itemSize = [anItem size];

	[anItem setOrigin: NSMakePoint(contentSize.width / 2 - itemSize.width / 2,
		contentSize.height / 2 - itemSize.height / 2)];
}

- (void) tile
{
	// FIXME: Handle the next line in a more transparent way in ETLayout
	[self syncRootItemGeometryWithSize: [[self layoutContext] visibleContentSize]];
	NSSize rootSize = [[self rootItem] size];

	if (_barPosition == ETPanePositionNone)
	{
		[[self barItem] setVisible: NO];
		[[self contentItem] setFrame: ETMakeRect(NSZeroPoint, rootSize)];
	}
	else if (_barPosition == ETPanePositionTop)
	{
		[[self barItem] setFrame: NSMakeRect(0, 0, rootSize.width, [self barHeightOrWidth])];
		[[self contentItem] setFrame: NSMakeRect(0, [self barHeightOrWidth], rootSize.width, rootSize.height - [self barHeightOrWidth])];
	}
	else if (_barPosition == ETPanePositionBottom)
	{
		[[self barItem] setFrame: NSMakeRect(0, rootSize.height - [self barHeightOrWidth], rootSize.width, [self barHeightOrWidth])];
		[[self contentItem] setFrame: NSMakeRect(0, 0, rootSize.width, rootSize.height - [self barHeightOrWidth])];
	}
	else if (_barPosition == ETPanePositionLeft)
	{
		[[self barItem] setFrame: NSMakeRect(0, 0, [self barHeightOrWidth], rootSize.height)];
		[[self contentItem] setFrame: NSMakeRect([self barHeightOrWidth], 0, rootSize.width - [self barHeightOrWidth], rootSize.height)];
	}
	else if (_barPosition == ETPanePositionRight)
	{
		[[self barItem] setFrame: NSMakeRect(rootSize.width - [self barHeightOrWidth], 0, [self barHeightOrWidth], rootSize.height)];
		[[self contentItem] setFrame: NSMakeRect(0, 0, rootSize.width - [self barHeightOrWidth], rootSize.height)];
	}
	
	[self tileContent];
}

/** Returns the main area item where panes are inserted and shown. */
- (ETLayoutItemGroup *) contentItem
{
	return _contentItem;
}

- (void) setContentItem: (ETLayoutItemGroup *)anItem
{
	NSParameterAssert(anItem != nil);

	if (_contentItem != nil)
	{
		[[self rootItem] removeItem: _contentItem];
	}

	ASSIGN(_contentItem, anItem);

	[anItem setName: @"Content item (ETPaneLayout)"]; /* For debugging */
	[anItem setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[[self rootItem] addItem: anItem];
	[self tile];
}

- (ETPanePosition) barPosition
{
	return _barPosition;
}

- (void) setBarPosition: (ETPanePosition)position
{
	if (_barPosition == position)
		return;
	
	_barPosition = position;
	if (_barPosition == ETPanePositionTop || _barPosition == ETPanePositionBottom)
	{
		[_barItem setAutoresizingMask: NSViewWidthSizable];
	}
	else if (_barPosition == ETPanePositionLeft || _barPosition == ETPanePositionRight)
	{
		[_barItem setAutoresizingMask: NSViewHeightSizable];
	}
	[self tile];
}

/** Returns the bar area item which can be used to interact with the receiver. */
- (ETLayoutItemGroup *) barItem
{
	return _barItem;
}

/** Sets the bar area item which can be used to interact with the receiver. */
- (void) setBarItem: (ETLayoutItemGroup *)anItem
{
	NSParameterAssert(anItem != nil);

	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: _barItem];

	if (_barItem != nil) 
	{
		[[self rootItem] removeItem: _barItem];
	}

	ASSIGN(_barItem, anItem);

	[anItem setName: @"Bar item (ETPaneLayout)"]; /* For debugging */
	[anItem setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[[self rootItem] addItem: anItem];
	[self tile];

	[[NSNotificationCenter defaultCenter] 
		   addObserver: self
	          selector: @selector(itemGroupSelectionDidChange:)
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: anItem];
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

/* Return consistently YES when an item proxy (current item) or its real item 
(content item child) is passed. Would otherwise return NO with the content item 
child because it is not a bar child item. */
- (BOOL) isCurrentItem: (ETLayoutItem *)anItem
{
	return ([anItem isEqual: [self currentItem]] || [[self contentItem] containsItem: anItem]);
}

- (BOOL) canGoToItem: (ETLayoutItem *)anItem
{
	return (anItem != nil && [[self barItem] containsItem: anItem]);
}

// TODO: Allows a default pane to be shown with -goToItem: -setStartItem: 
// and -startItem.
- (BOOL) goToItem: (ETLayoutItem *)anItem
{
	if ([self isCurrentItem: anItem])
		return YES;

	if ([self canGoToItem: anItem] == NO)
		return NO;

	NSParameterAssert([anItem parentItem] != nil);

	if (_currentItem != nil)
	{
		NSParameterAssert([_currentItem parentItem] != nil);

		[self endVisitingItem: _currentItem];
		//[[self contentItem] removeItem: [_currentItem representedObject]];
	}

	ASSIGN(_currentItem, [self beginVisitingItem: anItem]);

	[self tileContent];

	return YES;
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
	[self goToItem: barElementItem];
}

- (id) beginVisitingItem: (ETLayoutItem *)tabItem
{
	return tabItem;
}

/** Eliminates the given proxy items in the bar item by replacing them with 
the real items they currently represent. */
- (void) endVisitingItem: (ETLayoutItem *)tabItem
{

}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[self tile];
}

@end


@interface ETMasterDetailPaneLayout : ETPaneLayout
@end

@implementation ETMasterDetailPaneLayout

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETMasterDetailPaneLayout *layoutCopy = [super copyWithZone: aZone layoutContext: ctxt];

	/* We figure out the visited item and current item index in the original to 
	   look up the same item in the copy.
	   The current item is a proxy on the item displayed in the content and 
	   this proxy is inserted in the bar item by -beginVisitingItem: to play a 
	   tab item role.
	   The represented object is not copied in a layout item, which 
	   means we must adjust the copy of the visited item proxy to now point on 
	   the visited item copy.  */
	unsigned int visitedItemIndex = [[self contentItem] indexOfItem: [[self currentItem] representedObject]];
	unsigned int visitedItemProxyIndex = [[self barItem] indexOfItem: [self currentItem]];
	ETLayoutItem *visitedItemCopy = [[layoutCopy contentItem] itemAtIndex: visitedItemIndex];
	ETLayoutItem *visitedItemProxyCopy = [[layoutCopy barItem] itemAtIndex: visitedItemProxyIndex];

	[visitedItemProxyCopy setRepresentedObject: visitedItemCopy];

	return layoutCopy;
}

- (void) setBarItem: (ETLayoutItemGroup *)barItem
{
	[super setBarItem: barItem];
	[self setFirstPresentationItem: barItem];
}

/* Returns a new tab item that represents and replaces in the bar item the tab 
item that just got selected and moved into the content item. */
- (ETLayoutItem *) visitedItemProxyWithItem: (ETLayoutItem *)paneItem
{
	ETLayoutItem *tabItem = [[ETUIItemFactory factory] itemWithRepresentedObject: paneItem];
	NSImage *img = [tabItem valueForProperty: @"icon"];

	if (img == nil)
		img = [tabItem valueForProperty: @"image"];	

	if (img == nil)
	{
		ETLog(@"WARNING: Pane item  %@ has no image or icon available to "
			   "be displayed in switcher of %@", paneItem, self);
	}

	return tabItem;
}

- (id) beginVisitingItem: (ETLayoutItem *)tabItem
{
	ETLayoutItem *visitedItemProxy = [self visitedItemProxyWithItem: tabItem];
	unsigned int tabIndex = [[tabItem parentItem] indexOfItem: tabItem];

	[tabItem setDefaultValue: [NSValue valueWithRect: [tabItem frame]] forProperty: @"frame"];	
	[[tabItem parentItem] insertItem: visitedItemProxy atIndex: tabIndex];
	[[self contentItem] addItem: tabItem];

	return visitedItemProxy;
}

/** Eliminates the given proxy items in the bar item by replacing them with 
the real items they currently represent. */
- (void) endVisitingItem: (ETLayoutItem *)tabItem
{
	NSParameterAssert([tabItem isMetaLayoutItem]);

	ETLayoutItem *visitedItem = [tabItem representedObject];
	unsigned int tabIndex = [[tabItem parentItem] indexOfItem: tabItem];
	NSValue *frameBeforeVisit = [visitedItem defaultValueForProperty: @"frame"];
 
	[[tabItem parentItem] insertItem: visitedItem atIndex: tabIndex];
	[tabItem removeFromParent];
	[visitedItem setValue: frameBeforeVisit forProperty: @"frame"];
	// FIXME: [visitedItem setDefaultValue: nil forProperty: @"frame"];
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if (isNewContent)
	{
		[self goToItem: [[self barItem] firstItem]];
	}
	[self tile];
}

@end


@implementation ETPaneLayout (Factory)

/** Returns a new autoreleased pane selector layout.<br />
The bar item is the master view and the content item is the detail view. */
+ (ETPaneLayout *) masterDetailLayout
{
	return [ETMasterDetailPaneLayout layout];
}

+ (ETPaneLayout *) slideshowLayout
{
	ETPaneLayout *layout = [self layout]; // self is ETPaneLayout class here
	[layout setBarPosition:	ETPanePositionNone];
	return layout;
}

+ (ETPaneLayout *) slideshowLayoutWithNavigationBar
{
	ETPaneLayout *layout = [self layout];
	[[layout barItem] setLayout: [ETLineLayout layout]];
	[[[layout barItem] layout] setAttachedInstrument: [ETSelectTool instrument]];
	[[layout barItem] setHasHorizontalScroller: YES];
	return layout;
}

+ (ETPaneLayout *) drillDownLayout
{
	ETPaneLayout *layout = [self layout];
	[[layout barItem] setLayout: [ETBrowserLayout layout]];
	[[[layout barItem] layout] setAttachedInstrument: [ETSelectTool instrument]];
	[layout setBarPosition: ETPanePositionLeft];
	return layout;
}

+ (ETPaneLayout *) paneNavigationLayout
{
	ETPaneLayout *layout = [self layout];
	return layout;
}

+ (ETPaneLayout *) wizardLayout
{
	ETPaneLayout *layout = [self layout];	
	return layout;
}

@end
