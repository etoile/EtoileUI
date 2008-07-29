/*  <title>ETLayoutLine</title>

	ETLayoutLine.m
	
	<abstract>Represents an horizontal or vertical line box in a layout.</abstract>
 
	Copyright (C) 2006 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
 
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

#import <EtoileUI/ETLayoutLine.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETLayoutLine

+ (id) layoutLineWithViews: (NSArray *)views
{
	NSMutableArray *items = [NSMutableArray array];
	NSEnumerator *e = [views objectEnumerator];
	NSView *view = nil; 
	
	while ((view = [e nextObject]) != nil)
	{
		[items addObject: [ETLayoutItem layoutItemWithView: view]];
	}
    
	return [ETLayoutLine layoutLineWithLayoutItems: items];
}

+ (id) layoutLineWithLayoutItems: (NSArray *)items
{
	ETLayoutLine *layoutLine = [[ETLayoutLine alloc] init];
    
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
