/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  October 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <CoreObject/COObjectGraphContext.h>
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
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

@interface ETDecoratorItem (TestItemGeometry)
+ (ETDecoratorItem *) itemWithDummySupervisorView;
@end

static ETLayoutItemFactory *itemFactory = nil;

@interface ETLayoutItem (UnitKitTests) <UKTest>
@end

@interface ETLayoutItemGroup (UnitKitTests) <UKTest>
@end


@implementation ETLayoutItem (UnitKitTests)

- (id) initForTest
{
	self = [self initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	itemFactory = [ETLayoutItemFactory factory];
	return self;
}

/*- (void) buildTestTree
{
	id item1 = [itemFactory item];
	id item11 = [itemFactory item];
	id item12 = [itemFactory item];
	id item2 = [itemFactory item];
	id item21 = [itemFactory item];
	id item22 = [itemFactory item];
	id item221 = [itemFactory item];
	
	[self addItem: item1];
	[item1 addItem: item11];
	[item1 addItem: item12];
	[self addItem: item2];
	[item2 addItem: item21];	
	[item2 addItem: item22];
	[item22 addItem: item221];
}*/

- (void) testRetainCountForItemCreation
{

	id item = [itemFactory item];
	id itemGroup = [itemFactory itemGroup];

	/* Force the layout executor to release the item (the item was scheduled due 
	   to geometry initialization) */
	CREATE_AUTORELEASE_POOL(pool);
	[[ETLayoutExecutor sharedInstance] removeItems: S(item, itemGroup)];
	[[itemFactory objectGraphContext] discardAllChanges];
	DESTROY(pool);

	UKIntsEqual(1, [item retainCount]);
	UKIntsEqual(1, [itemGroup retainCount]);
}

- (void) testRetainCountForItemMutation
{
	id item = [itemFactory item];
	id itemGroup = [itemFactory itemGroup];
		
	CREATE_AUTORELEASE_POOL(pool);

    // Relationship cache may cause autoreleased references
    [itemGroup addItem: item];
	[itemGroup removeItem: item];

	[[ETLayoutExecutor sharedInstance] removeItems: S(item, itemGroup)];
	[[itemFactory objectGraphContext] discardAllChanges];
	DESTROY(pool);

	UKIntsEqual(1, [item retainCount]);
	UKIntsEqual(1, [itemGroup retainCount]);
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

	[parentItem setSupervisorView: AUTORELEASE([[ETView alloc] init])];
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
	ETLayoutItem* item = [itemFactory itemWithView: AUTORELEASE([[NSView alloc] init])];
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
	ETLayoutItem* item = [itemFactory itemWithView: AUTORELEASE([[NSView alloc] init])];
	ETLayoutItemGroup *parentItem = [itemFactory itemGroup];

	[parentItem setLayout: [ETTableLayout layoutWithObjectGraphContext: [parentItem objectGraphContext]]];
	[parentItem addItem: item];

	// FIXME: Probably update ETWidgetLayout to use -setVisibleItems:
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
	id item = [[ETLayoutItemGroup alloc]
		initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
	id item0 = [[ETLayoutItemGroup alloc]
		initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
	id item1 = [[ETLayoutItem alloc]
		initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];

	CREATE_AUTORELEASE_POOL(pool);
	[item addItems: A(item0, item1)];
	/* Required to get RELEASE(item) deallocates the item */
	[[ETLayoutExecutor sharedInstance] removeItem: item];
	[[item objectGraphContext] discardAllChanges];
	DESTROY(pool);

	RELEASE(item);
	/* The next tests ensure the parent item was correctly reset to nil, 
	   otherwise -parentItem crashes. */
	UKNil([item0 parentItem]);
	UKNil([item1 parentItem]);

	RELEASE(item0);
	RELEASE(item1);
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
	id item10 = self;
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

	UKObjectsEqual(emptyIndexPath, [self indexPathForItem: self]);
	UKNil([self indexPathForItem: nil]); /* Root item based index path */

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
	id item10 = self;
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

	UKObjectsEqual(emptyIndexPath, [self indexPathFromItem: self]);
	UKObjectsEqual(indexPath10, [self indexPathFromItem: nil]); /* Root item based index path */

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
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator2 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator3 = [ETWindowItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];
	
	UKNil([self decoratorItem]);
	
	[self setDecoratorItem: decorator1];
	UKObjectsEqual(decorator1, [self decoratorItem]);
	
	[decorator1 setDecoratorItem: decorator2];
	UKObjectsEqual(decorator2, [decorator1 decoratorItem]);
	
	[decorator2 setDecoratorItem: decorator3];
	UKObjectsEqual(decorator3, [decorator2 decoratorItem]);
}

- (void) testLastDecoratorItem
{
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator2 = [ETDecoratorItem itemWithDummySupervisorView];
	
	UKObjectsEqual(self, [self lastDecoratorItem]);
	
	[self setDecoratorItem: decorator1];
	UKObjectsEqual(decorator1, [self lastDecoratorItem]);
	[decorator1 setDecoratorItem: decorator2];
	UKObjectsEqual(decorator2, [self lastDecoratorItem]);
	UKObjectsEqual(decorator2, [decorator1 lastDecoratorItem]);
	UKObjectsEqual(decorator2, [decorator2 lastDecoratorItem]);
}

- (void) testFirstDecoratedItem
{
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView];
	id decorator2 = [ETDecoratorItem itemWithDummySupervisorView];
	
	UKObjectsEqual(self, [self firstDecoratedItem]);
	
	[decorator1 setDecoratedItem: self];
	UKObjectsEqual(self, [decorator1 firstDecoratedItem]);
	[decorator2 setDecoratedItem: decorator1];
	UKObjectsEqual(self,  [decorator2 firstDecoratedItem]);
	UKObjectsEqual(self, [decorator1 firstDecoratedItem]);
	UKObjectsEqual(self, [self firstDecoratedItem]);
}

- (void) testSupervisorView
{
	id view1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id view2 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(-50, 0, 100, 200)]);

	UKNil([self supervisorView]);
	
	[self setView: view1]; /* -setView: creates the supervisor view if needed */
	UKObjectKindOf([self supervisorView], ETView);
	UKObjectsEqual(view1, [self view]);
	UKObjectsEqual(view1, [[self supervisorView] wrappedView]);
	UKObjectsEqual(self, [[self supervisorView] layoutItem]);

	[self setSupervisorView: view2];
	UKObjectsEqual(view2, [self supervisorView]);
	UKObjectsEqual(self, [[self supervisorView] layoutItem]);
	UKRectsEqual(NSMakeRect(-50, 0, 100, 200), [[self supervisorView] frame]);
	UKRectsEqual(NSMakeRect(-50, 0, 100, 200), [self frame]);
}

