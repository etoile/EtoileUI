/*	<title>ETStackLayout</title>

	ETStackLayout.m

	<abstract>	A layout class that organize items in a single vertical column 
	or stack.</abstract>

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

#import "ETStackLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutLine.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETStackLayout

- (BOOL) isComputedLayout
{
	return YES;
}

/** Returns a line filled with views to layout (stored in an array). */
- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *itemToLayout = nil;
	NSMutableArray *layoutedItems = [NSMutableArray array];
	ETLayoutLine *line = nil;
	float vAccumulator = 0;
	float itemMargin = [self itemMargin];
    
	while ((itemToLayout = [e nextObject]) != nil)
	{
		vAccumulator += itemMargin + [itemToLayout height];
		
		if ([self isContentSizeLayout] || vAccumulator < [self layoutSize].height)
		{
			[layoutedItems addObject: itemToLayout];
		}
		else
		{
			break;
		}
	}
	
	if ([layoutedItems count] == 0)
		return nil;
		
	line = [ETLayoutLine layoutLineWithLayoutItems: layoutedItems];
	[line setVerticallyOriented: YES];
	
	/* Update layout size, useful when related container is embedded in a scroll view */
	if ([self isContentSizeLayout])
		[self setLayoutSize: NSMakeSize([line width], vAccumulator)];

	return line;
}

// Must override unless you use a display view
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
{
	if ([layoutModel count] > 1)
	{
		ETLog(@"%@ -computeViewLocationsForLayoutModel: receives a model with "
			  @"%d objects and not one, this usually means "
			  @"-layoutLineForViews: isn't overriden as it should.", self, 
			  [layoutModel count]);
	}
	
	[self computeLayoutItemLocationsForLayoutLine: [layoutModel lastObject]];
}

- (void) computeLayoutItemLocationsForLayoutLine: (ETLayoutLine *)line
{
	NSEnumerator *lineWalker = nil;
	ETLayoutItem *item = nil;
	float itemMargin = [self itemMargin];
	NSPoint itemLocation = NSMakePoint(itemMargin, itemMargin);
	BOOL isFlipped = [[self layoutContext] isFlipped];

	if (isFlipped)
	{
		lineWalker = [[line items] objectEnumerator];
	}
	else
	{
		/* Don't reverse the item order or selection and sorting will be messed */
		lineWalker = [[line items] reverseObjectEnumerator];
		itemLocation = NSMakePoint(itemMargin, [self layoutSize].height + itemMargin);	
	}
		
	while ((item = [lineWalker nextObject]) != nil)
	{
		[item setX: itemLocation.x];
		[item setY: itemLocation.y];
		if (isFlipped)
		{
			itemLocation.y += itemMargin + [item height];
		}
		else
		{
			itemLocation.y -= itemMargin + [item height];
		}
	}
	
	/* NOTE: to avoid computing view locations when they are outside of the
		frame, think to add an exit condition here. */
	
	ETDebugLog(@"View locations computed by layout line :%@", line);
}

@end
