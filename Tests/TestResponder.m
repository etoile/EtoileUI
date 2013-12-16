/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETActionHandler.h"
#import "ETApplication.h"
#import "ETController.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETSelectTool.h"
#import "ETScrollableAreaItem.h"
#import "ETTool.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"

@interface ETBipActionHandler : ETActionHandler
- (void) bip: (id)sender onItem: (ETLayoutItem *)anItem;
@end

@interface ETFirstResponderActionHandler : ETActionHandler
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
	ETTool *previousMainTool;
	ETTool *previousActiveTool;
}

@end

@implementation TestResponder

- (id) init
{
	SUPERINIT;

	itemFactory = [ETLayoutItemFactory factory];
	[self prepareNewResponderChain];

	ASSIGN(previousMainTool, [ETTool mainTool]);
	ASSIGN(previousActiveTool, [ETTool activeTool]);
	[ETTool setMainTool: [ETTestResponderTool tool]];
	[ETTool setActiveTool: [ETTool mainTool]];
	ETAssert(previousActiveTool != [ETTool activeTool]);

	return self;
}

- (void) dealloc
{
	[[itemFactory windowGroup] removeItem: mainItem];
	
	[ETTool setMainTool: previousMainTool];
	[ETTool setActiveTool: previousActiveTool];
	ETAssert(previousActiveTool == [ETTool activeTool]);
	DESTROY(previousMainTool);
	DESTROY(previousActiveTool);

	[super dealloc];
}

- (void) prepareNewResponderChain
{
	item = [itemFactory item];
	scrollableAreaItem = [ETScrollableAreaItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];

	[item setActionHandler: [ETFirstResponderActionHandler sharedInstanceForObjectGraphContext: [item objectGraphContext]]];
	[item setDecoratorItem: scrollableAreaItem];

	mainItem = [itemFactory itemGroupWithItems: A(item)];
	controller = [[ETController alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];

	[mainItem setController: controller];
	[mainItem setActionHandler: [ETBipActionHandler sharedInstanceForObjectGraphContext: [itemFactory objectGraphContext]]];
	
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

	NSLog(@"Key %@ and main %@", [ETApp keyWindow], [ETApp mainWindow]);
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

- (void) testFocusedItemForWindowAsFirstResponder
{
	[[ETTool activeTool] makeFirstResponder: (id)[windowItem window]];
	
	UKObjectsEqual(mainItem, [windowItem focusedItem]);
}

/* For this test case, the select tool just as the first responder and not the active tool */
- (void) testSelectToolAsFirstResponder
{
	[self prepareFirstResponder];

	ETSelectTool *tool = [ETSelectTool tool];

	[[mainItem layout] setAttachedTool: tool];

	[[ETTool activeTool] makeFirstResponder: tool];
	
	UKObjectsEqual(tool, [[ETTool activeTool] firstMainResponder]);
	UKObjectsEqual(mainItem, [windowItem focusedItem]);
}

- (void) testSelectToolAsActiveTool
{
	[self prepareFirstResponder];

	ETSelectTool *tool = [ETSelectTool tool];

	[[mainItem layout] setAttachedTool: tool];

	[ETTool setActiveTool: tool];

	UKObjectsEqual(tool, [ETTool activeTool]);
	// FIXME: UKObjectsEqual(tool, [[ETTool activeTool] firstMainResponder]);
	// FIXME: UKObjectsEqual(mainItem, [windowItem focusedItem]);
}

- (void) testWindowItemAsInvalidFirstResponder
{
	[[ETTool activeTool] makeFirstResponder: (id)windowItem];
	
	UKObjectsNotEqual(windowItem, [[ETTool activeTool] firstMainResponder]);
}

- (void) testScrollableAreaItemAsInvalidFirstResponder
{
	[[ETTool activeTool] makeFirstResponder: (id)scrollableAreaItem];
	
	UKObjectsNotEqual(scrollableAreaItem, [[ETTool activeTool] firstMainResponder]);

}

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

@implementation ETFirstResponderActionHandler

- (BOOL) acceptsFirstResponder
{
	return YES;
}

@end

@implementation ETBipActionHandler

- (void) bip: (id)sender onItem: (ETLayoutItem *)anItem
{
	[anItem setSelected: [sender isKindOfClass: [TestResponder class]]];
}

@end
