/*
	Copyright (C) 2006 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2006
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import "ETLineFragment.h"
#import "ETLayoutItem.h"
#import "ETComputedLayout.h"
#import "ETCompatibility.h"
#include <float.h>

@interface ETVerticalLineFragment : ETLineFragment
@end


@implementation ETLineFragment

/* <init /> */
- (instancetype) initWithOwner: (id <ETLayoutFragmentOwner>)anOwner 
      fragmentMargin: (CGFloat)aMargin 
            maxWidth: (CGFloat)aWidth
           maxHeight: (CGFloat)aHeight
           isFlipped: (BOOL)isFlipped
{
	SUPERINIT;
	_owner = anOwner;
	_fragments = [[NSMutableArray alloc] init];
	_fragmentMargin = aMargin;
	_maxWidth = aWidth;
	_maxHeight = aHeight;
	_flipped = isFlipped;
	return self;
}

- (instancetype) init
{
	return [self initWithOwner: nil fragmentMargin: 0 maxWidth: CGFLOAT_MAX maxHeight: CGFLOAT_MAX isFlipped: YES];
}

/** Returns a new autoreleased horizontal layout line filled with the given 
fragments. */
+ (id) horizontalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                    itemMargin: (CGFloat)aMargin 
                      maxWidth: (CGFloat)aWidth
{
	return [[[self class] alloc] initWithOwner: anOwner
		fragmentMargin: aMargin maxWidth: aWidth maxHeight: CGFLOAT_MAX isFlipped: YES];
}

/** Returns a new autoreleased vertical layout line filled with the given 
fragments. */
+ (id) verticalLineWithOwner: (id <ETLayoutFragmentOwner>)anOwner
                  itemMargin: (CGFloat)aMargin 
                   maxHeight: (CGFloat)aHeight
                   isFlipped: (BOOL)isFlipped
{
	return [[ETVerticalLineFragment alloc] initWithOwner: anOwner
		fragmentMargin: aMargin maxWidth: CGFLOAT_MAX maxHeight: aHeight isFlipped: isFlipped];
}

- (NSString *) description
{
    NSString *desc = [super description];

	for (id <ETFragment> fragment in _fragments)
    {
		NSRect fragmentRect = NSMakeRect(fragment.origin.x, fragment.origin.y,
		                                 fragment.width, fragment.height);

		desc = [desc stringByAppendingFormat: @", %@", NSStringFromRect(fragmentRect)];
    }
	
    return desc;
}

- (CGFloat) lengthForFragment: (id <ETFragment>)aFragment
{
	NSRect rect = [_owner rectForItem: aFragment];
	return [self isVerticallyOriented] ? rect.size.height : rect.size.width;
}

/** Adds the given fragments sequentially to the receiver until its length 
becomes greater than its max allowed length, then return all the fragments 
that were accepted and added.

Accepted fragments can be an empty array or equal to the fragments given in 
input. */
- (NSArray *) fillWithItems: (NSArray *)fragments
{
	NSMutableArray *acceptedFragments = [NSMutableArray arrayWithCapacity: [fragments count]];
	CGFloat length = 0;
	CGFloat maxLength = [self maxLength];

	for (id <ETFragment> fragment in fragments)
	{
		/* The right or bottom margin must not result in a line break, we don't 
		   include it in the sum right now. */
		length += [self lengthForFragment: fragment];
		
		if (length > maxLength)
			break;

		[acceptedFragments addObject: fragment];
		length += _fragmentMargin;
	}

	[_fragments addObjectsFromArray: acceptedFragments];

	return acceptedFragments;
}

/** Returns the fragments that fills the receiver. */
- (NSArray *) items
{
	return _fragments;
}

/** Returns the fragment margin that lies between between each fragment. */
- (CGFloat) itemMargin
{
	return _fragmentMargin;
}

- (CGFloat) totalFragmentMargin
{
	return ([_fragments count] - 1) * _fragmentMargin;
}

- (NSPoint) originOfFirstFragment: (id <ETFragment>)aFragment
{
	return NSMakePoint(_origin.x, _origin.y);
}

- (NSPoint) nextOriginAfterFragment: (id <ETFragment>)aFragment withOrigin: (NSPoint)aFragmentOrigin
{
	// NOTE: Next line could use -lengthForFragment:
	aFragmentOrigin.x += [_owner rectForItem: aFragment].size.width + _fragmentMargin;
	return aFragmentOrigin;	
}

