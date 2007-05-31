//
//  ETTableLayout.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETTableLayout.h"
#import "ETContainer.h"
#import "ETLayoutItem.h"
#import "ETViewLayoutLine.h"
#import "NSView+Etoile.h"
#import "GNUstep.h"

@interface NSDictionary (EtoileHorribleHack)
- (id) objectForUncopiedKey: (id)key;
- (void) setObject: (id)object forUncopiedKey: (id)key;
@end

/* Terribly unefficient but well will do the trick right now :-) */
@implementation NSMutableDictionary (EtoileHorribleHack)
- (id) objectForUncopiedKey: (id)key
{
	NSLog(@"Returning object for hash %d of key %@", [key hash], key);
	return [self objectForKey: [NSNumber numberWithInt: [key hash]]];
}

- (void) setObject: (id)object forUncopiedKey: (id)key
{
	NSLog(@"Setting object for hash %d of key %@", [key hash], key);
	[self setObject: object forKey: [NSNumber numberWithInt: [key hash]]];
}

@end


@implementation ETTableLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{
		_layoutItemCacheByContainer = [[NSMutableDictionary alloc] init];
		_layoutItemCacheByTableView = [[NSMutableDictionary alloc] init];
		_scrollingTableViewsByContainer = [[NSMutableDictionary alloc] init];
    }
    
	return self;
}

- (void) dealloc
{
	DESTROY(_layoutItemCacheByContainer);
	DESTROY(_layoutItemCacheByTableView);
	DESTROY(_scrollingTableViewsByContainer);
	
	[super dealloc];
}

/** Build a table view enclosed in a scroll view from scratch, set its data 
	source and delegate, finally register its association with container parameter
	and return it. */
- (NSScrollView *) scrollingTableViewForContainer: (ETContainer *)container
{
	NSScrollView *scrollView = [_scrollingTableViewsByContainer objectForUncopiedKey: container];
	
	if (scrollView == nil)
	{
		NSScrollView *scrollView = [self prebuiltTableView];
		NSTableView *tv = [scrollView documentView];
	
		[tv setDataSource: self];
		[tv setDelegate: self];
		
		[_scrollingTableViewsByContainer setObject: scrollView forUncopiedKey: container];
	}
	
	return scrollView;
}

- (NSScrollView *) prebuiltTableView
{
	NSTableView *tv = nil;
	NSScrollView *prebuiltTableView = nil;
	NSRect rect = NSMakeRect(0, 0, 180, 100);
	
	prebuiltTableView = [[NSScrollView alloc] initWithFrame: rect];
	[prebuiltTableView setAutoresizingMask: NSViewHeightSizable];
	
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: @"name"];
	
	[column setWidth: 180];
	[column setEditable: NO];
	
	rect = [[prebuiltTableView documentView] bounds];
	tv = [[NSTableView alloc] initWithFrame: rect];
	[tv setAutoresizingMask: NSViewHeightSizable];
	[tv addTableColumn: column];
	[prebuiltTableView setDocumentView: tv];
	DESTROY(column);
	RELEASE(tv);
	AUTORELEASE(prebuiltTableView);
	
	[tv setCornerView: nil];
	[tv setHeaderView: nil];
	
	return prebuiltTableView;
}

- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container
{
	NSScrollView *scrollView = [self scrollingTableViewForContainer: container];
	NSTableView *tv = [scrollView documentView];
	
	if ([scrollView superview] == nil)
	{
		[container setDisplayView: scrollView];
	}
	else if ([[scrollView superview] isEqual: container] == NO)
	{
		NSLog(@"WARNING: Table view of table layout should never have another "
			  @"superview than container parameter or nil.");
	}
	
	[_layoutItemCacheByContainer setObject: items forUncopiedKey: container];
	[_layoutItemCacheByTableView setObject: items forUncopiedKey: tv];
	[tv reloadData];
}

- (int) numberOfRowsInTableView: (NSTableView *)tv
{
	NSArray *layoutItems = [_layoutItemCacheByTableView objectForUncopiedKey: tv];
	
	//NSLog(@"Returns %d as number of items in table view %@", [layoutItems count], tv);
	
	return [layoutItems count];
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSArray *layoutItems = [_layoutItemCacheByTableView objectForUncopiedKey: tv];
	ETLayoutItem *item = [layoutItems objectAtIndex: rowIndex];
	
	//NSLog(@"Returns %@ as object value in table view %@", [item valueForProperty: [column identifier]], tv);
	
	return [item valueForProperty: [column identifier]];
}

@end
