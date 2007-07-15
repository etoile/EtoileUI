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

#import "ETContainer.h"
#import "ETLayoutItem.h"
#import "ETViewLayout.h"
#import "ETLayer.h"
#import "CocoaCompatibility.h"
#import "GNUstep.h"

#define ETLog NSLog

NSString *ETContainerSelectionDidChangeNotification = @"ETContainerSelectionDidChangeNotification";
NSString *ETLayoutItemPboardType = @"ETLayoutItemPboardType"; // FIXME: replace by UTI

@interface ETContainer (PackageVisibility)
- (NSArray *) layoutItems;
- (void) cacheLayoutItems: (NSArray *)layoutItems;
- (NSArray *) layoutItemCache;
- (int) checkSourceProtocolConformance;
@end

@interface ETContainer (Private)
- (void) syncDisplayViewWithContainer;
- (NSInvocation *) invocationForSelector: (SEL)selector;
- (id) sendInvocationToDisplayView: (NSInvocation *)inv;
- (NSArray *) layoutItemsFromSource;
- (NSArray *) layoutItemsFromFlatSource;
- (NSArray *) layoutItemsFromTreeSource;
- (void) updateLayoutWithItems: (NSArray *)itemsToLayout;
- (BOOL) doesSelectionContainsPoint: (NSPoint)point;
- (void) fixOwnerIfNeededForItem: (ETLayoutItem *)item;
- (BOOL) isScrollViewShown;
- (void) setShowsScrollView: (BOOL)scroll;
@end


@implementation ETContainer

/** <init /> */
- (id) initWithFrame: (NSRect)rect views: (NSArray *)views
{
	self = [super initWithFrame: rect];
    
    if (self != nil)
    {
		_layoutItems = [[NSMutableArray alloc] init];
		_path = @"";
		_itemScale = 1.0;
		_selection = [[NSMutableIndexSet alloc] init];
		_internalDragAllowed = YES;
		_prevInsertionIndicatorRect = NSZeroRect;
		_scrollView = nil; /* First instance created by calling private method -setShowsScrollView: */
		
		[self registerForDraggedTypes: [NSArray arrayWithObjects:
			ETLayoutItemPboardType, nil]];
		
		if (views != nil)
		{
			NSEnumerator *e = [views objectEnumerator];
			NSView *view = nil;
			
			while ((view = [e nextObject]) != nil)
			{
				[_layoutItems addObject: [ETLayoutItem layoutItemWithView: view]];
			}
		}
    }
    
    return self;
}

- (id) initWithFrame: (NSRect)rect
{
	return [self initWithFrame: rect views: nil];
}

- (void) dealloc
{
    DESTROY(_layoutItems);
	DESTROY(_containerLayout);
	DESTROY(_displayView);
	DESTROY(_path);
	DESTROY(_selection);
	_dataSource = nil;
    
    [super dealloc];
}

- (NSString *) description
{
	NSString *desc = [super description];
	
	desc = [@"<" stringByAppendingString: desc];
	desc = [desc stringByAppendingFormat: @" + %@>", [self layout], nil];
	return desc;
}

- (NSString *) path
{
	return _path;
}

/** Returns path value which is altered when the user navigates inside a tree 
	structure of a layout items. Path is only critical when a source is used,
	otherwise it's up to the developer to track the level of navigation inside
	the tree structure. You can use -setPath as a conveniency to memorize your
	location inside a layout item tree. In this case, each time the user enters
	a new level, you are in charge of removing then adding the proper layout
	items which are associated with the level requested by the user. That's
	why it's advised to always use a source when you want to display a 
	layout item tree inside a container. */
- (void) setPath: (NSString *)path
{
	ASSIGN(_path, path);
	
	// FIXME: May be it would be even better to keep selected any items still 
	// visible with updated layout at new path. Think of outline view or 
	// expanded stacks.
	[_selection removeAllIndexes]; /* Unset any selection */
	[self updateLayout];
}

#if 0
- (ETLayoutItem *) layoutItemAncestorWithPath: (NSString *)path matchingPath: (NSString **)ancestorPath

- (ETLayoutItem *) layoutItemAtPath: (NSString *)path
{
	NSArray *pathComponents = [path pathComponents];
	ETLayoutItem *item = nil
	NSArray *layoutItemsBylevel = [self layoutItemCache];
	
	for (int i = 0; i < [pathComponents count]; i++)
	{
		NSArray *itemViews = [layoutItemsBylevel valueForKey: @"view"];
		NSView *view = nil;
		NSString *comp = [pathComponents objectAtIndex: i];
		
		view = [itemViews objectWithValue: comp forKey: @"path"];
		item = [layoutItemsBylevel objectWithValue: view forKey: @"view"];
		if (item == nil)
		{
			// FIXME: -intValue returns 0 on failure.
			[layoutItemsBylevel objectAtIndex: [comp intValue]];
		}
		if (item != nil)
		{
			NSView *itemView = [item view];
			
			if ([itemView isKindOfClass: [ETContainer class]])
				layoutItemsBylevel = [(ETContainer *)itemView layoutItemCache];
		}
	}
}
#endif

