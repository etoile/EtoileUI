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

// NOTE: Dealloc and Awaking from nib handled by ETTableLayout superview.

- (int) outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item
{
	NSArray *childLayoutItems = nil;
	ETContainer *container =  [self container];
	
	if (item == nil)
	{
		childLayoutItems = [container layoutItemCache];
		
		return [childLayoutItems count];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		/* -view must always return a container for ETLayoutItemGroup */
		ETContainer *itemContainer = (ETContainer *)[item view];
		NSString *itemPath = [itemContainer path];
			
		/* 'item' path and source have been set in -[ETViewLayout layoutItemsFromTreeSource] */
		//childItem = [[itemContainer source] itemAtPath: childItemPath inContainer: [self container]];
		return [[container source] numberOfItemsAtPath: itemPath inContainer: container];
	}
	
	//NSLog(@"Returns %d as number of items in %@", [childLayoutItems count], outlineView);
	
	return 0;
}

- (id) outlineView: (NSOutlineView *)outlineView child: (int)rowIndex ofItem: (id)item
{
	NSArray *childLayoutItems = nil;
	ETContainer *container = [self container];
	ETLayoutItem *childItem = nil; /* Leaf by default */
	
	if (item == nil) /* Root */
	{
		childLayoutItems = [container layoutItemCache];
		childItem = [childLayoutItems objectAtIndex: rowIndex];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]]) /* Node */
	{
		ETContainer *itemContainer = nil;
		ETContainer *childContainer = nil;
		NSString *childPath = nil;

		/* -view must always return a container for ETLayoutItemGroup */
		itemContainer = (ETContainer *)[item view]; 
		childPath = [[itemContainer path] stringByAppendingPathComponent: 
			[NSString stringWithFormat: @"%d", rowIndex]];
			
		/* 'item' path and source have been set in -[ETViewLayout layoutItemsFromTreeSource] */
		//childItem = [[itemContainer source] itemAtPath: childItemPath inContainer: [self container]];
		childItem = [[container source] itemAtPath: childPath inContainer: container];
		//[[childItem container] setSource: [[self container] source]];
		if ([childItem isKindOfClass: [ETLayoutItemGroup class]])
		{
			childContainer = (ETContainer *)[childItem view];
			[childContainer setPath: childPath];
		}
	}

	//NSLog(@"Returns % child item in outline view %@", childItem, outlineView);
	
	return childItem;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		//NSLog(@"Returns item is expandable in outline view %@", outlineView);
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

	//NSLog(@"Returns %@ as object value in outline view %@", 
	//	[item valueForProperty: [column identifier]], outlineView);
	
	return [item valueForProperty: [column identifier]];
}

- (ETLayoutItem *) clickedItem
{
	NSOutlineView *outlineView = [(NSScrollView *)_displayViewPrototype documentView];
	ETLayoutItem *item = [outlineView itemAtRow: [outlineView clickedRow]];
	
	NSLog(@"-clickedItem in %@", self);
	
	return item;
}

@end
