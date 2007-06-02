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
#import "ETLayer.h"
#import "CocoaCompatibility.h"
#import "GNUstep.h"

@interface ETContainer (PackageVisibility)
- (NSArray *) layoutItems;
- (void) cacheLayoutItems: (NSArray *)layoutItems;
- (NSArray *) layoutItemCache;
- (int) checkSourceProtocolConformance;
@end

@interface ETContainer (Private)
- (void) syncDisplayViewWithContainer;
- (NSArray *) layoutItemsFromSource;
- (NSArray *) layoutItemsFromFlatSource;
- (NSArray *) layoutItemsFromTreeSource;
- (void) updateLayoutWithItems: (NSArray *)itemsToLayout;
- (void) fixOwnerIfNeededForItem: (ETLayoutItem *)item;
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

- (NSArray *) layoutItems
{
	return _layoutItems;
}

/* Uses to know which layout items the container takes care to display when
   a source is in use and layout items are thereby retrieved and managed by the 
   layout object itself. */
- (void) cacheLayoutItems: (NSArray *)layoutItems
{
	ASSIGN(_layoutItemCache, layoutItems);
}

/* Returns layout items currently displayed in the container unlike 
   -layoutItems which returns items displayed only when no source is used. Uses
   this method only for internal purpose when you need know layout items no 
   matter of how they have come into this container. */
- (NSArray *) layoutItemCache
{
	return _layoutItemCache;
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
	if (_displayView != nil)
	{
		if ([_displayView respondsToSelector: @selector(setDoubleAction:)])
			[(id)_displayView setDoubleAction: [self doubleAction]];
	}
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

- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	[_layoutItems insertObject: item atIndex: index];
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
	-setEnablesHitTest: with YES. */
- (NSView *) hitTest: (NSPoint)location
{
	if (_subviewHitTest)
	{
		NSEnumerator *e = [[self subviews] objectEnumerator];
		NSView *subview = nil;
		NSView *hitView = nil;
		/* Convert the location according to -hitTest: doc. It should be
		   expressed in superview coordinates. */
		NSPoint localLoc = [[[self window] contentView] 
			convertPoint: location toView: self];
		
		while (hitView == nil && (subview = [e nextObject]) != nil)
			hitView = [subview hitTest: localLoc];
		
		return hitView;
	}
	
	if (NSPointInRect(location, [self frame]))
		return self;

	return nil;
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

- (ETLayoutItem *) doubleClickedItem
{
	return _clickedItem;
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
