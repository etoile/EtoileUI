/*  <title>ETContainer</title>

	ETContainer.m
	
	<abstract>Description forthcoming.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <EtoileFoundation/NSIndexSet+Etoile.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import "ETContainer.h"
#import "ETController.h"
#import "ETDecoratorItem.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "ETActionHandler.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETEvent.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayout.h"
#import "ETLayer.h"
#import "ETInspector.h"
#import "ETPickboard.h"
#import "NSObject+EtoileUI.h"
#import "ETScrollableAreaItem.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETContainer

- (Class) defaultItemClass
{
	return [ETLayoutItemGroup class];
}

- (id) initWithFrame: (NSRect)rect item: (ETUIItem *)anItem
{
	if (anItem != nil && [anItem isLayoutItem] && [(ETLayoutItem *)anItem isGroup] == NO)
	{
		[NSException raise: NSInvalidArgumentException format: @"Layout item "
			@"parameter %@ must be of class ETLayoutItemGroup for initializing "
			@"an ETContainer instance", anItem];
	}

	return [super initWithFrame: rect item: anItem];
}

@end


/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

@implementation ETContainer (Deprecated)

- (id) delegate
{
	return [[self layoutItem] delegate];
}

- (void) setDelegate: (id)delegate
{
	[[self layoutItem] setDelegate: delegate];
}

- (id) source
{
	return [[self layoutItem] source];
}

- (void) setSource: (id)source
{
	[[self layoutItem] setSource: source];
}

- (NSString *) representedPath
{
	return [[self layoutItem] representedPathBase];
}

- (void) setRepresentedPath: (NSString *)path
{
	[[self layoutItem] setRepresentedPathBase: path];
}

/* Inspecting (WARNING CODE TO BE REPLACED BY THE NEW EVENT HANDLING) */

- (IBAction) inspect: (id)sender
{
	[[self layoutItem] inspect: sender];
}

- (IBAction) inspectSelection: (id)sender
{
	ETDebugLog(@"Inspect %@ selection", self);

	id inspector = [[self layoutItem] inspector];

	if (inspector == nil)
		inspector = [[ETInspector alloc] init]; // NOTE: Leak
	[inspector setInspectedObjects: [(id)[self layoutItem] selectedItemsInLayout]];
	[[inspector panel] makeKeyAndOrderFront: self];
}

/* Layout */

/** See -[ETLayoutItemGroup isAutolayout] */
- (BOOL) isAutolayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] isAutolayout];
}

/** See -[ETLayoutItemGroup setAutolayout:] */
- (void) setAutolayout: (BOOL)flag
{
	[(ETLayoutItemGroup *)[self layoutItem] setAutolayout: flag];
}

/** See -[ETLayoutItemGroup canUpdateLayout] */
- (BOOL) canUpdateLayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] canUpdateLayout];
}

/** See -[ETLayoutItemGroup updateLayout] */
- (void) updateLayout
{
	[[self layoutItem] updateLayout];
}

/** See -[ETLayoutItemGroup reloadAndUpdateLayout] */
- (void) reloadAndUpdateLayout
{
	[(ETLayoutItemGroup *)[self layoutItem] reloadAndUpdateLayout];
}

/** See -[ETLayoutItemGroup layout] */
- (ETLayout *) layout
{
	return [(ETLayoutItemGroup *)[self layoutItem] layout];
}

/** See -[ETLayoutItemGroup setLayout] */
- (void) setLayout: (ETLayout *)layout
{
	[(ETLayoutItemGroup *)[self layoutItem] setLayout: layout];
}

/*  Manipulating Layout Item Tree */

/** See -[ETLayoutItemGroup addItem:] */
- (void) addItem: (ETLayoutItem *)anItem
{
	[(ETLayoutItemGroup *)[self layoutItem] addItem: anItem];
}

/** See -[ETLayoutItemGroup insertItem:atIndex:] */
- (void) insertItem: (ETLayoutItem *)anItem atIndex: (int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] insertItem: anItem atIndex: index];
}

/** See -[ETLayoutItemGroup removeItem:] */
- (void) removeItem: (ETLayoutItem *)anItem
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItem: anItem];
}