- (NSArray *) layoutItems
{
	return _layoutItems;
}

/* Uses to know which layout items the container takes care to display when
   a source is in use and layout items are thereby retrieved and managed by the 
   layout object itself. 
   WARNING: Before calling this method, you must ensure no views of currently 
   cached items are currently use as subviews in this container. */
- (void) cacheLayoutItems: (NSArray *)layoutItems
{
	// TODO: Write a debug assertion checking every _layoutItemCache item views
	// aren't used in present container anymore.
	ASSIGN(_layoutItemCache, layoutItems);
}

/* Returns layout items currently displayed in the container unlike 
   -layoutItems which returns items displayed only when no source is used. Uses
   this method only for internal purpose when you need know layout items no 
   matter of how they have come into this container.
   Must only be modified through -cacheLayoutItems:, never directly. */
- (NSArray *) layoutItemCache
{
	return _layoutItemCache;
}

- (BOOL) isAutolayout
{
	return _autolayout;
}

- (void) setAutolayout: (BOOL)flag
{
	_autolayout = flag;
}

- (void) updateLayout
{
	/* Delegate layout rendering to custom layout object */
	[[self layout] render];
	
	[self setNeedsDisplay: YES];
}

/** Returns 0 when source doesn't conform to any parts of ETContainerSource informal protocol.
    Returns 1 when source conform to protocol for flat collections and display of items in a linear style.
	Returns 2 when source conform to protocol for tree collections and display of items in a hiearchical style.
	If tree collection part of the protocol is implemented through 
	-numberOfItemsAtPath:inContainer: , ETContainer by default ignores flat collection
	part of protocol like -numberOfItemsInContainer. */
- (int) checkSourceProtocolConformance
{
	if ([[self source] respondsToSelector: @selector(numberOfItemsAtPath:inContainer:)])
	{
		if ([[self source] respondsToSelector: @selector(itemAtPath:inContainer:)])
		{
			return 2;
		}
		else
		{
			NSLog(@"%@ implements numberOfItemsAtPath:inContainer: but misses "
				  @"itemAtPath:inContainer: as requested by ETContainerSource "
				  @"protocol.", [self source]);
			return 0;
		}
	}
	else if ([[self source] respondsToSelector: @selector(numberOfItemsInContainer:)])
	{
		if ([[self source] respondsToSelector: @selector(itemAtIndex:inContainer:)])
		{
			return 1;
		}
		else
		{
			NSLog(@"%@ implements numberOfItemsInContainer: but misses "
				  @"itemAtIndex:inContainer: as  requested by "
				  @"ETContainerSource protocol.", [self source]);
			return 0;
		}
	}

	else
	{
		NSLog(@"%@ implements neither numberOfItemsInContainer: nor "
			  @"numberOfItemsAtPath:inContainer: as requested by "
			  @"ETContainerSource protocol.", [self source]);
		return 0;
	}
}

- (ETViewLayout *) layout
{
	return _containerLayout;
}

- (void) setLayout: (ETViewLayout *)layout
{
	[_containerLayout setContainer: nil];
	ASSIGN(_containerLayout, layout);
	[layout setContainer: self];
	
	[self syncDisplayViewWithContainer];
	
	[self updateLayout];
}

/* Various adjustements necessary when layout object is a wrapper around an 
   AppKit view. This method is called on a regular basis each time a setting of
   the container is modified and needs to be mirrored on the display view. */
- (void) syncDisplayViewWithContainer
{
	NSInvocation *inv = nil;
	
	if (_displayView != nil)
	{
		SEL doubleAction = [self doubleAction];
		id target = [self target];
		
		inv = RETAIN([self invocationForSelector: @selector(setDoubleAction:)]);
		[inv setArgument: &doubleAction atIndex: 2];
		//[self sendInvocationToDisplayView: inv];
		
		// FIXME: Hack to work around invocation vanishing when we call -sendInvocationToDisplayView:
		id enclosedDisplayView = [(NSScrollView *)_displayView documentView];
		
		if ([enclosedDisplayView respondsToSelector: [inv selector]]);
			[inv invokeWithTarget: enclosedDisplayView];
		
		inv = RETAIN([self invocationForSelector: @selector(setTarget:)]);
		[inv setArgument: &target atIndex: 2];
		//[self sendInvocationToDisplayView: inv];
		
		// FIXME: Hack to work around invocation vanishing when we call -sendInvocationToDisplayView:
		enclosedDisplayView = [(NSScrollView *)_displayView documentView];
		
		if ([enclosedDisplayView respondsToSelector: [inv selector]]);
			[inv invokeWithTarget: enclosedDisplayView];
	}
}

