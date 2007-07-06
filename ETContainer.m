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
- (NSInvocation *) invocationForSelector: (SEL)selector;
- (id) sendInvocationToDisplayView: (NSInvocation *)inv;
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
		_path = @"";
		_itemScale = 1.0;
		
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
	_dataSource = nil;
    
    [super dealloc];
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
	_dataSource = source;
	if (source != nil && [[self path] isEqual: @""])
	{
		[self setPath: @"/"];
	}
	else if (source == nil)
	{
		[self setPath: @""];
	}
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

@end

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
