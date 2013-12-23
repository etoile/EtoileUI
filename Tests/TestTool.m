/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009

	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETApplication.h"
#import "ETArrowTool.h"
#import "ETIconLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLineLayout.h"
#import "ETLayoutItemFactory.h"
#import "ETTool.h"
#import "ETCompatibility.h"

@interface ETLayoutItem (UndefinedActions)
- (void) insertRectangle: (id)sender;
@end

@interface TestTool : TestCommon <UKTest>
{
	ETTool *tool;
	ETLayoutItemGroup *mainItem;
	ETLayoutItemGroup *otherItem;
	ETIconLayout *iconLayout;
	ETLineLayout *lineLayout;
}

@end


@implementation TestTool

- (id) init
{
	SUPERINIT;
	ASSIGN(tool, [ETTool tool]);
	ASSIGN(mainItem, [[ETLayoutItemFactory factory] itemGroup]);
	ASSIGN(otherItem, [[ETLayoutItemFactory factory] itemGroup]);
	ASSIGN(iconLayout,
		[ETIconLayout layoutWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]);
	ASSIGN(lineLayout,
		[ETLineLayout layoutWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]]);
	return self;
}

- (void) dealloc
{
	DESTROY(tool);
	DESTROY(mainItem);
	DESTROY(otherItem);
	DESTROY(iconLayout);
	DESTROY(lineLayout);
	[super dealloc];
}

- (void) testBasicTool
{
	UKDoesNotRaiseException([tool layoutOwner]);
	UKDoesNotRaiseException([tool targetItem]);
}

- (void) testDefaultActiveTool
{
	UKDoesNotRaiseException([ETTool activeTool]);
	UKDoesNotRaiseException([[ETTool activeTool] layoutOwner]);
	UKDoesNotRaiseException([[ETTool activeTool] targetItem]);
}

- (void) testToolActivation
{
	[[mainItem layout] setAttachedTool: tool];
	
	[[ETApp rootItem] addItem: mainItem];
	
	UKDoesNotRaiseException([ETTool setActiveTool: tool]);
	UKObjectsEqual(tool, [ETTool activeTool]);
	
	[[ETApp rootItem] removeItem: mainItem];
}

- (void) testExceptionOnActivatingToolWithoutLayout
{
	UKNil([tool layoutOwner]);
	UKRaisesException([ETTool setActiveTool: tool]);

	/* This rule doesn't apply to the main tool */
	UKNil([[ETTool mainTool] layoutOwner]);
	UKDoesNotRaiseException([ETTool setActiveTool: [ETTool mainTool]]);
}

- (void) testExceptionOnActivatingToolNotBoundToApplicationRootItemDescendant
{
	[[mainItem layout] setAttachedTool: tool];
	
	UKRaisesException([ETTool setActiveTool: tool]);
}

- (void) testExceptionOnDetachActiveTool
{
	// TODO: We should get exceptions on [[[ETTool activeTool] targetItem] removeFromParent]
	// or [[[ETTool activeTool] targetItem] setLayout: lineLayout]
	// or just handle that transparently as explained in -[ETTool setActiveTool:]
}

- (void) testAttachAndDetachTool
{
	[[mainItem layout] setAttachedTool: tool];

	UKObjectsEqual([mainItem layout], [tool layoutOwner]);
	UKObjectsEqual(mainItem, [tool targetItem]);
	
	[[mainItem layout] setAttachedTool: nil];
	
	UKNil([tool layoutOwner]);
	UKNil([tool targetItem]);
}

- (void) testAttachToolToLayoutWithPreviousAttachedTool
{
	[[mainItem layout] setAttachedTool: tool];
	
	UKObjectsEqual(mainItem, [tool targetItem]);

	ETTool *otherTool = [ETArrowTool tool];
	
	[[mainItem layout] setAttachedTool: otherTool];

	UKNil([tool layoutOwner]);
	UKNil([tool targetItem]);
	UKObjectsEqual([mainItem layout], [otherTool layoutOwner]);
	UKObjectsEqual(mainItem, [otherTool targetItem]);
}

- (void) testAttachToolReplacingActiveTool
{
	ETTool *otherTool = [ETArrowTool tool];

	[[ETApp rootItem] addItem: mainItem];

	[[mainItem layout] setAttachedTool: tool];
	[ETTool setActiveTool: tool];
	[[mainItem layout] setAttachedTool: otherTool];
	
	UKObjectsEqual(otherTool, [ETTool activeTool]);
	
	[[ETApp rootItem] removeItem: mainItem];
}

- (void) testDetachToolReplacingActiveTool
{
	[[ETApp rootItem] addItem: mainItem];

	[[mainItem layout] setAttachedTool: tool];
	[ETTool setActiveTool: tool];
	[[mainItem layout] setAttachedTool: nil];
	
	// TODO: For now, we have an arrow tool set in ETWindowLayout initializer.
	// Detect if the main tool gets activated in the menu bar.
	// Probably set no tool in ETWindowLayout initializer, and just let the
	// main tool be activated.
	UKObjectsEqual([[[mainItem parentItem] layout] attachedTool], [ETTool activeTool]);
	
	[[ETApp rootItem] removeItem: mainItem];
}

- (void) testNoExceptionOnAttachingToolToUnusedLayout
{
	UKDoesNotRaiseException([lineLayout setAttachedTool: tool]);
}

- (void) testExceptionOnAttachingToolInUse
{
	[[mainItem layout] setAttachedTool: tool];
	
	UKRaisesException([[otherItem layout] setAttachedTool: tool]);
}

- (void) testExceptionOnAttachingToolToSecondaryLayout
{
	UKRaisesException([(ETLayout *)[iconLayout positionalLayout] setAttachedTool: tool]);
}

- (void) testExceptionOnSetSecondaryLayoutWithAttachedTool
{
	[lineLayout setAttachedTool: tool];

	UKRaisesException([iconLayout setPositionalLayout: lineLayout]);
}

- (void) testLookUpArrowCursor
{
	[tool setCursorName: kETToolCursorNameArrow];
	
	UKObjectsEqual([NSCursor arrowCursor], [tool cursor]);
}

- (void) testLookUpOpenHandCursor
{
	[tool setCursorName: kETToolCursorNameOpenHand];
	
	UKObjectsEqual([NSCursor openHandCursor], [tool cursor]);
}

- (void) testLookUpPointingHandCursor
{
	[tool setCursorName: kETToolCursorNamePointingHand];
	
	UKObjectsEqual([NSCursor pointingHandCursor], [tool cursor]);
}

- (void) testRespondsToForwardedActionsForSelectTool
{
	UKTrue([[ETSelectTool tool] respondsToSelector: @selector(insertRectangle:)]);
	// TODO: Put the -scrollWheel: test in AppKit Widget backend tests
	UKTrue([[ETSelectTool tool] respondsToSelector: @selector(scrollWheel:)]);
	UKFalse([[ETSelectTool tool] respondsToSelector: @selector(addItem:)]);
}

- (void) testActionsForwardingForSelectTool
{
	UKDoesNotRaiseException([[ETSelectTool tool] insertRectangle: nil]);
	// TODO: Put the -scrollWheel: test in AppKit Widget backend tests
	UKDoesNotRaiseException([[ETSelectTool tool] scrollWheel: nil]);
	UKRaisesException([[ETSelectTool tool] addItem: nil]);
}

@end
