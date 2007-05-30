//
//  ETContainer.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETContainer.h"
#import "ETLayoutItem.h"
#import "ETViewLayout.h"
#import "CocoaCompatibility.h"
#import "GNUstep.h"

@interface ETContainer (Private)
- (int) checkSourceProtocolConformance;
- (NSArray *) layoutItemsFromSource;
- (NSArray *) layoutItemsFromFlatSource;
- (NSArray *) layoutItemsFromTreeSource;
- (void) updateLayoutWithItems: (NSArray *)itemsToLayout;
@end


@implementation ETContainer

/** <init /> */
- (id) initWithFrame: (NSRect)rect views: (NSArray *)views
{
	self = [super initWithFrame: rect];
    
    if (self != nil)
    {
		_layoutItems = [[NSMutableArray alloc] init];
		
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
	_dataSource = nil;
    
    [super dealloc];
}

- (void) updateLayout
{
	if ([self source] != nil) /* Make layout with items provided by source */
	{
		NSArray *itemsFromSource = nil;
		
		if ([_layoutItems count] > 0)
		{
			NSLog(@"Update layout from source, yet %d items owned by the "
				@"container already exists, it may be better to remove them "
				@"before setting source.", [_layoutItems count]);
		}
		itemsFromSource = [self layoutItemsFromSource];
		[self updateLayoutWithItems: itemsFromSource];
	}
	else /* Make layout with items directly provided by container */
	{
		[self updateLayoutWithItems: _layoutItems];
	}	
	
	[self setNeedsDisplay: YES];
}

/** Returns 0 when source doesn't conform to any parts of ETContainerSource informal protocol.
    Returns 1 when source conform to protocol for flat collections and display of items in a linear style.
	Returns 2 when source conform to protocol for tree collections and display of items in a hiearchical style.
	If flat collection part of the protocol is implemented through 
	-numberOfItemsInContainer, ETContainer by default ignores tree collections
	part of protocol like numberOfItemsAtPath:inContainer: unless it is needed 
	by the current layout. In some cases, it is useful to implement both parts
	of the protocol if you want a lot of flexibility in term of layout. */
- (int) checkSourceProtocolConformance
{
	if ([[self source] respondsToSelector: @selector(numberOfItemsInContainer:)])
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
	else if ([[self source] respondsToSelector: @selector(numberOfItemsAtPath:inContainer:)])
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
	else
	{
		NSLog(@"%@ implements neither numberOfItemsInContainer: nor "
			  @"numberOfItemsAtPath:inContainer: as requested by "
			  @"ETContainerSource protocol.", [self source]);
		return 0;
	}
}

- (NSArray *) layoutItemsFromSource
{
	switch ([self checkSourceProtocolConformance])
	{
		case 1:
			return [self layoutItemsFromFlatSource];
			break;
		case 2:
			return [self layoutItemsFromTreeSource];
			break;
		default:
			NSLog(@"WARNING: source protocol is incorrectly supported by %@.", [self source]);
	}
	
	return nil;
}

- (NSArray *) layoutItemsFromFlatSource
{
	NSMutableArray *itemsFromSource = [NSMutableArray array];
	ETLayoutItem *layoutItem = nil;
	int nbOfItems = [[self source] numberOfItemsInContainer: self];
	
	for (int i = 0; i++; i < nbOfItems)
	{
		layoutItem = [[self source] itemAtIndex: i inContainer: self];
		[itemsFromSource addObject: layoutItem];
	}
	
	return itemsFromSource;
}

- (NSArray *) layoutItemsFromTreeSource
{
	return nil;
}

- (void) updateLayoutWithItems: (NSArray *)itemsToLayout
{
	NSArray *itemDisplayViews = [itemsToLayout valueForKey: @"displayView"];
	
	[itemDisplayViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	/* Delegate layout rendering to custom layout object */
	[_containerLayout renderWithLayoutItems: itemsToLayout inContainer: self];
}

- (ETViewLayout *) layout
{
	return _containerLayout;
}

- (void) setLayout: (ETViewLayout *)layout
{
	ASSIGN(_containerLayout, layout);
	[self updateLayout];
}

- (id) source
{
	return _dataSource;
}

- (void) setSource: (id)source
{
	_dataSource = source;
	[self updateLayout];
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
	// FIXME: Asks layout whether it handles scroll view itself or not. If 
	// needed like with table layout, delegate scroll view handling.
	if (scroll)
	{
		_scrollView = [[NSScrollView alloc] initWithFrame: [self frame]];
		
		RETAIN(self);
		[self removeFromSuperview];
		[_containerLayout adjustLayoutSizeToContentSize];
		[self setFrameSize: [_containerLayout layoutSize]];
		[_scrollView setDocumentView: self];
		RELEASE(self);
	}
	else
	{
		RETAIN(self);
		[self removeFromSuperview];
		//[_scrollView setDocumentView: nil];
		[self setFrame: [_scrollView frame]];
		[[_scrollView superview] addSubview: self];
		[_scrollView removeFromSuperview];
		RELEASE(self);
		
		DESTROY(_scrollView);
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

- (void) setDisplayView: (NSView *)view
{
	[_displayView removeFromSuperview];
	
	_displayView = view;
	[view removeFromSuperview];
	[view setFrameSize: [self frame].size];
	[view setFrameOrigin: NSZeroPoint];
	[self addSubview: view];
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
	[_layoutItems addObject: item];
	[self updateLayout];
}

- (void) removeItem: (ETLayoutItem *)item
{
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
	
	while ((layoutItem = [e nextObject]) != nil)
	{
		[self addItem: layoutItem];
	}
}

- (void) removeItems: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *layoutItem = nil;
	
	while ((layoutItem = [e nextObject]) != nil)
	{
		[self removeItem: layoutItem];
	}
}

- (void) removeAllItems
{
	NSArray *itemDisplayViews = [_layoutItems valueForKey: @"displayView"];
	
	[itemDisplayViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	[_layoutItems removeAllObjects];
	[self updateLayout];
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

/*
- (void) addView: (NSView *)view withIdentifier: (NSString *)identifier
{
	if ([[_layoutItems valueForKey: @"view"] containsObject: view] == NO)
	{
		[_layoutItems addObject: view];
		[_layoutedViewIdentifiers setObject: view forKey: identifier];
	}
}

- (void) removeViewForIdentifier:(NSString *)identifier
{
  NSView *view = [_layoutedViewIdentifiers objectForKey: identifier];
*/
    
  /* We try to remove view by its identifier first, then if it fails we won't
     remove a view which could be properly part of layouted views. */
    
/*
  [_layoutedViewIdentifiers removeObjectForKey: identifier];
  [_layoutedViews removeObject: view];
}


- (NSView *) viewForIdentifier: (NSString *)identifier
{
  return [_layoutedViewIdentifiers objectForKey: identifier];
}
*/
@end
