/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2013
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayer.h"
#import "ETApplication.h"
#import "ETBrowserLayout.h"
#import "ETFreeLayout.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "ETSelectTool.h"
#import "ETWindowItem.h"

@interface TestWindowLayout : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItemGroup *windowGroup;
	ETLayoutItemGroup *itemGroup;
	ETLayoutItem *item;
}

@end


@implementation TestWindowLayout

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	/* -[ETLayoutItemGroup windowGroup] instantiates the window group as below but just once. 
	   To ignore state changes due to previous tests, we allocate a new ETWindowLayer directly. */
	windowGroup = [[ETWindowLayer alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];
	ASSIGN(itemGroup, [itemFactory itemGroup]);
	ASSIGN(item, [itemFactory item]);
	return self;
}

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(windowGroup);
	DESTROY(itemGroup);
	DESTROY(item);
	[super dealloc];
}

- (void) testFrame
{
	UKTrue(NSContainsRect([[NSScreen mainScreen] frame], [windowGroup frame]));
	UKTrue(NSContainsRect([windowGroup frame], [[NSScreen mainScreen] visibleFrame]));
}

- (void) testInitialActiveTool
{
	// FIXME: UKObjectsSame([[windowGroup layout] attachedTool], [ETTool activeTool]);
}

- (void) testFreeLayout
{
	[windowGroup setLayout: [ETFreeLayout layoutWithObjectGraphContext: [windowGroup objectGraphContext]]];

	UKObjectKindOf([[windowGroup layout] attachedTool], ETSelectTool);
	// FIXME: UKObjectsSame([ETTool activeTool], [[windowGroup layout] attachedTool]);
}

- (void) checkSwitchBackToWindowLayoutFromLayout: (ETLayout *)aLayout
{
	[windowGroup addItems: A(item, itemGroup)];

	NSWindow *itemWindow = [[item windowItem] window];
	NSWindow *itemGroupWindow = [[itemGroup windowItem] window];

	UKNotNil([item windowItem]);
	UKNotNil([itemGroup windowItem]);
	UKTrue([itemWindow isVisible]);
	UKTrue([itemGroupWindow isVisible]);
	UKNil([windowGroup windowItem]);

	[windowGroup setLayout: aLayout];

	NSWindow *rootWindow = [[windowGroup windowItem] window];

	UKNil([item windowItem]);
	UKNil([itemGroup windowItem]);
	UKFalse([itemWindow isVisible]);
	UKFalse([itemGroupWindow isVisible]);
	UKNotNil([windowGroup windowItem]);
	UKTrue([rootWindow isVisible]);

	[windowGroup setLayout: [ETWindowLayout layoutWithObjectGraphContext: [windowGroup objectGraphContext]]];

	UKNotNil([item windowItem]);
	UKNotNil([itemGroup windowItem]);
	UKTrue([itemWindow isVisible]);
	UKTrue([itemGroupWindow isVisible]);
	UKFalse([rootWindow isVisible]);
	UKTrue([S(itemWindow, itemGroupWindow) isSubsetOfSet: [NSSet setWithArray: [ETApp windows]]]);
}
			 
- (void) testSwitchBackToWindowLayoutFromFreeLayout
{
	[self checkSwitchBackToWindowLayoutFromLayout: [ETFreeLayout layoutWithObjectGraphContext: [windowGroup objectGraphContext]]];
}
			 
- (void) testSwitchBackToWindowLayoutFromWidgetLayout
{
	[self checkSwitchBackToWindowLayoutFromLayout: [ETBrowserLayout layoutWithObjectGraphContext: [windowGroup objectGraphContext]]];
}

@end
