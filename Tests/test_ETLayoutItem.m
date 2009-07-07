/*
	test_ETLayoutItem.m

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  October 2007

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETUIItemFactory.h"
#import "ETWindowItem.h"
#import "ETLayoutItemGroup.h"
#import "ETContainer.h"
#import "ETFlowLayout.h"
#import "ETScrollableAreaItem.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

static ETUIItemFactory *itemFactory = nil;

@interface ETLayoutItem (UnitKitTests) <UKTest>
@end

@interface ETLayoutItemGroup (UnitKitTests) <UKTest>
@end


@implementation ETLayoutItem (UnitKitTests)

- (id) initForTest
{
	self = [self init];
	itemFactory = [ETUIItemFactory factory];
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

- (void) testRootItem
{
	UKNotNil([self rootItem]);
	UKObjectsSame([self rootItem], self);
	
	id item1 = [itemFactory itemGroup];
	id item2 = [itemFactory itemGroup];
	
	[item1 addItem: item2];
	[item2 addItem: self];
	
	UKNotNil([item2 rootItem]);
	UKObjectsSame([item2 rootItem], item1);
	UKObjectsSame([item2 rootItem], [item2 parentItem]);
	UKObjectsSame([self rootItem], item1);
}

- (void) testSetParentItem
{
	id view = [[ETView alloc] initWithFrame: NSMakeRect(0, 0, 5, 10)];
	id parentView = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	id prevParentView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	id parentItem = [parentView layoutItem];
	
	[prevParentView addSubview: view];
	[self setSupervisorView: view];
	[parentItem setLayout: [ETFlowLayout layout]];
	
	[self setParentItem: parentItem];
	/* -setParentItem: doesn't touch the view hierarchy */
	UKObjectsNotSame(parentView, [[self supervisorView] superview]);
	UKObjectsSame(prevParentView, [[self supervisorView] superview]);
	UKObjectsSame([[self displayView] superview], [[self supervisorView] superview]);
	[self setParentItem: nil]; /* Revert to initial state */

	// TODO: More tests and move the following tests into standalone methods

	/* View is lazily inserted on layout update, unless -handleAttachViewOfItem: 
	  is called before the layout update occurs and calls this method. 
	  This special case occurs with a null layout. */

	[parentItem handleAttachViewOfItem: self];
	/* For flow layout of parentItem, view insertion is delayed */
	UKNil([[self supervisorView] superview]);
	UKObjectsSame([[self displayView] superview], [[self supervisorView] superview]);
	[parentItem handleDetachViewOfItem: self]; /* Revert to initial state */

	[parentItem addItem: self]; /* Will set parent layout item and update the layout */
	UKNotNil([[self displayView] superview]); /* View must be inserted as a subview now */
	UKObjectsSame([parentItem supervisorView], [[self displayView] superview]);	
	
	[parentItem removeItem: self];
	UKNil([[self displayView] superview]);
	UKObjectsNotSame([parentItem supervisorView], [[self displayView] superview]);
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

- (void) testUIMetalevel
{
	id item = [itemFactory item];
	id item1 = [itemFactory itemWithRepresentedObject: nil];
	id item2 = [itemFactory itemWithRepresentedObject: item1];
	id item3 = [itemFactory itemWithRepresentedObject: 
		[NSImage imageNamed: @"NSApplication"]];
	id item4 = [itemFactory itemWithRepresentedObject: item2];
	id item5 = [itemFactory itemWithRepresentedObject: 
		AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)])];	
	
	UKIntsEqual(0, [item UIMetalevel]);
	UKIntsEqual(0, [item1 UIMetalevel]);
	UKIntsEqual(1, [item2 UIMetalevel]);
	UKIntsEqual(0, [item3 UIMetalevel]);
	UKIntsEqual(2, [item4 UIMetalevel]);
	UKIntsEqual(1, [item5 UIMetalevel]);
}

/*  Test tree model:

	- root item					(0)
		- item 0				(2)
			- item 00			(1)
				- item 000		(4)
					- item 0000	(4)
					- item 0001	(0)
				- item 001		(2)
		- item 1				(0)
			- item 10			(0)
		
	Expected metalayers:
	- (0) item root, 1, 10
	- (2) item 0, 00, 001
	- (4) item 000, 0000, 0001 */
