/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
	License:  Modified BSD  (see COPYING)
 */
 
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import "ETPaneLayout.h"
#import "ETCompatibility.h"
#import "ETGeometry.h"
#import "ETSelectTool.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayoutItemGroup.h"
#import "ETLineLayout.h"
#import "ETTableLayout.h"
#import "ETOutlineLayout.h"
#import "ETBrowserLayout.h"
#import "ETLayoutItemFactory.h"
#import "EtoileUIProperties.h"

@interface ETPaneLayout (Private)
- (void) setContentItem: (ETLayoutItemGroup *)anItem;
@end


@implementation ETPaneLayout

/** Returns a new autoreleased pane layout.

See -initWithBarItem:contentItem:objectGraphContext:. */
+ (id) layoutWithBarItem: (ETLayoutItemGroup *)barItem
             contentItem: (ETLayoutItemGroup *)contentItem
      objectGraphContext: (COObjectGraphContext *)aContext
{
	return AUTORELEASE([[[self class] alloc] initWithBarItem: barItem
	                                             contentItem: contentItem
	                                      objectGraphContext: aContext]);
}

/** <init />Initializes and returns a new pane layout.

If barItem is nil, a default bar item will be created.
If contentItem is nil, a default content item will be created. */
- (id) initWithBarItem: (ETLayoutItemGroup *)barItem
           contentItem: (ETLayoutItemGroup *)contentItem
    objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithRootItem: AUTORELEASE([ETLayoutItemGroup new])
	         firstPresentationItem: nil
	            objectGraphContext: aContext];
	if (self == nil)
		return nil;

	if (nil != contentItem)
	{
		[self setContentItem: contentItem];
	}
	else
	{
		[self setContentItem: [[ETLayoutItemFactory factoryWithObjectGraphContext: aContext] itemGroup]];
	}

	if (nil != barItem)
	{
		[self setBarItem: barItem];
	}
	else
	{
		[self setBarItem: [[ETLayoutItemFactory factoryWithObjectGraphContext: aContext] itemGroup]];
	}
	//[_barItem setAutoresizingMask: NSViewWidthSizable];
	[_barItem setLayout: [ETTableLayout layoutWithObjectGraphContext: aContext]];
	_barPosition = ETPanePositionTop;
	_barThickness = 140;

	[[_barItem layout] setAttachedTool: [ETSelectTool tool]];

	return self;
}

// TODO: Remove and clean the initialization chain in ETCompositeLayout class hierarchy.
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	return [self initWithBarItem: nil contentItem: nil objectGraphContext: aContext];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	DESTROY(_contentItem);
	DESTROY(_barItem);
	DESTROY(_currentItem);
	[super dealloc];
}

- (void) setUpCopyWithZone: (NSZone *)aZone 
                  original: (ETPaneLayout *)layoutOriginal
{
	[super setUpCopyWithZone: aZone original: layoutOriginal];

	/* We figure out the bar item, content item and current item index path in 
	   the original to look up the same items in the copy.
	   We could simply look up the index, we look up the index path in case 
	   subclasses want to place those items elsewhere than in the holder item 
	   itself (e.g. in a descendant). */
	NSIndexPath *barIndexPath = [[layoutOriginal holderItem] indexPathForItem: [layoutOriginal barItem]];
	NSIndexPath *contentIndexPath = [[layoutOriginal holderItem] indexPathForItem: [layoutOriginal contentItem]];
	NSIndexPath *currentIndexPath = [[layoutOriginal holderItem] indexPathForItem: [layoutOriginal currentItem]];
	ETLayoutItemGroup *barItemCopy = (id)[[self holderItem] itemAtIndexPath: barIndexPath];
	ETLayoutItemGroup *contentItemCopy = (id)[[self holderItem] itemAtIndexPath: contentIndexPath];
	/* The current item will be a proxy (as a tab item) on the item displayed 
	   in the content in some subclasses such as ETMasterDetailPaneLayout. 
	   See -beginVisitingItem: */
	ETLayoutItem *currentItemCopy = [[self holderItem] itemAtIndexPath: currentIndexPath];

	ASSIGN(_barItem, barItemCopy);
	ASSIGN(_contentItem, contentItemCopy);
	ASSIGN(_currentItem, currentItemCopy);
	_barPosition = layoutOriginal->_barPosition;
	_barThickness = layoutOriginal->_barThickness;

	/* Replicate the observer set up in -setBarItem: */
	[[NSNotificationCenter defaultCenter] 
		   addObserver: self
	          selector: @selector(itemGroupSelectionDidChange:)
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: _barItem];
}

