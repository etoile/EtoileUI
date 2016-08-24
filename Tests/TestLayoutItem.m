/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <CoreObject/COObjectGraphContext.h>
#import "TestCommon.h"
#import "ETController.h"
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutExecutor.h"
#import "ETWindowItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutExecutor.h"
#import "ETFlowLayout.h"
#import "ETScrollableAreaItem.h"
#import "ETTableLayout.h"
#import "ETView.h"
#import "ETCompatibility.h"

@interface TestItem : TestCommon <UKTest>
@end

@interface TestItemGroup : TestCommon <UKTest>
{
	ETLayoutItemGroup *item;
}

@end


@implementation TestItem

- (void) testRetainCountForItemCreation
{
	ETUUID *itemUUID;
	ETUUID *itemGroupUUID;

    /* Force the layout executor to release the item (the item was scheduled due
	   to geometry initialization) */
	@autoreleasepool
	{
		id item = [itemFactory item];
		id itemGroup = [itemFactory itemGroup];

		itemUUID = [item UUID];
		itemGroupUUID = [itemGroup UUID];

		[[ETLayoutExecutor sharedInstance] removeItems: S(item, itemGroup)];
		[[itemFactory objectGraphContext] discardAllChanges];
	}

    UKTrue([ETUIObject isObjectDeallocatedForUUID: itemUUID]);
	UKTrue([ETUIObject isObjectDeallocatedForUUID: itemGroupUUID]);
}

- (void) testRetainCountForItemMutation
{
	ETUUID *itemUUID;
	ETUUID *itemGroupUUID;

    /* Relationship cache may cause autoreleased references (see
       -testRetainCountForItemCreation too) */
	@autoreleasepool
	{
		id item = [itemFactory item];
		id itemGroup = [itemFactory itemGroup];

		itemUUID = [item UUID];
		itemGroupUUID = [itemGroup UUID];

		[itemGroup addItem: item];
		[itemGroup removeItem: item];

		[[ETLayoutExecutor sharedInstance] removeItems: S(item, itemGroup)];
		[[itemFactory objectGraphContext] discardAllChanges];
	}

    UKTrue([ETUIObject isObjectDeallocatedForUUID: itemUUID]);
    UKTrue([ETUIObject isObjectDeallocatedForUUID: itemGroupUUID]);
}

- (void) testRootItem
{
	ETLayoutItem *item3 = [itemFactory item];

	UKObjectsSame([item3 rootItem], item3);
	
	ETLayoutItemGroup *item1 = [itemFactory itemGroup];
	ETLayoutItemGroup *item2 = [itemFactory itemGroup];
	
	[item1 addItem: item2];
	[item2 addItem: item3];
	
	UKObjectsSame([item2 rootItem], item1);
	UKObjectsSame([item2 rootItem], [item2 parentItem]);
	UKObjectsSame([item3 rootItem], item1);
}

- (void) testAttachAndDetachItemWithoutView
{
	ETLayoutItem* item = [itemFactory item];
	ETLayoutItemGroup *parentItem = [itemFactory itemGroup];

	[parentItem setSupervisorView: [[ETView alloc] init]];
	[parentItem handleAttachViewOfItem: item];
	[parentItem handleDetachViewOfItem: item];
	UKPass();
}

- (void) testAddAndRemoveItem
{
	// TODO: Test when the item has a parent item already
	ETLayoutItem* item = [itemFactory item];
	ETLayoutItemGroup *parentItem = [itemFactory itemGroup];

	[parentItem addItem: item];

	UKObjectsSame(parentItem, [item parentItem]);
	UKTrue([parentItem containsItem: item]);
	UKNil([item supervisorView]);
	UKNil([parentItem supervisorView]);

	[parentItem removeItem: item];

	UKNil([item parentItem]);
	UKFalse([parentItem containsItem: item]);
	UKNil([item supervisorView]);
	UKNil([parentItem supervisorView]);
}