- (void) testSupervisorViewInsertionByDecorator
{
	UKNil([self supervisorView]);
	
	ETWindowItem *windowItem = AUTORELEASE([[ETWindowItem alloc]
		initWithObjectGraphContext: [self objectGraphContext]]);
	[self setDecoratorItem: windowItem];
	
	UKNotNil([self supervisorView]);
	UKObjectsEqual([[windowItem window] contentView], [self supervisorView]);
}

- (void) testHandleDecorateItemInView
{
	id parentView = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	ETLayoutItemGroup *parent = [itemFactory itemGroup];
	id mySupervisorView = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id supervisorView1 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id decorator1 = [ETDecoratorItem itemWithDummySupervisorView]; //[itemFactory itemWithView: supervisorView1];

	[parent setSupervisorView: parentView];
	[parent addItem: self];
	
	[self setSupervisorView: mySupervisorView];
	[decorator1 setSupervisorView: supervisorView1];
	[decorator1 handleDecorateItem: self supervisorView: mySupervisorView inView: parentView];
	UKNotNil([[self supervisorView] superview]);
	/* Next line is valid with ETView instance as [decorator supervisorView] but 
	   might not with ETView subclasses (not valid with ETScrollView instance
	   to take an example) */
	UKObjectsEqual([[self supervisorView] superview], [decorator1 supervisorView]);
	
	UKObjectsEqual([[decorator1 supervisorView] superview], [parent supervisorView]);
	UKNil([[parent supervisorView] wrappedView]);
}

@end

#import "ETTableLayout.h"

@implementation ETLayoutItemGroup (UnitKitTests)

- (void) testSetSource
{
	UKTrue([self isEmpty]);

	[self addItem: [itemFactory item]];
	[self setSource: nil];

	UKFalse([self isEmpty]);
}

- (void) testSupervisorViewInsertionByLayoutView
{
	UKNil([self supervisorView]);
	
	ETTableLayout *layout = [ETTableLayout layoutWithObjectGraphContext: [self objectGraphContext]];
	[self setLayout: layout];
	
	UKNotNil([self supervisorView]);
	UKTrue([[[self supervisorView] subviews] containsObject: [layout layoutView]]);
}