- (NSInvocation *) invocationForSelector: (SEL)selector
{
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature: 
		[self methodSignatureForSelector: selector]];
	
	/* Method signature doesn't embed the selector, but only type infos related to it */
	[inv setSelector: selector];
	
	return inv;
}

- (id) sendInvocationToDisplayView: (NSInvocation *)inv
{
	id result = nil;
	
	if ([_displayView respondsToSelector: [inv selector]])
			[inv invokeWithTarget: _displayView];
			
	/* May be the display view is packaged inside a scroll view */
	if ([_displayView isKindOfClass: [NSScrollView class]])
	{
		id enclosedDisplayView = [(NSScrollView *)_displayView documentView];
		
		if ([enclosedDisplayView respondsToSelector: [inv selector]]);
			[inv invokeWithTarget: enclosedDisplayView];
	}
	
	if (inv != nil)
		[inv getReturnValue: &result];
		
	RELEASE(inv); /* Retained in -syncDisplayViewWithContainer otherwise it gets released too soon */
	
	return result;
}

- (id) source
{
	return _dataSource;
}

- (void) setSource: (id)source
{
	/* By safety, avoids to trigger extra updates */
	if (_dataSource == source)
		return;
	
	// NOTE: Resetting layout item cache is ETViewLayout responsability. We
	// only refresh the container display when the new source is set up.
	
	_dataSource = source;
	
	// NOTE: -setPath: takes care of calling -updateLayout
	if (source != nil && [[self path] isEqual: @""])
	{
		[self setPath: @"/"];
	}
	else if (source == nil)
	{
		[self setPath: @""];
	}
}

- (id) delegate
{
	return _delegate;
}

- (void) setDelegate: (id)delegate
{
	_delegate = delegate;
}

- (BOOL) letsLayoutControlsScrollerVisibility
{
	return NO;
}

- (void) setLetsLayoutControlsScrollerVisibility: (BOOL)layoutControl
{

}

- (BOOL) hasVerticalScroller
{
	return NO;
}

- (void) setHasVerticalScroller: (BOOL)scroll
{

}

- (BOOL) hasHorizontalScroller
{
	return NO;
}

- (void) setHasHorizontalScroller: (BOOL)scroll
{

}

- (BOOL) hasScrollView
{
	if (_scrollView != nil)
		return YES;

	return NO;
}

- (void) setHasScrollView: (BOOL)scroll
{
	if (scroll == YES && _scrollView == nil)
	{
		_scrollView = [[NSScrollView alloc] initWithFrame: [self frame]];
		[self setShowsScrollView: YES];

	}
	else if (scroll == NO)
	{
		[self setShowsScrollView: NO];
		DESTROY(_scrollView);
	}
}

/* Returns whether the scroll view of the current container is really used. If
   the container shows currently an AppKit control like NSTableView as display 
   view, the built-in scroll view of the table view is used instead of the one
   provided by the container. 
   It implies you can never have -hasScrollView returns NO and -isScrollViewShown 
   returns YES. There is no such exception with all other boolean combinations. */
- (BOOL) isScrollViewShown
{
	if ([_scrollView superview] != nil)
		return YES;
	
	return NO;
}

- (void) setShowsScrollView: (BOOL)scroll
{
	NSAssert(_scrollView != nil, @"For -setShowsScrollView:, scroll view must not be nil");
	if ([_scrollView superview] != nil)
		NSAssert([_scrollView documentView] == self, @"When scroll view superview is not nil, it must use self as document view");

	// FIXME: Asks layout whether it handles scroll view itself or not. If 
	// needed like with table layout, delegate scroll view handling.
	if (scroll && [_scrollView superview] == nil)
	{
		NSView *superview = [self superview];
				
		[_scrollView setAutohidesScrollers: NO];
		[_scrollView setHasHorizontalScroller: YES];
		[_scrollView setHasVerticalScroller: YES];
		[_scrollView setAutoresizingMask: [self autoresizingMask]];
		
		RETAIN(self);
		[self removeFromSuperview];
		
		[[self layout] setContentSizeLayout: YES];
		[[self layout] adjustLayoutSizeToContentSize];
		/*[self setFrameSize: [[self layout] layoutSize]];*/
		
		[_scrollView setDocumentView: self];
		[superview addSubview: _scrollView];
		RELEASE(self);
	}
	else if (scroll == NO && [_scrollView superview] != nil)
	{
		NSView *superview = [_scrollView superview];
		
		NSAssert(superview != nil, @"For -setShowsScrollView: NO, scroll view must have a superview");
		
		RETAIN(self);
		[self removeFromSuperview]; //[_scrollView setDocumentView: nil];
		[_scrollView removeFromSuperview];
		
		[self setFrame: [_scrollView frame]];
		[[self layout] setContentSizeLayout: NO];
		[[self layout] adjustLayoutSizeToSizeOfContainer: self];
		
		[superview addSubview: self];
		RELEASE(self);
	}
}

