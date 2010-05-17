/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2007
	License:  Modified BSD (see COPYING)
 */

#import "TableController.h"

/** All examples in this code could be rewritten with data source. They just 
shows very basic use of EtoileUI when you don't want to deal with the extra
burden involved by a data source. */
@implementation TableController

/* An item item group using a two columns table layout */
- (void) setUpTopLeftTableItem
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *tableItem2 = [tableContainer2 layoutItem];
	ETTableLayout *tableLayout2 = [ETTableLayout layout];
	NSArray *visibleColumnIds = [NSArray arrayWithObjects: @"displayName", @"intensity", nil];
	ETSelectTool *tool = [ETSelectTool tool];

	[tool setAllowsMultipleSelection: YES];
	[tool setAllowsEmptySelection: NO];
	[tool setShouldRemoveItemsAtPickTime: NO];

	[tableLayout2 setAttachedTool: tool];	
	[tableLayout2 setDisplayName: @"Name" forProperty: @"displayName"]; 
	[[tableLayout2 columnForProperty: @"displayName"] setWidth: 50];
	[tableLayout2 setDisplayName: @"Intensity" forProperty: @"intensity"]; 	
	[tableLayout2 setStyle: [itemFactory horizontalSlider]
	           forProperty: @"intensity"];
	[tableLayout2 setDisplayedProperties: visibleColumnIds];

	[tableItem2 setLayout: tableLayout2];

#define NUMBER(x) [NSNumber numberWithInt: x]

	ETLayoutItem *item = [itemFactory item];
	[item setValue: @"Red" forProperty: @"name"];
	[item setValue: NUMBER(10) forProperty: @"intensity"];	
	[tableItem2 addItem: item];
	
	item = [itemFactory item];
	[item setValue: @"Green" forProperty: @"name"];
	[item setValue: NUMBER(100) forProperty: @"intensity"];
	[tableItem2 addItem: item];

	item = [itemFactory item];
	[item setValue: @"Blue" forProperty: @"name"];
	[item setValue: NUMBER(0) forProperty: @"intensity"];	
	[tableItem2 addItem: item];
}

/* An item group based on a single column table layout */
- (void) setUpTopRightTableItem
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *tableItem = [tableContainer layoutItem];

	[tableItem setLayout: [ETTableLayout layout]];

	[[tableItem layout] setDisplayedProperties: [NSArray arrayWithObject: @"displayName"]];
	[[tableItem layout] setEditable: YES forProperty: @"displayName"];
	
	[tableItem addItem: [itemFactory itemWithValue: @"Red"]];
	[tableItem addItem: [itemFactory itemWithValue: @"Green"]];
	/* Illustrate autoboxing of objects into layout items */
	[tableItem addObject: @"Blue"];
	[tableItem addObject: [NSNumber numberWithInt: 3]];
	/* Value will be image object description */
	[tableItem addObject: [NSImage imageNamed: @"NSApplication"]];
}

/* An item group using a custom outline layout based on an existing outline view */
- (void) setUpBottomLeftOutlineItem
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *outlineItem = [outlineView owningItem];
	NSImage *icon = [NSImage imageNamed: @"NSApplicationIcon"];
	ETLayoutItem *imgViewItem = [itemFactory itemWithView: AUTORELEASE([[NSImageView alloc] init])];

	[[outlineItem layout] setStyle: imgViewItem forProperty: @""];
	/* icon and displayName are the properties visible by default */
	[[outlineItem layout] setEditable: YES forProperty: @"displayName"];
	[[outlineItem layout] setAttachedTool: [ETSelectTool tool]];
	[[[outlineItem layout] attachedTool] setAllowsMultipleSelection: YES];

	/* This line is optional and simply avoids to update outlineItem on 
	   each -addItem: call */
	[outlineItem setAutolayout: NO];

	ETLayoutItemGroup *itemGroup = [itemFactory itemGroupWithValue: icon];

	/* The name set will be returned by -displayName in addition to -name */
	[itemGroup setValue: @"Icon!" forProperty: @"name"];
	[itemGroup addItem: [itemFactory itemWithValue: icon]];
	[itemGroup addItem: [itemFactory itemWithValue: icon]];
	[outlineItem addItem: itemGroup];
	[outlineItem addItem: [itemFactory itemWithValue: icon]];
	
	[outlineItem setAutolayout: YES];
	[outlineItem updateLayout];
}

/* Invoked when the application is going to finish its launch because 
TableController is set as the application's delegate in the nib. 

What -rebuildMainNib does, is similar to converting the AppKit view hierarchy 
into a layout item tree with:

ETEtoileUIBuilder *builder = [ETEtoileUIBuilder builder];
NSWindow *window = [outlineView window];

[[ETLayoutItemGroup windowGroup] addItem: [builder render: window]]; */
- (void) applicationWillFinishLaunching: (NSNotification *)notif
{
	/* Will turn the nib views and windows into layout item trees */
	[ETApp rebuildMainNib];

	/* Add content and customize the item tree built from the nib */
	[self setUpTopLeftTableItem];
	[self setUpTopRightTableItem];
	[self setUpBottomLeftOutlineItem];

	/* Show the pick palette on which picked items will be put */
	[[ETPickboard localPickboard] showPickPalette];
}

@end
