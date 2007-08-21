/*
	ETFreeLayout.m
	
	Free layout class which let the user position the layout items by direct 
	manipulation
 
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

#import <EtoileUI/ETFreeLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/GNUstep.h>

@implementation ETFreeLayout

- (BOOL) isComputedLayout
{
	return NO;
}

- (void) resetItemLocationsWithLayout: (ETLayout *)layout
{
	RETAIN(self);
	[[self container] setLayout: layout];
	[[self container] updateLayout];
	[[self container] setLayout: self];
	RELEASE(self);
}
#if 0
- (void) renderWithLayoutItems: (NSArray *)items
{
	/* Prevent reentrancy. In a threaded environment, it isn't perfectly safe 
	   because _isLayouting test and _isLayouting assignement doesn't occur in
	   an atomic way. */
	if (_isLayouting)
	{
		NSLog(@"WARNING: Trying to reenter -renderWithLayoutItems: when the layout is already getting updated.");
		return;
	}
	else
	{
		_isLayouting = YES;
	}
	
	ETLog(@"Render layout items: %@", items);
	
	float scale = [[self container] itemScaleFactor];
	
	ETVector *vectorLoc = [self container: container locationForItem: item];
	
	[self resizeLayoutItems: items toScaleFactor: scale];
	
	// TODO: May be worth to optimize by computing set intersection of visible and unvisible layout items
	// NSLog(@"Remove views %@ of next layout items to be displayed from their superview", itemViews);
	[[self container] setVisibleItems: [NSArray array]];
	
	/* Adjust container size when it is embedded in a scroll view */
	if ([[self container] isScrollViewShown])
	{
		// NOTE: For this assertion check -[ETContainer setScrollView:] 
		NSAssert([self isContentSizeLayout] == YES, 
			@"Any layout done in a scroll view must be based on content size");
		
		[[self container] setFrameSize: [self layoutSize]];
		NSLog(@"Layout size is %@ with container size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self container] frame].size), 
			NSStringFromSize([[[self container] scrollView] contentSize]));
	}
	
	NSMutableArray *visibleItems = items;
	
	[[self container] setVisibleItems: visibleItems];
	
	_isLayouting = NO;	
}

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
@end