/** Returns the height or width to be set on the bar item in -tile.

By default, returns 200.

See also -setBarThickness:. */
- (CGFloat) barThickness
{
	return _barThickness;
}

/** Sets the height or width to be set on the bar item in -tile.

When -barPosition returns ETPanePositionLeft or ETPanePositionRight, sets the 
bar item width, otherwise sets the bar item height.  */
- (void) setBarThickness: (CGFloat)aThickness
{
	_barThickness = aThickness;
}

- (void) tileContent
{

}

- (CGFloat) maxAllowedBarThicknessForPosition: (ETPanePosition)aBarPosition
{
	NSSize maxSize = [[self holderItem] size];
	CGFloat thickness = [self barThickness];

	switch (aBarPosition)
	{
		case ETPanePositionTop:
		case ETPanePositionBottom:
			thickness = (maxSize.height > thickness ? thickness : maxSize.height);
			break;
		case ETPanePositionLeft:
		case ETPanePositionRight:
			thickness = (maxSize.width > thickness ? thickness : maxSize.width);
			break;
		case ETPanePositionNone:
			thickness = 0;
			break;
		default:
			ASSERT_INVALID_CASE;
	}

	return thickness;	
}

- (void) tile
{
	/* With no layout context, rootSize is zero and the item sizes can be negative. */
	if (nil == _layoutContext)
		return;

	// FIXME: Handle the next line in a more transparent way in ETLayout
	[self syncLayerItemGeometryWithSize: [[self layoutContext] visibleContentSize]];

	NSSize rootSize = [[self holderItem] size];
	CGFloat barThickness = [self maxAllowedBarThicknessForPosition: _barPosition];

	[[self contentItem] setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];

	if (_barPosition == ETPanePositionNone)
	{
		[[self barItem] setVisible: NO];
		[[self contentItem] setFrame: ETMakeRect(NSZeroPoint, rootSize)];
		[[self barItem] setAutoresizingMask: ETAutoresizingNone];
		[[self contentItem] setAutoresizingMask: ETAutoresizingNone];
	}
	else if (_barPosition == ETPanePositionTop)
	{
		[[self barItem] setFrame: NSMakeRect(0, 0, rootSize.width, barThickness)];
		[[self contentItem] setFrame: NSMakeRect(0, barThickness, rootSize.width, rootSize.height - barThickness)];
		//[[self barItem] setAutoresizingMask: ETAutoresizingFlexibleBottomMargin | ETAutoresizingFlexibleWidth];
	}
	else if (_barPosition == ETPanePositionBottom)
	{
		[[self barItem] setFrame: NSMakeRect(0, rootSize.height - barThickness, rootSize.width, barThickness)];
		[[self contentItem] setFrame: NSMakeRect(0, 0, rootSize.width, rootSize.height - barThickness)];
		[[self barItem] setAutoresizingMask: ETAutoresizingFlexibleTopMargin | ETAutoresizingFlexibleWidth];
	}
	else if (_barPosition == ETPanePositionLeft)
	{
		[[self barItem] setFrame: NSMakeRect(0, 0, barThickness, rootSize.height)];
		[[self contentItem] setFrame: NSMakeRect(barThickness, 0, rootSize.width - barThickness, rootSize.height)];
		[[self barItem] setAutoresizingMask: ETAutoresizingFlexibleRightMargin | ETAutoresizingFlexibleHeight];

	}
	else if (_barPosition == ETPanePositionRight)
	{
		[[self barItem] setFrame: NSMakeRect(rootSize.width - barThickness, 0, barThickness, rootSize.height)];
		[[self contentItem] setFrame: NSMakeRect(0, 0, rootSize.width - barThickness, rootSize.height)];
		[[self barItem] setAutoresizingMask: ETAutoresizingFlexibleLeftMargin | ETAutoresizingFlexibleHeight];
	}
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
		[[self holderItem] removeItem: _contentItem];
	}

	ASSIGN(_contentItem, anItem);

	if ([anItem identifier] == nil)
	{
		 /* For debugging */
		[anItem setIdentifier: [NSString stringWithFormat: @"contentItem in %@", self]];
	}
	[anItem setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	[[self holderItem] addItem: anItem];
	[self tile];
}