- (void) testAddAndRemoveItemWithView
{
	// TODO: Test when the item has a parent item already
	ETLayoutItem* item = [itemFactory itemWithView: [[NSView alloc] init]];
	ETLayoutItemGroup *parentItem = [itemFactory itemGroup];

	[parentItem addItem: item];

	UKNil([[parentItem supervisorView] superview]);	
	UKObjectsSame([parentItem supervisorView], [[item supervisorView] superview]);
	
	[parentItem removeItem: item];

	UKNil([[parentItem supervisorView] superview]);
	UKNil([[item supervisorView] superview]);
}

- (void) testAddItemWithViewIntoOpaqueLayout
{
	ETLayoutItem* item = [itemFactory itemWithView: [[NSView alloc] init]];
	ETLayoutItemGroup *parentItem = [itemFactory itemGroup];

	[parentItem setLayout: [ETTableLayout layoutWithObjectGraphContext: [parentItem objectGraphContext]]];
	[parentItem addItem: item];

	// FIXME: Probably update ETWidgetLayout to use -setExposedItems:
	//UKFalse([item isVisible]);
	UKNil([[item supervisorView] superview]);
	UKObjectsSame(parentItem, [item parentItem]);
	UKTrue([parentItem containsItem: item]);

	/* Switch to non-opaque layout */
	[parentItem setLayout: [ETFlowLayout layoutWithObjectGraphContext: [parentItem objectGraphContext]]];
	[parentItem updateLayoutIfNeeded];

	UKTrue([item isVisible]);
	UKObjectsSame([parentItem supervisorView], [[item supervisorView] superview]);
}

/* Verify that a parent item nullifies the weak references to itself on -dealloc. */
- (void) testDeallocatedParentItem
{
    @autoreleasepool {
		id item = [[ETLayoutItemGroup alloc]
			initWithObjectGraphContext: [COObjectGraphContext objectGraphContext]];
		id item0 = [[ETLayoutItemGroup alloc]
			initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
		id item1 = [[ETLayoutItem alloc]
			initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];

		[item addItems: A(item0, item1)];

		/* Required to get the item deallocated */
		[[ETLayoutExecutor sharedInstance] removeItem: item];
		[[item objectGraphContext] discardAllChanges];
   }

	/* The next tests ensure the parent item was correctly reset to nil, 
	   otherwise -parentItem crashes. */
    // FIXME: In -referringObjectForPropertyInTarget:,
    // [results addObject: entry->_sourceObject] raises an exception, because
    // the source object is nil.
	//UKNil([item0 parentItem]);
	//UKNil([item1 parentItem]);
}

- (void) testIndexOfMissingItem
{
	ETLayoutItem *item = [itemFactory item];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroup];

	UKTrue([itemGroup indexOfItem: item] == NSNotFound);
}

- (void) testIndexPathForItem
{
	id item = [itemFactory itemGroup];
	id item0 = [itemFactory itemGroup];
	id item00 = [itemFactory item];
	id item1 = [itemFactory itemGroup];
	id item10 = [itemFactory item];
	id item11 = [itemFactory itemGroup];
	id item110 = [itemFactory item];
	
	[item addItem: item0];
	[item0 addItem: item00];
	[item addItem: item1];
	[item1 addItem: item10];	
	[item1 addItem: item11];
	[item11 addItem: item110];
	
	id emptyIndexPath = [NSIndexPath indexPath];
	id indexPath0 = [emptyIndexPath indexPathByAddingIndex: 0];
	id indexPath00 = [indexPath0 indexPathByAddingIndex: 0];
	id indexPath1 = [emptyIndexPath indexPathByAddingIndex: 1];
	id indexPath10 = [indexPath1 indexPathByAddingIndex: 0];
	id indexPath11 = [indexPath1 indexPathByAddingIndex: 1];
	id indexPath110 = [indexPath11 indexPathByAddingIndex: 0];

	UKObjectsEqual(emptyIndexPath, [item10 indexPathForItem: item10]);
	UKNil([item10 indexPathForItem: [itemFactory item]]);
	UKNil([[itemFactory item] indexPathForItem: item10]);
	/* nil represents the root item in the receiver item tree */
	UKNil([item10 indexPathForItem: nil]);

	UKNil([item0 indexPathForItem: item]);	
	UKObjectsEqual(indexPath0, [item indexPathForItem: item0]);
	UKObjectsEqual(indexPath00, [item indexPathForItem: item00]);
	UKObjectsEqual(indexPath110, [item indexPathForItem: item110]);

	UKNil([item1 indexPathForItem: item]);	
	UKObjectsEqual(indexPath1, [item1 indexPathForItem: item11]);
	UKObjectsEqual(indexPath10, [item1 indexPathForItem: item110]);
	
	UKObjectsEqual(indexPath0, [item11 indexPathForItem: item110]);	
}

