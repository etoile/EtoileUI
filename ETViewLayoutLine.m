//
//  ETViewLayoutLine.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>


@implementation ETViewLayoutLine

+ (id) layoutLineWithViews: (NSArray *)views
{
	ETViewLayoutLine *layoutLine = [[ETViewLayoutLine alloc] init];
    
	ASSIGN(layoutLine->_views, views);
    
	return (id)AUTORELEASE(layoutLine);
}

- (NSArray *) views
{
	return _views;
}

- (void) setBaseLineLocation: (NSPoint)location
{
	_baseLineLocation = location;
	
	NSEnumerator *e = [_views objectEnumerator];
	NSView *view = nil;
	
	while ((view = [e nextObject]) != nil)
	{
		[view setY: _baseLineLocation.y];
	}
}

- (NSPoint) baseLineLocation
{
	return _baseLineLocation;  
}

- (float) height
{
	NSEnumerator *e = [_views objectEnumerator];
	NSView *view = nil;
	float height = 0;
	
	/* We must look for the tallest layouted view (by line). Useful 
		once we get out of -computeViewLocationsForLayoutModel: view walking loop. */
	
	while ((view = [e nextObject]) != nil)
	{
		if ([view height] > height)
			height = [view height];
	}
	
	return height;
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
    NSEnumerator *e = [_views objectEnumerator];
    id view = nil;
    
    while ((view = [e nextObject]) != nil)
    {
		desc = [desc stringByAppendingFormat: @", %@", NSStringFromRect([view frame])];
    }
    
    return desc;
}

@end