/** Computes and sets the new fragment locations relative the receiver parent 
coordinate space.

The fragment locations need to be recomputed every time the receiver origin, 
size or the fragment margin get changed. */
- (void) updateItemLocations
{
	NSPoint fragmentOrigin = [self originOfFirstFragment: [_fragments firstObject]];

	for (id <ETFragment> fragment in _fragments)
	{
		[_owner setOrigin: fragmentOrigin forItem: fragment];
		fragmentOrigin = [self nextOriginAfterFragment: fragment withOrigin: fragmentOrigin];
	}
}

/** Sets the origin of the line in a layout. 

The origin is at the top left corner of the line when the parent coordinate 
space is flipped, ortherwise at the bottom left corner. */
- (void) setOrigin: (NSPoint)location
{
	_origin = location;
	[self updateItemLocations];
}

/** Returns the origin of the line in a layout. */
- (NSPoint) origin
{
	return _origin;  
}

/** Returns the height of the line. */
- (CGFloat) height
{
	CGFloat height = 0;

	/* Find the tallest fragment in the line */
	for (id <ETFragment> fragment in _fragments)
	{
		if ([_owner rectForItem: fragment].size.height > height)
			height = [_owner rectForItem: fragment].size.height;
	}
	
	return height;
}

/** Returns the width of the line. */
- (CGFloat) width
{
	CGFloat totalFragmentWidth = 0;

	for (id <ETFragment> fragment in _fragments)
	{
		totalFragmentWidth += [_owner rectForItem: fragment].size.width;
	}

	return totalFragmentWidth + [self totalFragmentMargin];
}

/** Returns the max width to which the receiver can be stretched to.

See -maxLength. */
- (CGFloat) maxWidth
{
	return _maxWidth;
}

/** Returns the max height to which the receiver can be stretched to.

See -maxLength. */
- (CGFloat) maxHeight
{
	return _maxHeight;
}

/** <override-dummy />
Returns the max lenght of the line.

When the receiver length reaches the max length, it starts to refuse fragments.

The max length is the max width when the line is horizontal, the max height when 
the line is vertical. */
- (CGFloat) maxLength
{
	return _maxWidth;
}

/** <override-dummy />
Returns the lenght of the line.

The length is the width when the line is horizontal, the height when the line 
is vertical. */
- (CGFloat) length
{
	return [self width];
}

/** <override-dummy />
Returns the lenght of the line.

The thickness is the height when the line is horizontal, the width when the line 
is vertical. */
- (CGFloat) thickness
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

- (NSPoint) originOfFirstFragment: (id <ETFragment>)aFragment
{
	CGFloat fragmentY = 0;
	
	if (_flipped)
	{
		 fragmentY = _origin.y;
	}
	else
	{
		// NOTE: Next line equivalent to -lengthForFragment:
		CGFloat fragmentHeight = [_owner rectForItem: aFragment].size.height;
		fragmentY = _origin.y + [self height] - fragmentHeight;
	}

	return NSMakePoint(_origin.x, fragmentY);
}

- (NSPoint) nextOriginAfterFragment: (id <ETFragment>)aFragment withOrigin: (NSPoint)aFragmentOrigin
{
	NSPoint nextOrigin = aFragmentOrigin;
	// NOTE: Next line could use -lengthForFragment:
	CGFloat advancement = [_owner rectForItem: aFragment].size.height + _fragmentMargin;

	if (_flipped)
	{
		nextOrigin.y += advancement;
	}
	else
	{
		nextOrigin.y -= advancement;
	}
	
	return nextOrigin;	
}

- (CGFloat) height
{
	CGFloat totalFragmentHeight = 0;

	for (id <ETFragment> fragment in _fragments)
	{
		totalFragmentHeight += [_owner rectForItem: fragment].size.height;
	}

	return totalFragmentHeight + [self totalFragmentMargin];
}

- (CGFloat) width
{
	CGFloat width = 0;

	/* Find the widest fragment in the line */
	for (id <ETFragment> fragment in _fragments)
	{
		if ([_owner rectForItem: fragment].size.width > width)
			width = [_owner rectForItem: fragment].size.width;
	}
	
	return width;
}

- (CGFloat) maxLength
{
	return _maxHeight;
}

- (CGFloat) length
{
	return [self height];
}

- (CGFloat) thickness
{
	return [self width];
}

- (BOOL) isVerticallyOriented
{
	return YES;
}

@end
