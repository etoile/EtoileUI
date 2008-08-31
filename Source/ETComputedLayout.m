/*  <title>ETComputedLayout</title>

	ETComputedLayout.m

	<abstract>An abstract layout class whose subclasses position items by 
	computing their location based on a set of rules.</abstract>

	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
 
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

#import <EtoileUI/ETComputedLayout.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETComputedLayout

- (BOOL) isComputedLayout
{
	return YES;
}

/** Sets the size of the margin around each item to be layouted and triggers a 
    layout update. */
- (void) setItemMargin: (float)aMargin
{
	_itemMargin = aMargin;

	// TODO: Evaluate whether we should add an API at ETLayout level to request 
	// layout refresh, or rather remove this code and let the developer triggers
	// the layout update.
	if ([self canRender])
	{	
		[self render: nil isNewContent: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}

/** Returns the size of the margin around each item to be layouted. */
- (float) itemMargin
{
	return _itemMargin;
}

/** Runs the layout computation which finds a location in the view container
    to all layout items passed in parameter. 
	This method is usually called by -render and you should rarely need to
	do it by yourself. If you want to update the layout, just uses 
	-[ETContainer updateLayout]. 
	You may need to override this method in your layout subclasses if you want
	to create very special layout style. In this cases, it's important to know
	this method is in charge of calling -resizeLayoutItems, 
	-layoutModelForLayoutItems:, -computeLayoutItemLocationsForLayoutModel:.
	Finally once the layout is done, this method set the layout item visibility 
	by calling -setVisibleItems: on the related container. Actually it takes 
	care of the scroll view visibility but this may change a little bit in 
	future. */
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	[super renderWithLayoutItems: items isNewContent: isNewContent];

	NSArray *layoutModel = [self layoutModelForLayoutItems: items];
	/* Now computes the location of every views by relying on the line by line 
	   decomposition already made. */
	[self computeLayoutItemLocationsForLayoutModel: layoutModel];
	
	// TODO: May be worth to optimize by computing set intersection of visible and unvisible layout items
	// ETDebugLog(@"Remove views %@ of next layout items to be displayed from their superview", itemViews);
	[[self layoutContext] setVisibleItems: [NSArray array]];
	
	/* Adjust container size when it is embedded in a scroll view */
	if ([[self layoutContext] isScrollViewShown])
	{
		// NOTE: For this assertion check -[ETContainer setScrollView:] 
		NSAssert([self isContentSizeLayout] == YES, 
			@"Any layout done in a scroll view must be based on content size");
			
		[[self layoutContext] setContentSize: [self layoutSize]];
		ETDebugLog(@"Layout size is %@ with container size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self layoutContext] size]), 
			NSStringFromSize([[self layoutContext] visibleContentSize]));
	}
	
	NSMutableArray *visibleItems = [NSMutableArray array];
	NSEnumerator  *e = [layoutModel objectEnumerator];
	ETLayoutLine *line = nil;
	
	/* Flatten layout model by putting all views in a single array */
	while ((line = [e nextObject]) != nil)
	{
		[visibleItems addObjectsFromArray: [line items]];
	}
	
	[[self layoutContext] setVisibleItems: visibleItems];
}

/* 
 * Line-based layouts methods 
 */

/** Overrides this method to generate a layout line based on the container 
    constraints. Usual container constraints are size, vertical and horizontal 
	scroller visibility. */
- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
{
	return nil;
}

/** Overrides this method to generate a layout model based on the container 
    constraints. Usual container constraints are size, vertical and horizontal 
	scrollers visibility.
	A layout model is commonly made of several layouts lines inside an array
	where indexes indicates in which order these layout lines should be 
	displayed. It's up to you if you want to create a layout model with a more 
	elaborated ordering and rendering semantic. Finally the layout model is 
	interpreted by -computeViewLocationsForLayoutModel:. */
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items
{
	ETLayoutLine *line = [self layoutLineForLayoutItems: items];
	
	if (line != nil)
		return [NSArray arrayWithObject: line];

	return nil;
}

/** Overrides this method to interpretate the layout model and compute layout 
	item locations accordingly. Most of the work of layout process happens in 
	this method. */
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
{

}

@end