// FIXME: Implement or remove
- (NSSize) contentSize
{
	return NSZeroSize;
}

/** Returns the view that takes care of the display. Most of time it is equal
    to the container itself. But for some layout like ETTableLayout, the 
	returned view would be an NSTableView instance. */
- (NSView *) displayView
{
	return _displayView;
}

/* Method called when we switch between layouts. Currently called by 
   -renderWithLayoutItems: but this is probably going to change. */
- (void) setDisplayView: (NSView *)view
{
	if (view != nil && [self hasScrollView])
	{
		if ([self isScrollViewShown])
			[self setShowsScrollView: NO];
	}
	else if (view == nil && [self hasScrollView])
	{
		if ([self isScrollViewShown] == NO)
			[self setShowsScrollView: YES];		
	}

	[_displayView removeFromSuperview];
	
	_displayView = view;
	[view removeFromSuperview];
	[view setFrameSize: [self frame].size];
	[view setFrameOrigin: NSZeroPoint];
	[self addSubview: view];
	
	[self syncDisplayViewWithContainer];
}

/*
- (ETLayoutOverflowStyle) overflowStyle
{

}

- (void) setOverflowStyle: (ETLayoutOverflowStyle)
{

}
*/

- (void) addItem: (ETLayoutItem *)item
{
	//NSLog(@"Add item in %@", self);
	[_layoutItems addObject: item];
	[self updateLayout];
}

- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	//NSLog(@"Insert item in %@", self);
	[_layoutItems insertObject: item atIndex: index];
	[self updateLayout];
}

- (void) removeItem: (ETLayoutItem *)item
{
	//NSLog(@"Remove item in %@", self);
	if ([_selection containsIndex: [self indexOfItem: item]])
		[_selection removeIndex: [self indexOfItem: item]];
	[[item displayView] removeFromSuperview];
	[_layoutItems removeObject: item];
	[self updateLayout];
}

- (void) removeItemAtIndex: (int)index
{
	ETLayoutItem *item = [_layoutItems objectAtIndex: index];
	[self removeItem: item];
}

- (ETLayoutItem *) itemAtIndex: (int)index
{
	return [_layoutItems objectAtIndex: index];
}

- (void) addItems: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *layoutItem = nil;
	
	//NSLog(@"Add items in %@", self);
	
	while ((layoutItem = [e nextObject]) != nil)
	{
		[self addItem: layoutItem];
	}
}

- (void) removeItems: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *layoutItem = nil;
	
	//NSLog(@"Remove items in %@", self);
	
	while ((layoutItem = [e nextObject]) != nil)
	{
		[self removeItem: layoutItem];
	}
}

- (void) removeAllItems
{
	NSArray *itemDisplayViews = [_layoutItems valueForKey: @"displayView"];
	
	//NSLog(@"Remove all items in %@", self);
	
	[_selection removeAllIndexes];
	[itemDisplayViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	[_layoutItems removeAllObjects];
	[self updateLayout];
}

- (int) indexOfItem: (ETLayoutItem *)item
{
	return [_layoutItems indexOfObject: item];
}

- (NSArray *) items
{
	return _layoutItems;
}

/** Add a view to layout as a subview of the view container. */
- (void) addView: (NSView *)view
{
	if ([[_layoutItems valueForKey: @"view"] containsObject: view] == NO)
		[self addItem: [ETLayoutItem layoutItemWithView: view]];
}

/** Remove a view which was layouted as a subview of the view container. */
- (void) removeView: (NSView *)view
{
	ETLayoutItem *viewOwnerItem = [(NSArray *)_layoutItems objectWithValue: view forKey: @"view"];
	
	if (viewOwnerItem != nil)
		[_layoutItems removeObject: viewOwnerItem];
}

/** Remove the view located at index in the series of views (which were layouted as subviews of the view container). */
- (void) removeViewAtIndex: (int)index
{
	[_layoutItems removeObjectAtIndex: index];
	[self updateLayout];
}

/** Return the view located at index in the series of views (which are layouted as subviews of the view container). */
- (NSView *) viewAtIndex: (int)index
{
	return [[_layoutItems objectAtIndex: index] view];
}

- (void) addViews: (NSArray *)views
{
	NSEnumerator *e = [views objectEnumerator];
	NSView *view = nil;
	
	while ((view = [e nextObject]) != nil)
	{
		[self addView: view];
	}
}

- (void) removeViews: (NSArray *)views
{
	NSEnumerator *e = [views objectEnumerator];
	NSView *view = nil;
	
	while ((view = [e nextObject]) != nil)
	{
		[self removeView: view];
	}
}

/* Selection */

- (void) setSelectionIndexes: (NSIndexSet *)indexes
{
	int numberOfItems = [[self layoutItemCache] count];
	int lastSelectionIndex = [indexes lastIndex];
	NSLog(@"Set selection indexes to %@ in %@", indexes, self);
	if (lastSelectionIndex > (numberOfItems - 1))
	{
		NSLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
			lastSelectionIndex, self, numberOfItems);
		return;
	}
	
	/* First unset selected state in layout items directly */
	NSArray *selectedItems = [[self layoutItemCache] objectsAtIndexes: _selection];
	NSEnumerator *e = [selectedItems objectEnumerator];
	ETLayoutItem *item = nil;
		
	while ((item = [e nextObject]) != nil)
	{
		[item setSelected: NO];
	}
	
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
	selectedItems = [[self layoutItemCache] objectsAtIndexes: _selection];
	e = [selectedItems objectEnumerator];
	item = nil;
		
	while ((item = [e nextObject]) != nil)
	{
		[item setSelected: NO];
	}
	
	[self setNeedsDisplay: YES];
}

