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

#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/ETLineLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCollection.h>
#import <EtoileUI/GNUstep.h>

#define DEFAULT_FRAME NSMakeRect(0, 0, 50, 50)

@interface ETLayoutItem (SubclassVisibility)
- (void) setDisplayView: (ETView *)view;
@end

@interface ETLayoutItemGroup (ETSource)
- (ETContainer *) container;
- (BOOL) isReloading;
- (NSArray *) itemsFromSource;
- (NSArray *) itemsFromFlatSource;
- (NSArray *) itemsFromTreeSource;
@end

@interface ETContainer (PackageVisibility)
- (int) checkSourceProtocolConformance;
- (void) syncDisplayViewWithContainer;
@end

@interface ETLayoutItemGroup (Private)
- (void) collectSelectionIndexPaths: (NSMutableArray *)indexPaths;
- (void) applySelectionIndexPaths: (NSMutableArray *)indexPaths;
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

/** Designated initializer */
- (id) initWithLayoutItems: (NSArray *)layoutItems view: (NSView *)view value: (id)value representedObject: (id)repObject
{
    self = [super initWithView: view value: value representedObject: repObject];
    
    if (self != nil)
    {
		_layoutItems = [[NSMutableArray alloc] init];
		if (layoutItems != nil)
			[self addItems: layoutItems];
		_layout = nil;
		[self setStackedItemLayout: AUTORELEASE([[ETFlowLayout alloc] init])];
		[self setUnstackedItemLayout: AUTORELEASE([[ETLineLayout alloc] init])];
		_isStack = NO;
		_autolayout = YES;
		_usesLayoutBasedFrame = NO;
    }
    
    return self;
}

/* Overriden ETLayoutItem designated initializer */
- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	return [self initWithLayoutItems: nil view: view value: value representedObject: repObject];
}

- (id) initWithLayoutItems: (NSArray *)layoutItems view: (NSView *)view
{
	return [self initWithLayoutItems: layoutItems view: view value: nil representedObject: nil];
}

- (id) init
{
	return [self initWithLayoutItems: nil view: nil];
}

- (void) dealloc
{
	DESTROY(_layout);
	DESTROY(_stackedLayout);
	DESTROY(_unstackedLayout);
	DESTROY(_layoutItems);
	
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
	ETLayoutItemGroup *item = (ETLayoutItemGroup *)[(id)super copyWithZone: zone];
	
	item->_layoutItems = [[NSMutableArray alloc] init];
	
	// NOTE: Layout objects must be copied because they support only one layout 
	// context. If you share a layout like that: 
	// [item setLayout: [self layout]];
	// -[ETLayoutItemGroup setLayout:] will set the item copy as the layout 
	// context replacing the current value of -[[self layout] layoutContext].
	// This latter value is precisely self.
	/*[item setLayout: [[self layout] layoutPrototype]];
	[item setStackedItemLayout: [[self stackedItemLayout] layoutPrototype]];
	[item setUnstackedItemLayout: [[self unstackedItemLayout] layoutPrototype]];*/
	item->_isStack = [self isStack];
	item->_autolayout = [self isAutolayout];
	item->_usesLayoutBasedFrame = [self usesLayoutBasedFrame];
			
	return item;
}

- (BOOL) isGroup
{
	return YES;
}

- (BOOL) isContainer
{
	return [[self view] isKindOfClass: [ETContainer class]];
}

- (ETContainer *) ancestorContainerProvidingRepresentedPath
{
	if ([self isContainer] && [self representedPathBase] != nil
	 && [[self representedPathBase] isEqual: @""] == NO)
	{
		return (ETContainer *)[self view];
	}
	else
	{
		return [[self parentLayoutItem] ancestorContainerProvidingRepresentedPath];
	}
}

/* Overriden method */
/*- (void) setDisplayView: (ETView *)view
{

}*/

