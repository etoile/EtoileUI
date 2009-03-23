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
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETWindowItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <UnitKit/UnitKit.h>
#import <EtoileUI/ETCompatibility.h>
@interface ETLayoutItem (UnitKitTests) <UKTest>
@end

@interface ETLayoutItemGroup (UnitKitTests) <UKTest>
@end


@implementation ETLayoutItem (UnitKitTests)

/*- (void) buildTestTree
{
	id item1 = [ETLayoutItemGroup item];
	id item11 = [ETLayoutItem item];
	id item12 = [ETLayoutItem item];
	id item2 = [ETLayoutItemGroup item];
	id item21 = [ETLayoutItem item];
	id item22 = [ETLayoutItemGroup item];
	id item221 = [ETLayoutItem item];
	
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
	
	id item1 = [ETLayoutItemGroup item];
	id item2 = [ETLayoutItemGroup item];
	
	[item1 addItem: item2];
	[item2 addItem: self];
	
	UKNotNil([item2 rootItem]);
	UKObjectsSame([item2 rootItem], item1);
	UKObjectsSame([item2 rootItem], [item2 parentItem]);
	UKObjectsSame([self rootItem], item1);
}

- (void) testSetParentLayoutItem
{
	id view = [[ETView alloc] initWithFrame: NSMakeRect(0, 0, 5, 10)];
	id parentView = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	id prevParentView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	id parentItem = [parentView layoutItem];
	
	[prevParentView addSubview: view];
	[self setSupervisorView: view];
	[parentItem setLayout: [ETFlowLayout layout]];
	
	[self setParentLayoutItem: parentItem];
	/* -setParentLayoutItem: doesn't touch the view hierarchy */
	UKObjectsNotSame(parentView, [[self supervisorView] superview]);
	UKObjectsSame(prevParentView, [[self supervisorView] superview]);
	UKObjectsSame([[self displayView] superview], [[self supervisorView] superview]);
	[self setParentLayoutItem: nil]; /* Revert to initial state */

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
	id item = [ETLayoutItemGroup item];
	id item0 = [ETLayoutItemGroup item];
	id item00 = [ETLayoutItem item];
	id item1 = [ETLayoutItemGroup item];
	id item10 = self;
	id item11 = [ETLayoutItemGroup item];
	id item110 = [ETLayoutItem item];
	
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
	id item = [ETLayoutItemGroup item];
	id item0 = [ETLayoutItemGroup item];
	id item00 = [ETLayoutItem item];
	id item1 = [ETLayoutItemGroup item];
	id item10 = self;
	id item11 = [ETLayoutItemGroup item];
	id item110 = [ETLayoutItem item];
	
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
	id item = [ETLayoutItem item];
	id item1 = [ETLayoutItem itemWithRepresentedObject: nil];
	id item2 = [ETLayoutItem itemWithRepresentedObject: item1];
	id item3 = [ETLayoutItem itemWithRepresentedObject: 
		[NSImage imageNamed: @"NSApplication"]];
	id item4 = [ETLayoutItem itemWithRepresentedObject: item2];
	id item5 = [ETLayoutItem itemWithRepresentedObject: 
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
	id itemM0 = [ETLayoutItem item];
	id itemM1 = [ETLayoutItem itemWithRepresentedObject: itemM0];
	id itemM2 = [ETLayoutItem itemWithRepresentedObject: itemM1];
	id itemM3 = [ETLayoutItem itemWithRepresentedObject: itemM2];

	id item = [ETLayoutItemGroup item];
	id item0 = [ETLayoutItemGroup itemWithRepresentedObject: itemM1];
	id item00 = [ETLayoutItemGroup itemWithRepresentedObject: itemM0];
	id item000 = [ETLayoutItemGroup itemWithRepresentedObject: itemM3];
	id item0000 = [ETLayoutItem itemWithRepresentedObject: itemM3];
	id item0001 = [ETLayoutItem item];
	id item001 = [ETLayoutItem itemWithRepresentedObject: itemM1];
	id item1 = [ETLayoutItemGroup item];
	id item10 = [ETLayoutItem item];
	
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

- (void) testConvertRectToParent
{
	[[ETLayoutItem itemGroup] addItem: self];
	[self setOrigin: NSMakePoint(5, 2)];
	
	NSRect newRect = [self convertRectToParent: NSMakeRect(0, 0, 10, 20)];
	UKIntsEqual(5, newRect.origin.x);
	UKIntsEqual(2, newRect.origin.y);
	
	newRect = [self convertRectToParent: NSMakeRect(50, 100, 10, 20)];
	
	UKIntsEqual(55, newRect.origin.x);
	UKIntsEqual(102, newRect.origin.y);

	[self setOrigin: NSMakePoint(60, 80)];	
	newRect = [self convertRectToParent: NSMakeRect(-50, -100, 10, 20)];
	
	UKIntsEqual(10, newRect.origin.x);
	UKIntsEqual(-20, newRect.origin.y);
	UKIntsEqual(10, newRect.size.width);
	UKIntsEqual(20, newRect.size.height);
}


- (void) testConvertRectFromParent
{
	[[ETLayoutItem itemGroup] addItem: self];
	[self setOrigin: NSMakePoint(5, 2)];
	
	NSRect newRect = [self convertRectFromParent: NSMakeRect(0, 0, 10, 20)];
	UKIntsEqual(-5, newRect.origin.x);
	UKIntsEqual(-2, newRect.origin.y);
	
	newRect = [self convertRectFromParent: NSMakeRect(50, 100, 10, 20)];
	
	UKIntsEqual(45, newRect.origin.x);
	UKIntsEqual(98, newRect.origin.y);

	[self setOrigin: NSMakePoint(60, 80)];	
	newRect = [self convertRectFromParent: NSMakeRect(-50, -100, 10, 20)];
	
	UKIntsEqual(-110, newRect.origin.x);
	UKIntsEqual(-180, newRect.origin.y);
	UKIntsEqual(10, newRect.size.width);
	UKIntsEqual(20, newRect.size.height);
}

- (void) testDisplayView
{
	//id decorator1 = [ETLayoutItem item];
	//id decorator2 = [ETLayoutItem item];
}

#if 0
- (void) testDecoration
{

	/* Verify the proper set up of the current decorator */
	if (_decoratorItem != nil)
	{
		NSAssert1([self displayView] != nil, @"Display view must no be nil "
			@"when a decorator is set on item %@", self);		
		NSAssert2([[_decoratorItem displayView] isKindOfClass: [ETView class]], 
			@"Decorator %@ must have display view %@ of type ETView", 
			_decoratorItem, [_decoratorItem displayView]);
		NSAssert2([_decoratorItem displayView] == [self displayView], 
			@"Decorator display view %@ must be decorated item display view %@", 
			[_decoratorItem displayView], [self displayView]);
		NSAssert2([_decoratorItem parentItem] == nil, @"Decorator %@ "
			@"must have no parent %@ set", _decoratorItem, 
			[_decoratorItem parentItem]);
	}
		
	/* Verify the new decorator */
	if (decorator != nil)
	{
		NSAssert2([[decorator displayView] isKindOfClass: [ETView class]], 
			@"Decorator %@ must have display view %@ of type ETView", 
			decorator, [decorator displayView]);
		if ([decorator parentItem] != nil)
		{
			ETLog(@"WARNING: Decorator item %@ must have no parent to be used", 
				decorator);
			[[decorator parentItem] removeItem: decorator];
		}
	}
	
	// NOTE: New decorator must be set before updating display view because
	// display view related methods rely on -decoratorItem accessor
	ASSIGN(_decoratorItem, decorator);
	
	/* Finally updated the view tree */
	
	NSView *superview = [innerDisplayView superview];
	ETView *newDisplayView = nil;
	
	[self _setInnerDisplayView: innerDisplayView];
	// NOTE: Now innerDisplayView and [self displayView] doesn't match, the 
	// the latter has become [decorator displayView]
	newDisplayView = [self displayView];

	/* Verify new decorator has been correctly inserted */
	if (_decoratorItem != nil)
	{
		NSAssert3([newDisplayView isEqual: [self displayView]], @"Display "
			@" view %@ of item %@ must be the decorator display view %@", 
			[self displayView], self, newDisplayView);
	}
	
	/* If the previous display view was part of view tree, inserts the new
	   display view into the existing superview */
	if (superview != nil)
	{
		NSAssert2([newDisplayView superview] == nil, @"New display view %@ of "
			@"item %@ must have no superview at this point", 
			newDisplayView, self);
		[superview addSubview: newDisplayView];
	}
}
#endif

- (void) testSetDecoratorItem
{
	id decorator1 = [ETLayoutItem item];
	id decorator2 = [ETLayoutItem item];
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
	id decorator1 = [ETLayoutItem item];
	id decorator2 = [ETLayoutItem item];
	
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
	id decorator1 = [ETLayoutItem item];
	id decorator2 = [ETLayoutItem item];
	
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
	id view2 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	
	UKNil([self supervisorView]);
	[self setView: view1];
	UKNotNil([self supervisorView]);
	UKTrue([[self supervisorView] isKindOfClass: [ETView class]]);
	/* Next line only valid if view1 isn't an instance of ETView kind */
	UKObjectsEqual([[self supervisorView] wrappedView], [self view]);
	UKObjectsNotEqual(view1, [self supervisorView]);
	UKObjectsEqual(self, [[self supervisorView] layoutItem]);
	[self setSupervisorView: view2];
	UKNotNil([self supervisorView]);
	UKObjectsEqual(view2, [self supervisorView]);
	UKObjectsEqual(self, [[self supervisorView] layoutItem]);
}

- (void) testHandleDecorateItemInView
{
	id parentView = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id parent = [ETLayoutItem itemGroup];
	id supervisorView = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id supervisorView1 = AUTORELEASE([[ETView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]);
	id decorator1 = [ETLayoutItem item]; //[ETLayoutItem itemWithView: supervisorView1];

	[parent setSupervisorView: parentView];
	[parent addItem: self];
	
	[self setSupervisorView: supervisorView];
	[decorator1 setSupervisorView: supervisorView1];
	[decorator1 handleDecorateItem: self inView: parentView];
	UKObjectsEqual([self supervisorView], [decorator1 view]);
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
	id item0 = [ETLayoutItemGroup item]; \
	id item00 = [ETLayoutItem item]; \
	id item01 = [ETLayoutItem item]; \
	id item1 = [ETLayoutItemGroup item]; \
	id item10 = [ETLayoutItem item]; \
	id item11 = [ETLayoutItemGroup item]; \
	id item110 = [ETLayoutItem item]; \
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
	
	id item2 = [ETLayoutItem item];
	
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
