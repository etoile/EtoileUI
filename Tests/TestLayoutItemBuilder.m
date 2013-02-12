/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETView.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

@interface TestEtoileUIBuilder : NSObject <UKTest>
@end

/* NSView subclass for testing -renderView */
@interface CustomView : NSView { }
@end
@implementation CustomView
@end

@implementation TestEtoileUIBuilder

- (void) testRenderView
{
	id view = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview0 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview1 = AUTORELEASE([[CustomView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview00 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview01 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview010 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview02 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview020 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	
	[view addSubview: subview0];
	[view addSubview: subview1];

	[subview0 addSubview: subview00];
	[subview0 addSubview: subview01];
	[subview0 addSubview: subview02];

	[subview01 setWrappedView: subview010];	

	ETLayoutItemGroup *item02 = [[ETLayoutItemFactory factory] itemGroup];
	[item02 setSupervisorView: subview02];
	[item02 addItem: [[ETLayoutItemFactory factory] itemWithView: subview020]];

	ETLayoutItemGroup *rootItem = [[ETEtoileUIBuilder builder] renderView: view];
	id itemForSubview0 = [rootItem itemAtIndex: 0];
	id itemForSubview1 = [rootItem itemAtIndex: 1];
	id itemForSubview00 = [itemForSubview0 itemAtIndex: 0];
	id itemForSubview01 = [itemForSubview0 itemAtIndex: 1];
	id itemForSubview02 = [itemForSubview0 itemAtIndex: 2];
	id itemForSubview020 = [itemForSubview02 itemAtIndex: 0];

	UKObjectsNotSame(view, [rootItem view]);
	UKIntsEqual([[rootItem items] count], 2);

	/* NSView with subviews are turned into ETView and discarded */
	UKObjectKindOf([itemForSubview0 supervisorView], ETView);
	UKNil([itemForSubview0 view]);
	/* NSView without subviews are discarded */
	UKNil([itemForSubview00 supervisorView]);
	UKNil([itemForSubview00 view]);

	/* NSView subclass are not turned into ETView, but becomes item view */
	UKObjectsSame([itemForSubview1 view], subview1);
	
	/* ETView is rendered as ETLayoutItemGroup */
	UKTrue([itemForSubview01 isGroup]);
	UKTrue([itemForSubview02 isGroup]);

	/* ETView subviews are not rendered */
	UKObjectsSame(subview01 , [subview010 superview]);
	UKObjectsSame(itemForSubview01, [subview010 owningItem]);

	/* Standalone item which owns a view inserted a view hierarchy are 
	   are inserted in the item tree when the view hierarchy is rendered */
	UKObjectsSame(item02, itemForSubview02);
	UKIntsEqual(1, [[itemForSubview02 items] count]);
	UKObjectsSame(subview020, [itemForSubview020 view]);
}

@end
