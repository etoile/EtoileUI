/*  <title>ETFreeLayout</title>

	ETFreeLayout.m
	
	<abstract>Free layout class which let the user position the layout items by 
	direct manipulation</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
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

#import <EtoileFoundation/Macros.h>
#import <EtoileUI/ETFreeLayout.h>
#import <EtoileUI/ETComputedLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

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
		[self setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	}
	
	return self;
}

/** Always returns YES since items are positioned by the user. */
- (BOOL) isPositional
{
	return YES;
}

/** Always returns NO since items are positioned by the user and not computed 
by the receiver. */
- (BOOL) isComputedLayout
{
	return NO;
}

- (void) resetItemLocationsWithLayout: (ETComputedLayout *)layout
{
	RETAIN(self);
	[[self container] setLayout: layout];
	[[self container] updateLayout];
	[[self container] setLayout: self];
	RELEASE(self);
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	/* Frame must be set to persistent frame before -resizeItems:toScale: is 
	   called by -renderWithLayoutItems:isNewContent:, otherwise the scaling 
	   is computed based on the frame computed by the last layout in use which 
	   may not be ETFreeLayout (when switching from another layout). */
	[self loadPersistentFramesForItems: items];
	
	[super renderWithLayoutItems: items isNewContent: isNewContent];
	
	// TODO: May be worth to optimize by computing set intersection of visible and unvisible layout items
	// NSLog(@"Remove views %@ of next layout items to be displayed from their superview", itemViews);
	//[[self layoutContext] setVisibleItems: [NSArray array]];
	
	[[self layoutContext] setVisibleItems: items];
}

- (void) loadPersistentFramesForItems: (NSArray *)items
{
	FOREACH(items, item, ETLayoutItem *)
	{
		// TODO: -hasLocalProperty: would be a better check. -persistentFrame 
		// will return a zero rect both when no persistentFrame exists and when
		// it is explicitly set to a zero rect. Only -valueForProperty: or 
		// -hasLocalProperty: can really tell whether the property exists or not.
		if ([item valueForProperty: kETPersistentFrameProperty] != nil)
		{
			[item setFrame: [item persistentFrame]];
		}
		else /* First time persistent frame is accessed, initialize it */
		{
			[item setPersistentFrame: [item frame]];
		}
	}
}

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

- (void) handleMouseDown: (ETEvent *)event forItem: (id)item layout: (id)layout
{
	//NSLog(@"ETFreeLayout handleMouseDown: %@ forItem %@ layout %@", event, item, layout);
	_dragItem = item;
	_dragStartOffsetFromOrigin = [[self container] convertPoint: [event locationInWindow] fromView: nil];
	NSPoint origin = [item origin];
	_dragStartOffsetFromOrigin.x -= origin.x;
	_dragStartOffsetFromOrigin.y -= origin.y;
}

- (void) handleDrag: (ETEvent *)event forItem: (id)item layout: (id)layout
{
	if (_dragItem == nil || _dragItem == [self layoutContext])
	{
		return;
	}

	NSPoint newOrigin = [[self container] convertPoint: [event locationInWindow] fromView: nil];
	newOrigin.x -= _dragStartOffsetFromOrigin.x;
	newOrigin.y -= _dragStartOffsetFromOrigin.y;
	[_dragItem setOrigin: newOrigin];

	[[self container] updateLayout];
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
// Implementing these methods also mean to uncomment them in ETContainer.h.
// -container:locationForItem: should be called in -itemAtLocation:. If no
// source exists, -itemAtLocation must run exactly as it is now and requests the 
// item location to super.
// -container:setLocation:forItem: should be called in 
// -handleDrop:forItem:layout: or similar.
// -container:acceptLocation:forItem: may be needed in 
// -handleDrag:forItem:layout: to give feedback about positional constraints to 
// the user.
#if 0
/* Overriden method to delegate it to the container data source. */
- (ETVector *) container: (ETContainer *)container locationForItem: (ETLayoutItem *)item
{
	return [[[self container] source] container: container locationForItem: item];
}

/* Overriden method to delegate it to the container data source. */
- (void) container: (ETContainer *)container setLocation: (ETVector *)vectorLoc forItem: (ETLayoutItem *)item
{
	[[[self container] source] container: container setLocation: vectorLoc forItem: item];
}
#endif