- (BOOL) ensuresContentFillsVisibleArea
{
	return _ensuresContentFillsVisibleArea;
}

- (void) setEnsuresContentFillsVisibleArea: (BOOL)fill
{
	_ensuresContentFillsVisibleArea = fill;
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
	[[self barItem] updateLayout];
	[[self contentItem] updateLayout];
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
		[[self holderItem] removeItem: _barItem];
	}

	ASSIGN(_barItem, anItem);

	if ([anItem identifier] == nil)
	{
		 /* For debugging */
		[anItem setIdentifier: [NSString stringWithFormat: @"barItem in %@", self]];
	}
	[anItem setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[[self holderItem] addItem: anItem];
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
	return [[self barItem] isDescendantItem: anItem];
}

- (void) selectItemIfNeeded: (ETLayoutItem *)anItem
{
	/* visitedItemGroup is usually the bar item */
	ETLayoutItemGroup *visitedItemGroup = [anItem parentItem];

	if ([self shouldSelectVisitedItem: anItem] 
	 && [visitedItemGroup isChangingSelection] == NO)
	{
		NSUInteger visitedIndex = [visitedItemGroup indexOfItem: anItem];

		[visitedItemGroup setSelectionIndex: visitedIndex];
	}
}

// TODO: Allows a default pane to be shown with -goToItem: -setStartItem: 
// and -startItem.
- (BOOL) goToItem: (ETLayoutItem *)anItem isSelectionAction: (BOOL)isSelectionAction
{
	if ([self isCurrentItem: anItem])
		return YES;

	if ([self canGoToItem: anItem] == NO)
	{
		// TODO: Will make the selection jump back, but required when isSelectionAction is YES
		[self selectItemIfNeeded: _currentItem];
		return NO;
	}

	_isSwitching = YES;

	NSParameterAssert([anItem parentItem] != nil);

	if (_currentItem != nil)
	{
		// FIXME: When -reload is invoked on the bar item, e.g. -[ETMasterContentPaneLayout beginVisitingItem],
		// _currentItem is invalid and won't have a parent item.
		// We should probably have ETLayoutItemGroup posts a reload notif and 
		// go to a nil item when we receive it.
		// ETAssert([_currentItem parentItem] != nil);

		[self endVisitingItem: _currentItem];
		//[[self contentItem] removeItem: [_currentItem representedObject]];
	}

	ASSIGN(_currentItem, [self beginVisitingItem: anItem]);

	[self selectItemIfNeeded: _currentItem];
	[self tileContent];

	_isSwitching = NO;

	return YES;
}

- (BOOL) goToItem: (ETLayoutItem *)anItem
{
	return [self goToItem: anItem isSelectionAction: NO];
}

/* Propagates pane switch done in bar to content. */
- (void) itemGroupSelectionDidChange: (NSNotification *)notif
{
	//ETLog(@"Pane layout %@ receives selection change from %@", self, [notif object]);

	NSAssert1([[notif object] isEqual: [self barItem]], @"Selection "
		"notification must be posted by the bar item in %@", self);
	NSAssert1([[[self barItem] selectedItems] count] <= 1, @"Only a single "
		"item  at a time must be selected in the bar item in %@", self);

	/* When -goToItem: is underway and a subclass tries to update the selection */
	if (_isSwitching)
		return;

	ETLayoutItem *barElementItem = [[[self barItem] selectedItemsInLayout] firstObject];
	[self goToItem: barElementItem isSelectionAction: YES];
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

/** <override-dummy />
Returns whether the given item should appear selected in the UI.

The item is the one returned by -beginVisitingItem:.

By default, returns NO. */
- (BOOL) shouldSelectVisitedItem: (ETLayoutItem *)tabItem
{
	return NO;
}

/* Layouting */

- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[self tile];
}

@end


@interface ETMasterDetailPaneLayout : ETPaneLayout
@end

@implementation ETMasterDetailPaneLayout