/** See -[ETLayoutItemGroup removeItem:atIndex:] */
- (void) removeItemAtIndex: (int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItemAtIndex: index];
}

/** See -[ETLayoutItemGroup itemAtIndex:] */
- (ETLayoutItem *) itemAtIndex: (int)index
{
	return [(ETLayoutItemGroup *)[self layoutItem] itemAtIndex: index];
}

/** See -[ETLayoutItemGroup addItems:] */
- (void) addItems: (NSArray *)items
{
	[(ETLayoutItemGroup *)[self layoutItem] addItems: items];
}

/** See -[ETLayoutItemGroup removeItems] */
- (void) removeItems: (NSArray *)items
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItems: items];
}

/** See -[ETLayoutItemGroup removeAllItems] */
- (void) removeAllItems
{
	[(ETLayoutItemGroup *)[self layoutItem] removeAllItems];
}

/** See -[ETLayoutItemGroup indexOfItem:] */
- (int) indexOfItem: (ETLayoutItem *)anItem
{
	return [(ETLayoutItemGroup *)[self layoutItem] indexOfItem: anItem];
}

/** See -[ETLayoutItemGroup containsItem:] */
- (BOOL) containsItem: (ETLayoutItem *)anItem
{
	return [(ETLayoutItemGroup *)[self layoutItem] containsItem: anItem];
}

/** See -[ETLayoutItemGroup numberOfItems] */
- (int) numberOfItems
{
	return [(ETLayoutItemGroup *)[self layoutItem] numberOfItems];
}

/** See -[ETLayoutItemGroup items] */
- (NSArray *) items
{
	return [(ETLayoutItemGroup *)[self layoutItem] items];
}

/** See -[ETLayoutItemGroup selectedItemsInLayout] */
- (NSArray *) selectedItemsInLayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] selectedItemsInLayout];
}

/** See -[ETLayoutItemGroup selectionIndexPaths] */
- (NSArray *) selectionIndexPaths
{
	return [(ETLayoutItemGroup *)[self layoutItem] selectionIndexPaths];
}

/** See -[ETLayoutItemGroup setSelectionIndexPaths] */
- (void) setSelectionIndexPaths: (NSArray *)indexPaths
{
	[(ETLayoutItemGroup *)[self layoutItem] setSelectionIndexPaths: indexPaths];
}

- (void) setSelectionIndexes: (NSIndexSet *)indexes
{
	return [(ETLayoutItemGroup *)[self layoutItem] setSelectionIndexes: indexes];
}

- (NSMutableIndexSet *) selectionIndexes
{
	return [(ETLayoutItemGroup *)[self layoutItem] selectionIndexes];
}

- (void) setSelectionIndex: (unsigned int)index
{
	return [(ETLayoutItemGroup *)[self layoutItem] setSelectionIndex: index];
}

- (unsigned int) selectionIndex
{
	return [(ETLayoutItemGroup *)[self layoutItem] selectionIndex];
}

- (BOOL) allowsMultipleSelection
{
	return YES;
}

- (void) setAllowsMultipleSelection: (BOOL)multiple
{

}

- (BOOL) allowsEmptySelection
{
	return YES;
}

- (void) setAllowsEmptySelection: (BOOL)empty
{

}

/* Scrollers */

- (BOOL) hasVerticalScroller
{
	return [[self layoutItem] hasVerticalScroller];
}

- (void) setHasVerticalScroller: (BOOL)scroll
{
	[[self layoutItem] setHasVerticalScroller: scroll];
}

- (BOOL) hasHorizontalScroller
{
	return [[self layoutItem] hasHorizontalScroller];
}

- (void) setHasHorizontalScroller: (BOOL)scroll
{
	[[self layoutItem] setHasHorizontalScroller: scroll];
}

- (NSScrollView *) scrollView
{
	return [[self layoutItem] scrollView];
}

- (BOOL) isScrollViewShown
{
	return [[self layoutItem] isScrollViewShown];
}

- (void) setShowsScrollView: (BOOL)show
{
	[[self layoutItem] setScrollable: show];
}

/* Actions */

- (void) setTarget: (id)target
{
	[[self layoutItem] setTarget: target];
}

- (id) target
{
	return [[self layoutItem] target];
}

