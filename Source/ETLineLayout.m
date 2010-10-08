/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection.h>
#import "ETLineLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLineFragment.h"
#import "ETCompatibility.h"
#include "float.h"


@implementation ETLineLayout

/** Returns a line fragment filled with items to layout. */
- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)items
{
	float layoutWidth = [self layoutSize].width;

	if ([self isContentSizeLayout])
	{
		layoutWidth = FLT_MAX;
	}

	ETLineFragment *line = [ETLineFragment horizontalLineWithOwner: self 
	                                                    itemMargin: [self itemMargin] 
	                                                      maxWidth: layoutWidth];
	NSArray *acceptedItems = [line fillWithItems: items];

	if ([acceptedItems isEmpty])
		return nil;

	return line;
}

- (NSSize) computeLocationsForFragments: (NSArray *)layoutModel
{
	if ([layoutModel isEmpty])
		return NSZeroSize;

	NSParameterAssert([layoutModel count] == 1);

	ETLineFragment *line = [layoutModel lastObject];
	float totalMargin = ([self borderMargin] + [self itemMargin]) * 2;
	float contentHeight = [line height] + totalMargin;

	/* Will compute and set the item locations */
	[line setOrigin: [self originOfFirstFragment: line
	                            forContentHeight: contentHeight]];

	ETDebugLog(@"Item locations computed by layout line :%@", line);

	return NSMakeSize([line width] + totalMargin, contentHeight);
}

static const float undeterminedHeight = 10;

- (void) prepareSeparatorItem: (ETLayoutItem *)separator
{
	NSString *identifier = [separator identifier];
 
	if ([identifier isEqual: kETLineSeparatorItemIdentifier])
	{
		[separator setSize: NSMakeSize(kETLineSeparatorMinimumSize, undeterminedHeight)];
	}
	else if ([identifier isEqual: kETSpaceSeparatorItemIdentifier])
	{
		[separator setHeight: undeterminedHeight];
	}
	else if ([identifier isEqual: kETFlexibleSpaceSeparatorItemIdentifier])
	{
		[separator setSize: NSZeroSize];
	}
}

/** Returns a suggested size to adjust the flexible space separators for the 
given layout area size. */ 
- (NSSize) sizeOfFlexibleSeparatorItem: (ETLayoutItem *)separator 
                  forCurrentLayoutSize: (NSSize)aLayoutSize 
            numberOfFlexibleSeparators: (NSUInteger)nbOfFlexibleSeparators
                         inMaxAreaSize: (NSSize)maxSize 
{
	return NSMakeSize((maxSize.width - aLayoutSize.width) / nbOfFlexibleSeparators, aLayoutSize.height);
}

- (void) adjustSeparatorItem: (ETLayoutItem *)separator forLayoutSize: (NSSize)newLayoutSize
{
	NSString *identifier = [separator identifier];
 
	if ([identifier isEqualToString: kETLineSeparatorItemIdentifier])
	{
		float totalEndMargin = [self separatorItemEndMargin];

		[separator setY: totalEndMargin];
		[separator setHeight: (newLayoutSize.height - totalEndMargin * 2)];
	}
	else if ([identifier isEqualToString: kETSpaceSeparatorItemIdentifier])
	{
		[separator setHeight: newLayoutSize.height];
	}
	if ([identifier isEqualToString: kETFlexibleSpaceSeparatorItemIdentifier])
	{
		[separator setHeight: newLayoutSize.height];
	}

}

@end
