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
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/NSIndexPath+Etoile.h>
#import <UnitKit/UnitKit.h>
#ifndef GNUSTEP
#import <GNUstepBase/GNUstep.h>
#endif

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

- (void) buildTestSelectionTree
{
	//[self buildTestTree];
	id item0 = [ETLayoutItemGroup layoutItem];
	id item00 = [ETLayoutItem layoutItem];
	id item01 = [ETLayoutItem layoutItem];
	id item1 = [ETLayoutItemGroup layoutItem];
	id item10 = [ETLayoutItem layoutItem];
	id item11 = [ETLayoutItemGroup layoutItem];
	id item110 = [ETLayoutItem layoutItem];
	
	[self addItem: item0];
	[item0 addItem: item00];
	[item0 addItem: item01];
	[self addItem: item1];
	[item1 addItem: item10];	
	[item1 addItem: item11];
	[item11 addItem: item110];

	[self setSelected: YES];
	[item0 setSelected: YES];
	[item10 setSelected: YES];
	[item110 setSelected: YES];
}

- (void) testSelectionIndexPaths
{
	//[self buildTestSelectionTree];
	id item0 = [ETLayoutItemGroup layoutItem];
	id item00 = [ETLayoutItem layoutItem];
	id item01 = [ETLayoutItem layoutItem];
	id item1 = [ETLayoutItemGroup layoutItem];
	id item10 = [ETLayoutItem layoutItem];
	id item11 = [ETLayoutItemGroup layoutItem];
	id item110 = [ETLayoutItem layoutItem];
	
	[self addItem: item0];
	[item0 addItem: item00];
	[item0 addItem: item01];
	[self addItem: item1];
	[item1 addItem: item10];	
	[item1 addItem: item11];
	[item11 addItem: item110];

	NSArray *indexPaths = nil;
	
	[self setSelected: YES];
	[item0 setSelected: YES];
	[item10 setSelected: YES];
	[item110 setSelected: YES];
	indexPaths = [self selectionIndexPaths];
	
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
	//[self buildTestSelectionTree];
	id item0 = [ETLayoutItemGroup layoutItem];
	id item00 = [ETLayoutItem layoutItem];
	id item01 = [ETLayoutItem layoutItem];
	id item1 = [ETLayoutItemGroup layoutItem];
	id item10 = [ETLayoutItem layoutItem];
	id item11 = [ETLayoutItemGroup layoutItem];
	id item110 = [ETLayoutItem layoutItem];
	
	[self addItem: item0];
	[item0 addItem: item00];
	[item0 addItem: item01];
	[self addItem: item1];
	[item1 addItem: item10];	
	[item1 addItem: item11];
	[item11 addItem: item110];
	
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

@end
