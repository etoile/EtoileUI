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

@interface ETVerticalLineFragment : ETLayoutLine
@end


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

/** Returns a new autoreleased vertical layout line filled with the given 
fragments. */
+ (id) verticalLineWithFragments: (NSArray *)fragments
{
	return AUTORELEASE([[ETVerticalLineFragment alloc] initWithFragments: fragments]);
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

- (float) fragmentMargin
{
	return _fragmentMargin;
}

- (void) setFragmentMargin: (float)aMargin
{
	_fragmentMargin = aMargin;
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
	return [[_fragments valueForKey: @"@sum.width"] floatValue];
}

/** <override-dummy />
Returns the lenght of the line.

The length is the width when the line is horizontal, the height when the line 
is vertical. */
- (float) length
{
	return [self width];
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
	return [[_fragments valueForKey: @"@sum.height"] floatValue];
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