- (void) testIndexPathFromItem
{
	id item = [itemFactory itemGroup];
	id item0 = [itemFactory itemGroup];
	id item00 = [itemFactory item];
	id item1 = [itemFactory itemGroup];
	id item10 = [itemFactory item];
	id item11 = [itemFactory itemGroup];
	id item110 = [itemFactory item];
	
	[item addItem: item0];
	[item0 addItem: item00];
	[item addItem: item1];
	[item1 addItem: item10];	
	[item1 addItem: item11];
	[item11 addItem: item110];
	
	id emptyIndexPath = [NSIndexPath indexPath];
	id indexPath0 = [emptyIndexPath indexPathByAddingIndex: 0];
	id indexPath00 = [indexPath0 indexPathByAddingIndex: 0];
	id indexPath1 = [emptyIndexPath indexPathByAddingIndex: 1];
	id indexPath10 = [indexPath1 indexPathByAddingIndex: 0];
	id indexPath11 = [indexPath1 indexPathByAddingIndex: 1];
	id indexPath110 = [indexPath11 indexPathByAddingIndex: 0];

	UKObjectsEqual(emptyIndexPath, [item10 indexPathFromItem: item10]);
	/* nil represents the root item in the receiver item tree */
	UKObjectsEqual(indexPath10, [item10 indexPathFromItem: nil]);

	UKNil([item indexPathFromItem: item0]);	
	UKObjectsEqual(indexPath0, [item0 indexPathFromItem: item]);
	UKObjectsEqual(indexPath00, [item00 indexPathFromItem: item]);
	UKObjectsEqual(indexPath110, [item110 indexPathFromItem: item]);

	UKNil([item00 indexPathFromItem: item1]);	
	UKObjectsEqual(indexPath1, [item11 indexPathFromItem: item1]);
	UKObjectsEqual(indexPath10, [item110 indexPathFromItem: item1]);
	
	UKObjectsEqual(indexPath0, [item110 indexPathFromItem: item11]);
}

- (void) testSetDecoratorItem
{
	id item = [itemFactory item];
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator2 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator3 = [ETWindowItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];
	
	UKNil([item decoratorItem]);
	
	[item setDecoratorItem: decorator1];
	UKObjectsEqual(decorator1, [item decoratorItem]);
	
	[decorator1 setDecoratorItem: decorator2];
	UKObjectsEqual(decorator2, [decorator1 decoratorItem]);
	
	[decorator2 setDecoratorItem: decorator3];
	UKObjectsEqual(decorator3, [decorator2 decoratorItem]);
}

- (void) testLastDecoratorItem
{
	id item = [itemFactory item];
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator2 = [ETDecoratorItem itemWithDummySupervisorView];
	
	UKObjectsEqual(item, [item lastDecoratorItem]);
	
	[item setDecoratorItem: decorator1];
	UKObjectsEqual(decorator1, [item lastDecoratorItem]);
	[decorator1 setDecoratorItem: decorator2];
	UKObjectsEqual(decorator2, [item lastDecoratorItem]);
	UKObjectsEqual(decorator2, [decorator1 lastDecoratorItem]);
	UKObjectsEqual(decorator2, [decorator2 lastDecoratorItem]);
}

- (void) testFirstDecoratedItem
{
	id item = [itemFactory item];
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator2 = [ETDecoratorItem itemWithDummySupervisorView];
	
	UKObjectsEqual(item, [item firstDecoratedItem]);
	
	[decorator1 setDecoratedItem: item];
	UKObjectsEqual(item, [decorator1 firstDecoratedItem]);
	[decorator2 setDecoratedItem: decorator1];
	UKObjectsEqual(item,  [decorator2 firstDecoratedItem]);
	UKObjectsEqual(item, [decorator1 firstDecoratedItem]);
	UKObjectsEqual(item, [item firstDecoratedItem]);
}