- (NSMutableIndexSet *) selectionIndexes
{
	return AUTORELEASE([_selection mutableCopy]);
}

- (void) setSelectionIndex: (int)index
{
	int numberOfItems = [[self layoutItemCache] count];
	
	NSLog(@"Modify selected item from %d to %d of %@", [self selectionIndex], index, self);
	
	if (index > (numberOfItems - 1))
	{
		NSLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
			index, self, numberOfItems);
		return;
	}

	if ([_selection count] > 0)
	{
		NSArray *selectedItems = [[self layoutItemCache] objectsAtIndexes: _selection];
		NSEnumerator *e = [selectedItems objectEnumerator];
		ETLayoutItem *item = nil;
		
		while ((item = [e nextObject]) != nil)
		{
			[item setSelected: NO];
		}
		[_selection removeAllIndexes];
	}
	
	[_selection addIndex: index]; // cache
	[[[self layoutItemCache] objectAtIndex: index] setSelected: YES];
	
	NSAssert([_selection count] == 1, @"-setSelectionIndex: must result in a single index and not more");
	
	/* Finally propagate changes by posting notification */
	NSNotification *notif = [NSNotification 
		notificationWithName: ETContainerSelectionDidChangeNotification object: self];
	
	if ([[self delegate] respondsToSelector: @selector(containerSelectionDidChange:)])
		[[self delegate] containerSelectionDidChange: notif];

	[[NSNotificationCenter defaultCenter] postNotification: notif];
}

- (int) selectionIndex
{
	return [_selection firstIndex];
}

- (BOOL) allowsMultipleSelection
{
	return _multipleSelectionAllowed;
}

- (void) setAllowsMultipleSelection: (BOOL)multiple
{
	_multipleSelectionAllowed = multiple;
}

- (BOOL) allowsEmptySelection
{
	return _emptySelectionAllowed;
}

- (void) setAllowsEmptySelection: (BOOL)empty
{
	_emptySelectionAllowed = empty;
}

- (BOOL) doesSelectionContainsPoint: (NSPoint)point
{
	ETLayoutItem *item = [[self layout] itemAtLocation: point];

	if ([item isSelected])
	{
		NSAssert2([[self selectionIndexes] containsIndex: [[self layoutItemCache] indexOfObject: item]],
			@"Mismatch between selection indexes and item %@ selected state in %@", 
			item, self);
		return YES;
	}
		
	return NO;

// NOTE: The code below could be significantly faster on large set of items
#if 0
	NSArray *selectedItems = [[self layoutItemCache] objectsAtIndexes: [self selectionIndexes]];
	NSEnumerator *e = [selectedItems objectEnumerator];
	ETLayoutItem *item = nil;
	BOOL hitSelection = NO;
	
	while ((item = [nextObject]) != nil)
	{
		if ([item displayView] != nil)
		{
			hitSelection = NSPointInRect(point, [[item displayView] frame]);
		}
		else /* Layout items uses no display view */
		{
			// FIXME: Implement
		}
	}
	
	return hitSelection;
#endif
}

/*
- (ETSelection *) selection
{
	return _selection;
}

- (void) setSelection: (ETSelection *)
{
	_selection;
} */

/* Dragging */

- (void) setAllowsInternalDragging: (BOOL)flag
{
	_internalDragAllowed = flag;
}

- (BOOL) allowsInternalDragging
{
	return _internalDragAllowed;
}

/* Layers */

- (void) fixOwnerIfNeededForItem: (ETLayoutItem *)item
{
	/* Check the item to be now embedded in a new container (owned by the new 
	   layer) isn't already owned by current container */
	if ([_layoutItems containsObject: item])
		[_layoutItems removeObject: item];
}

- (void) addLayer: (ETLayoutItem *)item
{
	ETLayer *layer = [ETLayer layerWithLayoutItem: item];
	
	/* Insert layer on top of the layout item stack */
	if (layer != nil)
		[self addItem: (ETLayoutItem *)layer];
}