/** Returns a normal path relative to the receiver by translating index path 
	into a layout item sequence and concatenating the names of all layout items 
	in the sequence. Each index in the index path references a child item by 
	its index in the parent layout item. 
	Resulting path uses '/' as path separator and always begins by '/'. If an 
	item has no name (-name returns nil or an empty string), its index is used 
	instead of the name as a path component.
	For index path 3.4.8.0, a valid translation would be:
	      3     .4 .8   .0
	/BlackCircle/4/Tulip/Zone
	Returns '/' if indexPath is nil or empty. */
- (NSString *) pathForIndexPath: (NSIndexPath *)indexPath
{
	NSString *path = @"/";
	ETLayoutItem *item = self;
	unsigned int index = NSNotFound;
	
	for (unsigned int i = 0; i < [indexPath length]; i++)
	{
		index = [indexPath indexAtPosition: i];
		
		if (index == NSNotFound)
			return nil;

		NSAssert2([item isKindOfClass: [ETLayoutItemGroup class]], @"Item %@ "
			@"must be layout item group to resolve the index path %@", 
			item, indexPath);
		NSAssert3(index < [[(ETLayoutItemGroup *)item items] count], @"Index "
			@"%d in path %@ position %d must be inferior to children item "
			@"number", index + 1, indexPath, i);
			
		item = [(ETLayoutItemGroup *)item itemAtIndex: index];
		if ([item name] != nil && [item isEqual: @""] == NO)
		{
			path = [path stringByAppendingPathComponent: [item name]];
		}
		else
		{
			path = [path stringByAppendingPathComponent: 
				[NSString stringWithFormat: @"%d", index]];	
		}
	}
	
	return path;
}

/** Returns an index path relative to the receiver by translating normal path 
	into a layout item sequence and pushing parent relative index of each 
	layout item in the sequence into an index path. Each index in the index 
	path references a child item by its index in the parent layout item. 
	Resulting path uses internally '.' as path seperator and internally always 
	begins by an index number and not a path seperator. 
	For the translation, empty path component or component made of path 
	separator '/' are skipped in path parameter.
	For index path /BlackCircle/4/Tulip/Zone, a valid translation would be:
	/BlackCircle/4/Tulip/Zone
	      3     .4 .8   .0
	Take note 3.5.8.0 could be a valid translation too because a name could be 
	a number which is unrelated to the item index used by its parent layout 
	item to reference it. */
- (NSIndexPath *) indexPathForPath: (NSString *)path
{
	NSIndexPath *indexPath = AUTORELEASE([[NSIndexPath alloc] init]);
	NSArray *pathComponents = [path pathComponents];
	NSString *pathComp = nil;
	ETLayoutItem *item = self;
	int index = -1;
		
	for (int position = 0; position < [pathComponents count]; position++)
	{
		pathComp = [pathComponents objectAtIndex: position];
	
		if ([pathComp isEqual: @"/"] || [pathComp isEqual: @""])
			continue;

		if ([item isKindOfClass: [ETLayoutItemGroup class]] == NO)
		{
			/* path is invalid */
			indexPath = nil;
			break;
		}
		item = [(ETLayoutItemGroup *)item itemAtPath: pathComp];
		
		/* If no item can be found by interpreting pathComp as an identifier, 
		   try to interpret pathComp as a number */
		if (item == nil)
		{
			index = [pathComp intValue];
			/* -intValue returns 0 when no numeric value is present to be 
			   converted */
			if (index == 0 && [pathComp isEqual: @"0"] == NO)
			{
				/* path is invalid */
				indexPath = nil;
				break;
			}
			
			/* Verify the index truly references a child item */
			if (index >= [[(ETLayoutItemGroup *)item items] count])
			{
				/* path is invalid */
				indexPath = nil;
				break;			
			}
			item = [(ETLayoutItemGroup *)item itemAtIndex: index];
		}
		else
		{
			index = [[item parentLayoutItem] indexOfItem: item];
		}
		
		/*NSAssert1(index == 0 && [pathComp isEqual: @"0"] == NO,
			@"Path components must be indexes for path %@", path);
		NSAssert2([item isKindOfClass: [ETLayoutItemGroup class]], @"Item %@ "
			@"must be layout item group to resolve the index path %@", 
			item, indexPath);
		NSAssert3(index < [[(ETLayoutItemGroup *)item items] count], @"Index "
			@"%d in path %@ position %d must be inferior to children item "
			@"number", index + 1, position, path);*/
		
		indexPath = [indexPath indexPathByAddingIndex: index];
	}	
	
	return indexPath;
}

