//
//  ETLineLayout.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETLineLayout.h"
#import "ETContainer.h"
#import "ETViewLayoutLine.h"


@implementation ETLineLayout

- (ETSizeConstraintStyle) layoutSizeConstraintStyle
{
	// NOTE: We use this constrain value to express our needs because
	// ETFlowLayout doesn't use it.
	return ETSizeConstraintStyleNone;
}


#if 0
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
	line = [self layoutLineForViews: unlayoutedViews inContainer: container];
		
	if ([[line views] count] > 0)
	{
		[layoutModel addObject: line];    
				
		/* In unlayoutedViews, remove the views which have just been layouted on the previous line. */
		[unlayoutedViews removeObjectsInArray: [line views]];
	}

	if ([unlayoutedViews count] > 0)
		NSLog(@"Not enough space to layout all the views. Views remaining unlayouted: %@", unlayoutedViews);
NSLog(@"bip bip bip");
	return layoutModel;
}
#endif
@end
