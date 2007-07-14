/*  <title>ETFlowLayout</title>

	ETFlowLayout.m
	
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

#import "ETFlowLayout.h"
#import "ETContainer.h"
#import "ETLayoutItem.h"
#import "ETViewLayout.h"
#import "ETViewLayoutLine.h"
#import "NSView+Etoile.h"
#import "GNUstep.h"


@implementation ETFlowLayout

- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{
	NSEnumerator *layoutWalker = [layoutModel objectEnumerator];
	ETViewLayoutLine *line;
	NSEnumerator *lineWalker = nil;
	NSView *view;
	NSPoint viewLocation = NSMakePoint(0, [container height]);
  
	while ((line = [layoutWalker nextObject]) != nil)
	{
    /*
         A +---------------------------------------
           |          ----------------
           |----------|              |    Layout
           | Layouted |   Layouted   |    Line
           |  View 1  |   View 2     |
         --+--------------------------------------- <-- here is the baseline
           B
       
       In view container coordinates we have:   
       baseLineLocation.x = A.x and baseLineLocation.y = A.y - B.y
       
     */
    
		[line setBaseLineLocation: viewLocation];
		lineWalker = [[line views] objectEnumerator];
    
		while ((view = [lineWalker nextObject]) != nil)
		{
			[view setX: viewLocation.x];
			viewLocation.x += [view width];
		}
    
		/* NOTE: to avoid computing view locations when they are outside of the
		   frame, think to add an exit condition here. */
    
		/* Before computing the following views location in 'x' on the next line, we have 
		   to reset the 'x' accumulator and take in account the end of the current 
		   line, by substracting to 'y' the last layout line height. */
		[line setBaseLineLocation: 
			NSMakePoint([line baseLineLocation].x, viewLocation.y - [line height])];
		viewLocation.x = 0;
		viewLocation.y = [line baseLineLocation].y;
       
		//NSLog(@"View locations computed by layout line :%@", line);
	}

}

/* A layout is decomposed in lines. A line is decomposed in views. Finally a layout is displayed in a view container. */

/** Run the layout computation which assigns a location in the view container
    to each view added to the flow layout manager. */
- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)container;
{
	NSMutableArray *unlayoutedViews = 
		[NSMutableArray arrayWithArray: views];
	ETViewLayoutLine *line = nil;
	NSMutableArray *layoutModel = [NSMutableArray array];
	
	/* First start by breaking views to layout by lines. We have to fill the layout
	   line (layoutLineList) until a view is crossing the right boundary which
	   happens when -layoutedViewForNextLineInViews: returns nil. */
	while ([unlayoutedViews count] > 0)
	{
		line = [self layoutLineForViews: unlayoutedViews inContainer: container];
		
		if ([[line views] count] > 0)
		{
			[layoutModel addObject: line];    
				
			/* In unlayoutedViews, remove the views which have just been layouted on the previous line. */
			[unlayoutedViews removeObjectsInArray: [line views]];
		}
		else
		{
			NSLog(@"Not enough space to layout all the views. Views remaining unlayouted: %@", unlayoutedViews);
			break;
		}
	}
	
	return layoutModel;
}

/** Returns a line filled with views to layout (stored in a layout line). */
- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: container
{
	//int maxViewHeightInLayoutLine = 0;
	NSEnumerator *e = [views objectEnumerator];
	NSView *viewToLayout = nil;
	NSMutableArray *layoutedViews = [NSMutableArray array];
	ETViewLayoutLine *line = nil;
	float hAccumulator = 0;
    
	while ((viewToLayout = [e nextObject]) != nil)
	{
		hAccumulator += [viewToLayout width];
		
		if (hAccumulator < [container width])
		{
			[layoutedViews addObject: viewToLayout];
		}
		else
		{
			break;
		}
	}
	
	if ([layoutedViews count] == 0)
		return nil;
		
	line = [ETViewLayoutLine layoutLineWithViews: layoutedViews];
	[line setVerticallyOriented: NO];

	return line;
}

- (BOOL) usesGrid
{
	return _grid;
}

- (void) setUsesGrid: (BOOL)constraint
{
	_grid = constraint;
}

@end
