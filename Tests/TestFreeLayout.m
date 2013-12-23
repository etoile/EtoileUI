/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009

	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETApplication.h"
#import "ETEvent.h"
#import "ETFreeLayout.h"
#import "ETHandle.h"
#import "ETTool.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETSelectTool.h"
#import "ETCompatibility.h"

@interface TestFreeLayout : TestEvent <UKTest>
{
	ETLayoutItemGroup *rootItem;
	ETLayoutItem *item1;
	ETLayoutItemGroup *item2;
	ETLayoutItem *item21;
}

@end

@implementation TestFreeLayout

- (id) init
{
	SUPERINIT

	[mainItem setLayout: [ETFreeLayout layoutWithObjectGraphContext: [mainItem objectGraphContext]]];
	ASSIGN(tool, [[mainItem layout] attachedTool]);
	ASSIGN(rootItem, [[mainItem layout] layerItem]);
	ASSIGN(item1, [itemFactory rectangleWithRect: NSMakeRect(50, 30, 50, 30)]);
	ASSIGN(item2, [itemFactory graphicsGroup]);
	[item2 setFrame: NSMakeRect(0, 0, 100, 50)];
	ASSIGN(item21, [itemFactory rectangleWithRect: NSMakeRect(10, 10, 80, 30)]);

	/* We need a active tool in order to have -observeValueForKeyPath:XXX 
	   in ETFreeLayout reacts to a selection change by toggling the handle visibility */
	[ETTool setActiveTool: tool];
	
	[mainItem addItem: item1];
	[item2 addItem: item21]; /* Test methods insert item2 as they want */

	[self updateObservedItemsInTree];

	return self;
}

- (void) dealloc
{
	DESTROY(rootItem);
	DESTROY(item1);
	DESTROY(item2);
	DESTROY(item21);
	[super dealloc];
}

/* For handle creation on selection change, we must run -[ETFreeLayout updateKVOForItems:] */
- (void) updateObservedItemsInTree
{
	[mainItem updateLayoutIfNeeded];
}

- (void) testFreeLayoutInit
{
	UKIntsEqual(0, [rootItem numberOfItems]);
	UKObjectKindOf([item2 layout], ETFreeLayout);
}

- (void) testShowAndHideHandles
{
	[item1 setSelected: YES];

	UKIntsEqual(1, [rootItem numberOfItems]);
	[item1 setSelected: NO];
	UKIntsEqual(0, [rootItem numberOfItems]);	
}

- (void) testShowAndHideHandlesForAddedItem
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	[item2 setSelected: YES];

	UKIntsEqual(1, [rootItem numberOfItems]);
	[item2 setSelected: NO];
	UKIntsEqual(0, [rootItem numberOfItems]);	
}

- (void) testShowAndHideHandlesInTree
{
	[item1 setSelected: YES];

	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	[item2 setSelected: YES];
	[item21 setSelected: YES];

	[mainItem updateLayoutIfNeeded];

	UKIntsEqual(2, [rootItem numberOfItems]);
	UKIntsEqual(1, [[[item2 layout] layerItem] numberOfItems]);	
	
	[item2 setSelected: NO];
	UKIntsEqual(1, [rootItem numberOfItems]);
	UKIntsEqual(1, [[[item2 layout] layerItem] numberOfItems]);

	[item21 setSelected: NO];
	UKIntsEqual(0, [[[item2 layout] layerItem] numberOfItems]);
}

- (void) testHitTestHandle
{
	[item1 setSelected: YES];

	ETResizeRectangle *handleGroup1 = (ETResizeRectangle *)[rootItem firstItem];
	ETHandle *handle1 = [handleGroup1 topLeftHandle];

	UKObjectKindOf(handleGroup1, ETResizeRectangle);
	UKObjectsSame(item1, [tool hitTestWithEvent: EVT(75, 45)]);
	UKObjectsSame(handle1, [tool hitTestWithEvent: EVT(47, 27)]);
	UKObjectsSame(handle1, [tool hitTestWithEvent: EVT(50, 30)]);
	UKObjectsSame(handle1, [tool hitTestWithEvent: EVT(53, 33)]);
}

- (void) testHitTestHandleWithoutFlip
{
	[mainItem setFlipped: NO];
	[self testHitTestHandle];
}

- (void) testHitTestHandleInTree
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	[item1 setSelected: YES];
	[item2 setSelected: YES];
	[item21 setSelected: YES];

	UKIntsEqual(2, [rootItem numberOfItems]);

	ETResizeRectangle *handleGroup1 = (ETResizeRectangle *)[rootItem firstItem];
	ETResizeRectangle *handleGroup2 = (ETResizeRectangle *)[rootItem itemAtIndex: 1];
	ETHandle *handle2 = [handleGroup2 topRightHandle];

	UKObjectsSame([handleGroup1 topLeftHandle], [tool hitTestWithEvent: EVT(47, 27)]);
	UKObjectsSame([handleGroup1 bottomRightHandle], [tool hitTestWithEvent: EVT(103, 63)]);
	UKObjectsSame(handle2, [tool hitTestWithEvent: EVT(97, 3)]);
	UKObjectsSame(handle2, [tool hitTestWithEvent: EVT(100, 3)]);
	UKObjectsSame(handle2, [tool hitTestWithEvent: EVT(103, 3)]);
	UKObjectsSame(handle2, [tool hitTestWithEvent: EVT(103, 3)]);
}

- (void) testHitTestHandleInTreeWithoutFlip
{
	[mainItem setFlipped: NO];
	// FIXME: Work that out...
	//[self testHitTestHandleInTree];
}

