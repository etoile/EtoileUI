/*	<title>ETPaneLayout</title>

	ETPaneLayout.m

	<abstract>Description forthcoming.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
 
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
 
#import "ETPaneLayout.h"
#import "NSView+Etoile.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETContainer.h"

@implementation ETPaneLayout

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	/* Neither container and delegate have to be retained. For container, only
	   because it retains us and is in charge of us
	   For _displayViewPrototype, it's up to subclasses to manage it. */
	[super dealloc];
}

- (void) itemGroupSelectionDidChange: (NSNotification *)notif
{
	NSAssert2([[notif object] isEqual: [[self container] layoutItem]], 
		@"Notification object %@ doesn't match item group of layout %@", [notif object], self);
	
	NSLog(@"Pane layout %@ receives selection change from %@", self, [notif object]);
	[[self container] updateLayout]; /* Will trigger -[ETLayout render] */

}

/*- (void) allowsMultipleSelection
{
	return NO;
}*/

- (void) setContainer: (ETContainer *)container
{
	// FIXME: Use layout context
	//[super setContainer: container];
	// FIXME: Memorize container selection style and restore it when the layout
	// is unset.
	[[self container] setEnablesHitTest: YES];
	[[self container] setAllowsMultipleSelection: NO];
	[[self container] setAllowsEmptySelection: NO];
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
		          name: ETItemGroupSelectionDidChangeNotification 
			    object: nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver: self 
		   selector: @selector(itemGroupSelectionDidChange:)
		       name: ETItemGroupSelectionDidChangeNotification
		     object: [[self container] layoutItem]];
}

/* Sizing Methods */

- (BOOL) isAllContentVisible
{
	return YES;
}

- (void) adjustLayoutSizeToContentSize
{

}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	NSArray *layoutModel = nil;
	
	/* By safety, we correct container style in case it got modified between
	   -setContainer: call and now. */
	[[self container] setAllowsMultipleSelection: NO];
	[[self container] setAllowsEmptySelection: NO];
	
	//float scale = [container itemScaleFactor];
	//[self resizeLayoutItems: items toScaleFactor: scale];
	
	layoutModel = [self layoutModelForLayoutItems: items];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeLayoutItemLocationsForLayoutModel: layoutModel];
		
	/* Don't forget to remove existing display view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	[[self container] setLayoutView: nil];
	
	// FIXME: Use layout item group and not the container directly
	//[[self container] setVisibleItems: layoutModel];
}

/* Only returns selected item view */
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items
{
	int selectedPaneIndex = [[self container] selectionIndex];
	
	NSLog(@"Layout selected pane %d in container %@", selectedPaneIndex, [self container]);
	
	if (selectedPaneIndex == NSNotFound)
		return items; // return nil;
		
	return [NSArray arrayWithObject: [items objectAtIndex: selectedPaneIndex]];
	/*@try 
	{ 
		return [views objectAtIndex: selectedPaneIndex];
	}
	@catch (NSException *e)
	{
		NSLog(@"Selection handling bug in ETContainer code");
	}
	@finally { return nil; }*/
}

- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
{
	//NSPoint viewLocation = NSMakePoint([container width] / 2.0, [container height] / 2.0);
	NSPoint itemLocation = NSZeroPoint;
	NSEnumerator *itemWalker = [layoutModel objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [itemWalker nextObject]) != nil)
	{
		[item setOrigin: itemLocation];
	}
	
	NSLog(@"Layout item locations computed by layout model %@", layoutModel);
}

// Private use
- (void) adjustLayoutSizeToSizeOfContainer: (ETContainer *)container { }

@end
