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
