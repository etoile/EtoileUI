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

#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETLayer.h>
#import <EtoileUI/ETInspector.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/NSIndexSet+Etoile.h>
#import <EtoileUI/CocoaCompatibility.h>
#import <EtoileUI/GNUstep.h>

#define SELECTION_BY_RANGE_KEY_MASK NSShiftKeyMask
#define SELECTION_BY_ONE_KEY_MASK NSCommandKeyMask

NSString *ETContainerSelectionDidChangeNotification = @"ETContainerSelectionDidChangeNotification";
NSString *ETLayoutItemPboardType = @"ETLayoutItemPboardType"; // FIXME: replace by UTI

@interface ETContainer (PackageVisibility)
- (int) checkSourceProtocolConformance;
- (BOOL) isScrollViewShown;
- (void) setShowsScrollView: (BOOL)scroll;
- (BOOL) hasScrollView;
- (void) setHasScrollView: (BOOL)scroll;
- (void) setDisplayView: (NSView *)view;
@end

@interface ETContainer (Private)
- (void) syncDisplayViewWithContainer;
- (NSInvocation *) invocationForSelector: (SEL)selector;
- (void) sendInvocationToDisplayView: (NSInvocation *)inv;
- (BOOL) canUpdateLayout;
- (BOOL) doesSelectionContainsPoint: (NSPoint)point;
- (void) fixOwnerIfNeededForItem: (ETLayoutItem *)item;
- (void) mouseDoubleClick: (NSEvent *)event;
@end


@implementation ETContainer

/** <init /> */
- (id) initWithFrame: (NSRect)rect layoutItem: (ETLayoutItem *)item
{
	if (item != nil && [item isKindOfClass: [ETLayoutItemGroup class]] == NO)
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
		_path = nil;
		_subviewHitTest = NO;
		_flipped = YES;
		_itemScale = 1.0;
		_selection = [[NSMutableIndexSet alloc] init];
		_dragAllowed = YES;
		_dropAllowed = YES;
		_prevInsertionIndicatorRect = NSZeroRect;
		_scrollView = nil; /* First instance created by calling private method -setShowsScrollView: */
		_inspector = nil; /* Instantiated lazily in -inspector if needed */
		
		[self registerForDraggedTypes: [NSArray arrayWithObjects:
			ETLayoutItemPboardType, nil]];
		
		/*if (views != nil)
		{
			NSEnumerator *e = [views objectEnumerator];
			NSView *view = nil;
			
			while ((view = [e nextObject]) != nil)
			{
				[_layoutItems addObject: [ETLayoutItem layoutItemWithView: view]];
			}
		}*/
    }
    
    return self;
}

- (id) initWithFrame: (NSRect)rect
{
	return [self initWithFrame: rect layoutItem: nil];
}

- (void) dealloc
{
	// FIXME: Clarify memory management of _displayView and _scrollView
	DESTROY(_displayView);
	DESTROY(_path);
	DESTROY(_selection);
	DESTROY(_inspector);
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

/** Returns the layout item representing the receiver container in the layout
	item tree. Layout item representing a container is always an instance of
	ETLayoutItemGroup class kind (and not ETLayoutItem unlike ETView).
	Never returns nil. */
- (ETLayoutItem *) layoutItem
{
	NSAssert([[super layoutItem] isKindOfClass: [ETLayoutItemGroup class]], 
		@"Layout item in a container must of ETLayoutItemGroup type");
	return [super layoutItem];
}

/* Basic Accessors */

/** Returns the represented path which is the model path whose content is 
	currently displayed in the receiver. It is useful to keep track of your 
	location inside the model currently browsed. Tree-related methods 
	implemented by a data source are passed paths which are subpaths of the 
	represented path.
	This path is unrelated to the layout item path like 
	[[self layoutItem] path]. */
- (NSString *) representedPath
{
	return _path;
}

/** Sets the represented path, automatically altered when the user navigates inside a 
	tree structure of layout items. Path is only critical when a source is used,
	otherwise it's up to the developer to track the level of navigation inside
	the tree structure. You can use -setRepresentedPath: as a conveniency to memorize your
	location inside a layout item tree. In this case, each time the user enters
	a new level, you are in charge of removing then adding the proper layout
	items which are associated with the level requested by the user. That's
	why it's advised to always use a source when you want to display a 
	layout item tree inside a container. */
- (void) setRepresentedPath: (NSString *)path
{
	ASSIGN(_path, path);
	
	// FIXME: May be it would be even better to keep selected any items still 
	// visible with updated layout at new path. Think of outline view or 
	// expanded stacks.
	[_selection removeAllIndexes]; /* Unset any selection */
	[self updateLayout];
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
	
	/* Also resets any particular state associated with the container like
	   selection */
	[self removeAllItems];
	
	_dataSource = source;
	
	// NOTE: Resetting layout item cache is ETLayout responsability. We
	// only refresh the container display when the new source is set up.
	
	// NOTE: -setPath: takes care of calling -updateLayout
	if (source != nil && ([self representedPath] == nil || [[self representedPath] isEqual: @""]))
	{
		[self setRepresentedPath: @"/"];
	}
	else if (source == nil)
	{
		[self setRepresentedPath: @""];
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

/* Layout */

- (BOOL) isAutolayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] isAutolayout];
}

