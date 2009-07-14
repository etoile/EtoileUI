/*  <title>ETCompositeLayout</title>

	ETCompositeLayout.m

	<abstract>A layout subclass that formalizes and simplifies the 
	composition of layouts.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
 
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

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileUI/ETCompositeLayout.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETContainer.h>

@interface ETCompositeLayout (Private)
- (ETLayoutItemGroup *) firstDescendantGroupForItem: (ETLayoutItemGroup *)itemGroup;
@end


@implementation ETCompositeLayout

- (id) init
{
	return nil;
}

- (id) initWithRootItem: (ETLayoutItemGroup *)itemGroup
{
	return [self initWithRootItem: itemGroup 
	                   targetItem: [self firstDescendantGroupForItem: itemGroup]];
}

- (ETLayoutItemGroup *) firstDescendantGroupForItem: (ETLayoutItemGroup *)itemGroup
{
	NSArray *descendants = [itemGroup itemsIncludingAllDescendants];

	FOREACHI(descendants, item)
	{
		if ([item isGroup])
			return item;
	}

	return  nil;
}

/** The target item must be part of the descendent items of rootItem, otherwise 
    an exception will be thrown. */
//- (id) initWithRootItem: (ETLayoutItemGroup *)itemGroup targetIndexPath: (NSIndexPath *)indexPath
- (id) initWithRootItem: (ETLayoutItemGroup *)rootItem 
             targetItem: (ETLayoutItemGroup *)targetItem

{
	NSAssert([rootItem isContainer], @"Root item parameter must have a container");

	self = [super initWithLayoutView: nil];

	if (self != nil)
	{
		ASSIGN(_rootItem, rootItem);
		[self setTargetItem: targetItem];
	}

	return self;
}

DEALLOC(DESTROY(_rootItem); DESTROY(_targetItem));

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[[self rootItem] reloadAndUpdateLayout]; // not necessary I think
	[[self targetLayout] renderWithLayoutItems: items isNewContent: isNewContent];
	/* Triggers the refresh of everything including the items to be routed 
	   from the target layout to another child item of the root item. For 
	   example, if an item is selected in the target layout in a master-detail
	   interface. The target item is the master UI, when another child of the
	   root item plays the role of the detail UI. */
	[[self rootItem] reloadAndUpdateLayout]; 
}

- (ETLayoutItemGroup *) rootItem
{
	return _rootItem;
}

- (ETContainer *) rootContainer
{
	NSAssert([_rootItem isContainer], @"Root item parameter must have a container");
	id container = [[self rootItem] supervisorView];
	return container;
}

- (id) targetLayout
{
	return [[self targetItem] layout];
}

- (id) targetItem
{
	return _targetItem;
}

- (void) setTargetItem: (ETLayoutItemGroup *)targetItem
{
	//[_targetItem setLayoutContext: nil];
	ASSIGN(_targetItem, targetItem);
	[[_targetItem layout] setLayoutContext: self];
}

/* Layouting Context Protocol 

   We redirect several calls on the layout context to the target item where the 
   layout items are really rendered. 
   You may better understand what is really going on by reading the code of 
   -renderWithLayoutItems:isNewContent:.
   The target item is the layout context for all presentational related calls 
   and all other calls that relates to the tree structure to be displayed are 
   passed to the receiver layout context (the layout item on which is the 
   composite layout is applied). */

// NOTE: Eventually use FORWARD(NSArray *, items, self) and
// BOUNCEBACK(NSArray *, items)

- (NSArray *) items
{
	return [[self layoutContext] items];
}

- (NSArray *) visibleItems
{
	return [[self targetItem] visibleItems];
}

- (void) setVisibleItems: (NSArray *)items
{
	[[self targetItem] setVisibleItems: items];
}

- (NSSize) size
{
	return [[self targetItem] size];
}

- (void) setSize: (NSSize)size
{
	[[self targetItem] setSize: size];
}

- (NSView *) view
{
	return [[self targetItem] view];
}

- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path
{
	return [[self layoutContext] itemAtIndexPath: path];
}

- (ETLayoutItem *) itemAtPath: (NSString *)path
{
	return [[self layoutContext] itemAtPath: path];
}

- (float) itemScaleFactor
{
	return [[self targetItem] itemScaleFactor];
}

- (NSSize) visibleContentSize
{
	return [[self targetItem] contentSize];
}

- (void) setContentSize: (NSSize)size;
{
	[[self targetItem] setContentSize: size];
}

- (BOOL) isScrollViewShown
{
	return [[self targetItem] isScrollViewShown];
}

@end
