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

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	/* Neither container and delegate have to be retained. For container, only
	   because it retains us and is in charge of us
	   For _displayViewPrototype, it's up to subclasses to manage it. */
	[super dealloc];
}

- (void) containerSelectionDidChange: (NSNotification *)notif
{
	NSAssert2([[notif object] isEqual: [self container]], 
		@"Notification object %@ doesn't match container of layout %@", [notif object], self);
	
	NSLog(@"Pane layout %@ receives selection change from %@", self, [self container]);
	[[self container] updateLayout]; /* Will trigger -[ETViewLayout render] */

}

/*- (void) allowsMultipleSelection
{
	return NO;
}*/

- (void) setContainer: (ETContainer *)container
{
	[super setContainer: container];
	// FIXME: Memorize container selection style and restore it when the layout
	// is unset.
	[[self container] setEnablesSubviewHitTest: YES];
	[[self container] setAllowsMultipleSelection: NO];
	[[self container] setAllowsEmptySelection: NO];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: ETContainerSelectionDidChangeNotification 
			    object: nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(containerSelectionDidChange:)
		       name: ETContainerSelectionDidChangeNotification
		     object: [self container]];
}

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
	
	/* By safety, we correct container style in case it got modified between
	   -setContainer: call and now. */
	[[self container] setAllowsMultipleSelection: NO];
	[[self container] setAllowsEmptySelection: NO];
	
	//float scale = [container itemScaleFactor];
	//[self resizeLayoutItems: items toScaleFactor: scale];
	
	layoutModel = [self layoutModelForViews: itemViews inContainer: container];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeViewLocationsForLayoutModel: layoutModel inContainer: container];
		
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[container setDisplayView: nil];
	
	// TODO: Optimize by computing set intersection of visible and unvisible item display views
	//NSLog(@"Remove views of next layout items to be displayed from their superview");
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

/* Only returns selected item view */
- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer
{
	int selectedPaneIndex = [[self container] selectionIndex];
	
	NSLog(@"Layout selected pane %d in container %@", selectedPaneIndex, [self container]);
	
	if (selectedPaneIndex == NSNotFound)
		return views; // return nil;
		
	return [NSArray arrayWithObject: [views objectAtIndex: selectedPaneIndex]];
	/*@try 
	{ 
		return [views objectAtIndex: selectedPaneIndex];
	}
	@catch (NSException *e)
	{
		NSLog(@"Selection handling bug in ETContainer code");
	}
	@finally { return nil; }*/
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
