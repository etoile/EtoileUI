//
//  ETViewLayoutLine.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>


@implementation ETViewLayoutLine

+ (id) layoutLineWithViews: (NSArray *)views
{
	NSMutableArray *items = [NSMutableArray array];
	NSEnumerator *e = [views objectEnumerator];
	NSView *view = nil; 
	
	while ((view = [e nextObject]) != nil)
	{
		[items addObject: [ETLayoutItem layoutItemWithView: view]];
	}
    
	return [ETViewLayoutLine layoutLineWithLayoutItems: items];
}

+ (id) layoutLineWithLayoutItems: (NSArray *)items
{
	ETViewLayoutLine *layoutLine = [[ETViewLayoutLine alloc] init];
    
	ASSIGN(layoutLine->_items, items);
    
	return (id)AUTORELEASE(layoutLine);
}

- (NSArray *) views
{
	return [_items valueForKey: @"view"];
}

- (NSArray *) items
{
	return _items;
}

- (void) setBaseLineLocation: (NSPoint)location
{
	_baseLineLocation = location;
	
	NSEnumerator *e = [_items objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		[item setY: _baseLineLocation.y];
	}
}

- (NSPoint) baseLineLocation
{
	return _baseLineLocation;  
}

- (float) height
{
	NSEnumerator *e = [_items objectEnumerator];
	ETLayoutItem *item = nil;
	float height = 0;
	
	/* We must look for the tallest layouted item (by line) when we are
	   horizontally oriented. When vertically oriented, we must compute the sum 
	   of layout item height. */
	
	if ([self isVerticallyOriented])
	{
		height = [[_items valueForKey: @"@sum.height"] floatValue];
	}
	else
	{
		// FIXME: Try to make the next line works
		// height = [[_items valueForKey: @"@max.height"] floatValue];
		
		while ((item = [e nextObject]) != nil)
		{
			if ([item height] > height)
				height = [item height];
		}
	}
	
	return height;
}

- (float) width
{
	NSEnumerator *e = [_items objectEnumerator];
	ETLayoutItem *item = nil;
	float width = 0;
	
	/* We must look for the widest layouted item (by line) when we are
	   vertically oriented. When horizontally riented, we must compute the sum 
	   of layout item width. */

	if ([self isVerticallyOriented])
	{
		// FIXME: Try to make the next line works
		// width = [[_items valueForKey: @"@max.width"] floatValue];
		
		while ((item = [e nextObject]) != nil)
		{
			if ([item width] > width)
				width = [item width];
		}
	}
	else
	{
		width = [[_items valueForKey: @"@sum.width"] floatValue];
	}

	
	return width;
}

- (BOOL) isVerticallyOriented
{
	return _vertical;
}

- (void) setVerticallyOriented: (BOOL)vertical
{
	_vertical = vertical;
}

- (NSString *) description
{
    NSString *desc = [super description];
    NSEnumerator *e = [_items objectEnumerator];
    id item = nil;
    
    while ((item = [e nextObject]) != nil)
    {
		desc = [desc stringByAppendingFormat: @", %@", NSStringFromRect([item frame])];
    }
    
    return desc;
}

@end
