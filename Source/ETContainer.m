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

- (id) initWithLayoutView: (NSView *)layoutView
{
	self = [self initWithFrame: [layoutView frame]];

	if (self != nil)
	{
		id existingSuperview = [layoutView superview];
		ETLayout *layout = [ETLayout layoutWithLayoutView: layoutView];
		
		if ([existingSuperview isContainer]) // existingSuperview must respond to -layoutItem
		{
		   [(ETContainer *)existingSuperview addItem: [self layoutItem]];
		}
		else // existingSuperview isn't a view-based node in a layout item tree
		{
		   [existingSuperview addSubview: self];
		}

		[self setLayout: layout]; // inject the initial view as a layout
	}
	
	return self;
}

/** <init /> Returns a new container instance that is bound to item. This layout 
     item becomes the abstract representation associated with the new container.
     A container plays the role of a concrete representation specific to the 
     underlying UI toolkit, for a collection of layout items.
     item should be an ETLayoutItemGroup instance in almost all cases.
     The returned container is created by default with a flexible height and 
     width, this autoresizingMask also holds for the layout item bound to it. 
    (see -[ETLayoutItem autoresizingMask]). */
- (id) initWithFrame: (NSRect)rect layoutItem: (ETLayoutItem *)item
{
	if (item != nil && [item isGroup] == NO)
	{
		[NSException raise: NSInvalidArgumentException format: @"Layout item "
			@"parameter %@ must be of class ETLayoutItemGroup for initializing "
			@"an ETContainer instance", item];
	}

	/* Before all, bind layout item group representing the container */

	ETLayoutItemGroup *itemGroup = (ETLayoutItemGroup *)item;
	
	if (itemGroup == nil)
		itemGroup = AUTORELEASE([[ETLayoutItemGroup alloc] init]);

	// NOTE: Very important to destroy ETView layout item to avoid any 
	// layout update in ETLayoutItem
	// -setView: -> -setDefaultFrame: -> -restoreDefaultFrame -> -setFrame:
	// then reentering ETContainer
	// -setFrameSize: -> -canUpdateLayout
	// and failing because [self layoutItem] returns ETLayoutItem instance
	// and not ETLayoutItemGroup instance; ETLayoutItem doesn't respond to
	// -canUpdateLayout...
	self = [super initWithFrame: rect layoutItem: itemGroup];
    
	if (self != nil)
    {
		[self setRepresentedPath: @"/"];
		[self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    }
    
    return self;
}

/** Deep copies are never created by the container itself, but they are instead
	delegated to the item group returned by -layoutItem. When the layout item
	receives a deep copy request it will call back -copy on each view (including
	containers) embedded in descendant items. Subview hierarchy will later get 
	transparently reconstructed when -updateLayout will be called on the 
	resulting layout item tree copy.
	
		View Tree							Layout Item Tree
	
	-> [container deepCopy] 
									-> [containerItem deepCopy] 
	-> [container copy]
									-> [childItem deepCopy]
	-> [subview copy] 
	
	For ETView and ETContainer, view copies created by -copy are shallow copies
	that don't include subviews unlike -copy invoked on NSView and other 
	related subclasses. Layout/Display view isn't copied either. However title 
	bar view is copied unlike other subviews (as explained in -[ETView copy]).
	Remember -[NSView copy] returns a deep copy (view hierachy copy) 
	but -[ETView copy] doesn't. */
- (id) deepCopy
{
	id item = [[self layoutItem] deepCopy];
	id container = [item supervisorView];
	
	// TODO: Finish to implement...
	// NSAssert3([container isKindOfClass: [ETContainer class]], 
	
	return container;
}

- (NSString *) description
{
	NSString *desc = [super description];
	
	desc = [@"<" stringByAppendingString: desc];
	desc = [desc stringByAppendingFormat: @" + %@>", [self layout], nil];
	return desc;
}

- (NSString *) displayName
{
	// FIXME: Trim the angle brackets out.
	return [self description];
}

/** Returns the layout item to which the receiver is bound to. 

This layout item can only be an ETLayoutItemGroup instance unlike ETView. See 
also -[ETView setLayoutItem:].

Never returns nil. */
- (id) layoutItem
{
	if ([[super layoutItem] isGroup] == NO)
		ETLog(@"WARNING: Layout item in a container must of ETLayoutItemGroup type");

	return [super layoutItem];
}

/* Private helper methods to sync display view and container */

/** Sets the custom view provided by the layout set on -layoutItem. 

Never calls this method unless you write an ETLayout subclass.

Method called when we switch between layouts. Manipulating the layout view is 
the job of ETContainer, ETLayout instances may provide a layout view prototype
but they never never manipulate it as a subview in view hierachy. */
- (void) setTemporaryView: (NSView *)view
{
	if (_temporaryView == nil && view == nil)
		return;

	if (_temporaryView == view && (_temporaryView != nil || view != nil))
	{
		ETLog(@"WARNING: Trying to assign an identical display view to container %@", self);
		return;
	}
	
	[_temporaryView removeFromSuperview];
	/* Retain indirectly by our layout item which retains the layout that 
	   provides this view. Also retain as a subview by us just below. */
	_temporaryView = view; 

	if (view != nil) /* Set up layout view */
	{
		/* Inserts the layout view */
		[view removeFromSuperview];
		[view setFrameSize: [self frame].size];
		[view setFrameOrigin: NSZeroPoint];
		[self addSubview: view];
	}
}

/* Overriden NSView methods */

/* GNUstep doesn't rely on -setFrameSize: in -setFrame: unlike Cocoa, so we 
   patch frame parameter in -setFrame: too.
   See -setFrame: below to understand the reason behind this method. */
#ifdef GNUSTEP
- (void) setFrame: (NSRect)frame
{
	NSRect patchedFrame = frame;
	
	ETDebugLog(@"-setFrame to %@", NSStringFromRect(frame));
		
	if ([[self layoutItem] isContainerScrollViewInserted])
	{
		NSSize clipViewSize = [[self scrollView] contentSize];

		if (clipViewSize.width < frame.size.width || clipViewSize.height < frame.size.height)
		{
			patchedFrame.size = clipViewSize;
		}
	}
	
	[super setFrame: patchedFrame];
	
	if ([self canUpdateLayout])
		[self updateLayout];
}
#endif

/* We override this method to patch the size in case we are located in a scroll 
   view owned by the receiver container. We must patch the container size to be 
   sure it will never be smaller than the clip view size. If both container and 
   clip view size don't match, you cannot click on the background to unselect 
   items and the drawing of the container background doesn't fully fill the 
   visible area of the scroll view.
   -setFrame: calls -setFrameSize: on Cocoa but not on GNUstep. */
- (void) setFrameSize: (NSSize)size
{
	NSSize patchedSize = size;

	//ETDebugLog(@"-setFrameSize: to %@", NSStringFromSize(size));

	// NOTE: Very weird resizing behavior can be observed if the following code 
	/// is executed when a layout view is in use. The layout view size will be 
	// constrained to the clip view size of the cached scroll view decorator.
	if ([[self layoutItem] isContainerScrollViewInserted])
	{
		NSSize clipViewSize = [[self scrollView] contentSize];

		if (size.width < clipViewSize.width)
			patchedSize.width = clipViewSize.width;
		if (size.height < clipViewSize.height)
			patchedSize.height = clipViewSize.height;
	}
	
	[super setFrameSize: patchedSize];
	
	if ([self canUpdateLayout])
		[self updateLayout];
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
- (void) addItem: (ETLayoutItem *)item
{
	[(ETLayoutItemGroup *)[self layoutItem] addItem: item];
}

/** See -[ETLayoutItemGroup insertItem:atIndex:] */
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] insertItem: item atIndex: index];
}

/** See -[ETLayoutItemGroup removeItem:] */
- (void) removeItem: (ETLayoutItem *)item
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItem: item];
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
- (int) indexOfItem: (ETLayoutItem *)item
{
	return [(ETLayoutItemGroup *)[self layoutItem] indexOfItem: item];
}

/** See -[ETLayoutItemGroup containsItem:] */
- (BOOL) containsItem: (ETLayoutItem *)item
{
	return [(ETLayoutItemGroup *)[self layoutItem] containsItem: item];
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
	[[self layoutItem] setShowsScrollView: show];
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
