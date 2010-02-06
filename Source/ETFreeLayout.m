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
unlike ETLayout.

The returned object is always an ETFreeLayout object if layoutView is nil. If a
layout view is passed in parameter, the returned layout can be any ETLayout
subclasses (see -[ETLayout initWithLayoutView:]). */
- (id) initWithLayoutView: (NSView *)layoutView
{
	self = [super initWithLayoutView: layoutView];
	
	if (self != nil)
	{
		[self setAttachedInstrument: [ETSelectTool instrument]];
		[[self attachedInstrument] setShouldProduceTranslateActions: YES];
		[self setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
		_rootItem = [[ETLayoutItemGroup alloc] init];
		[_rootItem setActionHandler: nil];
		[_rootItem setStyle: nil];
	}
	
	return self;
}

- (void) dealloc
{
	[self updateKVOForItems: [NSArray array]]; /* Release _observedItems */

	[super dealloc];
}

- (void) setUpCopyWithZone: (NSZone *)aZone original: (ETLayout *)layoutOriginal
{
	/* Only to set the parent item, we don't need to synchronize the geometry */
	[self mapRootItemIntoLayoutContext];

	/* Rebuild the handles to manipulate the item copies and not their originals */
	// TODO: May be avoid to copy the original handles in -copyWithZone:layoutContext:
	[self updateKVOForItems: [_layoutContext arrangedItems]];
	[self buildHandlesForItems: [_layoutContext arrangedItems]];
}

- (id) attachedInstrument
{
	return [super attachedInstrument];
}

- (void) didChangeAttachedInstrument: (ETInstrument *)oldInstrument 
                        toInstrument: (ETInstrument*)newInstrument
{
	NSParameterAssert(oldInstrument != newInstrument);

	/* Let the superclass tells our descendant layouts about the instrument change */
	[super didChangeAttachedInstrument: oldInstrument toInstrument: newInstrument];

	BOOL wereHandlesVisible = [self showsHandlesForInstrument: oldInstrument];
	BOOL willHandlesBeVisible = [self showsHandlesForInstrument: newInstrument];

	if (NO == wereHandlesVisible && willHandlesBeVisible)
	{
		[self showHandles];
	}
	else if (wereHandlesVisible && NO == willHandlesBeVisible)
	{
		[self hideHandles];
	}
	// else the handle visibility remains identical
}

- (BOOL) showsHandlesForInstrument: (ETInstrument *)anInstrument
{
	return [anInstrument isKindOfClass: [ETSelectTool class]];
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

	ASSIGN(_observedItems, items);

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
	if ([self showsHandlesForInstrument: [ETInstrument activeInstrument]] == NO)
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
	FOREACH(_observedItems, item, ETLayoutItem *)
	{
		if ([item isSelected])
		{
			[self showHandlesForItem: item];
		}
	}
}

- (void) hideHandles
{
	FOREACH(_observedItems, item, ETLayoutItem *)
	{
		if ([item isSelected])
		{
			[self hideHandlesForItem: item];
		}
	}
}

- (void) showHandlesForItem: (ETLayoutItem *)item
{
	ETHandleGroup *handleGroup = AUTORELEASE([[ETResizeRectangle alloc] initWithManipulatedObject: item]);
		
	[[self rootItem] addItem: handleGroup];
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
	FOREACHI([[self rootItem] items], utilityItem)
	{
		if ([utilityItem isKindOfClass: [ETHandleGroup class]] == NO)
			continue;

		if ([[utilityItem manipulatedObject] isEqual: item])
		{
			[utilityItem setNeedsDisplay: YES]; /* Propagate the damaged area upwards */
			[item setNeedsDisplay: YES];
			[[self rootItem] removeItem: utilityItem];
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
	[[self rootItem] removeAllItems];

	FOREACH(manipulatedItems, item, ETLayoutItem *)
	{
		if ([item isSelected])
		{
			ETHandleGroup *handleGroup = AUTORELEASE([[ETResizeRectangle alloc] initWithManipulatedObject: item]);
			[[self rootItem] addItem: handleGroup];
		}
	}
}

/** Recomputes new persistent frames for every layout items provided by the 
layout context, based on the rules or policy of the given layout. */
- (void) resetItemPersistentFramesWithLayout: (ETComputedLayout *)layout
{
	id layoutContext = [self layoutContext];

	RETAIN(self);
	/* The next line makes [self layoutContext] returns nil because 'layout' 
	   takes control over it with -setLayout:. */
	// FIXME: -setLayout: won't recompute every item frames, only the visible 
	// items are relayouted.
	[layoutContext setLayout: layout];

	/* Sync the persistent frames with the frames just computed by -setLayout: */
	FOREACH([layoutContext items], item, ETLayoutItem *)
	{
		[item setPersistentFrame: [item frame]];
	}

	[layoutContext setLayout: self];
	RELEASE(self);
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	[super renderWithLayoutItems: items isNewContent: isNewContent];
	if (isNewContent)
	{
		[self updateKVOForItems: items];
		[self buildHandlesForItems: items];
	}
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

// TODO: If we want to allow the source to handle the item locations manually,
// the following methods have to be added back to ETFreeLayout. Take note 
// that vectorLoc could be an NSPoint initially. The benefit of using a vector 
// would be simplify the support of a 2.5D behavior (simulating 3D with 2D 
// transforms).
// I'm not yet sure that's the best way to let the developer implement 
// positional constraint. May be this could be implemented in a 'positional 
// constraint layer/handler' that the developer sets on its ETFreeLayout 
// instance, this might be better if the contraint logic tends to be large. By 
// doing so, we could eventually provide more ready-to-use logic that simplifies 
// the developer task.
// For 2.5D or 3D, we could add more properties to ETLayoutItem in CoreAnimation 
// spirit. For example, a zPosition property and a orientationVector property. 
// Think more about that...
// -itemGroup:locationForItem: should be called in -itemAtLocation:. If no
// source exists, -itemAtLocation must run exactly as it is now and requests the 
// item location to super.
// -itemGroup:setLocation:forItem: should be called in 
// -handleDrop:forItem:layout: or similar.
// -itemGroup:acceptLocation:forItem: may be needed in 
// -handleDrag:forItem:layout: to give feedback about positional constraints to 
// the user.
#if 0
/* Overriden method to delegate it to the layout item group data source. */
- (ETVector *) itemGroup: (ETLayoutItemGroup *)itemGroup locationForItem: (ETLayoutItem *)item
{
	return [[itemGroup source] itemGroup: itemGroup locationForItem: item];
}

/* Overriden method to delegate it to the layout item group data source. */
- (void) itemGroup: (ETLayoutItemGroup *)itemGroup setLocation: (ETVector *)vectorLoc forItem: (ETLayoutItem *)item
{
	[[itemGroup source] itemGroup: itemGroup setLocation: vectorLoc forItem: item];
}
#endif
