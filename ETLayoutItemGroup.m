/*  <title>ETLayoutItemGroup</title>

	ETLayoutItemGroup.m
	
	<abstract>Description forthcoming.</abstract>
 
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

#import <EtoileUI/ETViewLayout.h>

#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/GNUstep.h>

#define DEFAULT_FRAME NSMakeRect(0, 0, 50, 50)

@interface ETLayoutItem (SubclassVisibility)
- (void) setDisplayView: (ETView *)view;
@end


@implementation ETLayoutItemGroup

+ (ETLayoutItemGroup *) layoutItemGroup
{
	return AUTORELEASE([[self alloc] init]);
}

+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItem: (ETLayoutItem *)item
{
	return [ETLayoutItemGroup layoutItemGroupWithLayoutItem: [NSArray arrayWithObject: item]];
}

+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItems: (NSArray *)items
{
	return AUTORELEASE([[self alloc] initWithLayoutItems: items view: nil]);
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view
{
	return AUTORELEASE([[self alloc] initWithLayoutItems: nil view: view]);
}

/** Designated initialize */
- (id) initWithLayoutItems: (NSArray *)layoutItems view: (NSView *)view
{
	ETContainer *containerAsLayoutItemGroup = 
		[[ETContainer alloc] initWithFrame: DEFAULT_FRAME];
		
	AUTORELEASE(containerAsLayoutItemGroup);
    self = (ETLayoutItemGroup *)[super initWithView: (NSView *)containerAsLayoutItemGroup];
    
    if (self != nil)
    {
		if ([[self view] isKindOfClass: [ETContainer class]] == NO)
		{
			if ([self view] == nil)
			{
				NSLog(@"WARNING: New %@ must have a container as view and not nil", self);
			}
			else
			{
				NSLog(@"WARNING: New %@ must embed a container and not another view %@", self, [self view]);
			}
			return nil;
		}
		
		if (layoutItems != nil)
			[(ETContainer *)[self view] addItems: layoutItems];
		if (view != nil)
		{
			[view removeFromSuperview]; // Note sure we should pay heed to such case
			[view setFrame: [[self view] frame]];
			[(ETContainer *)[self view] addSubview: view];
		}
    }
    
    return self;
}

- (id) init
{
	return [self initWithLayoutItems: nil view: nil];
}

- (void) dealloc
{
	DESTROY(_parentLayoutItem);
	DESTROY(_layout);
	DESTROY(_layoutItems);
	
	[super dealloc];
}

- (BOOL) isContainer
{
	return [[self view] isKindOfClass: [ETContainer class]];
}

// FIXME: Move layout item collection from ETContainer to ETLayoutItemGroup
- (void) addItem: (ETLayoutItem *)item
{
	//NSLog(@"Add item in %@", self);
	[item setParentLayoutItem: self];
	[_layoutItems addObject: item];
	if ([self canUpdateLayout])
		[self updateLayout];
}

- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	//NSLog(@"Insert item in %@", self);
	
	//FIXME: NSMutableIndexSet *indexes = [self selectionIndexes];
	
	/* In this example, 1 means selected and 0 unselected.
       () represents old item index shifted by insertion
	   
       Item index      0   1   2   3   4
       Item selected   0   1   0   1   0
   
       When you call shiftIndexesStartingAtIndex: 2 by: 1, you get:
       Item index      0   1   2   3   4
       Item selected   0   1   0   0   1  0
       Now by inserting an item at 2:
       Item index      0   1   2  (2) (3) (4)
       Item selected   0   1   0   0   1   0
		   
       That's precisely the selections state we expect once item at index 2
       has been removed. */
	
	[item setParentLayoutItem: nil];
	[_layoutItems insertObject: item atIndex: index];
	//[indexes shiftIndexesStartingAtIndex: index by: 1];
	//[self setSelectionIndexes: indexes];
	if ([self canUpdateLayout])
		[self updateLayout];
}

