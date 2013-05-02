/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import "ETGeometry.h"
#import <EtoileFoundation/Macros.h>
#include <float.h>

const NSPoint ETNullPoint = {FLT_MIN, FLT_MIN};
const NSSize ETNullSize = {FLT_MIN, FLT_MIN};
const NSRect ETNullRect = {{FLT_MIN, FLT_MIN}, {FLT_MIN, FLT_MIN}};

NSRect ETScaledRect(NSSize aSize, NSRect inRect, ETContentAspect anAspect)
{
	NSRect newRect = ETMakeRect(NSZeroPoint, aSize);
	BOOL fillHorizontally = (ETContentAspectScaleToFillHorizontally == anAspect);
	BOOL fillVertically = (ETContentAspectScaleToFillVertically == anAspect);
	float widthRatio = inRect.size.width / aSize.width;	
	float heightRatio = inRect.size.height / aSize.height;
	BOOL hasPortraitOrientation = (widthRatio > heightRatio);

	if (ETContentAspectScaleToFill == anAspect)
	{
		if (hasPortraitOrientation)
		{
			fillVertically = NO;
			fillHorizontally = YES;
		}
		else
		{
			fillVertically = YES;
			fillHorizontally = NO;
		}	
	}
	else if (ETContentAspectScaleToFit == anAspect)
	{
		if (hasPortraitOrientation)
		{
			fillVertically = YES;
			fillHorizontally = NO;
		}
		else
		{
			fillVertically = NO;
			fillHorizontally = YES;
		}
	}

	if (fillHorizontally)
	{
		newRect.size.height *= widthRatio;
		newRect.size.width = inRect.size.width;
	}
	else if (fillVertically)
	{
		newRect.size.width *= heightRatio;
		newRect.size.height = inRect.size.height;
	}

	return ETCenteredRect(newRect.size, inRect);
}

typedef NSRect (*RectIMP)(id, SEL);

/** Returns an union rect computed by iterating over itemArray and unionning the 
rects returned by the objects which must all respond to rectSelector.

itemArray must only contain objects of the same type.

A zero rect is returned when itemArray is empty. */
NSRect ETUnionRectWithObjectsAndSelector(NSArray *itemArray, SEL rectSelector)
{
	if ([itemArray count] == 0)
		return NSZeroRect;

	NSRect rect = NSZeroRect;
	RectIMP rectFunction = (RectIMP)[[itemArray objectAtIndex: 0] methodForSelector: rectSelector];

	FOREACHI(itemArray, item)
	{
		rect = NSUnionRect(rect, rectFunction(item, rectSelector));
	}

	return rect;
}

/* This method is based on autoresize() function in GNUstep GUI */
void ETAutoresize(CGFloat *position,
				  CGFloat *size,
                  BOOL minMarginFlexible,
                  BOOL maxMarginFlexible,
                  BOOL sizeFlexible,
                  CGFloat newContainerSize,
                  CGFloat oldContainerSize)
{
	CGFloat containerResizeAmount = newContainerSize - oldContainerSize;
	CGFloat oldSize = *size;
	CGFloat oldPosition = *position;
	CGFloat flexibleSizeAmount = 0.0;

	if (sizeFlexible)
	{
		flexibleSizeAmount += oldSize;
	}
	if (minMarginFlexible)
	{
		flexibleSizeAmount += oldPosition;
	}
	if (maxMarginFlexible)
	{
		flexibleSizeAmount += oldContainerSize - oldPosition - oldSize;
	}
	
	BOOL isUpsizing = (flexibleSizeAmount > 0.0);

	if (isUpsizing)
    {
		assert(flexibleSizeAmount >= containerResizeAmount);
		CGFloat resizeFactor = (containerResizeAmount / flexibleSizeAmount);
		
		if (sizeFlexible)
		{
			*size += resizeFactor * oldSize;
		}
		if (minMarginFlexible)
		{
			*position += resizeFactor * oldPosition;
		}
    }
	else 
    {
		int nbOfFlexibleRegions = ((sizeFlexible ? 1 : 0)
			+ (minMarginFlexible ? 1 : 0) + (maxMarginFlexible ? 1 : 0));
		
		if (nbOfFlexibleRegions > 0)
		{
			CGFloat resizeAmount = (containerResizeAmount / nbOfFlexibleRegions);
			assert(resizeAmount <= 0.0);
			
			if (sizeFlexible)
			{
				*size += resizeAmount;
			}
			if (minMarginFlexible)
			{
				*position += resizeAmount;
			}
		}
    }
}
