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
#import "ETWindowItem.h"
#import "ETCompatibility.h"
#include <objc/runtime.h>

@interface ETBipActionHandler : ETActionHandler
- (void) bip: (id)sender onItem: (ETLayoutItem *)anItem;
@end

@interface ETFirstResponderActionHandler : ETActionHandler
@end

/* This gives us access to the first main and key responders since we cannot 
   use -makeMainWindow since main or key are resigned immediately while running 
   tests (at least from Xcode because the test process runs in background). */
@interface ETTestResponderApplication : ETApplication
{

}

- (void) setMainItem: (ETLayoutItem *)anItem;
- (void) setKeyItem: (ETLayoutItem *)anItem;

@end

@interface TestResponder : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItem *item;
	ETLayoutItemGroup *mainItem;
	ETScrollableAreaItem *scrollableAreaItem;
	ETWindowItem *windowItem;
	ETController *controller;
	Class previousAppClass;
}

@end

@implementation TestResponder

- (id) init
{
	SUPERINIT;

	ASSIGN(previousAppClass, [ETApp class]);
	object_setClass([ETApplication sharedApplication], [ETTestResponderApplication class]);

	ETAssert([ETApp isMemberOfClass: [ETTestResponderApplication class]]);

	itemFactory = [ETLayoutItemFactory factory];
	[self prepareNewResponderChain];

	return self;
}

- (void) dealloc
{
	object_setClass(ETApp, previousAppClass);
	DESTROY(previousAppClass);

	[[itemFactory windowGroup] removeItem: mainItem];

	[super dealloc];
}

// TODO: Write a subclass testing mainItem as -[ETApp mainItem]
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
	
	/* Bringing the test suite to the front doesn't work or is unreliable if 
	   the test suite is run inside an IDE. Unless the test suite is brought 
	   to the front, -makeMainWindow and -makeKeyWindow are useless. */
	[(ETTestResponderApplication *)ETApp setKeyItem: mainItem];
	
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
	[[item firstResponderSharingArea] makeFirstResponder: (id)item];

	UKObjectsSame(item, [[item firstResponderSharingArea] firstResponder]);
	UKObjectsSame(item, [[item firstResponderSharingArea] focusedItem]);
}

- (void) testExceptionOnInvalidFirstResponder
{
	UKRaisesException([[item firstResponderSharingArea] makeFirstResponder: (id)[windowItem window]]);
	UKRaisesException([[item firstResponderSharingArea] makeFirstResponder: (id)[mainItem view]]);
	UKRaisesException([[item firstResponderSharingArea] makeFirstResponder: (id)[mainItem supervisorView]]);
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

- (void) testFocusedItemForWindowAsFirstResponder
{
	[[windowItem window] makeFirstResponder: (id)[windowItem window]];
	
	// FIXME: UKObjectsEqual(mainItem, [windowItem focusedItem]);
}

/* For this test case, the select tool just as the first responder and not the active tool */
- (void) testSelectToolAsFirstResponder
{
	[self prepareFirstResponder];

	ETSelectTool *tool = [ETSelectTool tool];

	[[mainItem layout] setAttachedTool: tool];

	[[mainItem firstResponderSharingArea] makeFirstResponder: tool];
	
	UKObjectsEqual(tool, [[mainItem firstResponderSharingArea] firstResponder]);
	UKObjectsEqual(mainItem, [[mainItem firstResponderSharingArea] focusedItem]);
}

- (void) testSelectToolAsActiveTool
{
	[self prepareFirstResponder];

	ETSelectTool *tool = [ETSelectTool tool];

	[[mainItem layout] setAttachedTool: tool];

	[ETTool setActiveTool: tool];

	UKObjectsEqual(tool, [ETTool activeTool]);
	// FIXME: UKObjectsEqual(tool, [[item firstResponderSharingArea] firstResponder]);
	// FIXME: UKObjectsEqual(mainItem, [[item firstResponderSharingArea] focusedItem]);
}

- (void) testLayoutItemValidityAsFirstResponder
{
	[windowItem makeFirstResponder: item];
	
	UKObjectsEqual(item, [windowItem firstResponder]);
	UKObjectsEqual(item, [windowItem focusedItem]);

	[[mainItem layout] setAttachedTool: [ETArrowTool tool]];
	[windowItem makeFirstResponder: mainItem];
	
	UKObjectsNotEqual(mainItem, [windowItem firstResponder]);
	UKObjectsNotEqual(mainItem, [windowItem focusedItem]);

	[[mainItem layout] setAttachedTool: [ETSelectTool tool]];
	[windowItem makeFirstResponder: mainItem];
	
	UKObjectsEqual([[mainItem layout] attachedTool], [windowItem firstResponder]);
	UKObjectsEqual(mainItem, [windowItem focusedItem]);
}

- (void) testControllerAsInvalidFirstResponder
{
	[windowItem makeFirstResponder: controller];
	
	UKObjectsNotEqual(controller, [windowItem firstResponder]);
}

- (void) testWindowItemAsInvalidFirstResponder
{
	[windowItem makeFirstResponder: windowItem];
	
	UKObjectsNotEqual(windowItem, [windowItem firstResponder]);
}

- (void) testScrollableAreaItemAsInvalidFirstResponder
{
	[windowItem makeFirstResponder: scrollableAreaItem];
	
	UKObjectsNotEqual(scrollableAreaItem, [windowItem firstResponder]);

}

- (void) testWindowItemActions
{
	
}

@end


@implementation ETTestResponderApplication

- (ETLayoutItem *) mainItem
{
	return objc_getAssociatedObject(self, "mainItem");
}

- (void) setMainItem: (ETLayoutItem *)anItem
{
	objc_setAssociatedObject(self, "mainItem", anItem, OBJC_ASSOCIATION_RETAIN);
}

- (ETLayoutItem *) keyItem;
{
	return objc_getAssociatedObject(self, "keyItem");
}

- (void) setKeyItem: (ETLayoutItem *)anItem
{
	objc_setAssociatedObject(self, "keyItem", anItem, OBJC_ASSOCIATION_RETAIN);
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
