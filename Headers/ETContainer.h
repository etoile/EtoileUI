/*
	ETContainer.h
	
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
#import <EtoileFoundation/ETCollection.h>
#import <EtoileUI/ETView.h>
#import <EtoileUI/ETLayout.h>

@class ETLayoutItem, ETLayout, ETLayer, ETLayoutItemGroup, ETSelection, 
	ETPickboard, ETEvent, ETDecoratorItem;

extern NSString *ETLayoutItemPboardType;

@interface ETContainer : ETView
{
	NSView *_layoutView;
	
	float _itemScale;

	/* Insertion indicator to erase on next mouse move event in a drag */
	NSRect _prevInsertionIndicatorRect; 
}

- (id) initWithLayoutView: (NSView *)layoutView;

- (id) layoutItem;

- (id) deepCopy;

/* Basic Accessors */

- (NSView *) layoutView;
- (void) setLayoutView: (NSView *)view;

/* Groups and Stacks */

- (IBAction) stack: (id)sender;

/* Item scaling */

- (float) itemScaleFactor;
- (void) setItemScaleFactor: (float)factor;

@end

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

@interface ETContainer (Deprecated)

- (NSString *) representedPath;
- (void) setRepresentedPath: (NSString *)path;
- (id) source;
- (void) setSource: (id)source;
- (id) delegate;
- (void) setDelegate: (id)delegate;

/* Inspecting */

- (IBAction) inspect: (id)sender;
- (IBAction) inspectSelection: (id)sender;

/* Layout */

- (BOOL) isAutolayout;
- (void) setAutolayout: (BOOL)flag;
- (BOOL) canUpdateLayout;
- (void) updateLayout;
- (void) reloadAndUpdateLayout;

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;

/* Layout Item Tree */

- (void) addItem: (ETLayoutItem *)item;
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtIndex: (int)index;
- (int) indexOfItem: (ETLayoutItem *)item;
- (BOOL) containsItem: (ETLayoutItem *)item;
- (int) numberOfItems;
- (NSArray *) items;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;

/* Selection */

- (NSArray *) selectedItemsInLayout;
- (NSArray *) selectionIndexPaths;
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;
- (void) setSelectionIndexes: (NSIndexSet *)selection;
- (NSMutableIndexSet *) selectionIndexes;
- (void) setSelectionIndex: (unsigned int)index;
- (unsigned int) selectionIndex;

- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection: (BOOL)multiple;
- (BOOL) allowsEmptySelection;
- (void) setAllowsEmptySelection: (BOOL)empty;

/* Scrolling */

- (BOOL) hasVerticalScroller;
- (void) setHasVerticalScroller: (BOOL)scroll;
- (BOOL) hasHorizontalScroller;
- (void) setHasHorizontalScroller: (BOOL)scroll;
- (NSScrollView *) scrollView;
- (BOOL) isScrollViewShown;

/* Actions */

- (void) setTarget: (id)target;
- (id) target;
- (void) setDoubleAction: (SEL)selector;
- (SEL) doubleAction;
- (ETLayoutItem *) doubleClickedItem;
- (BOOL) isHitTestEnabled;
- (void) setEnablesHitTest: (BOOL)hit;

@end