/** Returns the layout item child identified by the index path paremeter 
	interpreted as relative to the receiver. */
- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path
{
	int length = [path length];
	ETLayoutItem *item = self;
	
	for (unsigned int i = 0; i < length; i++)
	{
		if ([item isKindOfClass: [ETLayoutItemGroup class]])
		{		
			item = [(ETLayoutItemGroup *)item itemAtIndex: [path indexAtPosition: i]];
		}
		else
		{
			item = nil;
			break;
		}
	}
	
	return item;
}

/** Returns the layout item child identified by the path paremeter interpreted 
	as relative to the receiver. 
	Whether the path begins by '/' or not doesn't modify the result. */
- (ETLayoutItem *) itemAtPath: (NSString *)path
{
	NSArray *pathComponents = [path pathComponents];
	NSEnumerator *e = [pathComponents objectEnumerator];
	NSString *pathComp = nil;
	ETLayoutItem *item = self;
	
	while ((pathComp = [e nextObject]) != nil)
	{
		if (pathComp == nil || [pathComp isEqual: @"/"] || [pathComp isEqual: @""])
			continue;
	
		if ([item isKindOfClass: [ETLayoutItemGroup class]])
		{
			item = [[(ETLayoutItemGroup *)item items] firstObjectMatchingValue: pathComp forKey: @"name"];
		}
		else
		{
			item = nil;
			break;
		}
	}
	
	return item;
}

- (NSString *) representedPathBase
{
	NSString *pathBase = nil;
	
	if ([self isContainer])
		pathBase = [(ETContainer *)[self view] representedPath];
		
	return pathBase;
}

/* Layout Item Tree */

/** Returns existing subviews of the receiver as layout items. 
	First checks whether the receiver responds to -layoutItem and in such case 
	doesn't already include child items for these subviews. 
	If no, either the subview is an ETView or an NSView 
	instance. When the subview is NSView-based, a new layout item is 
	instantiated by calling +layoutItemWithView: with subview as parameter. 
	Then the new item is automatically inserted as a child item in the layout 
	item representing the receiver. If the subview is ETView-based, the item
	reprensenting the subview is immediately inserted in the receiver item. */
- (NSArray *) itemsWithSubviewsOfView: (NSView *)view
{
	// FIXME: Implement
	return nil;
}

// FIXME: Move layout item collection from ETContainer to ETLayoutItemGroup
- (void) addItem: (ETLayoutItem *)item
{
	//NSLog(@"Add item in %@", self);
	
	if ([_layoutItems containsObject: item])
	{
		ETLog(@"WARNING: Trying to add item %@ to the item group %@ it "
			@"already belongs to", item, self);
		return;
	}
		
	RETAIN(item);
	if ([item parentLayoutItem] != nil)
		[[item parentLayoutItem] removeItem: item];
	[item setParentLayoutItem: self];
	RELEASE(item);
	[_layoutItems addObject: item];
	if ([self canUpdateLayout])
		[self updateLayout];
}

- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index
{
	//NSLog(@"Insert item in %@", self);
	
	if ([_layoutItems containsObject: item])
	{
		ETLog(@"WARNING: Trying to insert item %@ in the item group %@ it "
			@"already belongs to", item, self);
		return;
	}
	
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
	
	NSLog(@"Remove items in %@", self);
	
	while ((layoutItem = [e nextObject]) != nil)
	{
		[self removeItem: layoutItem];
	}
}