- (void) setAutolayout: (BOOL)flag
{
	[(ETLayoutItemGroup *)[self layoutItem] setAutolayout: flag];
}

- (BOOL) canUpdateLayout
{
	return [(ETLayoutItemGroup *)[self layoutItem] canUpdateLayout];
}

- (void) updateLayout
{
	[[self layoutItem] updateLayout];
}

- (void) reloadAndUpdateLayout
{
	[(ETLayoutItemGroup *)[self layoutItem] reloadAndUpdateLayout];
}

/** Returns 0 when source doesn't conform to any parts of ETContainerSource informal protocol.
    Returns 1 when source conform to protocol for flat collections and display of items in a linear style.
	Returns 2 when source conform to protocol for tree collections and display of items in a hiearchical style.
	If tree collection part of the protocol is implemented through 
	-container:numberOfItemsAtPath: , ETContainer by default ignores flat collection
	part of protocol like -numberOfItemsInContainer. */
- (int) checkSourceProtocolConformance
{
	if ([[self source] respondsToSelector: @selector(container:numberOfItemsAtPath:)])
	{
		if ([[self source] respondsToSelector: @selector(container:itemAtPath:)])
		{
			return 2;
		}
		else
		{
			NSLog(@"%@ implements container:numberOfItemsAtPath: but misses "
				  @"container:itemAtPath: as requested by ETContainerSource "
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
			  @"container:numberOfItemsAtPath: as requested by "
			  @"ETContainerSource protocol.", [self source]);
		return 0;
	}
}

- (ETLayout *) layout
{
	return [(ETLayoutItemGroup *)[self layoutItem] layout];
}

- (void) setLayout: (ETLayout *)layout
{
	[(ETLayoutItemGroup *)[self layoutItem] setLayout: layout];
}

/* Private helper methods to sync display view and container */

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
		[self sendInvocationToDisplayView: inv];
		
		inv = RETAIN([self invocationForSelector: @selector(setTarget:)]);
		[inv setArgument: &target atIndex: 2];
		[self sendInvocationToDisplayView: inv];
		
		BOOL hasVScroller = [self hasVerticalScroller];
		BOOL hasHScroller = [self hasHorizontalScroller];
		
		if ([self scrollView] == nil)
		{
			hasVScroller = NO;
			hasHScroller = NO;
		}
		
		inv = RETAIN([self invocationForSelector: @selector(setHasHorizontalScroller:)]);
		[inv setArgument: &hasHScroller atIndex: 2];
		[self sendInvocationToDisplayView: inv];
		
		inv = RETAIN([self invocationForSelector: @selector(setHasVerticalScroller:)]);
		[inv setArgument: &hasVScroller atIndex: 2];
		[self sendInvocationToDisplayView: inv];
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

- (void) sendInvocationToDisplayView: (NSInvocation *)inv
{
	//id result = [[inv methodSignature] methodReturnLength];
	
	if ([_displayView respondsToSelector: [inv selector]])
	{
			[inv invokeWithTarget: _displayView];
	}
	else if ([_displayView isKindOfClass: [NSScrollView class]])
	{
		/* May be the display view is packaged inside a scroll view */
		id enclosedDisplayView = [(NSScrollView *)_displayView documentView];
		
		if ([enclosedDisplayView respondsToSelector: [inv selector]]);
			[inv invokeWithTarget: enclosedDisplayView];
	}
	
	//if (inv != nil)
	//	[inv getReturnValue: &result];
		
	RELEASE(inv); /* Retained in -syncDisplayViewWithContainer otherwise it gets released too soon */
	
	//return result;
}

/* Inspecting */

- (IBAction) inspect: (id)sender
{
	NSLog(@"inspect %@", self);
	[[[self inspector] panel] makeKeyAndOrderFront: self];
}

- (void) setInspector: (id <ETInspector>)inspector
{
	ASSIGN(_inspector, inspector);
}

/** Returns inspector based on selection.
	If the inspector hasn't been set by calling -setInspector:, it gets lazily
	instantiated when this accessors is called. */
- (id <ETInspector>) inspector
{
	if (_inspector == nil)
		_inspector = [[ETInspector alloc] init];

	return [self inspectorForItems: [self items]];
}

- (id <ETInspector>) inspectorForItems: (NSArray *)items
{
	[_inspector setInspectedItems: items];
	
	return _inspector;
}

/** Returns whether the receiver uses flipped coordinates or not. 
	Default returned value is YES. */
- (BOOL) isFlipped
{
	return _flipped;
}

/** Unlike NSView, ETContainer uses flipped coordinates by default in order to 
	simplify layout computation.
	You can revert to non-flipped coordinates by passing NO to this method. */
- (void) setFlipped: (BOOL)flag
{
	_flipped = flag;
}

- (BOOL) letsLayoutControlsScrollerVisibility
{
	return NO;
}

- (void) setLetsLayoutControlsScrollerVisibility: (BOOL)layoutControl
{

}

/* From API viewpoint, it makes little sense to keep these scroller methods 
   if we offert direct access to the underlying scroll view. However a class
   like NSBrowser has a method like -setHasHorizontalScroller. We cannot 
   forward -[NSScrollView setHasHorizontalScroller:] unless we create a 
   subclass ETScrollView to override this method. Creating a subclass like that
   for almost no reasons is dubious. In future, a better way to achieve the
   same result would be to swizzle -[NSScrollView setHasHorizontalScroller:]
   method with a decorator method. 
   That means, these following methods will probably be deprecated at some 
   points. */

- (BOOL) hasVerticalScroller
{
	return [_scrollView hasVerticalScroller];
}

- (void) setHasVerticalScroller: (BOOL)scroll
{
	if ([self scrollView] == nil)
		[self setShowsScrollView: YES];
	
	[_scrollView setHasVerticalScroller: scroll];
	
	/* Updated NSBrowser, NSOutlineView enclosing scroll view etc. */
	[self syncDisplayViewWithContainer];
}

- (BOOL) hasHorizontalScroller
{
	return [_scrollView hasHorizontalScroller];
}

- (void) setHasHorizontalScroller: (BOOL)scroll
{
	if ([self scrollView] == nil)
		[self setShowsScrollView: YES];
		
	[_scrollView setHasHorizontalScroller: scroll];
	
	/* Updated NSBrowser, NSOutlineView enclosing scroll view etc. */
	[self syncDisplayViewWithContainer];
}

- (NSScrollView *) scrollView
{
	return _scrollView;
}

- (void) setScrollView: (NSScrollView *)scrollView
{
	if ([_scrollView isEqual: scrollView])
		return;

	if (_scrollView != nil)
	{
		/* Dismantle current scroll view and move container outside of it */
		[self setShowsScrollView: NO];
	}

	ASSIGN(_scrollView, scrollView);
	
	/* If a new scroll view has been provided and no display view is in use */
	if (_scrollView != nil && [self displayView] == nil)
		[self setShowsScrollView: YES];
	
	/* Updated NSBrowser, NSOutlineView enclosing scroll view etc. */
	[self syncDisplayViewWithContainer];
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
	/* If no scroll view exists we create one even when a display view is in use
	   simply because we use the container scroll view instance to store all
	   scroller settings. We update any scroller settings defined in a display
	   view with that of the newly created scroll view.  */

	if (_scrollView == nil)
	{
		_scrollView = [[NSScrollView alloc] initWithFrame: [self frame]];
		[_scrollView setAutohidesScrollers: NO];
		[_scrollView setHasHorizontalScroller: YES];
		[_scrollView setHasVerticalScroller: YES];
	}
		
	/*if ([self displayView] == nil)
		return;*/

	//NSAssert(_scrollView != nil, @"For -setShowsScrollView:, scroll view must not be nil");
	//if ([_scrollView superview] != nil)
	//	NSAssert([_scrollView documentView] == self, @"When scroll view superview is not nil, it must use self as document view");
		
	NSView *superview = nil;

	// FIXME: Asks layout whether it handles scroll view itself or not. If 
	// needed like with table layout, delegate scroll view handling.
	if ([_scrollView superview] == nil && [self displayView] == nil)
	{
		superview = [self superview];
		
		RETAIN(self);
		[self removeFromSuperview];
		
		[_scrollView setAutoresizingMask: [self autoresizingMask]];
		
		[[self layout] setContentSizeLayout: YES];
		// Updating layout here is a source of complication for no visible benefits
		//[[self layout] adjustLayoutSizeToContentSize];
		[self setFrameSize: [_scrollView contentSize]];
		
		[_scrollView setDocumentView: self];
		[superview addSubview: _scrollView];
		RELEASE(self);
	}
	else if ([_scrollView superview] != nil) /* -isScrollViewShown */
	{
		superview = [_scrollView superview];
		NSAssert(superview != nil, @"For -setShowsScrollView: NO, scroll view must have a superview");
		
		RETAIN(self);
		[_scrollView setDocumentView: nil];
		[self removeFromSuperview]; 
		[_scrollView removeFromSuperview];
		
		[self setAutoresizingMask: [_scrollView autoresizingMask]];
		
		[self setFrame: [_scrollView frame]];
		// WARNING: More about next line and following assertion can be read here: 
		// <http://www.cocoabuilder.com/archive/message/cocoa/2006/9/29/172021>
		// Stop also to receive any view/window notifications in ETContainer code 
		// before turning scroll view on or off.
		NSAssert1(NSEqualRects([self frame], [_scrollView frame]), 
			@"Unable to update the frame of container %@, you must stop watch "
			@"any notifications posted by container before hiding or showing "
			@"its scroll view (Cocoa bug)", self);

		
		[[self layout] setContentSizeLayout: NO];
		// Updating layout here is a source of complication for no visible benefits
		//[[self layout] adjustLayoutSizeToSizeOfContainer: self];
		
		[superview addSubview: self];
		RELEASE(self);
	}
}

/** Returns the view that takes care of the display. Most of time it is equal
    to the container itself. But for some layout like ETTableLayout, the 
	returned view would be an NSTableView instance. */
- (NSView *) displayView
{
	return _displayView;
}

/* Method called when we switch between layouts. Manipulating the display view
   is the job of ETContainer, ETLayout instances may provide display view
   prototype but they never never manipulate it as a subview in view hierachy. */
- (void) setDisplayView: (NSView *)view
{
	if (_displayView == nil && view == nil)
		return;
	if (_displayView == view && (_displayView != nil || view != nil))
	{
		NSLog(@"WARNING: Trying to assign an identical display view to container %@", self);
		return;
	}
	
	[_displayView removeFromSuperview];
	
	_displayView = view;
	
	/* Be careful with scroll view code, it will call -displayView and thereby
	   needs up-to-date _displayView */
	if (view != nil && [self scrollView] != nil)
	{
		if ([self isScrollViewShown])
			[self setShowsScrollView: NO];
	}
	else if (view == nil && [self scrollView] != nil)
	{
		if ([self isScrollViewShown] == NO)
			[self setShowsScrollView: YES];		
	}

	if (view != nil)
	{	
		[view removeFromSuperview];
		[view setFrameSize: [self frame].size];
		[view setFrameOrigin: NSZeroPoint];
		[self addSubview: view];
		
		[self syncDisplayViewWithContainer];
	}
}

/*
- (ETLayoutOverflowStyle) overflowStyle
{

}

- (void) setOverflowStyle: (ETLayoutOverflowStyle)
{

}
*/

/* Layout Item Tree */

- (void) addItem: (ETLayoutItem *)item
{
	[(ETLayoutItemGroup *)[self layoutItem] addItem: item];
}

- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] insertItem: item atIndex: index];
}