- (void) testSupervisorViewInsertionByChild
{
	UKNil([self supervisorView]);
	
	ETLayoutItem *textFieldItem = [itemFactory textField];
	[self addItem: textFieldItem];
	
	UKNotNil([self supervisorView]);
	UKTrue([[[self supervisorView] subviews] containsObject: [textFieldItem supervisorView]]);
}

- (void) testSupervisorViewInsertionByDescendant
{
	ETLayoutItemGroup *intermediateParent = [itemFactory itemGroup];
	ETLayoutItem *textFieldItem = [itemFactory textField];

	UKNil([self supervisorView]);
	UKNil([intermediateParent supervisorView]);

	[self addItem: intermediateParent];
	[intermediateParent addItem: textFieldItem];
	
	UKNotNil([self supervisorView]);
	UKTrue([[[self supervisorView] subviews] containsObject: [intermediateParent supervisorView]]);
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
	[self addItem: item0]; \
	[item0 addItem: item00]; \
	[item0 addItem: item01]; \
	[self addItem: item1]; \
	[item1 addItem: item10]; \
	[item1 addItem: item11]; \
	[item11 addItem: item110]; \
	
#define BUILD_SELECTION_TEST_TREE_self_0_10_110 BUILD_TEST_TREE \
	[self setSelected: YES]; \
	[item0 setSelected: YES]; \
	[item10 setSelected: YES]; \
	[item110 setSelected: YES]; \
	
#define DEFINE_BASE_ITEMS_0_11 \
	[item0 setController: AUTORELEASE([[ETController alloc] \
		initWithObjectGraphContext: [itemFactory objectGraphContext]])]; \
	[item11 setController: AUTORELEASE([[ETController alloc] \
		initWithObjectGraphContext: [itemFactory objectGraphContext]])]; \

- (void) testDescendantItemsSharingSameBaseItem
{
	BUILD_TEST_TREE
	DEFINE_BASE_ITEMS_0_11
	
	NSArray *items = [self descendantItemsSharingSameBaseItem];

	UKIntsEqual(4, [items count]);	
	UKTrue([items containsObject: item0]);
	UKFalse([items containsObject: item00]);
	UKFalse([items containsObject: item01]);
	UKTrue([items containsObject: item1]);
	UKTrue([items containsObject: item10]);
	UKTrue([items containsObject: item11]);
	UKFalse([items containsObject: item110]);
}

- (void) testSelectionIndexPaths
{
	BUILD_SELECTION_TEST_TREE_self_0_10_110

	NSArray *indexPaths = [self selectionIndexPaths];
	
	UKIntsEqual(3, [indexPaths count]);
	UKTrue([indexPaths containsObject: [item0 indexPath]]);
	UKTrue([indexPaths containsObject: [item10 indexPath]]);
	UKTrue([indexPaths containsObject: [item110 indexPath]]);

	[item0 setSelected: NO];	
	[item10 setSelected: NO];
	[item01 setSelected: YES];
	indexPaths = [self selectionIndexPaths];
	
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
	[self setSelectionIndexPaths: indexPaths];
	
	UKTrue([item0 isSelected]);
	UKTrue([item00 isSelected]);
	UKTrue([item110 isSelected]);
	UKFalse([item11 isSelected]);
	UKIntsEqual(3, [[self selectionIndexPaths] count]);

	[item110 setSelected: NO]; /* Test -setSelected: -setSelectionIndexPaths: interaction */
	indexPaths = [NSMutableArray arrayWithObjects: indexPath00, indexPath10, indexPath11, indexPath110, nil];
	[self setSelectionIndexPaths: indexPaths];

	UKFalse([item0 isSelected]);
	UKFalse([item1 isSelected]);	
	UKTrue([item00 isSelected]);
	UKTrue([item10 isSelected]);
	UKTrue([item11 isSelected]);
	UKTrue([item110 isSelected]);
	UKIntsEqual(4, [[self selectionIndexPaths] count]);
}

- (void) testSelectedItems
{
	BUILD_SELECTION_TEST_TREE_self_0_10_110
	
	id item2 = [itemFactory item];
	
	[self addItem: item2];
	[item2 setSelected: YES];
	
	NSArray *selectedItems = [self selectedItems];

	UKIntsEqual(2, [selectedItems count]);	
	UKIntsEqual([[self selectionIndexPaths] count], [selectedItems count] + 2);
	UKTrue([selectedItems containsObject: item0]);
	UKFalse([selectedItems containsObject: item10]);
	UKFalse([selectedItems containsObject: item110]);
	
	UKTrue([selectedItems containsObject: item2]);
}

@end