- (void) setUpCopyWithZone: (NSZone *)aZone 
                  original: (ETMasterDetailPaneLayout *)layoutOriginal
{
	[super setUpCopyWithZone: aZone original: layoutOriginal];

	if ([layoutOriginal currentItem] == nil)
		return;

	/* We figure out the visited item and current item index in the original to 
	   look up the same item in the copy.
	   The current item is a proxy on the item displayed in the content and 
	   this proxy is inserted in the bar item by -beginVisitingItem: to play a 
	   tab item role.
	   The represented object is not copied in a layout item, which 
	   means we must adjust the copy of the visited item proxy to now point on 
	   the visited item copy.  */
	unsigned int visitedItemIndex = [[layoutOriginal contentItem] indexOfItem: [[layoutOriginal currentItem] representedObject]];
	unsigned int visitedItemProxyIndex = [[layoutOriginal barItem] indexOfItem: [layoutOriginal currentItem]];
	ETLayoutItem *visitedItemCopy = [[self contentItem] itemAtIndex: visitedItemIndex];
	ETLayoutItem *visitedItemProxyCopy = [[self barItem] itemAtIndex: visitedItemProxyIndex];

	[visitedItemProxyCopy setRepresentedObject: visitedItemCopy];
}

- (void) setBarItem: (ETLayoutItemGroup *)barItem
{
	[super setBarItem: barItem];
	[self setFirstPresentationItem: barItem];
}

- (BOOL) shouldFillContentItemWithItem: (ETLayoutItem *)anItem
{
	// FIXME: Remove the last two ugly cases
	return ([self ensuresContentFillsVisibleArea] 
		|| [[anItem layout] isKindOfClass: [ETCompositeLayout class]] 
		|| [[anItem ifResponds] controller] != nil);
}

- (void) tileContent
{
	if ([[self contentItem] isEmpty])
		return;

	ETLayoutItem *anItem = [[self contentItem] firstItem];
	NSSize contentSize = [[self contentItem] size];

	if ([self shouldFillContentItemWithItem: anItem])
	{
		[anItem setSize: contentSize];
		[anItem setOrigin: NSZeroPoint];
	}
	else /* Center */
	{
		// TODO: Shows scroller if item size > content size
		[anItem setAnchorPoint: NSMakePoint([anItem width] * 0.5, [anItem height] * 0.5)];
		[anItem setPosition: NSMakePoint(contentSize.width * 0.5, contentSize.height * 0.5)];
	}
}

/* Returns a new tab item that represents and replaces in the bar item the tab 
item that just got selected and moved into the content item. */
- (ETLayoutItem *) visitedItemProxyWithItem: (ETLayoutItem *)paneItem
{
	ETLayoutItem *tabItem = [[ETLayoutItemFactory factory] itemWithRepresentedObject: paneItem];
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
	NSValue *frameBeforeVisit = [NSValue valueWithRect: [tabItem frame]];

	[tabItem setDefaultValue: frameBeforeVisit forProperty: kETFrameProperty];	

	[[tabItem parentItem] insertItem: visitedItemProxy atIndex: tabIndex];
	[[self contentItem] addItem: tabItem];

	/* The tab item content shouldn't appear as selected */
	[tabItem setSelected: NO];

	return visitedItemProxy;
}

/** Eliminates the given proxy items in the bar item by replacing them with 
the real items they currently represent. */
- (void) endVisitingItem: (ETLayoutItem *)tabItem
{
	NSParameterAssert([tabItem isMetaItem]);

	ETLayoutItem *visitedItem = [tabItem representedObject];
	unsigned int tabIndex = [[tabItem parentItem] indexOfItem: tabItem];
	NSValue *frameBeforeVisit = [visitedItem defaultValueForProperty: kETFrameProperty];
 
	[[tabItem parentItem] insertItem: visitedItem atIndex: tabIndex];
	[tabItem removeFromParent];

	[visitedItem setValue: frameBeforeVisit forProperty: kETFrameProperty];
	// FIXME: [visitedItem setDefaultValue: nil forProperty: kETFrameProperty];
}

- (BOOL) shouldSelectVisitedItem: (ETLayoutItem *)anItem
{
	return YES;
}

- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[self tile];
	if (isNewContent)
	{
		[self goToItem: [[self barItem] firstItem]];
	}
	/* -tileContent requires both the current item and content item frame to 
	    have been updated, so the content item size can be use to compute 
		position and resize the current item. */
	[self tileContent];
}

@end

@interface ETMasterContentPaneLayout : ETPaneLayout
@end

@implementation ETMasterContentPaneLayout

