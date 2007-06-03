//
//  ETOutlineLayout.m
//  Container
//
//  Created by Quentin Mathé on 31/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ETOutlineLayout.h"
#import "ETContainer.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETViewLayoutLine.h"
#import "NSView+Etoile.h"
#import "GNUstep.h"

@interface ETContainer (PackageVisibility)
- (NSArray *) layoutItemCache;
@end

@implementation ETOutlineLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{
		BOOL nibLoaded = [NSBundle loadNibNamed: @"OutlinePrototype" owner: self];
		
		if (nibLoaded == NO)
		{
			NSLog(@"Failed to load nib OutlinePrototype");
			RELEASE(self);
			return nil;
		}
    }
    
	return self;
}

- (void) dealloc
{
	DESTROY(_displayViewPrototype);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	NSLog(@"%@ awakes from nib", self);
	RETAIN(_displayViewPrototype);
	[_displayViewPrototype removeFromSuperview];
}

- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container
{
	NSScrollView *scrollView = nil;
	NSOutlineView *tv = nil;
	
	/* No display view proto available, a table view needs needs to be created 
	   in code */
	if ([self displayViewPrototype] == nil)
	{
		//scrollView = [self scrollingTableView];
	}
	else
	{
		NSView *proto = [self displayViewPrototype];
		
		if ([proto isKindOfClass: [NSScrollView class]])
		{
			scrollView = (NSScrollView *)[self displayViewPrototype];
		}
		else
		{
			NSLog(@"WARNING: %@ display view prototype %@ isn't an NSScrollView instance", self, proto);
		}
	}
	
	NSLog(@"%@ scroll view has %@ as document view", self, [scrollView documentView]);
	tv = [scrollView documentView];
	
	if ([scrollView superview] == nil)
	{
		[container setDisplayView: scrollView];
	}
	else if ([[scrollView superview] isEqual: container] == NO)
	{
		NSLog(@"WARNING: Table view of table layout should never have another "
			  @"superview than container parameter or nil.");
	}
	
	if ([tv dataSource] == nil)
		[tv setDataSource: self];
	if ([tv delegate] == nil)
		[tv setDelegate: self];
		
	[tv reloadData];
}

- (int) outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item
{
	NSArray *childLayoutItems = nil;
	ETContainer *container = nil;
	
	if (item == nil)
	{
		container = [self container];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		/* -view must always return a container for ETLayoutItemGroup */
		container = (ETContainer *)[item view]; 
	}
	
	childLayoutItems = [[self container] layoutItemCache];
	NSLog(@"Returns %d as number of items in outline view %@", [childLayoutItems count], outlineView);
	
	return [childLayoutItems count];
}

- (id) outlineView: (NSOutlineView *)outlineView child: (int)rowIndex ofItem: (id)item
{
	NSArray *childLayoutItems = nil;
	ETContainer *container = nil;
	ETLayoutItem *childItem = nil;
	
	if (item == nil)
	{
		container = [self container];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		/* -view must always return a container for ETLayoutItemGroup */
		container = (ETContainer *)[item view]; 
	}
	
	childLayoutItems = [container layoutItemCache];
	childItem = [childLayoutItems objectAtIndex: rowIndex];
	NSLog(@"Returns % child item in outline view %@", childItem, outlineView);
	
	return childItem;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		NSLog(@"Returns item is expandable in outline view %@", outlineView);
		return YES;
	}
	
	return NO;
}

- (id) outlineView: (NSOutlineView *)outlineView 
	objectValueForTableColumn: (NSTableColumn *)column byItem: (id)item
{
	if (item == nil)
	{
		//NSLog(@"WARNING: Get nil item in -outlineView:objectValueForTableColumn:byItem: of %@", self);
		return nil;
	}

	NSLog(@"Returns %@ as object value in outline view %@", 
		[item valueForProperty: [column identifier]], outlineView);
	
	return [item valueForProperty: [column identifier]];
}

- (ETLayoutItem *) clickedItem
{
	NSTableView *tv = [(NSScrollView *)_displayViewPrototype documentView];
	NSArray *layoutItems = [[self container] layoutItemCache];
	ETLayoutItem *item = [layoutItems objectAtIndex: [tv clickedRow]];
	
	return item;
}

@end
