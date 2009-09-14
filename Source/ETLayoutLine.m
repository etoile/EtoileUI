/*
	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD  (see COPYING)
 */

#import "ETLayoutLine.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETLayoutLine

+ (id) layoutLineWithLayoutItems: (NSArray *)items
{
	ETLayoutLine *layoutLine = [[ETLayoutLine alloc] init];
    
	ASSIGN(layoutLine->_items, items);
    
	return (id)AUTORELEASE(layoutLine);
}

- (NSArray *) items
{
	return _items;
}

- (void) setOrigin: (NSPoint)location
{
	_origin = location;
	
	NSEnumerator *e = [_items objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		[item setY: _origin.y];
	}
}

- (NSPoint) origin
{
	return _origin;  
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