- (void) testUIMetalayer
{
	id itemM0 = [itemFactory item];
	id itemM1 = [itemFactory itemWithRepresentedObject: itemM0];
	id itemM2 = [itemFactory itemWithRepresentedObject: itemM1];
	id itemM3 = [itemFactory itemWithRepresentedObject: itemM2];

	id item = [itemFactory itemGroup];
	id item0 = [itemFactory itemGroupWithRepresentedObject: itemM1];
	id item00 = [itemFactory itemGroupWithRepresentedObject: itemM0];
	id item000 = [itemFactory itemGroupWithRepresentedObject: itemM3];
	id item0000 = [itemFactory itemWithRepresentedObject: itemM3];
	id item0001 = [itemFactory item];
	id item001 = [itemFactory itemWithRepresentedObject: itemM1];
	id item1 = [itemFactory itemGroup];
	id item10 = [itemFactory item];
	
	[item addItem: item0];
	[item0 addItem: item00];
	[item00 addItem: item000];
	[item000 addItem: item0000];
	[item000 addItem: item0001];
	[item00 addItem: item001];
	[item addItem: item1];
	[item1 addItem: item10];	
	
	UKIntsEqual(0, [item UIMetalayer]);
	UKIntsEqual(0, [item1 UIMetalayer]);
	UKIntsEqual(0, [item10 UIMetalayer]);
	UKIntsEqual(2, [item0 UIMetalayer]);
	UKIntsEqual(2, [item00 UIMetalayer]);
	UKIntsEqual(2, [item001 UIMetalayer]);
	UKIntsEqual(4, [item000 UIMetalayer]);
	UKIntsEqual(4, [item0000 UIMetalayer]);
	UKIntsEqual(4, [item0001 UIMetalayer]);
}

- (void) testSetDecoratorItem
{
	id decorator1 = [ETDecoratorItem item];
	id decorator2 = [ETDecoratorItem item];
	id decorator3 = [ETWindowItem item];
	
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
	id decorator1 = [ETDecoratorItem item];
	id decorator2 = [ETDecoratorItem item];
	
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
	id decorator1 = [ETDecoratorItem item];
	id decorator2 = [ETDecoratorItem item];
	
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

- (void) testHandleDecorateItemInView
{
	id parentView = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id parent = [itemFactory itemGroup];
	id supervisorView = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id supervisorView1 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id decorator1 = [ETDecoratorItem item]; //[itemFactory itemWithView: supervisorView1];

	[parent setSupervisorView: parentView];
	[parent addItem: self];
	
	[self setSupervisorView: supervisorView];
	[decorator1 setSupervisorView: supervisorView1];
	[decorator1 handleDecorateItem: self supervisorView: supervisorView inView: parentView];
	UKNotNil([[self supervisorView] superview]);
	/* Next line is valid with ETView instance as [decorator supervisorView] but 
	   might not with ETView subclasses (not valid with ETScrollView instance
	   to take an example) */
	UKObjectsEqual([[self supervisorView] superview], [decorator1 supervisorView]);
	
	UKObjectsEqual([[decorator1 supervisorView] superview], [parent supervisorView]);
	UKNil([[parent supervisorView] wrappedView]);
}

@end


@implementation ETLayoutItemGroup (UnitKitTests)
	
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
	[item0 setRepresentedPathBase: @"/myModel1"]; \
	[item11 setRepresentedPathBase: @"/myModel3"]; \

- (void) testIsContainer
{
	id container = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	
	[self setSupervisorView: container];
	RELEASE(container);
	
	UKTrue([self isContainer]);
}

- (void) testItemsIncludingRelatedDescendants
{
	BUILD_TEST_TREE
	DEFINE_BASE_ITEMS_0_11
	
	NSArray *items = [self itemsIncludingRelatedDescendants];

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

- (void) testSelectedItemsIncludingAllDescendants
{
	BUILD_SELECTION_TEST_TREE_self_0_10_110
	
	NSArray *selectedItems = [self selectedItemsIncludingAllDescendants];

	UKIntsEqual(3, [selectedItems count]);	
	UKIntsEqual([[self selectionIndexPaths] count], [selectedItems count]);
	UKTrue([selectedItems containsObject: item0]);
	UKTrue([selectedItems containsObject: item10]);
	UKTrue([selectedItems containsObject: item110]);
}

- (void) testSelectedItemsIncludingRelatedDescendants
{
	BUILD_SELECTION_TEST_TREE_self_0_10_110
	DEFINE_BASE_ITEMS_0_11
	
	NSArray *selectedItems = [self selectedItemsIncludingRelatedDescendants];

	UKIntsEqual(2, [selectedItems count]);	
	UKIntsEqual([[self selectionIndexPaths] count], [selectedItems count] + 1);
	UKTrue([selectedItems containsObject: item0]);
	UKTrue([selectedItems containsObject: item10]);
	UKFalse([selectedItems containsObject: item110]);
}

@end
