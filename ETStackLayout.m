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

// Must override unless you use a display view
- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{
	if ([layoutModel count] > 1)
	{
		NSLog(@"%@ -computeViewLocationsForLayoutModel: receives a model with "
			  @"%d objects and not one, this usually means "
			  @"-layoutLineForViews: isn't overriden as it should.", self, 
			  [layoutModel count]);
	}
	[self computeViewLocationsForLayoutLine: [layoutModel lastObject] inContainer: container];
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
