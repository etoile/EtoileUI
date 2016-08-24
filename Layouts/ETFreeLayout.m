/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETFreeLayout.h"
#import "ETComputedLayout.h"
#import "ETGeometry.h"
#import "ETHandle.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETSelectTool.h"
#import "ETCompatibility.h"

@implementation ETFreeLayout

/** <init \> Initializes and returns a new layout without constraint on item size
unlike ETPositionalLayout.  */
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	[self setAttachedTool: [ETSelectTool toolWithObjectGraphContext: aContext]];
	[[self attachedTool] setShouldProduceTranslateActions: YES];
	[self setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	[[self layerItem] setActionHandler: nil];
	[[self layerItem] setCoverStyle: nil];
	
	return self;
}

- (void) willDiscard
{
	/* Release the observed items */
	[self updateKVOForItems: [NSArray array]];
	[super willDiscard];
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"zone--pencil.png"];
}

- (BOOL) preventsDrawingItemSelectionIndicator
{
	return YES;
}

- (id) attachedTool
{
	return [super attachedTool];
}

- (void) didChangeAttachedTool: (ETTool *)oldTool
                        toTool: (ETTool *)newTool
{
	NSParameterAssert(oldTool != newTool);

	/* Let the superclass tells our descendant layouts about the tool change */
	[super didChangeAttachedTool: oldTool toTool: newTool];

	BOOL wereHandlesVisible = [self showsHandlesForTool: oldTool];
	BOOL willHandlesBeVisible = [self showsHandlesForTool: newTool];

	if (NO == wereHandlesVisible && willHandlesBeVisible)
	{
		[self showHandles];
		_areHandlesHidden = NO;
	}
	else if (wereHandlesVisible && NO == willHandlesBeVisible)
	{
		[self hideHandles];
		_areHandlesHidden = YES;
	}
	// else the handle visibility remains identical
}

- (BOOL) showsHandlesForTool: (ETTool *)anTool
{
	return [anTool isKindOfClass: [ETSelectTool class]];
}

/* KVO */

- (void) updateKVOForItems: (NSArray *)items
{
	NSParameterAssert(nil != items);

	FOREACHI(_observedItems, oldItem)
    {
		[oldItem removeObserver: self
				  forKeyPath: kETSelectedProperty];
	}

	_observedItems = items;

	FOREACHI(items, newItem)
    {
		[newItem addObserver: self
              forKeyPath: kETSelectedProperty
                 options: NSKeyValueObservingOptionNew
				 context: NULL];
	}
}

- (void) observeValueForKeyPath: (NSString *)keyPath 
                       ofObject: (id)object 
					     change: (NSDictionary *)change 
						context: (void *)context
{
	/* If the closest attached tool among the ancestor items is not the 
	   selection tool, this implies the handles are hidden.
	   The active tool doesn't matter here. For example, it could be an arrow 
	   tool attached an inspector pane, and yet the handles must remain visible 
	   for the free layout. */
	if (_areHandlesHidden)
		return;

	BOOL selected = [[change objectForKey: NSKeyValueChangeNewKey] boolValue];
	
	if (selected)
	{
		[self showHandlesForItem: object];
	}
	else
	{
		[self hideHandlesForItem: object];
	}
}

- (void) showHandles
{
	for (ETLayoutItem *item in _observedItems)
	{
		if ([item isSelected])
		{
			[self showHandlesForItem: item];
		}
	}
}

- (void) hideHandles
{
	for (ETLayoutItem *item in _observedItems)
	{
		if ([item isSelected])
		{
			[self hideHandlesForItem: item];
		}
	}
}

- (void) showHandlesForItem: (ETLayoutItem *)item
{
	ETHandleGroup *handleGroup = [[ETResizeRectangle alloc]
		initWithManipulatedObject: item objectGraphContext: [[self layerItem] objectGraphContext]];
		
	[[self layerItem] addItem: handleGroup];
	// FIXME: Should [handleGroup display]; and display should retrieve the 
	// bounding box of the handleGroup. This bouding box would include the 
	// handles unlike the frame.
	// Finally we should use -setNeedsDisplay:
	//[[self rootItem] display];
	[handleGroup setNeedsDisplay: YES];
	[item setNeedsDisplay: YES];
}

- (void) hideHandlesForItem: (ETLayoutItem *)item
{
	FOREACHI([[self layerItem] items], utilityItem)
	{
		if ([utilityItem isKindOfClass: [ETHandleGroup class]] == NO)
			continue;

		if ([[utilityItem manipulatedObject] isEqual: item])
		{
			[utilityItem setNeedsDisplay: YES]; /* Propagate the damaged area upwards */
			[item setNeedsDisplay: YES];
			[[self layerItem] removeItem: utilityItem];
			break;
		}
	}
	// FIXME: Should [handleGroup display]; and -display should retrieve the 
	// bounding box of the handleGroup. This bouding box would include the 
	// handles unlike the frame. 
	// Finally we should use -setNeedsDisplay:
	//[[self rootItem] display];
}

- (void) buildHandlesForItems: (NSArray *)manipulatedItems
{
	[[self layerItem] removeAllItems];

	for (ETLayoutItem *item in manipulatedItems)
	{
		if ([item isSelected])
		{
			ETHandleGroup *handleGroup = [[ETResizeRectangle alloc]
				initWithManipulatedObject: item objectGraphContext: [[self layerItem] objectGraphContext]];
			[[self layerItem] addItem: handleGroup];
		}
	}
}

- (ETLayoutItemGroup *) handleGroupForItem: (ETLayoutItem *)aManipulatedItem
{
	for (ETLayoutItem *item in [self layerItem])
	{
		// TODO: Should check -isHandleGroup
		if ([item isGroup] && [(ETHandleGroup *)item manipulatedObject] == aManipulatedItem)
		{
			return (ETLayoutItemGroup *)item;
		}
	}
	return nil;
}

/** Recomputes new persistent frames for every layout items provided by the 
layout context, based on the rules or policy of the given layout. */
- (void) resetItemPersistentFramesWithLayout: (ETComputedLayout *)layout
{
	id layoutContext = [self layoutContext];

	/* The next line makes [self layoutContext] returns nil because 'layout' 
	   takes control over it with -setLayout:. */
	// FIXME: -setLayout: won't recompute every item frames, only the visible 
	// items are relayouted.
	[layoutContext setLayout: layout];
	[layoutContext updateLayoutRecursively: NO];

	/* Sync the persistent frames with the frames just computed */
	for (ETLayoutItem *item in [layoutContext items])
	{
		[item setPersistentFrame: [item frame]];
	}

	[layoutContext setLayout: self];
}

- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[super renderWithItems: items isNewContent: isNewContent];
	if (isNewContent)
	{
		[self updateKVOForItems: items];
		[self buildHandlesForItems: items];
	}
	return [self layoutSize];
}

#if 0
- (NSArray *) selectedItems
{
	// TODO: Probably returns the selected items by collecting them 
	// recursively over nested free layouts.
	return [[self layoutContext] items];
}
#endif

- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	ETLayoutItem *item = [super itemAtLocation: location];
	if (item != nil)
	{
		return item;
	}

	/* If the layout context is an ETLayoutItemGroup, (the "backdrop" of the layout)
	  return that. */
	if ([(NSObject*)[self layoutContext] isKindOfClass: [ETLayoutItemGroup class]])
	{
		return (ETLayoutItem *)[self layoutContext];
	}

	return nil;
}

@end
