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
	NSArray *itemDisplayViews = [_layoutItems valueForKey: @"displayView"];
	
	[itemDisplayViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	/* Delegate layout rendering to custom layout object */
	[_containerLayout renderWithLayoutItems: _layoutItems inContainer: self];

	[self setNeedsDisplay: YES];
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

/** Returns the view that takes care of the display. Most of time it is equal
    to the container itself. But for some layout like ETTableLayout, the 
	returned view would be an NSTableView instance. */
- (NSView *) displayView
{
	return _displayView;
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
