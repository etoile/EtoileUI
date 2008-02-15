/*
	ETLayoutItemGroup.h
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
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
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETCollection.h>

@class ETLayout;


@interface ETLayoutItemGroup : ETLayoutItem <ETLayoutingContext, ETCollection, ETCollectionMutation>
{
	NSMutableArray *_layoutItems;
	ETLayout *_layout;
	ETLayout *_stackedLayout;
	ETLayout *_unstackedLayout;
	//NSString *_path; /* Path caching */
	BOOL _isStack;
	BOOL _autolayout;
	BOOL _usesLayoutBasedFrame;
	BOOL _reloading; /* ivar used by ETSource category */
	BOOL _shouldMutateRepresentedObject;
}

/* Factory Methods */

+ (ETLayoutItemGroup *) layoutItemGroup;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItem: (ETLayoutItem *)item;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItems: (NSArray *)items;

- (id) itemWithObject: (id)object isValue: (BOOL)isValue;

/* Initialization */

- (id) initWithLayoutItems: (NSArray *)layoutItems view: (NSView *)view;

/* Finding Container */

- (BOOL) isContainer;
- (ETContainer *) ancestorContainerProvidingRepresentedPath;

/* Traversing Layout Item Tree */

- (NSString *) pathForIndexPath: (NSIndexPath *)path;
- (NSIndexPath *) indexPathForPath: (NSString *)path;
- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path;
- (ETLayoutItem *) itemAtPath: (NSString *)path;

/*  Manipulating Layout Item Tree */

- (void) addItem: (ETLayoutItem *)item;
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtIndex: (int)index;
- (int) indexOfItem: (id)item;
- (BOOL) containsItem: (ETLayoutItem *)item;
- (int) numberOfItems;
//- (int) indexOfItem: (ETLayoutItem *)item;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;
- (NSArray *) items;
- (NSArray *) itemsIncludingRelatedDescendants;
- (NSArray *) itemsIncludingAllDescendants;

- (void) reload;

- (void) handleAttachItem: (ETLayoutItem *)item;
- (void) handleAttachViewOfItem: (ETLayoutItem *)item;
- (void) handleDetachItem: (ETLayoutItem *)item;
- (void) handleDetachViewOfItem: (ETLayoutItem *)item;

- (BOOL) shouldMutateRepresentedObject;
- (void) setShouldMutateRepresentedObject: (BOOL)flag;
- (BOOL) usesRepresentedObjectAsProvider;

/* Layout */

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;

- (void) reloadAndUpdateLayout;
- (void) updateLayout;
- (BOOL) canUpdateLayout;
// FIXME: Implement methods below
/*- (BOOL) canApplyLayout; // would replace -canUpdateLayout
- (void) applyLayout;
- (void) setNeedsLayout: (BOOL)needsLayout;*/

- (BOOL) isAutolayout;
- (void) setAutolayout: (BOOL)flag;
- (BOOL) usesLayoutBasedFrame;
- (void) setUsesLayoutBasedFrame: (BOOL)flag;

/* Layouting Context Protocol */

- (NSArray *) visibleItems;
- (void) setVisibleItems: (NSArray *)items;
- (NSSize) size;
- (void) setSize: (NSSize)size;
- (NSView *) view;
- (float) itemScaleFactor;
- (NSSize) visibleContentSize;
- (void) setContentSize: (NSSize)size;
- (BOOL) isScrollViewShown;

/* Rendering */

- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view;

/* Grouping */

- (ETLayoutItemGroup *) makeGroupWithItems: (NSArray *)items;
- (NSArray *) unmakeGroup;

/* Stacking */

- (ETLayout *) stackedItemLayout;
- (void) setStackedItemLayout: (ETLayout *)layout;
- (ETLayout *) unstackedItemLayout;
- (void) setUnstackedItemLayout: (ETLayout *)layout;

- (void) setIsStack: (BOOL)flag;
- (BOOL) isStack;
- (BOOL) isStacked;

- (void) stack;
- (void) unstack;

/* Selection */

- (NSArray *) selectionIndexPaths;
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;

- (NSArray *) selectedItems;
- (NSArray *) selectedItemsInLayout;
- (NSArray *) selectedItemsIncludingRelatedDescendants;
- (NSArray *) selectedItemsIncludingAllDescendants;

/* Collection Protocol */

- (BOOL) isOrdered;
- (BOOL) isEmpty;
- (unsigned int) count;
- (id) content;
- (NSArray *) contentArray;
- (void) addObject: (id)object;
- (void) removeObject: (id)object;

@end