- (void) removeAllItems
{
	NSLog(@"Remove all items in %@", self);
	
	// FIXME: [_selection removeAllIndexes];
	[_layoutItems makeObjectsPerformSelector: @selector(setParentLayoutItem:) withObject: nil];
	[_layoutItems removeAllObjects];
	if ([self canUpdateLayout])
		[self updateLayout];
}

// FIXME: (id) parameter rather than (ETLayoutItem *) turns off compiler 
// conflicts with menu item protocol which also implements this method. 
// Fix compiler.
- (int) indexOfItem: (id)item
{
	return [_layoutItems indexOfObject: item];
}

- (NSArray *) items
{
	return [NSArray arrayWithArray: _layoutItems];
}

- (void) reload
{
	_reloading = YES;
	
	ETContainer *container = [self ancestorContainerProvidingRepresentedPath];

	/* Retrieve layout items provided by source */
	if (container != nil && [container source] != nil)
	{
		NSArray *itemsFromSource = [self itemsFromSource];
		[self removeAllItems];
		[self addItems: itemsFromSource];
	}
	else
	{
		ETLog(@"Impossible to reload %@ because the layout item miss either "
			@"a container or a source", self);
	}
	
	_reloading = NO;
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

	//ETLog(@"Modify layout from %@ to %@ in %@", _layout, layout, self);
	
	BOOL wasAutolayoutEnabled = [self isAutolayout];
	
	/* Disable autolayout to avoid spurious updates triggered by stuff like
	   view/container frame modification on layout view insertion */
	[self setAutolayout: NO];
	
	[_layout setLayoutContext: nil];
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	// NOTE: Be careful of layout objects which can share a common class but 
	// all differs by their unique display view prototype.
	// May be we should move it into -[layout setContainer:]...
	// Triggers scroll view display which triggers layout render in turn to 
	// compute the content size
	if ([self isContainer])
		[(ETContainer *)[self displayView] setDisplayView: nil]; 
	ASSIGN(_layout, layout);
	[layout setLayoutContext: self];
	
	/* if ([_layout representedItem] != nil)
		[[_layoutItem setDecoratorItem: self]; */

	// FIXME: We should move code to set display view when necessary here. By
	// calling -setDisplayView: [_container layoutView] we wouldn't
	// need anymore to call -syncDisplayViewWithContainer here.
	// All display view set up code is currently in -renderWithLayoutItems:
	// of AppKit-based layouts. Part of this code should be put inside 
	// overidden -layoutView method in each ETLayout suclasses.
	if ([self isContainer])
		[(ETContainer *)[self displayView] syncDisplayViewWithContainer];
	
	[self setAutolayout: wasAutolayoutEnabled];
	if ([self canUpdateLayout])
		[self updateLayout];
}

- (void) reloadAndUpdateLayout
{
	[self reload];
	[self updateLayout];
}

- (void) updateLayout
{
	if ([self layout] == nil)
		return;
	
	/* Update layout of descendant items before all because our own layout 
	   depends on the layout of the descendant items. Layout update may modify
	   number and frame of descendant items, thereby producing different layout
	   conditions higher in the hierarchy (like ourself). */
	if ([[self items] count] > 0)
		[[self items] makeObjectsPerformSelector: @selector(updateLayout)];
	
	/* Delegate layout rendering to custom layout object */
	[[self layout] render];
	
	[[self closestAncestorContainer] setNeedsDisplay: YES];
	// FIXME: Redisplay closestAncestorContainer with our rect
	/*ETContainer *closestContainer = [self closestAncestorContainer];
	NSRect closestViewInsideRect = [closestContainer frame];
	NSRect dirtyRect = [self frame];
	
	closestViewInsideRect.origin = NSZeroPoint;
	if ([self displayView] != nil)
	{
		dirtyRect = [[self displayView] convertRect: dirtyRect toView: closestContainer];
	}
	dirtyRect = NSIntersectionRect(dirtyRect, closestViewInsideRect);
	[closestContainer setNeedsDisplayInRect: dirtyRect];*/
}

