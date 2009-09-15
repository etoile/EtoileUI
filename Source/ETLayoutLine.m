/*
	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETLayoutLine.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"
#include <float.h>

@interface ETVerticalLineFragment : ETLayoutLine
@end


@implementation ETLayoutLine

/* <init /> */
- (id) initWithFragments: (NSArray *)fragments 
          fragmentMargin: (float)aMargin 
                maxWidth: (float)aWidth
               maxHeight: (float)aHeight
{
	NILARG_EXCEPTION_TEST(fragments);
	SUPERINIT;
	ASSIGN(_fragments, fragments);
	_fragmentMargin = aMargin;
	_maxWidth = aWidth;
	_maxHeight = aHeight;
	return self;
}

- (id) init
{
	return [self initWithFragments: [NSArray array] fragmentMargin: 0
		maxWidth: FLT_MAX maxHeight: FLT_MAX];
}

DEALLOC(DESTROY(_fragments))

/** Returns a new autoreleased horizontal layout line filled with the given 
fragments. */
+ (id) horizontalLineWithFragmentMargin: (float)aMargin 
                               maxWidth: (float)aWidth
{
	return AUTORELEASE([[[self class] alloc] initWithFragments: [NSMutableArray array]
		fragmentMargin: aMargin maxWidth: aWidth maxHeight: FLT_MAX]);
}

/** Returns a new autoreleased vertical layout line filled with the given 
fragments. */
+ (id) verticalLineWithFragmentMargin: (float)aMargin 
                            maxHeight: (float)aHeight
{
	return AUTORELEASE([[ETVerticalLineFragment alloc] initWithFragments: [NSMutableArray array]
		fragmentMargin: aMargin maxWidth: FLT_MAX maxHeight: aHeight]);
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

/** Adds the given fragments sequentially to the receiver until its length 
becomes greater than its max allowed length, then return all the fragments 
that were accepted and added.

Accepted fragments can be an empty array or equal to the fragments given in 
input. */
- (NSArray *) fillWithFragments: (NSArray *)fragments
{
	NSMutableArray *acceptedFragments = [NSMutableArray arrayWithCapacity: [fragments count]];
	float length = 0;
	float maxLength = [self maxLength];

	FOREACH(fragments, fragment, ETLayoutItem *)
	{
		length += _fragmentMargin + [fragment width]; // TODO: Retrieve with or height
		
		if (length > maxLength)
			break;

		[acceptedFragments addObject: fragment];
	}

	[self setLength: length];
	[_fragments addObjectsFromArray: acceptedFragments];

	return acceptedFragments;
}

/** Returns the fragments that fills the receiver. */
- (NSArray *) fragments
{
	return _fragments;
}

- (float) fragmentMargin
{
	return _fragmentMargin;
}

- (void) setFragmentMargin: (float)aMargin
{
	_fragmentMargin = aMargin;
}

- (float) totalFragmentMargin
{
	return ([_fragments count] + 1) * _fragmentMargin;
}

/** Computes and sets the new fragment locations relative the receiver parent 
coordinate space.

The fragment locations need to be recomputed every time the receiver origin, 
size or the fragment margin get changed. */
- (void) updateFragmentLocations
{
	NSPoint fragmentOrigin = NSMakePoint(_origin.x + _fragmentMargin, _origin.y + _fragmentMargin);

	FOREACHI(_fragments, fragment)
	{
		[fragment setOrigin: fragmentOrigin];
		fragmentOrigin.x += [fragment width] + _fragmentMargin;
	}
}

/** Sets the origin of the line in a layout. 

The origin is at the top left corner of the line when the parent coordinate 
space is flipped, ortherwise at the bottom left corner. */
- (void) setOrigin: (NSPoint)location
{
	_origin = location;
	[self updateFragmentLocations];
}

/** Returns the origin of the line in a layout. */
- (NSPoint) origin
{
	return _origin;  
}

/** Returns the height of the line. */
- (float) height
{
	float height = 0;
	
	/* We must look for the tallest layouted item (by line) when we are
	   horizontally oriented. */

	// FIXME: Try to make the next line works
	// height = [[_fragments valueForKey: @"@max.height"] floatValue];
	
	FOREACHI(_fragments, fragment)
	{
		if ([fragment height] > height)
			height = [fragment height];
	}
	
	return height;
}

/** Returns the width of the line. */
- (float) width
{
	/* We must compute the sum of layout item width when we are horizontally 
	   oriented. */
	float totalFragmentWidth = 0;

	FOREACHI(_fragments, fragment)
	{
		totalFragmentWidth += [fragment width];
	}

	return totalFragmentWidth + [self totalFragmentMargin];
	// FIXME: Next line should work but does not on Mac OS X.
	//return [[_fragments valueForKey: @"@sum.width"] floatValue] + [self totalFragmentMargin];
}

/** Returns the max width to which the receiver can be stretched to.

See -maxLength. */
- (float) maxWidth
{
	return _maxWidth;
}

/** Returns the max height to which the receiver can be stretched to.

See -maxLength. */
- (float) maxHeight
{
	return _maxHeight;
}

/** <override-dummy />
Returns the max lenght of the line.

When the receiver length reaches the max length, it starts to refuse fragments.

The max length is the max width when the line is horizontal, the max height when 
the line is vertical. */
- (float) maxLength
{
	return _maxWidth;
}

/** <override-dummy />
Returns the lenght of the line.

The length is the width when the line is horizontal, the height when the line 
is vertical. */
- (float) length
{
	return [self width];
}

- (void) setLength: (float)aLength
{

}

/** <override-dummy />
Returns the lenght of the line.

The thickness is the height when the line is horizontal, the width when the line 
is vertical. */
- (float) thickness
{
	return [self height];
}

/** <override-dummy />
Returns whether the line is vertical or horizontal. */
- (BOOL) isVerticallyOriented
{
	return NO;
}

@end


@implementation ETVerticalLineFragment

- (void) updateFragmentLocations
{
	FOREACHI(_fragments, fragment)
	{
		[fragment setX: _origin.x];
	}
}

- (float) height
{
	/* We must compute the sum of layout item height when we are vertically 
	   oriented. */
	return [[_fragments valueForKey: @"@sum.height"] floatValue] + [self totalFragmentMargin];
}

- (float) width
{
	float width = 0;
	
	/* We must look for the widest layouted item (by line) when we are
	   vertically oriented. */

	// FIXME: Try to make the next line works
	// width = [[_fragments valueForKey: @"@max.width"] floatValue];

	FOREACHI(_fragments, fragment)
	{
		if ([fragment width] > width)
			width = [fragment width];
	}
	
	return width;
}

- (float) maxLength
{
	return _maxHeight;
}

- (float) length
{
	return [self height];
}

- (float) thickness
{
	return [self width];
}

- (BOOL) isVerticallyOriented
{
	return YES;
}

@end
