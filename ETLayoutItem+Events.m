/*
	ETLayoutItem+Events.m
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
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

#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETLayoutItem (Events)

- (BOOL) allowsDragging
{
	return [[self closestAncestorContainer] allowsDragging];
}

- (void) mouseDown: (NSEvent *)event on: (id)item
{
	if ([self representedPathBase] != nil)
	{
		//[self handleClickForItem: item];
	}
	else
	{
		[[self parentLayoutItem] mouseDown: event on: item];
	}
}

- (void) mouseDragged: (NSEvent *)event on: (id)item
{
	if ([self allowsDragging] == NO)
		return;

	if ([self representedPathBase] != nil)
	{
		ETLog(@"Allowed dragging on selection");
		[self handleDrag: event forItem: item];
	}
	else
	{
		[[self parentLayoutItem] mouseDragged: event on: item];
	}
}

// NOTE: ETOutlineLayout would override this method to call 
// -selectedItemsIncludingRelatedDescendants instead of -selectedItems	
//[pickboard pushObject: [ETPickCollection pickCollectionWithObjects: [self selectedItems]];
- (void) handleDrag: (NSEvent *)event forItem: (id)item
{
	id layout = nil;
	
	if ([self isGroup])
		layout = [(ETLayoutItemGroup *)self layout];
	
	if (layout != nil && [layout respondsToSelector: @selector(handleDragForItem:)])
	{
		[layout handleDrag: event forItem: item];
	}
	else
	{
		// TODO: pickboard shouldn't be harcoded but rather customizable
		[[ETPickboard localPickboard] pushObject: item];
		
		/* We need to put something on the pasteboard otherwise AppKit won't 
		   allow the drag */
		NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
		[pboard declareTypes: [NSArray arrayWithObject: ETLayoutItemPboardType] owner: nil];
		
		// TODO: Implements pasteboard compatibility to integrate with 
		// non-native Etoile code
		//NSData *data = [NSKeyedArchiver archivedDataWithRootObject: item];
		//[pboard setData: data forType: ETLayoutItemPboardType];
		
		[self beginDrag: event forItem: item image: nil];
	}
}

/* ETLayoutItem specific method to create a new drag and passing the request to data source */
- (void) beginDrag: (NSEvent *)event forItem: (id)item image: (NSImage *)customDragImage
{
	id dragSource = [event window];
	NSImage *dragIcon = customDragImage;
	
	if (dragIcon == nil)
		dragIcon = [item image];
	
	// FIXME: Draw drag image made of all dragged items and not just first one
	[dragSource dragImage: dragIcon
					   at: [event locationInWindow]
				   offset: NSZeroSize
					event: event 
			   pasteboard: [NSPasteboard pasteboardWithName: NSDragPboard]
				   source: dragSource
				slideBack: YES];
}

#if 0
- (void) handleDropForItem: (id)item
{

}

- (void) handleDropForObject: (id)object
{
	if ([[self allowedDroppingTypes] containsObject: [object type]] == NO)
		return;
		
	
	if ([object isKindOfClass: [ETLayoutItem class]])
	{
		[self handleDropForItem: object];
	}
	else
	{
		if (layout != nil && [layout respondsToSelector: @selector(handleDropForObject:)])
		{
			[layout handleDropForObject: item];
		}
		else
		{
			// TODO: pickboard shouldn't be harcoded but rather customizable
			ETPickboard *pickboard = [ETPickboard activePickboard];

			[dropTargetItem insertItems: [pickboard popObjectCollection] atIndex: ];
		}
	}
}
#endif
@end
