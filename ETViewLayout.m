//
//  ETViewLayout.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETViewLayout.h"
#import "ETViewLayoutLine.h"
#import "ETContainer.h"
#import "GNUstep.h"

/*
 * Private methods
 */

@interface ETViewLayout (Private)

/* Utility methods */
- (NSRect) lineLayoutRectForViewAtIndex: (int)index;
- (NSPoint) locationForViewAtIndex: (int)index;
- (NSView *) viewIndexAtPoint: (NSPoint)location;
- (NSRange) viewRangeForLineLayoutWithIndex: (int)lineIndex;

@end

/*
 * Main implementation
 */

@implementation ETViewLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{

    }
    
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

/** Returns the view where the layout happens (by computing location of a subview series). */
/*
- (ETContainer *) container;
{
	return _container;
}
*/

/** Run the layout computation which assigns a location in the view container
    to each view added to the flow layout manager. */
- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container
{
	NSArray *itemViews = [items valueForKey: @"displayView"];
	NSArray *layoutModel = nil;
	
	layoutModel = [self layoutModelForViews: itemViews inContainer: container];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeViewLocationsForLayoutModel: layoutModel inContainer: container];
	
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[container setDisplayView: nil];
	
	// TODO: Optimize by computing set intersection of visible and unvisible item display views
	[itemViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	NSMutableArray *visibleItemViews = [NSMutableArray array];
	NSEnumerator  *e = [layoutModel objectEnumerator];
	ETViewLayoutLine *line = nil;
	
	/* Flatten layout model by putting all views in a single array */
	while ((line = [e nextObject]) != nil)
	{
		[visibleItemViews addObjectsFromArray: [line views]];
	}
	
	e = [visibleItemViews objectEnumerator];
	NSView *visibleItemView = nil;
	
	while ((visibleItemView = [e nextObject]) != nil)
	{
		if ([[container subviews] containsObject: visibleItemView] == NO)
			[container addSubview: visibleItemView];
	}
}

- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	return nil;
}

- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	return nil;
}

- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{

}

/* 
 * Utility methods
 */
 
- (NSRect) lineLayoutRectForViewAtIndex: (int)index { return NSZeroRect; }

- (NSPoint) locationForViewAtIndex: (int)index
{
    return NSZeroPoint;
}

- (NSView *) viewIndexAtPoint: (NSPoint)location
{
    return nil;
}

//- (NSRange) viewRangeForLineLayout:
- (NSRange) viewRangeForLineLayoutWithIndex: (int)lineIndex
{
    return NSMakeRange(0, 0);
}

@end