- (id) initWithBarItem: (ETLayoutItemGroup *)barItem
           contentItem: (ETLayoutItemGroup *)contentItem
    objectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithBarItem: barItem contentItem: contentItem objectGraphContext: aContext];
	if (nil == self)
		return nil;

	[barItem setLayout: [ETOutlineLayout layoutWithObjectGraphContext: aContext]];
	[contentItem setLayout: [ETOutlineLayout layoutWithObjectGraphContext: aContext]];

	return self;
}

- (void) setUpCopyWithZone: (NSZone *)aZone 
                  original: (ETMasterDetailPaneLayout *)layoutOriginal
{
	[super setUpCopyWithZone: aZone original: layoutOriginal];

	if ([layoutOriginal currentItem] == nil)
		return;

	if ([[[layoutOriginal contentItem] representedObject] isEqual: [layoutOriginal currentItem]] == NO)
		return;
	
	/* We figure out the visited item and current item index in the original to 
	   look up the same item in the copy.
	   The represented object is not copied in a layout item, which 
	   means we must adjust the copy of the content item to now point on 
	   the visited item copy as represented object.  */
	unsigned int visitedItemIndex = [[layoutOriginal barItem] indexOfItem: [layoutOriginal currentItem]];
	ETLayoutItem *visitedItemCopy = [[self barItem] itemAtIndex: visitedItemIndex];

	[[self contentItem] setRepresentedObject: visitedItemCopy];
}

- (void) setBarItem: (ETLayoutItemGroup *)barItem
{
	[super setBarItem: barItem];
	[self setFirstPresentationItem: barItem];
}

- (ETLayoutItemGroup *) presentationItem
{
	if ([[[self contentItem] layout] isKindOfClass: [ETPaneLayout class]])
	{
		return [[[self contentItem] layout] barItem];
	}
	else
	{
		return [self contentItem];
	}
}

- (id) beginVisitingItem: (ETLayoutItem *)tabItem
{
	ETLayoutItemGroup *presentationItem = [self presentationItem];

	[presentationItem setSource: presentationItem];
	[presentationItem setRepresentedObject: [tabItem subject]];
	[presentationItem reloadAndUpdateLayout];
	return tabItem;
}

/** Eliminates the given proxy items in the bar item by replacing them with 
the real items they currently represent. */
- (void) endVisitingItem: (ETLayoutItem *)tabItem
{
	[[self contentItem] setRepresentedObject: nil];
}

- (BOOL) shouldSelectVisitedItem: (ETLayoutItem *)anItem
{
	return YES;
}

- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
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
+ (ETPaneLayout *) masterDetailLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	return [ETMasterDetailPaneLayout layoutWithObjectGraphContext: aContext];
}

/** Returns a new autoreleased pane selector layout.<br />
The bar item is the master view and the content item is the content view. */
+ (ETPaneLayout *) masterContentLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	return [ETMasterContentPaneLayout layoutWithObjectGraphContext: aContext];
}

+ (ETPaneLayout *) slideshowLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETPaneLayout *layout = [self layoutWithObjectGraphContext: aContext]; // self is ETPaneLayout class here
	[layout setBarPosition:	ETPanePositionNone];
	return layout;
}

+ (ETPaneLayout *) slideshowLayoutWithNavigationBarWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETPaneLayout *layout = [self layoutWithObjectGraphContext: aContext];
	[[layout barItem] setLayout: [ETLineLayout layoutWithObjectGraphContext: aContext]];
	[[[layout barItem] layout] setAttachedTool: [ETSelectTool tool]];
	[[layout barItem] setHasHorizontalScroller: YES];
	return layout;
}

+ (ETPaneLayout *) drillDownLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETPaneLayout *layout = [self layoutWithObjectGraphContext: aContext];
	[[layout barItem] setLayout: [ETBrowserLayout layoutWithObjectGraphContext: aContext]];
	[[[layout barItem] layout] setAttachedTool: [ETSelectTool tool]];
	[layout setBarPosition: ETPanePositionLeft];
	return layout;
}

+ (ETPaneLayout *) paneNavigationLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETPaneLayout *layout = [self layoutWithObjectGraphContext: aContext];
	return layout;
}

+ (ETPaneLayout *) wizardLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	ETPaneLayout *layout = [self layoutWithObjectGraphContext: aContext];
	return layout;
}

@end