- (void) insertLayer: (ETLayoutItem *)item atIndex: (int)layerIndex
{
	[self fixOwnerIfNeededForItem: item];
	
	ETLayer *layer = [ETLayer layerWithLayoutItem: item];
	
	// FIXME: the insertion code is truly unefficient, it could prove to be
	// a bottleneck when we have few hundreds of layout items.
	if (layer != nil)
	{
		NSArray *layers = nil;
		ETLayer *layerToMoveUp = nil;
		int realIndex = 0;
		
		/*
		           _layoutItems            by index (or z order)
		     
		               *****  <-- layer 2      4  <-- higher
		   item          -                     3
		   item          -                     2
		               *****  <-- layer 1      1
		   item          -                     0  <-- lower visual element (background)
		   
		   Take note that layout items embedded inside a layer have a 
		   distinct z order. Rendering isn't impacted by this point.
		   
		  */
		
		/* Retrieve layers spread in _layoutItems */
		layers = [_layoutItems objectsWithValue: [ETLayer class] forKey: @"class"];
		/* Find the layer to be replaced in layers array */
		layerToMoveUp = [layers objectAtIndex: layerIndex];
		/* Retrieve the index in layoutItems array for this particular layer */
		realIndex = [_layoutItems indexOfObject: layerToMoveUp];
		
		/* Insertion will move replaced layer at index + 1 (to top) */
		[self insertItem: layer atIndex: realIndex];
	}
}

- (void) insertLayer: (ETLayoutItem *)item atZIndex: (int)z
{

}

- (void) removeLayer: (ETLayoutItem *)item
{

}

- (void) removeLayerAtIndex: (int)layerIndex
{

}

/* Item scaling */

- (float) itemScaleFactor
{
	return _itemScale;
}

- (void) setItemScaleFactor: (float)factor
{
	_itemScale = factor;
	[self updateLayout];
}

/* Rendering Chain */

- (void) render
{
	[_layoutItems makeObjectsPerformSelector: @selector(render)];
}

/* Actions */

/** Hit test is disabled by default in container to eliminate potential issues
	you may encounter by using subclasses of NSControl like NSImageView as 
	layout item view. 
	If you want to layout controls which should support direct interaction like
	checkbox or popup menu, you can turn hit test on by calling 
	-setEnablesHitTest: with YES. 
	*/
- (NSView *) hitTest: (NSPoint)location
{
	/* If we use an AppKit control as a display view, everything should be
	   handled as usual. Ditto if we have no display view but subview hit test 
	   is turned on. */
	if ([self displayView] || _subviewHitTest)
	{
		return [super hitTest: location];
	}
	else if (NSPointInRect(location, [self frame]))
	{
		return self;
	}
	else
	{
		return nil;
	}
}

- (void) setEnablesSubviewHitTest: (BOOL)passHitTest
{ 
	_subviewHitTest = passHitTest; 
}

- (BOOL) isSubviewHitTestEnabled { return _subviewHitTest; }

- (void) mouseDown: (NSEvent *)event
{
	//NSLog(@"Mouse down in %@", self);
	
	if ([self displayView] != nil) /* Layout object is wrapping an AppKit control */
	{
		NSLog(@"WARNING: %@ should have catch mouse down %@", [self displayView], event);
		return;
	}
	
	NSPoint localPosition = [self convertPoint: [event locationInWindow] fromView: nil];
	ETLayoutItem *newlyClickedItem = [[self layout] itemAtLocation: localPosition];
	int newIndex = NSNotFound;
	
	/* If no item has been clicked, we exit by default (may change in future) */
	if (newlyClickedItem == nil)
		return;
		
	newIndex = [[self layoutItemCache] indexOfObject: newlyClickedItem];
	
	/* Update selection if needed */
	if ([[self selectionIndexes] containsIndex: newIndex] == NO)
	{
		ETLog(@"Update selection on mouse down");
		[self setSelectionIndex: newIndex];
		
		/*NSMutableIndexSet *selection = [self selectionIndexes];
			
		[selection addIndex: [[self layoutItemCache] indexOfObject: _clickedItem]];
		[self setSelectionIndexes: selection];*/
	}

	if ([event clickCount] > 1) /* Double click */
	{
		NSView *hitView = nil;
		NSPoint location = [[[self window] contentView] 
			convertPoint: [event locationInWindow] toView: [self superview]];
		
		/* Find whether hitView is a layout item view */
		_subviewHitTest = YES; /* Allow us to make a hit test on our subview */
		hitView = [self hitTest: location];
		_subviewHitTest = NO;
		DESTROY(_clickedItem);
		_clickedItem = [[self layoutItemCache] objectWithValue: hitView forKey: @"displayView"];
		RETAIN(_clickedItem);
		NSLog(@"Double click detected on view %@ and layout item %@", hitView, _clickedItem);
		
		[self sendAction: [self doubleAction] to: [self target]];
	}
}

