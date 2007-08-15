/*	<title>ETStackLayout</title>

	ETStackLayout.m

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

#import <EtoileUI/ETStackLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>


@implementation ETStackLayout

/** Returns a line filled with views to layout (stored in an array). */
- (ETViewLayoutLine *) layoutLineForLayoutItems: (NSArray *)items inContainer: (ETContainer *)viewContainer
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *itemToLayout = nil;
	NSMutableArray *layoutedItems = [NSMutableArray array];
	ETViewLayoutLine *line = nil;
	float vAccumulator = 0;
    
	while ((itemToLayout = [e nextObject]) != nil)
	{
		vAccumulator += [itemToLayout height];
		
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
		
	line = [ETViewLayoutLine layoutLineWithLayoutItems: layoutedItems];
	[line setVerticallyOriented: YES];
	
	/* Update layout size, useful when related container is embedded in a scroll view */
	if ([self isContentSizeLayout])
		[self setLayoutSize: NSMakeSize([line width], vAccumulator)];

	return line;
}

// Must override unless you use a display view
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{
	if ([layoutModel count] > 1)
	{
		NSLog(@"%@ -computeViewLocationsForLayoutModel: receives a model with "
			  @"%d objects and not one, this usually means "
			  @"-layoutLineForViews: isn't overriden as it should.", self, 
			  [layoutModel count]);
	}
	
	[self computeLayoutItemLocationsForLayoutLine: [layoutModel lastObject] inContainer: container];
}

- (void) computeLayoutItemLocationsForLayoutLine: (ETViewLayoutLine *)line inContainer: (ETContainer *)container
{
	NSEnumerator *lineWalker = nil;
	ETLayoutItem *item = nil;
	NSPoint itemLocation = NSMakePoint(0, 0);
	
	if ([[self container] isFlipped])
	{
		lineWalker = [[line items] objectEnumerator];
	}
	else
	{
		/* Don't reverse the item order or selection and sorting will be messed */
		lineWalker = [[line items] reverseObjectEnumerator];
		itemLocation = NSMakePoint(0, [self layoutSize].height);	
	}
		
	while ((item = [lineWalker nextObject]) != nil)
	{
		[item setX: itemLocation.x];
		[item setY: itemLocation.y];
		if ([[self container] isFlipped])
		{
			itemLocation.y += [item height];
		}
		else
		{
			itemLocation.y -= [item height];
		}
	}
	
	/* NOTE: to avoid computing view locations when they are outside of the
		frame, think to add an exit condition here. */
	
	NSLog(@"View locations computed by layout line :%@", line);
}

@end