- (void) setDoubleAction: (SEL)selector
{
	return [(ETLayoutItemGroup *)[self layoutItem] setDoubleAction: selector];
}

- (SEL) doubleAction
{
	return [(ETLayoutItemGroup *)[self layoutItem] doubleAction];
}

- (ETLayoutItem *) doubleClickedItem
{
	return [[self layoutItem] doubleClickedItem];
}

- (void) setEnablesHitTest: (BOOL)passHitTest
{ 
 
}

- (BOOL) isHitTestEnabled 
{ 
	return YES; 
}

@end


/* Selection Caching Code (not used currently) */

#if 0
- (void) setSelectionIndexes: (NSIndexSet *)indexes
{
	int numberOfItems = [[self items] count];
	int lastSelectionIndex = [indexes lastIndex];
	
	ETDebugLog(@"Set selection indexes to %@ in %@", indexes, self);
	
	if (lastSelectionIndex > (numberOfItems - 1) && lastSelectionIndex != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		ETLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
			lastSelectionIndex, self, numberOfItems);
		return;
	}
	
	/* Discard previous selection */
	if ([_selection count] > 0)
	{
		NSArray *selectedItems = [[self items] objectsAtIndexes: _selection];
		NSEnumerator *e = [selectedItems objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			[item setSelected: NO];
		}
		[_selection removeAllIndexes];
	}

	/* Update selection */
	if (lastSelectionIndex != NSNotFound)
	{
		/* Cache selection locally in this container */
		if ([indexes isKindOfClass: [NSMutableIndexSet class]])
		{
			ASSIGN(_selection, indexes);
		}
		else
		{
			ASSIGN(_selection, [indexes mutableCopy]);
		}
	
		/* Update selection state in layout items directly */
		NSArray *selectedItems = [[self items] objectsAtIndexes: _selection];
		NSEnumerator *e = [selectedItems objectEnumerator];
		ETLayoutItem *item = nil;
			
		while ((item = [e nextObject]) != nil)
		{
			[item setSelected: YES];
		}
	}
	
	/* Finally propagate changes by posting notification */
	NSNotification *notif = [NSNotification 
		notificationWithName: ETContainerSelectionDidChangeNotification object: self];
	
	if ([[self delegate] respondsToSelector: @selector(containerSelectionDidChange:)])
		[[self delegate] containerSelectionDidChange: notif];

	[[NSNotificationCenter defaultCenter] postNotification: notif];
	
	/* Reflect selection change immediately */
	[self display];
}

- (NSMutableIndexSet *) selectionIndexes
{
	return AUTORELEASE([_selection mutableCopy]);
}

- (void) setSelectionIndex: (int)index
{
	int numberOfItems = [[self items] count];
	
	ETDebugLog(@"Modify selected item from %d to %d of %@", [self selectionIndex], index, self);
	
	/* Check new selection validity */
	NSAssert1(index >= 0, @"-setSelectionIndex: parameter must not be a negative value like %d", index);
	if (index > (numberOfItems - 1) && index != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		ETLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
			index, self, numberOfItems);
		return;
	}

	/* Discard previous selection */
	if ([_selection count] > 0)
	{
		NSArray *selectedItems = [[self items] objectsAtIndexes: _selection];
		NSEnumerator *e = [selectedItems objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			[item setSelected: NO];
		}
		[_selection removeAllIndexes];
	}
	
	/* Update selection */
	if (index != NSNotFound)
	{
		[_selection addIndex: index]; // cache
		[[self itemAtIndex: index] setSelected: YES];
	}
	
	NSAssert([_selection count] == 0 || [_selection count] == 1, @"-setSelectionIndex: must result in either no index or a single index but not more");
	
	/* Finally propagate changes by posting notification */
	NSNotification *notif = [NSNotification 
		notificationWithName: ETContainerSelectionDidChangeNotification object: self];
	
	if ([[self delegate] respondsToSelector: @selector(containerSelectionDidChange:)])
		[[self delegate] containerSelectionDidChange: notif];

	[[NSNotificationCenter defaultCenter] postNotification: notif];
	
	/* Reflect selection change immediately */
	[self display];
}

- (int) selectionIndex
{
	return [_selection firstIndex];
}
#endif