- (void) testActiveToolAsActivatableTool
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	[[item2 layout] setAttachedTool: nil];

	ETEvent *event = EVT(20, 20);
	ETTool *basicTool =
		[ETTool toolWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];

	// TODO: Do the hit test in the EVT() macro
	[basicTool hitTestWithEvent: event];
	
	UKObjectsEqual(item21, [event layoutItem]);

	[ETTool updateActiveToolWithEvent: event];

	UKObjectsEqual(tool, [ETTool activeTool]);
}

- (void) testNonActivatableNestedTools
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];
	
	[[item2 layout] setAttachedTool: [ETSelectTool tool]];
	
	ETEvent *event = EVT(20, 20);
	ETTool *basicTool =
		[ETTool toolWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];

	// TODO: Do the hit test in the EVT() macro
	[basicTool hitTestWithEvent: event];
	
	UKObjectsEqual(item21, [event layoutItem]);
	
	[ETTool updateActiveToolWithEvent: event];

	UKObjectsEqual(tool, [ETTool activeTool]);
}

- (void) testHitTestNonEditableNestedItems
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	[tool mouseUp: EVT(20, 20)];

	UKFalse([item1 isSelected]);
	UKTrue([item2 isSelected]);
	UKFalse([item21 isSelected]);
	UKIntsEqual(1, [rootItem numberOfItems]);
	UKIntsEqual(0, [[[item2 layout] layerItem] numberOfItems]);
}

- (void) testNestedEditing
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	UKObjectsEqual(mainItem, [tool targetItem]);

	/* Begin nested editing (on double click inside the nested area) */

	[tool mouseUp: CLICK_EVT(20, 20, 2)];

	UKObjectsEqual(tool, [ETTool activeTool]);
	UKObjectsEqual(item2, [tool targetItem]);
	UKFalse([mainItem isSelected]);
	UKFalse([item1 isSelected]);
	UKFalse([item2 isSelected]);
	UKFalse([item21 isSelected]);
	UKIntsEqual(0, [rootItem numberOfItems]);
	UKIntsEqual(0, [[[item2 layout] layerItem] numberOfItems]);
	
	/* Click on the nested area background */

	[tool mouseUp: CLICK_EVT(5, 5, 1)];

	UKObjectsEqual(tool, [ETTool activeTool]);
	UKObjectsEqual(item2, [tool targetItem]);
	UKFalse([mainItem isSelected]);
	UKFalse([item1 isSelected]);
	UKFalse([item2 isSelected]);
	UKFalse([item21 isSelected]);
	UKIntsEqual(0, [rootItem numberOfItems]);
	UKIntsEqual(0, [[[item2 layout] layerItem] numberOfItems]);

	/* Click on a nested area item */

	[tool mouseUp: CLICK_EVT(20, 20, 1)];

	UKObjectsEqual(tool, [ETTool activeTool]);
	UKObjectsEqual(item2, [tool targetItem]);
	UKFalse([mainItem isSelected]);
	UKFalse([item1 isSelected]);
	UKFalse([item2 isSelected]);
	UKTrue([item21 isSelected]);
	UKIntsEqual(0, [rootItem numberOfItems]);
	UKIntsEqual(1, [[[item2 layout] layerItem] numberOfItems]);

	/* End nested editing (on clicked outside the nested area) */
	
	[tool mouseUp: CLICK_EVT(120, 70, 1)];

	UKObjectsEqual(tool, [ETTool activeTool]);
	UKObjectsEqual(mainItem, [tool targetItem]);
	UKFalse([mainItem isSelected]);
	UKFalse([item1 isSelected]);
	UKFalse([item2 isSelected]);
	UKTrue([item21 isSelected]);
	UKIntsEqual(0, [rootItem numberOfItems]);
	UKIntsEqual(1, [[[item2 layout] layerItem] numberOfItems]);
}

- (void) testSelectAll
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	[tool selectAll: self];

	UKObjectsEqual(A(item1, item2), [mainItem selectedItems]);
	UKIntsEqual(2, [rootItem numberOfItems]);
	UKIntsEqual(0, [[[item2 layout] layerItem] numberOfItems]);
	UKObjectsEqual(mainItem, [tool targetItem]);
}

- (void) testGroupAndUngroup
{
	[mainItem addItem: item2];
	[self updateObservedItemsInTree];

	[item1 setSelected: YES];
	[item2 setSelected: YES];

	[tool group: self];

	ETLayoutItemGroup *newItem = (ETLayoutItemGroup *)[mainItem firstItem];
	
	RETAIN(newItem);

	UKObjectsEqual(A(newItem), [mainItem items]);
	UKObjectsEqual(A(item1, item2), [newItem items]);
	UKIntsEqual(1, [rootItem numberOfItems]);
	UKIntsEqual(0, [[[newItem layout] layerItem] numberOfItems]);
	UKIntsEqual(0, [[[item2 layout] layerItem] numberOfItems]);
	UKObjectsEqual(mainItem, [tool targetItem]);
	
	[tool ungroup: self];

	UKObjectsEqual(S(item1, item2), SA([mainItem items]));
	UKNil([newItem parentItem]);
	UKIntsEqual(2, [rootItem numberOfItems]);
	UKIntsEqual(0, [[[item2 layout] layerItem] numberOfItems]);
	// FIXME: UKObjectsEqual(A(item1, item2), [mainItem selectedItems]);
	UKObjectsEqual(mainItem, [tool targetItem]);

	RELEASE(newItem);
}

@end