- (void) removeItem: (ETLayoutItem *)item
{
	//NSLog(@"Remove item in %@", self);

// FIXME
#if 0	
	NSMutableIndexSet *indexes = [self selectionIndexes];
	int removedIndex = [self indexOfItem: item];
	
	if ([indexes containsIndex: removedIndex])
	{
		/* In this example, 1 means selected and 0 unselected.
		
		   Item index      0   1   2   3   4
		   Item selected   0   1   0   1   0
		   
		   When you call shiftIndexesStartingAtIndex: 3 by: -1, you get:
		   Item index      0   1   2   3   4
		   Item selected   0   1   1   0   0
		   Now by removing item 2:
		   Item index      0   1   3   4
		   Item selected   0   1   1   0   0
		   		   
		   That's precisely the selections state we expect once item at index 2
		   has been removed. */
		[indexes shiftIndexesStartingAtIndex: removedIndex + 1 by: -1];
		
		/* Verify basic shitfing errors before really updating the selection */
		if ([[self selectionIndexes] containsIndex: removedIndex + 1])
		{
			NSAssert([indexes containsIndex: removedIndex], 
				@"Item at the index of the removal must remain selected because it was previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex - 1])
		{
			NSAssert([indexes containsIndex: removedIndex - 1], 
				@"Item before the index of the removal must remain selected because it was previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex + 1] == NO)
		{
			NSAssert([indexes containsIndex: removedIndex] == NO, 
				@"Item at the index of the removal must not be selected because it wasn't previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex - 1] == NO)
		{
			NSAssert([indexes containsIndex: removedIndex - 1] == NO, 
				@"Item before the index of the removal must not be selected because it wasn't previously");
		}
		[self setSelectionIndexes: indexes];
	}
#endif
	[item setParentLayoutItem: nil];
	[_layoutItems removeObject: item];
	if ([self canUpdateLayout])
		[self updateLayout];
}

- (void) removeItemAtIndex: (int)index
{
	ETLayoutItem *item = [_layoutItems objectAtIndex: index];
	[self removeItem: item];
}

- (ETLayoutItem *) itemAtIndex: (int)index
{
	return [_layoutItems objectAtIndex: index];
}

- (void) addItems: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *layoutItem = nil;
	
	//NSLog(@"Add items in %@", self);
	
	while ((layoutItem = [e nextObject]) != nil)
	{
		[self addItem: layoutItem];
	}
}

- (void) removeItems: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *layoutItem = nil;
	
	//NSLog(@"Remove items in %@", self);
	
	while ((layoutItem = [e nextObject]) != nil)
	{
		[self removeItem: layoutItem];
	}
}

- (void) removeAllItems
{
	//NSLog(@"Remove all items in %@", self);
	
	// FIXME: [_selection removeAllIndexes];
	[_layoutItems makeObjectsPerformSelector: @selector(setParentLayoutItem:) withObject: nil];
	[_layoutItems removeAllObjects];
	if ([self canUpdateLayout])
		[self updateLayout];
}

- (int) indexOfItem: (ETLayoutItem *)item
{
	return [_layoutItems indexOfObject: item];
}

- (NSArray *) items
{
	return _layoutItems;
}

/* Layout */

- (ETLayout *) layout
{
	return _layout;
}

- (void) setLayout: (ETLayout *)layout
{
	if (_layout == layout)
		return;
	
	[_layout setLayoutContext: nil];
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	// NOTE: Be careful of layout objects which can share a common class but 
	// all differs by their unique display view prototype.
	// May be we should move it into -[layout setContainer:]...
	// Triggers scroll view display which triggers layout render in turn to 
	// compute the content size
	[self setDisplayView: nil]; 
	ASSIGN(_layout, layout);
	[layout setLayoutContext: self];

	// FIXME: We should move code to set display view when necessary here. By
	// calling -setDisplayView: [_container displayViewPrototype] we wouldn't
	// need anymore to call -syncDisplayViewWithContainer here.
	// All display view set up code is currently in -renderWithLayoutItems:
	// of AppKit-based layouts. Part of this code should be put inside 
	// overidden -displayViewPrototype method in each ETViewLayout suclasses.
	if ([self isContainer])
		[(ETContainer *)[self displayView] syncDisplayViewWithContainer];
	
	if ([self canUpdateLayout])
		[self updateLayout];
}

- (void) updateLayout
{
	/* Delegate layout rendering to custom layout object */
	[[self layout] render];
	
	[self setNeedsDisplay: YES];
}

- (BOOL) canUpdateLayout
{
	return [self isAutolayout] && ![[self layout] isRendering];
}

- (BOOL) isAutolayout
{
	return _autolayout;
}

- (void) setAutolayout: (BOOL)flag
{
	_autolayout = flag;
}

- (BOOL) usesLayoutBasedFrame
{
	return _usesLayoutBasedFrame;
}

- (void) setUsesLayoutBasedFrame: (BOOL)flag
{
	_usesLayoutBasedFrame = flag;
}

- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view 
{
	if ([self usesLayoutBasedFrame] || NSIntersectsRect(dirtyRect, [self frame]))
	{
		NSView *renderView = view;
		
		if ([self displayView] != nil)
			renderView = [self displayView];
		
		if ([[NSView focusView] isEqual: renderView] == NO)
			[renderView lockFocus];
			
		NSAffineTransform *transform = [NSAffineTransform transform];
		
		/* Modify coordinate matrix when the layout item doesn't use a view for 
		   drawing. */
		if ([self displayView] == nil)
		{
			[transform translateXBy: [self x] yBy: [self y]];
			[transform concat];
		}
		
		[[self renderer] renderLayoutItem: self];
		
		if ([self displayView] == nil)
		{
			[transform invert];
			[transform concat];
		}
			
		[view unlockFocus];
		
		/* Render child items */
		
		NSEnumerator *e = [[self items] reverseObjectEnumerator];
		ETLayoutItem *item = nil;
		NSRect newDirtyRect = NSZeroRect;
		
		if ([self displayView] != nil)
		{
			newDirtyRect = NSIntersectionRect(dirtyRect, [[self displayView] frame]);
			[view convertRect: newDirtyRect toView: [self displayView]];
		}
		
		while ((item = [e nextObject]) != nil)
		{
			[item render: inputValues dirtyRect: newDirtyRect inView: renderView];
		}
	}
}


- (NSArray *) visibleLayoutItems
{
#if 0
	ETContainer *container = (ETContainer *)[self view];
	NSMutableArray *visibleItems = [NSMutableArray array];
	NSEnumerator  *e = [[container items] objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		if ([item isVisible])
			[visibleItems addObject: item];
	}
	
	return visibleItems;
#endif
	return nil;
}

// FIXME: Make a bottom top traversal to find the first view which can be used 
// as superview for the visible layout item views. Actually this isn't needed
// or supported because all ETLayoutItemGroup instances must embed a container.
// This last point is going to become purely optional.
- (void) setVisibleLayoutItems: (NSArray *)visibleItems
{
#if 0
	ETContainer *container = (ETContainer *)[self view];
	NSEnumerator  *e = [[container items] objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		if ([visibleItems containsObject: item])
		{
			[item setVisible: YES];
			if ([[container subviews] containsObject: [item displayView]] == NO)
			{
				[container addSubview: [item displayView]];
				NSLog(@"Inserted view at %@", NSStringFromRect([[item displayView] frame]));
			}
		}
		else
		{
			[item setVisible: NO];
			if ([[container subviews] containsObject: [item displayView]])
			{
				[[item displayView] removeFromSuperview];
				NSLog(@"Removed view at %@", NSStringFromRect([[item displayView] frame]));
			}
		}
	}
#endif
}

- (NSArray *) ungroup
{
	return nil;
}

/* Stacking */

- (void) stack
{

}

- (void) unstack
{

}

@end