- (void) removeItem: (ETLayoutItem *)item
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItem: item];
}

- (void) removeItemAtIndex: (int)index
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItemAtIndex: index];
}

- (ETLayoutItem *) itemAtIndex: (int)index
{
	return [(ETLayoutItemGroup *)[self layoutItem] itemAtIndex: index];
}

- (void) addItems: (NSArray *)items
{
	[(ETLayoutItemGroup *)[self layoutItem] addItems: items];
}

- (void) removeItems: (NSArray *)items
{
	[(ETLayoutItemGroup *)[self layoutItem] removeItems: items];
}

- (void) removeAllItems
{
	[(ETLayoutItemGroup *)[self layoutItem] removeAllItems];
}

- (int) indexOfItem: (ETLayoutItem *)item
{
	return [(ETLayoutItemGroup *)[self layoutItem] indexOfItem: item];
}

- (NSArray *) items
{
	return [(ETLayoutItemGroup *)[self layoutItem] items];
}

/** Add a view to layout as a subview of the view container. */
/** Remove a view which was layouted as a subview of the view container. */
/** Remove the view located at index in the series of views (which were layouted as subviews of the view container). */
/** Return the view located at index in the series of views (which are layouted as subviews of the view container). */

/* Selection */

- (NSArray *) selectionIndexPaths
{
	return [(ETLayoutItemGroup *)[self layoutItem] selectionIndexPaths];
}

