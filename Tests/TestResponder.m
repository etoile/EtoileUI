/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETActionHandler.h"
#import "ETApplication.h"
#import "ETController.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETScrollableAreaItem.h"
#import "ETTool.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"

@interface ETBipActionHandler : ETActionHandler
- (void) bip: (id)sender onItem: (ETLayoutItem *)anItem;
@end

/* This gives us access to the first main and key responders since we cannot 
   use -makeMainWindow since main or key are resigned immediately while running 
   tests (at least from Xcode because the test process runs in background). */
@interface ETTool (TestResponder)
- (id) lastRequestedFirstMainResponder;
- (id) lastRequestedFirstKeyResponder;
@end

@interface ETTestResponderTool : ETTool
@end

@interface TestResponder : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItem *item;
	ETLayoutItemGroup *mainItem;
	ETScrollableAreaItem *scrollableAreaItem;
	ETWindowItem *windowItem;
	ETController *controller;
	ETTool *previousActiveTool;
}

@end

@implementation TestResponder

- (id) init
{
	SUPERINIT;
	itemFactory = [ETLayoutItemFactory factory];
	[self prepareNewResponderChain];
	ASSIGN(previousActiveTool, [ETTool activeTool]);
	[ETTool setActiveTool: [ETTestResponderTool tool]];
	return self;
}

- (void) dealloc
{
	[[itemFactory windowGroup] removeItem: mainItem];
	[ETTool setActiveTool: previousActiveTool];
	DESTROY(previousActiveTool);
	[super dealloc];
}

- (void) prepareNewResponderChain
{
	item = [itemFactory item];
	scrollableAreaItem = [ETScrollableAreaItem item];
	
	[item setDecoratorItem: scrollableAreaItem];

	mainItem = [itemFactory itemGroupWithItems: A(item)];
	controller = [ETController new];

	[mainItem setController: controller];
	[mainItem setActionHandler: AUTORELEASE([ETBipActionHandler new])];
	
	[[itemFactory windowGroup] addItem: mainItem];
	
	windowItem = (ETWindowItem *)[mainItem decoratorItem];
}

- (void) testControllerAndDecoratorInResponderChain
{
	UKObjectsSame(scrollableAreaItem, [item nextResponder]);
	UKObjectsSame(mainItem, [scrollableAreaItem nextResponder]);
	UKObjectsSame(controller, [mainItem nextResponder]);
	UKObjectsSame(windowItem, [controller nextResponder]);
	UKObjectsSame([itemFactory windowGroup], [windowItem nextResponder]);
}

- (void) prepareFirstResponder
{
	UKNotNil([ETTool activeTool]);

	[[ETTool activeTool] makeFirstResponder: (id)item];

	UKObjectsSame(item, [[ETTool activeTool] firstMainResponder]);
}

- (void) testFirstResponderLookup
{
	[self prepareFirstResponder];

	UKObjectsSame(item, [ETApp targetForAction: @selector(sendBackward:)]);
	UKObjectsSame(mainItem, [ETApp targetForAction: @selector(bip:)]);
	UKObjectsSame(controller, [ETApp targetForAction: @selector(add:)]);
	UKNil([ETApp targetForAction: @selector(nonExistentAction:)]);
}

- (void) testTargetLookup
{
	[self prepareFirstResponder];

	UKObjectsSame(mainItem, [ETApp targetForAction: @selector(sendBackward:) to: mainItem from: nil]);
	UKNil([ETApp targetForAction: @selector(bip:) to: item from: nil]);
	UKNil([ETApp targetForAction: @selector(add:) to: mainItem from: nil]);
	UKObjectsSame(controller, [ETApp targetForAction: @selector(addNewGroup:) to: controller from: nil]);
}

- (void) testSendAction
{
	[self prepareFirstResponder];

	[ETApp sendAction: @selector(bip:) to: nil from: self];

	UKTrue([mainItem isSelected]);
}

// TODO: Test keyResponder and mainResponder distinction for ETTool

@end


@implementation ETTool (TestResponder)

- (id) lastRequestedFirstMainResponder
{
	return _firstMainResponder;
}

- (id) lastRequestedFirstKeyResponder
{
	return _firstKeyResponder;
}

@end

@implementation ETTestResponderTool

- (id) firstMainResponder
{
	return [self lastRequestedFirstMainResponder];
}

- (id) firstKeyResponder
{
	return [self lastRequestedFirstKeyResponder];
}

@end


@implementation ETBipActionHandler

- (void) bip: (id)sender onItem: (ETLayoutItem *)anItem
{
	[anItem setSelected: [sender isKindOfClass: [TestResponder class]]];
}

@end