- (void) setTarget: (id)target
{
	_target = target;
	
	/* If a display view is used, sync its settings with container */
	[self syncDisplayViewWithContainer];
}

- (id) target
{
	return _target;
}


- (void) setDoubleAction: (SEL)selector
{
	_doubleClickAction = selector;
	
	/* If a display view is used, sync its settings with container */
	[self syncDisplayViewWithContainer];
}

- (SEL) doubleAction
{
	return _doubleClickAction;
}

- (ETLayoutItem *) clickedItem
{
	if (_displayView != nil)
	{
		if ([[self layout] respondsToSelector: @selector(clickedItem)])
		{
			DESTROY(_clickedItem);
			_clickedItem = [(id)[self layout] clickedItem];
			RETAIN(_clickedItem);
		}
		else
		{
			NSLog(@"WARNING: Layout %@ based on a display view must implement -clickedItem", [self layout]);
		}
	}
	
	return _clickedItem;
}

- (void) setFrame: (NSRect)frame
{
	//NSLog(@"-setFrame to %@", NSStringFromRect(frame));
	if (_displayView != nil)
		[_displayView setFrame: frame];
	[super setFrame: frame];
}

@end

/* Dragging Support */

@interface ETContainer (ETContainerDraggingSupport)
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)drag atIndex: (int)index;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)drag atIndex: (int)index;
@end

/* By default ETContainer implements data source methods related to drag and 
   drop. This is a convenience you can override by implementing drag and
   drop related methods in your own data source. DefaultDragDataSource is
   typically used when -allowsInternalDragging: returns YES. */
@implementation ETContainer (ETContainerDraggingSupport)

/* Default Dragging-specific Implementation of Data Source */

/* Dragging Source */

// NOTE: this method isn't part of NSDraggingSource protocol but of NSResponder
- (void) mouseDragged: (NSEvent *)event
{
	/* Only handles event when it is located inside selection */
	if ([self doesSelectionContainsPoint: [event locationInWindow]])
	{
		ETLog(@"Mouse dragged on selection");
		//[_layoutItems objectsAtIndexes: indexes];
		ETLayoutItem *item = [[self layoutItemCache] objectAtIndex: [self selectionIndex]];
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
		NSPoint dragPosition = [self convertPoint: [event locationInWindow]
										 fromView: nil];
						
		[pboard declareTypes: [NSArray arrayWithObject: ETLayoutItemPboardType]
			owner: nil];
		// NOTE: If we implement an unified layout item tree shared by 
		// applications through CoreObject, we could eventually just put simple
		// path on the pasteboard rather than archived object or index.
		//[pboard setString: forType: ETLayoutItemPboardType];
		/*[pboard setData: forType: ETLayoutItemPboardType];*/
		[pboard setString: [NSString stringWithFormat: @"%d", [self selectionIndex]] 
		          forType: ETLayoutItemPboardType];
 
		//dragPosition.x -= 32;
		//dragPosition.y -= 32;
		
		[self dragImage: [item image]
					 at: dragPosition
				 offset: NSZeroSize
				  event: event 
			 pasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]
				 source: self 
			  slideBack: YES];
	}
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	if (isLocal)
	{
		return NSDragOperationPrivate; //Move
	}
	else
	{
		return NSDragOperationNone;
	}
}

- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint
{
#if 0
	if ([self source] != nil 
	 && [[self source] respondsToSelector: @selector(container:writeItemsWithIndexes:toPasteboard:)])
	{
		[[self source] container: self 
		   writeItemsWithIndexes: [self selectionIndexes] 
		            toPasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]];
	}
	else if ([self source] == nil && [self allowsInternalDragging]) /* Handles drag by ourself when allowed */
	{
		[self container: self 
		   writeItemsWithIndexes: [self selectionIndexes] 
		            toPasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]];
	}
#endif
}

- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint
{
	ETLog(@"Drag move receives in dragging source %@", self);
}

- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation
{
	ETLog(@"Drag end receives in dragging source %@", self);
}

/* Dragging Destination */

- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)sender
{
	ETLog(@"Drag enter receives in dragging destination %@", self);
	return NSDragOperationPrivate;
}

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)drag
{
	ETLog(@"Drag update receives in dragging destination %@", self);
	
	NSPoint localDropPosition = [self convertPoint: [drag draggingLocation] fromView: nil];
	ETLayoutItem *hoveredItem = [[self layout] itemAtLocation: localDropPosition];
	NSRect hoveredRect = [[self layout] displayRectOfItem: hoveredItem];
	float itemMiddleWidth = hoveredRect.origin.x + hoveredRect.size.width / 2;
	float indicatorWidth = 4.0;
	float indicatorLineX = 0.0;
	NSRect indicatorRect = NSZeroRect;
	
	[self lockFocus];
	[[NSColor magentaColor] setStroke];
	[NSBezierPath setDefaultLineCapStyle: NSButtLineCapStyle];
	[NSBezierPath setDefaultLineWidth: indicatorWidth];
	
	/* Decides whether to draw on left or right border of hovered item */
	if (localDropPosition.x >= itemMiddleWidth)
	{
		indicatorLineX = NSMaxX(hoveredRect);
		ETLog(@"Draw right insertion bar");
	}
	else if (localDropPosition.x < itemMiddleWidth)
	{
		indicatorLineX = NSMinX(hoveredRect);
		ETLog(@"Draw left insertion bar");
	}
	else
	{
	
	}
	/* Computes indicator rect */
	indicatorRect = NSMakeRect(indicatorLineX - indicatorWidth / 2.0, 
		NSMinY(hoveredRect), indicatorWidth, NSHeight(hoveredRect));
		
	/* Insertion indicator has moved */
	if (NSEqualRects(indicatorRect, _prevInsertionIndicatorRect) == NO)
	{
		[self setNeedsDisplayInRect: NSIntegralRect(_prevInsertionIndicatorRect)];
		[self displayIfNeeded];
		//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
	}
	
	/* Draws indicator */
	[NSBezierPath strokeLineFromPoint: NSMakePoint(indicatorLineX, NSMinY(hoveredRect))
							  toPoint: NSMakePoint(indicatorLineX, NSMaxY(hoveredRect))];
	[[self window] flushWindow];
	[self unlockFocus];
	
	_prevInsertionIndicatorRect = indicatorRect;
	
	return NSDragOperationPrivate;
}

- (void) draggingExited: (id <NSDraggingInfo>)sender
{
	ETLog(@"Drag exit receives in dragging destination %@", self);
	
	/* Erases insertion indicator */
	[self setNeedsDisplayInRect: NSIntegralRect(_prevInsertionIndicatorRect)];
	[self displayIfNeeded];
	//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
}


- (void) draggingEnded: (id <NSDraggingInfo>)sender
{
	ETLog(@"Drag end receives in dragging destination %@", self);
	
	/* Erases insertion indicator */
	[self setNeedsDisplayInRect: NSIntegralRect(_prevInsertionIndicatorRect)];
	[self displayIfNeeded];
	//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
}

- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{
	ETLayoutItem *item = [[self layout] itemAtLocation: [sender draggingLocation]];
	int index = [[self layoutItemCache] indexOfObject: item];
	
	ETLog(@"Prepare drag receives in dragging destination %@", self);
	
	if ([self source] != nil && [[self source] respondsToSelector: @selector(container:acceptDrop:atIndex:)])
	{
		return [[self source] container: self 
			                 acceptDrop: sender
					            atIndex: index];
	}
	else if ([self source] == nil && [self allowsInternalDragging]) /* Handles drag by ourself when allowed */
	{
		return [self container: self acceptDrop: sender atIndex: index];
	}
	
	return NO;
}

- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)drag atIndex: (int)index
{
	return YES;
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
	ETLayoutItem *item = [[self layout] itemAtLocation: [sender draggingLocation]];
	int index = [[self layoutItemCache] indexOfObject: item];
	
	ETLog(@"Perform drag receives in dragging destination %@", self);
	
	if ([self source] != nil && [[self source] respondsToSelector: @selector(container:validateDrop:atIndex:)])
	{
		[[self source] container: self 
					validateDrop: sender
					     atIndex: index];
	}
	else if ([self source] == nil && [self allowsInternalDragging]) /* Handles drag by ourself when allowed */
	{
		[self container: self 
		   validateDrop: sender
				atIndex: index];
	}
	
	return YES;
}

- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)drag atIndex: (int)index
{
	int movedIndex = [[[drag draggingPasteboard] stringForType: ETLayoutItemPboardType] intValue];
	ETLayoutItem *movedItem = [self itemAtIndex: movedIndex];
	NSPoint localDropPosition = [self convertPoint: [drag draggingLocation] fromView: nil];
	int dropIndex = [self indexOfItem: [[self layout] itemAtLocation: localDropPosition]];
	
	[self setAutolayout: NO];
	RETAIN(movedItem);
	[self removeItem: movedItem];
	[self insertItem: movedItem atIndex: dropIndex];
	[self setAutolayout: YES];
	
	return NSDragOperationPrivate;
}

/* This method is called in replacement of -draggingEnded: when a drop has 
   occured. That's why it's not enough to clean insertion indicator in
   -draggingEnded: */
- (void) concludeDragOperation: (id <NSDraggingInfo>)sender
{
	ETLog(@"Conclude drag receives in dragging destination %@", self);
	
	/* Erases insertion indicator */
	[self setNeedsDisplayInRect: NSIntegralRect(_prevInsertionIndicatorRect)];
	[self displayIfNeeded];
	//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
}

@end
