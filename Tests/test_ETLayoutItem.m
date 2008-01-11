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
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/NSIndexPath+Etoile.h>
#import <UnitKit/UnitKit.h>
#import <EtoileUI/ETCompatibility.h>
@interface ETLayoutItem (UnitKitTests) <UKTest>
@end

@interface ETLayoutItemGroup (UnitKitTests) <UKTest>
@end


@implementation ETLayoutItem (UnitKitTests)

/*- (void) buildTestTree
{
	id item1 = [ETLayoutItemGroup layoutItem];
	id item11 = [ETLayoutItem layoutItem];
	id item12 = [ETLayoutItem layoutItem];
	id item2 = [ETLayoutItemGroup layoutItem];
	id item21 = [ETLayoutItem layoutItem];
	id item22 = [ETLayoutItemGroup layoutItem];
	id item221 = [ETLayoutItem layoutItem];
	
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
	
	id item1 = [ETLayoutItemGroup layoutItem];
	id item2 = [ETLayoutItemGroup layoutItem];
	
	[item1 addItem: item2];
	[item2 addItem: self];
	
	UKNotNil([item2 rootItem]);
	UKObjectsSame([item2 rootItem], item1);
	UKObjectsSame([item2 rootItem], [item2 parentLayoutItem]);
	UKObjectsSame([self rootItem], item1);
}

- (void) testSetParentLayoutItem
{
	id view = [[ETView alloc] initWithFrame: NSMakeRect(0, 0, 5, 10)];
	id parentView = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	id prevParentView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	id parentItem = [parentView layoutItem];
	
	[prevParentView addSubview: view];
	[self setView: view];
	[parentItem setLayout: [ETFlowLayout layout]];
	
	[self setParentLayoutItem: parentItem];
	UKObjectsNotSame(prevParentView, [[self view] superview]);
	UKNil([[self displayView] superview]); /* View is lazily inserted on layout update */
	[self setParentLayoutItem: nil]; /* Revert to initial state */
	
	[parentItem addItem: self]; /* Will set parent layout item and update the layout */
	UKNotNil([[self displayView] superview]); /* View must be inserted as a subview now */
	UKObjectsSame([parentItem view], [[self displayView] superview]);	
	
	[parentItem removeItem: self];
	UKNil([[self displayView] superview]);
	UKObjectsNotSame([parentItem view], [[self displayView] superview]);
}

- (void) testIndexPathForItem
{
	id item = [ETLayoutItemGroup layoutItem];
	id item0 = [ETLayoutItemGroup layoutItem];
	id item00 = [ETLayoutItem layoutItem];
	id item1 = [ETLayoutItemGroup layoutItem];
	id item10 = self;
	id item11 = [ETLayoutItemGroup layoutItem];
	id item110 = [ETLayoutItem layoutItem];
	
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
	id item = [ETLayoutItemGroup layoutItem];
	id item0 = [ETLayoutItemGroup layoutItem];
	id item00 = [ETLayoutItem layoutItem];
	id item1 = [ETLayoutItemGroup layoutItem];
	id item10 = self;
	id item11 = [ETLayoutItemGroup layoutItem];
	id item110 = [ETLayoutItem layoutItem];
	
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
	id item = [ETLayoutItem layoutItem];
	id item1 = [ETLayoutItem layoutItemWithRepresentedObject: nil];
	id item2 = [ETLayoutItem layoutItemWithRepresentedObject: item1];
	id item3 = [ETLayoutItem layoutItemWithRepresentedObject: 
		[NSImage imageNamed: @"NSApplication"]];
	id item4 = [ETLayoutItem layoutItemWithRepresentedObject: item2];
	id item5 = [ETLayoutItem layoutItemWithRepresentedObject: 
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
	id itemM0 = [ETLayoutItem layoutItem];
	id itemM1 = [ETLayoutItem layoutItemWithRepresentedObject: itemM0];
	id itemM2 = [ETLayoutItem layoutItemWithRepresentedObject: itemM1];
	id itemM3 = [ETLayoutItem layoutItemWithRepresentedObject: itemM2];

	id item = [ETLayoutItemGroup layoutItem];
	id item0 = [ETLayoutItemGroup layoutItemWithRepresentedObject: itemM1];
	id item00 = [ETLayoutItemGroup layoutItemWithRepresentedObject: itemM0];
	id item000 = [ETLayoutItemGroup layoutItemWithRepresentedObject: itemM3];
	id item0000 = [ETLayoutItem layoutItemWithRepresentedObject: itemM3];
	id item0001 = [ETLayoutItem layoutItem];
	id item001 = [ETLayoutItem layoutItemWithRepresentedObject: itemM1];
	id item1 = [ETLayoutItemGroup layoutItem];
	id item10 = [ETLayoutItem layoutItem];
	
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

@end


@implementation ETLayoutItemGroup (UnitKitTests)
	
#define BUILD_TEST_TREE \
	id item0 = [ETLayoutItemGroup layoutItem]; \
	id item00 = [ETLayoutItem layoutItem]; \
	id item01 = [ETLayoutItem layoutItem]; \
	id item1 = [ETLayoutItemGroup layoutItem]; \
	id item10 = [ETLayoutItem layoutItem]; \
	id item11 = [ETLayoutItemGroup layoutItem]; \
	id item110 = [ETLayoutItem layoutItem]; \
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
	
#define DEFINE_BASE_ITEMS_0_10_11 \
	id container1 = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)]; \
	id container2 = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)]; \
	id container3 = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)]; \
	 \
	[container1 setRepresentedPath: @"/myModel1"]; \
	[container2 setRepresentedPath: @"/myModel2"]; \
	[container3 setRepresentedPath: @"/myModel3"]; \
	[item0 setView: container1]; \
	[item10 setView: container2]; \
	[item11 setView: container3]; \
	RELEASE(container1); \
	RELEASE(container2); \
	RELEASE(container3); \

- (void) testRepresentedPathBase
{
	id container = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	
	UKNil([self representedPathBase]);
	
	[container setRepresentedPath: @"/myModel"];
	[self setView: container];
	RELEASE(container);
	
	UKNotNil([self representedPathBase]);
	UKStringsEqual(@"/myModel", [self representedPathBase]);
}

- (void) testIsContainer
{
	id container = [[ETContainer alloc] initWithFrame: NSMakeRect(0, 0, 50, 100)];
	
	[self setView: container];
	RELEASE(container);
	
	UKTrue([self isContainer]);
}

- (void) testItemsIncludingRelatedDescendants
{
	BUILD_TEST_TREE
	DEFINE_BASE_ITEMS_0_10_11
	
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
	
	id item2 = [ETLayoutItem layoutItem];
	
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
	DEFINE_BASE_ITEMS_0_10_11
	
	NSArray *selectedItems = [self selectedItemsIncludingRelatedDescendants];

	UKIntsEqual(2, [selectedItems count]);	
	UKIntsEqual([[self selectionIndexPaths] count], [selectedItems count] + 1);
	UKTrue([selectedItems containsObject: item0]);
	UKTrue([selectedItems containsObject: item10]);
	UKFalse([selectedItems containsObject: item110]);
}

@end