- (BOOL) canUpdateLayout
{
	return [self isAutolayout] && ![self isReloading] && ![[self layout] isRendering];
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

- (NSArray *) visibleItems
{
	ETContainer *container = nil;
	NSMutableArray *visibleItems = [NSMutableArray array];
	NSEnumerator  *e = [[self items] objectEnumerator];
	ETLayoutItem *item = nil;
	
	if ([self isContainer])
		container = (ETContainer *)[self view];
	
	while ((item = [e nextObject]) != nil)
	{
		if ([item isVisible])
			[visibleItems addObject: item];
	}
	
	return visibleItems;
}

// FIXME: Make a bottom top traversal to find the first view which can be used 
// as superview for the visible layout item views. Actually this isn't needed
// or supported because all ETLayoutItemGroup instances must embed a container.
// This last point is going to become purely optional.
- (void) setVisibleItems: (NSArray *)visibleItems
{
	ETContainer *container = nil;
	NSEnumerator  *e = [[self items] objectEnumerator];
	ETLayoutItem *item = nil;
	
	if ([self isContainer])
		container = (ETContainer *)[self view];
	
	while ((item = [e nextObject]) != nil)
	{
		if ([visibleItems containsObject: item])
		{
			[item setVisible: YES];
			if (container != nil && [[container subviews] containsObject: [item displayView]] == NO)
			{
				[container addSubview: [item displayView]];
				//NSLog(@"Inserted view at %@", NSStringFromRect([[item displayView] frame]));
			}
		}
		else
		{
			[item setVisible: NO];
			if (container != nil && [[container subviews] containsObject: [item displayView]])
			{
				[[item displayView] removeFromSuperview];
				//NSLog(@"Removed view at %@", NSStringFromRect([[item displayView] frame]));
			}
		}
	}
}

/* Grouping */

- (ETLayoutItemGroup *) makeGroupWithItems: (NSArray *)items
{
	ETLayoutItemGroup *itemGroup = nil;
	ETLayoutItemGroup *prevParent = nil;
	int firstItemIndex = NSNotFound;
	
	if (items != nil && [items count] > 0)
	{
		NSEnumerator *e = [[self items] objectEnumerator];
		ETLayoutItem *item = [e nextObject];
		
		prevParent = [item parentLayoutItem];
		firstItemIndex = [prevParent indexOfItem: item];
		
		/* Try to find a common parent shared by all items */
		while ((item = [e nextObject]) != nil)
		{
			if ([[item parentLayoutItem] isEqual: prevParent] == NO)
			{
				prevParent = nil;
				break;
			}
		}
	}
		
	/* Will reparent each layout item to itemGroup */
	itemGroup = [ETLayoutItemGroup layoutItemGroupWithLayoutItems: items];
	/* When a parent shared by all items exists, inserts new item group where
	   its first item was previously located */
	if (prevParent != nil)
		[prevParent insertItem: itemGroup atIndex: firstItemIndex];
	
	return itemGroup;
}

/** Dismantles the receiver layout item group. If all items owned by the item */
- (NSArray *) unmakeGroup
{
	ETLayoutItemGroup *parent = [self parentLayoutItem];
	NSArray *items = [self items];
	//int itemGroupIndex = [parent indexOfItem: self];
	
	RETAIN(self);
	[parent removeItem: self];
	/* Delay release the receiver until we fully step out of receiver's 
	   instance methods (like this method). */
	AUTORELEASE(self);

	// FIXME: Implement -insertItems:atIndex:
	//[parent insertItems: items atIndex: itemGroupIndex];		
	
	return items;
}

/* Stacking */

+ (NSSize) stackSize
{
	return NSMakeSize(200, 200);
}

- (ETLayout *) stackedItemLayout
{
	return _stackedLayout;
}

- (void) setStackedItemLayout: (ETLayout *)layout
{
	ASSIGN(_stackedLayout, layout);
}

- (ETLayout *) unstackedItemLayout
{
	return _unstackedLayout;
}

- (void) setUnstackedItemLayout: (ETLayout *)layout
{
	ASSIGN(_unstackedLayout, layout);
}

- (void) setIsStack: (BOOL)flag
{
	if (_isStack == NO)
	{
		if ([[self view] isKindOfClass: [ETContainer class]] == NO)
		{
			/*NSRect stackFrame = ETMakeRect(NSZeroPoint, [ETLayoutItemGroup stackSize]);
			ETContainer *container = [[ETContainer alloc] 
				initWithFrame: stackFrame layoutItem: self];*/
			// FIXME: Insert the container on the fly
		}
		[[self container] setItemScaleFactor: 0.7];
		[self setSize: [ETLayoutItemGroup stackSize]];
	}
		
	_isStack = flag;
}

- (BOOL) isStack
{
	return _isStack;
}

- (BOOL) isStacked
{
	return [self isStack] && [[self layout] isEqual: [self stackedItemLayout]];
}

- (void) stack
{
	/* Turn item group into stack if necessary */
	[self setIsStack: YES];
	[self reload];
	[self setLayout: [self stackedItemLayout]];
}

- (void) unstack
{
	/* Turn item group into stack if necessary */
	[self setIsStack: YES];
	[self reload];
	[self setLayout: [self unstackedItemLayout]];
}

/* Selection */

- (void) collectSelectionIndexPaths: (NSMutableArray *)indexPaths
{
	NSEnumerator *e = [[self items] objectEnumerator];
	id item = nil;
		
	while ((item = [e nextObject]) != nil)
	{
		if ([item isSelected])
			[indexPaths addObject: [item indexPath]];
		if ([item isGroup])
			[item collectSelectionIndexPaths: indexPaths];
	}
}

- (NSArray *) selectionIndexPaths
{
	NSMutableArray *indexPaths = [NSMutableArray array];
	
	[self collectSelectionIndexPaths: indexPaths];
	
	return indexPaths;
}

- (void) applySelectionIndexPaths: (NSMutableArray *)indexPaths
{
	NSEnumerator *e = [[self items] objectEnumerator];
	id item = nil;
		
	while ((item = [e nextObject]) != nil)
	{
		NSIndexPath *itemIndexPath = [item indexPath];
		if ([indexPaths containsObject: itemIndexPath])
		{
			[item setSelected: YES];
			[indexPaths removeObject: itemIndexPath];
		}
		else
		{
			[item setSelected: NO];
		}
		if ([item isGroup])
			[item applySelectionIndexPaths: indexPaths];
	}
}

- (void) setSelectionIndexPaths: (NSArray *)indexPaths
{
	[self applySelectionIndexPaths: [NSMutableArray arrayWithArray: indexPaths]];
}

/* Collection Protocol */

- (id) content
{
	return [self items];
}

- (NSArray *) contentArray
{
	return [self items];
}

/* ETLayoutingContext */

- (float) itemScaleFactor
{
	if ([[self view] respondsToSelector: @selector(itemScaleFactor)])
	{
		return	[(id)[self view] itemScaleFactor];
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ doesn't respond to -itemScaleFactor", self);
		return 0;
	}
}

/* ETLayoutingContext scroll view related methods */

/* -documentVisibleRect size */
- (NSSize) visibleContentSize
{
	if ([[self view] respondsToSelector: @selector(contentSize)])
	{
		return	[(id)[self view] contentSize];
	}
	else if ([[self view] respondsToSelector: @selector(scrollView)]
	 && [[(id)[self view] scrollView] respondsToSelector: @selector(contentSize)])
	{
		return [[(id)[self view] scrollView] contentSize];
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ doesn't respond to -contentSize", self);
		return NSZeroSize;
	}
}

- (BOOL) isScrollViewShown
{
	if ([[self view] respondsToSelector: @selector(isScrollViewShown)])
	{
		return	[(id)[self view] isScrollViewShown];
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ doesn't respond to -isScrollViewShown", self);
		return NO;
	}
}

		/* The frame may be patched by the display view, that's why 
		   _frame = rect would be incorrect. When the display view is embedded
		   inside a scroll view, the display view is the document view of the
		   scroll view and must fit perfectly into it.
		   For more details, see -[ETContainer setFrameSize:] */
- (void) setContentSize: (NSSize)size
{
	if ([[self view] respondsToSelector: @selector(setContentSize:)])
	{
		[(id)[self view] setContentSize: size];
	}
	else if ([[self view] respondsToSelector: @selector(scrollView)]
	 && [[(id)[self view] scrollView] isKindOfClass: [NSScrollView class]])
	{
		[[[(id)[self view] scrollView] documentView] setFrameSize: size];		
	}
	else
	{
		ETLog(@"WARNING: Layout item %@ doesn't respond to -setContentSize:", self);
	}
}

/* Dummy methods to shut down compiler warning about ETLayoutingContext not 
   fully implemented */

- (NSSize) size
{
	return [super size];
}

- (void) setSize: (NSSize)size
{
	[super setSize: size];
}

- (NSView *) view
{
	return [super view];
}

@end

/* Helper methods to retrieve layout items provided by data sources */

@implementation ETLayoutItemGroup (ETSource)

- (ETContainer *) container
{
	if ([self isContainer])
	{
		return (ETContainer *)[self view];
	}
	else
	{
		return nil;
	}
}

- (BOOL) isReloading
{
	return _reloading;
}

- (NSArray *) itemsFromSource
{
	ETContainer *container = [self ancestorContainerProvidingRepresentedPath];

	switch ([container checkSourceProtocolConformance])
	{
		case 1:
			//NSLog(@"Will -reloadFromFlatSource");
			return [self itemsFromFlatSource];
			break;
		case 2:
			//NSLog(@"Will -reloadFromTreeSource");
			return [self itemsFromTreeSource];
			break;
		default:
			NSLog(@"WARNING: source protocol is incorrectly supported by %@.", [[self container] source]);
	}
	
	return nil;
}

- (NSArray *) itemsFromFlatSource
{
	NSMutableArray *itemsFromSource = [NSMutableArray array];
	ETLayoutItem *layoutItem = nil;
	ETContainer *container = [self ancestorContainerProvidingRepresentedPath];
	int nbOfItems = [[container source] numberOfItemsInContainer: container];
	
	for (int i = 0; i < nbOfItems; i++)
	{
		layoutItem = [[container source] container: container itemAtIndex: i];
		[itemsFromSource addObject: layoutItem];
	}
	
	return itemsFromSource;
}

- (NSArray *) itemsFromTreeSource
{
	NSMutableArray *itemsFromSource = [NSMutableArray array];
	ETLayoutItem *layoutItem = nil;
	ETContainer *baseContainer = [self ancestorContainerProvidingRepresentedPath];
	// NOTE: [self indexPathFromItem: [container layoutItem]] is equal to [[container layoutItem] indexPathFortem: self]
	NSIndexPath *indexPath = [self indexPathFromItem: [baseContainer layoutItem]];
	int nbOfItems = 0;
	
	//NSLog(@"-itemsFromTreeSource in %@", self);
	
	/* Request number of items to the source by passing receiver index path 
	   expressed in a way relative to the base container */
	nbOfItems = [[baseContainer source] container: baseContainer numberOfItemsAtPath: indexPath];

	for (int i = 0; i < nbOfItems; i++)
	{
		NSIndexPath *indexSubpath = nil;
		
		indexSubpath = [indexPath indexPathByAddingIndex: i];
		/* Request item to the source by passing item index path expressed in a
		   way relative to the base container */
		layoutItem = [[baseContainer source] container: baseContainer itemAtPath: indexSubpath];
		//ETLog(@"Retrieved item %@ known by path %@", layoutItem, indexSubpath);
		[itemsFromSource addObject: layoutItem];
	}
	
	return itemsFromSource;
}

@end