- (void) testSupervisorView
{
	id item = [itemFactory item];
	id view1 = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)];
	id view2 = [[ETView alloc] initWithFrame: NSMakeRect(-50, 0, 100, 200)];

	UKNil([item supervisorView]);
	
	[item setView: view1]; /* -setView: creates the supervisor view if needed */
	UKObjectKindOf([item supervisorView], ETView);
	UKObjectsEqual(view1, [item view]);
	UKObjectsEqual(view1, [[item supervisorView] wrappedView]);
	UKObjectsEqual(item, [[item supervisorView] layoutItem]);

	[item setSupervisorView: view2];
	UKObjectsEqual(view2, [item supervisorView]);
	UKObjectsEqual(item, [[item supervisorView] layoutItem]);
	UKRectsEqual(NSMakeRect(-50, 0, 100, 200), [[item supervisorView] frame]);
	UKRectsEqual(NSMakeRect(-50, 0, 100, 200), [item frame]);
}

- (void) testSupervisorViewInsertionByDecorator
{
	id item = [itemFactory item];

	UKNil([item supervisorView]);
	
	ETWindowItem *windowItem = [[ETWindowItem alloc]
		initWithObjectGraphContext: [item objectGraphContext]];
	[item setDecoratorItem: windowItem];
	
	UKNotNil([item supervisorView]);
	UKObjectsEqual([[windowItem window] contentView], [item supervisorView]);
}

- (void) testHandleDecorateItemInView
{
	id item = [itemFactory item];
	id parentView = [[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)];
	ETLayoutItemGroup *parent = [itemFactory itemGroup];
	id mySupervisorView = [[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)];
	id supervisorView1 = [[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)];
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView]; //[itemFactory itemWithView: supervisorView1];

	[parent setSupervisorView: parentView];
	[parent addItem: item];
	
	[item setSupervisorView: mySupervisorView];
	[decorator1 setSupervisorView: supervisorView1];
	[decorator1 handleDecorateItem: item supervisorView: mySupervisorView inView: parentView];
	UKNotNil([[item supervisorView] superview]);
	/* Next line is valid with ETView instance as [decorator supervisorView] but 
	   might not with ETView subclasses (not valid with ETScrollView instance
	   to take an example) */
	UKObjectsEqual([[item supervisorView] superview], [decorator1 supervisorView]);
	
	UKObjectsEqual([[decorator1 supervisorView] superview], [parent supervisorView]);
	UKNil([[parent supervisorView] wrappedView]);
}

@end

#import "ETTableLayout.h"

@implementation TestItemGroup

- (id) init
{
	SUPERINIT;
	item = [itemFactory itemGroup];
	return self;
}

- (void) testSetSource
{
	UKTrue([item isEmpty]);

	[item addItem: [itemFactory item]];
	[item setSource: nil];

	UKFalse([item isEmpty]);
}

- (void) testSupervisorViewInsertionByLayoutView
{
	UKNil([item supervisorView]);
	
	ETTableLayout *layout = [ETTableLayout layoutWithObjectGraphContext: [item objectGraphContext]];
	[item setLayout: layout];
	
	UKNotNil([item supervisorView]);
	UKTrue([[[item supervisorView] subviews] containsObject: [layout layoutView]]);
}

- (void) testSupervisorViewInsertionByChild
{
	UKNil([item supervisorView]);
	
	ETLayoutItem *textFieldItem = [itemFactory textField];
	[item addItem: textFieldItem];
	
	UKNotNil([item supervisorView]);
	UKTrue([[[item supervisorView] subviews] containsObject: [textFieldItem supervisorView]]);
}

- (void) testSupervisorViewInsertionByDescendant
{
	ETLayoutItemGroup *intermediateParent = [itemFactory itemGroup];
	ETLayoutItem *textFieldItem = [itemFactory textField];

	UKNil([item supervisorView]);
	UKNil([intermediateParent supervisorView]);

	[item addItem: intermediateParent];
	[intermediateParent addItem: textFieldItem];
	
	UKNotNil([item supervisorView]);
	UKTrue([[[item supervisorView] subviews] containsObject: [intermediateParent supervisorView]]);
}
	
