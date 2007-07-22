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

- (id) init
{
	self = [super init];
	
	if (self != nil)
	{
		_layoutConstraint = ETSizeConstraintStyleHorizontal;
	}
	
	return self;
}

- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container
{
	NSEnumerator *layoutWalker = [layoutModel objectEnumerator];
	ETViewLayoutLine *line;
	NSEnumerator *lineWalker = nil;
	NSView *view;
	NSPoint viewLocation = NSMakePoint(0, 0);
	float newLayoutHeight = 0;
	
	if ([[self container] isFlipped] == NO)
	{
		NSLog(@"WARNING: Flow layout doesn't non-flipped coordinates inside scroll view");
		viewLocation = NSMakePoint(0, [self layoutSize].height);
	}
  
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
		if ([[self container] isFlipped])
		{
			[line setBaseLineLocation: 
				NSMakePoint([line baseLineLocation].x, viewLocation.y)];
			viewLocation.y = [line baseLineLocation].y + [line height];
		}
		else
		{
			[line setBaseLineLocation: 
				NSMakePoint([line baseLineLocation].x, viewLocation.y - [line height])];
			viewLocation.y = [line baseLineLocation].y;		
		}
		viewLocation.x = 0;
		
		/* Increase height of the content size. Used to adjust the document 
		   view size in scroll view */
		newLayoutHeight += [line height];
       
		//NSLog(@"View locations computed by layout line :%@", line);
	}
	
	[self setLayoutSize: NSMakeSize([self layoutSize].width, newLayoutHeight)];
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
	float widthAccumulator = 0;
    
	while ((viewToLayout = [e nextObject]) != nil)
	{
		widthAccumulator += [viewToLayout width];
		
		if ([self layoutSizeConstraintStyle] != ETSizeConstraintStyleHorizontal
		 || widthAccumulator < [self layoutSize].width)
		{
			[layoutedViews addObject: viewToLayout];
		}
		else
		{
			break;
		}
	}
	
	// NOTE: Not really useful for now because we don't support filling the 
	// layout horizontally, only vertical filling is in place.
	// We only touch the layout size height in -computeViewLocationsForLayoutModel:
	if ([self isContentSizeLayout] && [self layoutSize].width < widthAccumulator)
		[self setLayoutSize: NSMakeSize(widthAccumulator, [self layoutSize].height)];
	
	if ([layoutedViews count] == 0)
		return nil;
		
	line = [ETViewLayoutLine layoutLineWithViews: layoutedViews];
	[line setVerticallyOriented: NO];

	return line;
}

/** Lets you control the constraint applied on the layout 
    when -isContentSizeLayout returns YES. The most common case is when the 
	layout is set on a container embbeded in a scroll view. 
	By passing ETSizeConstraintStyleVertical, the layout will try to fill the
	limited height (provided by -layoutSize) with as many lines of equal 
	width as possible. In this case, layout width and line width are stretched.
	By passing ETSizeConstraintStyleHorizontal, the layout will try to fill 
	the unlimited height with as many lines of equally limited width (returned
	by -layoutSize) as needed. In this case, only layout height is stretched. 
	ETSizeConstraintStyleNone and ETSizeConstraintStyleVerticalHorizontal are
	not supported. If you use them, the receiver resets 
	ETSizeConstraintStyleHorizontal default value. */
- (void) setLayoutSizeConstraintStyle: (ETSizeConstraintStyle)constraint
{
	if (constraint == ETSizeConstraintStyleHorizontal 
	 || constraint == ETSizeConstraintStyleVertical)
	{ 
		_layoutConstraint = constraint;
	}
	else
	{
		_layoutConstraint = ETSizeConstraintStyleHorizontal;
	}
}

/** Returns the constraint applied on the layout which are only valid when 
	 -isContentSizeLayout returns YES. 
	 Default value is ETSizeConstraintStyleHorizontal. */
- (ETSizeConstraintStyle) layoutSizeConstraintStyle
{
	return _layoutConstraint;
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
