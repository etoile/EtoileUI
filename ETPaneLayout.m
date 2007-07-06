//
//  ETPaneLayout.m
//  Container
//
//  Created by Quentin Mathé on 07/06/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ETPaneLayout.h"
#import "ETPaneLayout.h"
#import "NSView+Etoile.h"
//#import "ETLayoutItem.h"
#import "ETContainer.h"

@implementation ETPaneLayout

/* Sizing Methods */

- (BOOL) isAllContentVisible
{
	return YES;
}

- (void) adjustLayoutSizeToContentSize
{

}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container
{
	NSArray *itemViews = [items valueForKey: @"displayView"];
	NSArray *layoutModel = nil;
	
	float scale = [container itemScaleFactor];
	//[self resizeLayoutItems: items toScaleFactor: scale];
	
	layoutModel = [self layoutModelForViews: itemViews inContainer: container];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeViewLocationsForLayoutModel: layoutModel inContainer: container];
		
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[container setDisplayView: nil];
	
	// TODO: Optimize by computing set intersection of visible and unvisible item display views
	NSLog(@"Remove views of next layout items to be displayed from their superview");
	[itemViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	NSMutableArray *visibleItemViews = [NSMutableArray arrayWithArray: layoutModel];
	NSEnumerator *e = [visibleItemViews objectEnumerator];
	NSView *visibleItemView = nil;
	
	while ((visibleItemView = [e nextObject]) != nil)
	{
		if ([[container subviews] containsObject: visibleItemView] == NO)
			[container addSubview: visibleItemView];
	}
}

- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	return views;
}

- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{
	//NSPoint viewLocation = NSMakePoint([container width] / 2.0, [container height] / 2.0);
	NSPoint viewLocation = NSZeroPoint;
	NSEnumerator *viewWalker = [layoutModel objectEnumerator];
	NSView *view = nil;
	
	while ((view = [viewWalker nextObject]) != nil)
	{
		[view setFrameOrigin: viewLocation];
	}
	
	NSLog(@"View locations computed by layout model %@", layoutModel);
}

// Private use
- (void) adjustLayoutSizeToSizeOfContainer: (ETContainer *)container { }

@end
