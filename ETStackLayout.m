//
//  ETStackLayout.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETStackLayout.h"
#import "ETContainer.h"
#import "ETLayoutItem.h"
#import "ETViewLayoutLine.h"
#import "NSView+Etoile.h"
#import "GNUstep.h"


@implementation ETStackLayout

- (void) renderWithLayoutItems: (NSArray *) items inContainer: (ETContainer *)container
{
	NSArray *itemViews = [items valueForKey: @"displayView"];
	ETViewLayoutLine *layoutLine = nil;
	
	layoutLine = [self layoutLineForViews: itemViews inContainer: container];
	[self computeViewLocationsForLayoutLine: layoutLine inContainer: container];
	
	NSEnumerator  *e = [[layoutLine views] objectEnumerator];
	NSView *visibleItemView = nil;
	
	// TODO: Optimize by computing set intersection of visible and unvisible item display views
	[itemViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	while ((visibleItemView = [e nextObject]) != nil)
	{
		if ([[container subviews] containsObject: visibleItemView] == NO)
			[container addSubview: visibleItemView];
	}
}

/** Returns a line filled with views to layout (stored in an array). */
- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	NSEnumerator *e = [views objectEnumerator];
	NSView *viewToLayout = nil;
	NSMutableArray *layoutedViews = [NSMutableArray array];
	ETViewLayoutLine *line = nil;
	float vAccumulator = 0;
    
	while ((viewToLayout = [e nextObject]) != nil)
	{
		vAccumulator += [viewToLayout height];
		
		if (vAccumulator < [viewContainer height])
		{
			[layoutedViews addObject: viewToLayout];
		}
		else
		{
			break;
		}
	}
	
	if ([layoutedViews count] == 0)
		return nil;
		
	line = [ETViewLayoutLine layoutLineWithViews: layoutedViews];
	[line setVerticallyOriented: YES];

	return line;
}

- (void) computeViewLocationsForLayoutLine: (ETViewLayoutLine *)line inContainer: (ETContainer *)container
{
	NSEnumerator *lineWalker = nil;
	NSView *view = nil;
	NSPoint viewLocation = NSMakePoint(0, [container height]);
	
	lineWalker = [[line views] objectEnumerator];
	
	while ((view = [lineWalker nextObject]) != nil)
	{
		[view setX: viewLocation.x];
		viewLocation.y -= [view height];
		[view setY: viewLocation.y];
	}
	
	/* NOTE: to avoid computing view locations when they are outside of the
		frame, think to add an exit condition here. */
	
	//NSLog(@"View locations computed by layout line :%@", line);
}

@end
