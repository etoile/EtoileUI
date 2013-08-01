/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2010
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETWidgetLayout.h"
#import "ETTableLayout.h"
#import "ETCompatibility.h"

@interface TestWidgetLayout : NSObject <UKTest>
{

}

@end

@implementation TestWidgetLayout

/* Builds a table view enclosed in a scroll view from scratch. */
- (NSScrollView *) scrollingTableView
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

- (void) testInitWithNibLayoutView
{
	COObjectGraphContext *context = [ETUIObject defaultTransientObjectGraphContext];
	ETTableLayout *layout = AUTORELEASE([[ETTableLayout alloc]
		initWithLayoutView: nil objectGraphContext: context]);

	UKNotNil([layout layoutView]);
	UKObjectKindOf([layout tableView], ETTableView);
}

- (void) testInitWithCustomLayoutView
{
	NSScrollView *layoutView = [self scrollingTableView];
	COObjectGraphContext *context = [ETUIObject defaultTransientObjectGraphContext];
	ETTableLayout *layout = AUTORELEASE([[ETTableLayout alloc]
		initWithLayoutView: layoutView objectGraphContext: context]);

	UKObjectsEqual(layoutView, [layout layoutView]);
	UKObjectKindOf([layout tableView], ETTableView);
}

@end

