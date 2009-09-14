/*
	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETLayoutLine.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Factory.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"


@implementation ETLayoutLine

/* <init /> */
- (id) initWithFragments: (NSArray *)fragments
{
	NILARG_EXCEPTION_TEST(fragments);
	SUPERINIT;
	ASSIGN(_fragments, fragments);
	return self;
}

- (id) init
{
	return [self initWithFragments: [NSArray array]];
}

DEALLOC(DESTROY(_fragments))

/** Returns a new autoreleased horizontal layout line filled with the given 
fragments. */
+ (id) horizontalLineWithFragments: (NSArray *)fragments
{
	return AUTORELEASE([[[self class] alloc] initWithFragments: fragments]);
}

- (NSString *) description
{
    NSString *desc = [super description];

	FOREACHI(_fragments, fragment)
    {
		desc = [desc stringByAppendingFormat: @", %@", NSStringFromRect([fragment frame])];
    }
    
    return desc;
}


/** Returns the fragments that fills the receiver. */
- (NSArray *) fragments
{
	return _fragments;
}

/** Sets the origin of the line in a layout. 

The origin is at the top left corner of the line when the parent coordinate 
space is flipped, ortherwise at the bottom left corner. */
- (void) setOrigin: (NSPoint)location
{
	_origin = location;
	
	NSEnumerator *e = [_fragments objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		[item setY: _origin.y];
	}
}

/** Returns the origin of the line in a layout. */
- (NSPoint) origin
{
	return _origin;  
}

/** Returns the height of the line. */
- (float) height
{
	NSEnumerator *e = [_fragments objectEnumerator];
	ETLayoutItem *item = nil;
	float height = 0;
	
	/* We must look for the tallest layouted item (by line) when we are
	   horizontally oriented. When vertically oriented, we must compute the sum 
	   of layout item height. */
	
	if ([self isVerticallyOriented])
	{
		height = [[_fragments valueForKey: @"@sum.height"] floatValue];
	}
	else
	{
		// FIXME: Try to make the next line works
		// height = [[_fragments valueForKey: @"@max.height"] floatValue];
		
		while ((item = [e nextObject]) != nil)
		{
			if ([item height] > height)
				height = [item height];
		}
	}
	
	return height;
}

/** Returns the width of the line. */
- (float) width
{
	NSEnumerator *e = [_fragments objectEnumerator];
	ETLayoutItem *item = nil;
	float width = 0;
	
	/* We must look for the widest layouted item (by line) when we are
	   vertically oriented. When horizontally riented, we must compute the sum 
	   of layout item width. */

	if ([self isVerticallyOriented])
	{
		// FIXME: Try to make the next line works
		// width = [[_fragments valueForKey: @"@max.width"] floatValue];
		
		while ((item = [e nextObject]) != nil)
		{
			if ([item width] > width)
				width = [item width];
		}
	}
	else
	{
		width = [[_fragments valueForKey: @"@sum.width"] floatValue];
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

@end
