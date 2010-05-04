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
#import "ETLayoutItem+Factory.h"
#import "ETView.h"
#import "ETContainer.h"
#import "ETCompatibility.h"

@interface ETEtoileUIBuilder (UnitKitTests) <UKTest>
@end

/* NSView subclass for testing -renderView */
@interface CustomView : NSView { }
@end
@implementation CustomView
@end

@implementation ETEtoileUIBuilder (UnitKitTests)

- (void) testRender
{

}

- (void) testRenderView
{
	id view = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview0 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview1 = AUTORELEASE([[CustomView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	//id subview10 = AUTORELEASE([[CustomView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	//id subview11 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview00 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);

	id subview01 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview010 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview02 = AUTORELEASE([[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview020 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id subview021 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	
	[view addSubview: subview0];
	[view addSubview: subview1];
	[subview0 addSubview: subview00];
	
	[subview0 addSubview: subview01];	
	[subview01 setWrappedView: subview010];
	[subview0 addSubview: subview02];
	[subview02 addSubview: subview020];
	[(ETContainer *)subview02 addItem: [ETLayoutItem itemWithView: subview021]];

	id rootItem = [[ETEtoileUIBuilder builder] renderView: view];
	id childItem = nil;
	
	UKObjectsNotSame(view, [rootItem view]);
	UKIntsEqual([[rootItem items] count], 2);
	/* NSView are turned into containers but NSView subclasses aren't */
	UKObjectsNotSame(subview0, [[rootItem itemAtIndex: 0] view]);
	UKObjectKindOf([[rootItem itemAtIndex: 0] supervisorView], ETView);
	//UKObjectKindOf(ETContainer, [[rootItem itemAtIndex: 0] view]);
	UKObjectsSame([[rootItem itemAtIndex: 1] view], subview1);
	childItem = [rootItem itemAtIndex: 0];
	UKObjectsNotSame([[childItem itemAtIndex: 0] view], subview00);
	
	UKFalse([(ETLayoutItem *)[childItem itemAtIndex: 1] isGroup]); // ETView item check
	childItem = [childItem itemAtIndex: 2];
	UKTrue([childItem isGroup]); // ETContainer item check
	UKIntsEqual(1, [[childItem items] count]);
	UKObjectsSame([[childItem itemAtIndex: 0] view], subview021);
}

@end