- (void) setSelectionIndexPaths: (NSArray *)indexPaths
{
	[(ETLayoutItemGroup *)[self layoutItem] setSelectionIndexPaths: indexPaths];
}

- (void) setSelectionIndexes: (NSIndexSet *)indexes
{
	int numberOfItems = [[self items] count];
	int lastSelectionIndex = [indexes lastIndex];
	
	NSLog(@"Set selection indexes to %@ in %@", indexes, self);
	
	if (lastSelectionIndex > (numberOfItems - 1) && index != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		NSLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
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
	if (index != NSNotFound)
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
	
	NSLog(@"Modify selected item from %d to %d of %@", [self selectionIndex], index, self);
	
	/* Check new selection validity */
	NSAssert1(index >= 0, @"-setSelectionIndex: parameter must not be a negative value like %d", index);
	if (index > (numberOfItems - 1) && index != NSNotFound) /* NSNotFound is a big value and not -1 */
	{
		NSLog(@"WARNING: Try to set selection index %d when container %@ only contains %d items",
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

- (ETSelection *) selectionShape
{
	return _selectionShape;
}

/** point parameter must be expressed in receiver coordinates */
- (BOOL) doesSelectionContainsPoint: (NSPoint)point
{
	ETLayoutItem *item = [[self layout] itemAtLocation: point];

	if ([item isSelected])
	{
		NSAssert2([[self selectionIndexes] containsIndex: [self indexOfItem: item]],
			@"Mismatch between selection indexes and item %@ selected state in %@", 
			item, self);
		return YES;
	}
		
	return NO;

// NOTE: The code below could be significantly faster on large set of items
#if 0
	NSArray *selectedItems = [[self items] objectsAtIndexes: [self selectionIndexes]];
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

- (void) setAllowsDragging: (BOOL)flag
{
	_dragAllowed = flag;
}

- (BOOL) allowsDragging
{
	return _dragAllowed;
}

- (void) setAllowsDropping: (BOOL)flag
{
	_dropAllowed = flag;
}

- (BOOL) allowsDropping
{
	// FIXME: We should rather check whether source implement dragging data
	// source methods.
	if ([self source] != nil)
		return NO;
	
	return _dropAllowed;
}

/* Layers */

- (void) fixOwnerIfNeededForItem: (ETLayoutItem *)item
{
	/* Check the item to be now embedded in a new container (owned by the new 
	   layer) isn't already owned by current container */
	if ([[self items] containsObject: item])
		[self removeItem: item];
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
		layers = [[self items] objectsWithValue: [ETLayer class] forKey: @"class"];
		/* Find the layer to be replaced in layers array */
		layerToMoveUp = [layers objectAtIndex: layerIndex];
		/* Retrieve the index in layoutItems array for this particular layer */
		realIndex = [self indexOfItem: layerToMoveUp];
		
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

/* Grouping and Stacking */

- (void) group: (id)sender
{
	/*ETLayoutItem *item = [self itemAtIndex: [self selectionIndex]]; 
	
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		[(ETLayoutItemGroup *)item make];
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ must be an item group to be stacked", self);
	}
	
	if ([self canUpdateLayout])
		[self updateLayout];*/	
}

- (void) stack: (id)sender
{
	ETLayoutItem *item = [self itemAtIndex: [self selectionIndex]]; 
	
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		[(ETLayoutItemGroup *)item stack];
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ must be an item group to be stacked", self);
	}
	
	if ([self canUpdateLayout])
		[self updateLayout];	
}

/* Item scaling */

- (float) itemScaleFactor
{
	return _itemScale;
}

- (void) setItemScaleFactor: (float)factor
{
	_itemScale = factor;
	if ([self canUpdateLayout])
		[self updateLayout];
}

/* Rendering Chain */

- (void) render
{
	//[_layoutItems makeObjectsPerformSelector: @selector(render)];
}

- (void) render: (NSMutableDictionary *)inputValues
{
	[[self items] makeObjectsPerformSelector: @selector(render:) withObject: nil];
}

- (void) drawRect: (NSRect)rect
{
	/* Takes care of drawing layout items with a view */
	[super drawRect: rect];
	
	/* Now we must draw layout items without view... using either a cell or 
	   their own renderer. Layout item are smart enough to avoid drawing their
	   view when they have one. */
	//[[self items] makeObjectsPerformSelector: @selector(render:) withObject: nil];
}

/* Actions */

/** Returns usually the lowest subcontainer of the receiver which contains 
    location point in the view hierarchy. For any other kind of subviews, hit 
	test doesn't succeed by default to eliminate potential issues you may 
	encounter by using subclasses of NSControl like NSImageView as layout item 
	view.
	If you want to layout controls which should support direct interaction like
	checkbox or popup menu, you can turn hit test on by calling 
	-setEnablesHitTest: with YES.
	If the point is located in the receiver itself but outside of any 
	subcontainers, returns self. When no subcontainer can be found, returns 
	nil. 
	*/
- (NSView *) hitTest: (NSPoint)location
{
	NSView *subview = [super hitTest: location];
	
	/* If -[NSView hitTest:] returns a container or if we use an AppKit control 
	   as a display view, we simply return the subview provided by 
	   -[NSView hitTest:]
	   If hit test is turned on, everything should be handled as usual. */
	if ([self displayView] || [self isHitTestEnabled] 
	 || [subview isKindOfClass: [self class]])
	{
		return subview;
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

- (void) setEnablesHitTest: (BOOL)passHitTest
{ 
	_subviewHitTest = passHitTest; 
}

- (BOOL) isHitTestEnabled { return _subviewHitTest; }

- (void) mouseDown: (NSEvent *)event
{
	NSLog(@"Mouse down in %@", self);
	
	if ([self displayView] != nil) /* Layout object is wrapping an AppKit control */
	{
		NSLog(@"WARNING: %@ should have catch mouse down %@", [self displayView], event);
		return;
	}
	
	NSPoint localPosition = [self convertPoint: [event locationInWindow] fromView: nil];
	ETLayoutItem *newlyClickedItem = [[self layout] itemAtLocation: localPosition];
	int newIndex = NSNotFound;
	
	if (newlyClickedItem != nil)
		newIndex = [self indexOfItem: newlyClickedItem];
	
	/* Update selection if needed */
	ETLog(@"Update selection on mouse down");
	
	if (newIndex == NSNotFound && [self allowsEmptySelection])
	{
			[self setSelectionIndex: newIndex];
	}
	else if (newIndex != NSNotFound)
	{
		if (([event modifierFlags] & SELECTION_BY_ONE_KEY_MASK
		  || [event modifierFlags] & SELECTION_BY_RANGE_KEY_MASK)
		  && ([self allowsMultipleSelection]))
		{
			NSMutableIndexSet *indexes = [self selectionIndexes];
			
			[indexes invertIndex: newIndex];
			[self setSelectionIndexes: indexes];
		}
		else /* Only single selection has to be handled */
		{
			[self setSelectionIndex: newIndex];
		}
	}
	
	/*NSMutableIndexSet *selection = [self selectionIndexes];
		
	[selection addIndex: [self indexOfItem: _clickedItem]];
	[self setSelectionIndexes: selection];*/

	/* Handle possible double click */
	if ([event clickCount] > 1) 
		[self mouseDoubleClick: event];
}

- (void) mouseDoubleClick: (NSEvent *)event
{
	NSView *hitView = nil;
	NSPoint location = [[[self window] contentView] 
		convertPoint: [event locationInWindow] toView: [self superview]];
	
	/* Find whether hitView is a layout item view */
	_subviewHitTest = YES; /* Allow us to make a hit test on our subview */
	hitView = [self hitTest: location];
	_subviewHitTest = NO;
	DESTROY(_clickedItem);
#if 0
	_clickedItem = [[self items] objectWithValue: hitView forKey: @"displayView"];
#else
	_clickedItem = [[self items] objectWithValue: hitView forKey: @"view"];
#endif
	RETAIN(_clickedItem);
	NSLog(@"Double click detected on view %@ and layout item %@", hitView, _clickedItem);
	
	[[NSApplication sharedApplication] sendAction: [self doubleAction] to: [self target] from: self];
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

/* Overriden NSView methods */

/* GNUstep doesn't rely on -setFrameSize: in -setFrame: unlike Cocoa, so we 
   patch frame parameter in -setFrame: too */
#ifdef GNUSTEP
- (void) setFrame: (NSRect)frame
{

	NSRect patchedFrame = frame;
	NSSize clipViewSize = [[self scrollView] contentSize];
	
	NSLog(@"-setFrame to %@", NSStringFromRect(frame));
		
	if ([self isScrollViewShown])
	{
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
   view. -setFrame: calls -setFrameSize: on Cocoa but not on GNUstep. */
- (void) setFrameSize: (NSSize)size
{
	NSSize patchedSize = size;
	NSSize clipViewSize = [[self scrollView] contentSize];
	
	//NSLog(@"-setFrameSize: to %@", NSStringFromSize(size));

	if ([self isScrollViewShown])
	{
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

/* Dragging Support */

@interface ETContainer (ETContainerDraggingSupport)
- (void) beginDragWithEvent: (NSEvent *)event;
- (BOOL) container: (ETContainer *)container writeItemsAtIndexes: (NSIndexSet *)indexes toPasteboard: (NSPasteboard *)pboard;
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
	ETLog(@"Mouse dragged");
	
	/* Convert drag location from window coordinates to the receiver coordinates */
	NSPoint localPoint = [self convertPoint: [event locationInWindow] fromView: nil];

	/* Only handles event when it is located inside selection */
	if ([self allowsDragging] && [self doesSelectionContainsPoint: localPoint])
	{
		ETLog(@"Allowed dragging on selection");
		[self beginDragWithEvent: event]; 
	}
}

/* ETContainer specific method to create a new drag and passing the request to data source */
- (void) beginDragWithEvent: (NSEvent *)event
{
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	NSPoint dragPosition = [self convertPoint: [event locationInWindow]
									 fromView: nil];
	BOOL dragDataProvided = NO;

	dragDataProvided = [self container: self writeItemsAtIndexes: [self selectionIndexes]
		toPasteboard: pboard];	
	
	//dragPosition.x -= 32;
	//dragPosition.y -= 32;
	
	// FIXME: Draw drag image made of all dragged items and not just first one
	if (dragDataProvided)
	{
		[self dragImage: [[self itemAtIndex: [self selectionIndex]] image]
					 at: dragPosition
				 offset: NSZeroSize
				  event: event 
			 pasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]
				 source: self 
			  slideBack: YES];
	}
}

- (BOOL) container: (ETContainer *)container writeItemsAtIndexes: (NSIndexSet *)indexes toPasteboard: (NSPasteboard *)pboard
{
	BOOL dragDataProvided = NO;
	
	/* Verify if the drag is allowed now for AppKit-based layout */
	if ([self allowsDragging] == NO)
		return NO;
	
	if ([self source] != nil 
	 && [[self source] respondsToSelector: @selector(container:writeItemsWithIndexes:toPasteboard:)])
	{
		dragDataProvided = [[self source] container: self writeItemsAtIndexes: [self selectionIndexes]
			toPasteboard: pboard];
	}
	else if ([self source] == nil) /* Handles drag by ourself when allowed */
	{
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject: indexes];
		
		[pboard declareTypes: [NSArray arrayWithObject: ETLayoutItemPboardType]
			owner: nil];
			
		// NOTE: If we implement an unified layout item tree shared by 
		// applications through CoreObject, we could eventually just put simple
		// path on the pasteboard rather than archived object or index.
		//[pboard setString: forType: ETLayoutItemPboardType];
		/*[pboard setData: forType: ETLayoutItemPboardType];*/
		dragDataProvided = [pboard setData: data forType: ETLayoutItemPboardType];
	}

	return dragDataProvided;
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
	
	if ([self allowsDropping] == NO)
		return NSDragOperationNone;
	
	return NSDragOperationPrivate;
}

// FIXME: Handle layout orientation, only works with horizontal layout
// currently, in other words the insertion indicator is always vertical.
- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)drag
{
	ETLog(@"Drag update receives in dragging destination %@", self);
	
	if ([self allowsDropping] == NO)
		return NSDragOperationNone;
		
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
		// NOTE: Following code doesn't work...
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
	// NOTE: Following code doesn't work...
	//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
}


- (void) draggingEnded: (id <NSDraggingInfo>)sender
{
	ETLog(@"Drag end receives in dragging destination %@", self);
	
	/* Erases insertion indicator */
	[self setNeedsDisplayInRect: NSIntegralRect(_prevInsertionIndicatorRect)];
	[self displayIfNeeded];
	// NOTE: Following code doesn't work...
	//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -validateDropXXX data source method.  */
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)sender
{
	ETLog(@"Prepare drag receives in dragging destination %@", self);
	
	NSPoint localDropPosition = [self convertPoint: [sender draggingLocation] fromView: nil];
	ETLayoutItem *dropTargetItem = [[self layout] itemAtLocation: localDropPosition];
	int dropIndex = NSNotFound;
	NSRect itemRect = NSZeroRect;
	
	ETLog(@"Found item %@ as drop target", dropTargetItem);
	
	/* Found no drop target */
	if (dropTargetItem == nil)
		return NO;
	
	/* Found a drop target at dropIndex */
	dropIndex = [self indexOfItem: dropTargetItem];
	
	/* Increase index if the insertion is located on the right of dropTargetItem */
	// FIXME: Handle layout orientation, only works with horizontal layout
	// currently.
	itemRect = [[self layout] displayRectOfItem: dropTargetItem];
	if (localDropPosition.x > NSMidX(itemRect))
		dropIndex++;
	
	return [self container: self validateDrop: sender atIndex: dropIndex];
}

- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)drag atIndex: (int)index
{
	// FIXME: Test all possible drag methods supported by data source
	if ([self source] != nil && [[self source] respondsToSelector: @selector(container:acceptDrop:atIndex:)])
	{
		return [[self source] container: self 
			                 acceptDrop: drag
					            atIndex: index];
	}
	else if ([self source] == nil) /* Handles drag by ourself when allowed */
	{
		NSPasteboard *pboard = [drag draggingPasteboard];
		NSData *data = [pboard dataForType: ETLayoutItemPboardType];
		NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData: data];
		int movedIndex = [indexes firstIndex];
		ETLayoutItem *movedItem = [self itemAtIndex: movedIndex];
		int insertionIndex = index;
		BOOL itemAlreadyRemoved = NO; // NOTE: Feature to be implemented
		
		RETAIN(movedItem);
		
		//[self setAutolayout: NO];
		 /* Dropped item is visible where it was initially located.
		    If the flag is YES, dropped item is currently invisible. */
		if (itemAlreadyRemoved == NO)
		{
			ETLog(@"For drop, removes item at index %d", movedIndex);
			[self removeItem: movedItem];
			if (insertionIndex > movedIndex)
				insertionIndex--;
		}
		//[self setAutolayout: YES];
		
		ETLog(@"For drop, insert item at index %d", insertionIndex);
		[self insertItem: movedItem atIndex: insertionIndex];
		[self setSelectionIndex: insertionIndex];
		
		RELEASE(movedItem);
		
		return YES;
	}

	/* Don't handle drag when a source is set and doesn't implement this 
	   mandatory drag data source method. */		
	return NO;
}

/* Will be called when -draggingEntered and -draggingUpdated have validated the drag
   This method is equivalent to -acceptDropXXX data source method.  */
- (BOOL) performDragOperation: (id <NSDraggingInfo>)sender
{
	ETLog(@"Perform drag receives in dragging destination %@", self);
	
	NSPoint localDropPosition = [self convertPoint: [sender draggingLocation] fromView: nil];
	ETLayoutItem *dropTargetItem = [[self layout] itemAtLocation: localDropPosition];
	int dropIndex = NSNotFound;
	NSRect itemRect = NSZeroRect;
	
	ETLog(@"Found item %@ as drop target", dropTargetItem);
	
	/* Found no drop target */
	if (dropTargetItem == nil)
		return NO;
	
	/* Found a drop target at dropIndex */
	dropIndex = [self indexOfItem: dropTargetItem];
	
	/* Increase index if the insertion is located on the right of dropTargetItem */
	// FIXME: Handle layout orientation, only works with horizontal layout
	// currently.
	itemRect = [[self layout] displayRectOfItem: dropTargetItem];
	if (localDropPosition.x > NSMidX(itemRect))
		dropIndex++;

	return [self container: self acceptDrop: sender atIndex: dropIndex];
}

- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)drag atIndex: (int)dropIndex
{
	// FIXME: Test all possible drag methods supported by data source	
	if ([self source] != nil && [[self source] respondsToSelector: @selector(container:validateDrop:atIndex:)])
	{
		return [[self source] container: self 
		                   validateDrop: drag
		                        atIndex: dropIndex];
	}
	else if ([self source] == nil) /* Handles drag by ourself when allowed */
	{
		return YES;
	}

	/* Implementation -container:validateDrop:atIndex: is optional thereby we don't
	   disallow dragging. */
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
	// NOTE: Following code doesn't work...
	//[self displayIfNeededInRectIgnoringOpacity: _prevInsertionIndicatorRect];
}

@end