#define BUILD_TEST_TREE \
	id item0 = [itemFactory itemGroup]; \
	id item00 = [itemFactory item]; \
	id item01 = [itemFactory item]; \
	id item1 = [itemFactory itemGroup]; \
	id item10 = [itemFactory item]; \
	id item11 = [itemFactory itemGroup]; \
	id item110 = [itemFactory item]; \
	\
	[item addItem: item0]; \
	[item0 addItem: item00]; \
	[item0 addItem: item01]; \
	[item addItem: item1]; \
	[item1 addItem: item10]; \
	[item1 addItem: item11]; \
	[item11 addItem: item110]; \
	
#define BUILD_SELECTION_TEST_TREE_item_0_10_110 BUILD_TEST_TREE \
	[item setSelected: YES]; \
	[item0 setSelected: YES]; \
	[item10 setSelected: YES]; \
	[item110 setSelected: YES]; \

- (void) testSelectionIndexPaths
{
	BUILD_SELECTION_TEST_TREE_item_0_10_110

	NSArray *indexPaths = [item selectionIndexPaths];
	
	UKIntsEqual(3, [indexPaths count]);
	UKTrue([indexPaths containsObject: [item0 indexPath]]);
	UKTrue([indexPaths containsObject: [item10 indexPath]]);
	UKTrue([indexPaths containsObject: [item110 indexPath]]);

	[item0 setSelected: NO];	
	[item10 setSelected: NO];
	[item01 setSelected: YES];
	indexPaths = [item selectionIndexPaths];
	
	UKIntsEqual(2, [indexPaths count]);
	UKTrue([indexPaths containsObject: [item01 indexPath]]);
	UKTrue([indexPaths containsObject: [item110 indexPath]]);
}

- (void) testSetSelectionIndexPaths
{
	BUILD_TEST_TREE
	
	id indexPaths = nil;
	id indexPath0 = [NSIndexPath indexPathWithIndex: 0];
	id indexPath00 = [indexPath0 indexPathByAddingIndex: 0];
	id indexPath1 = [NSIndexPath indexPathWithIndex: 1];
	id indexPath10 = [indexPath1 indexPathByAddingIndex: 0];
	id indexPath11 = [indexPath1 indexPathByAddingIndex: 1];
	id indexPath110 = [indexPath11 indexPathByAddingIndex: 0];
		
	indexPaths = [NSMutableArray arrayWithObjects: indexPath0, indexPath00, indexPath110, nil];
	[item setSelectionIndexPaths: indexPaths];
	
	UKTrue([item0 isSelected]);
	UKTrue([item00 isSelected]);
	UKTrue([item110 isSelected]);
	UKFalse([item11 isSelected]);
	UKIntsEqual(3, [[item selectionIndexPaths] count]);

	[item110 setSelected: NO]; /* Test -setSelected: -setSelectionIndexPaths: interaction */
	indexPaths = [NSMutableArray arrayWithObjects: indexPath00, indexPath10, indexPath11, indexPath110, nil];
	[item setSelectionIndexPaths: indexPaths];

	UKFalse([item0 isSelected]);
	UKFalse([item1 isSelected]);	
	UKTrue([item00 isSelected]);
	UKTrue([item10 isSelected]);
	UKTrue([item11 isSelected]);
	UKTrue([item110 isSelected]);
	UKIntsEqual(4, [[item selectionIndexPaths] count]);
}

- (void) testSelectedItems
{
	BUILD_SELECTION_TEST_TREE_item_0_10_110
	
	id item2 = [itemFactory item];
	
	[item addItem: item2];
	[item2 setSelected: YES];
	
	NSArray *selectedItems = [item selectedItems];

	UKIntsEqual(2, [selectedItems count]);	
	UKIntsEqual([[item selectionIndexPaths] count], [selectedItems count] + 2);
	UKTrue([selectedItems containsObject: item0]);
	UKFalse([selectedItems containsObject: item10]);
	UKFalse([selectedItems containsObject: item110]);
	
	UKTrue([selectedItems containsObject: item2]);
}

@end
