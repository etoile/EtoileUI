/** <title>Geometry</title>

	<abstract>Geometry utility functions and constants.</abstract>

	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

/** The null point which is not equal to NSZeroPoint. It can be returned 
when a point value is undefined and is a nil-like marker for NSPoint primitive. */
extern const NSPoint ETNullPoint;
/** The null size which is not equal to NSZeroSize. It can be returned 
when a size value is undefined and is a nil-like marker for NSSize primitive. */
extern const NSSize ETNullSize;
/** The null rectangle which is not equal to NSZeroRect. It can be returned 
when a rect value is undefined and is a nil-like marker for NSRect primitive. */
extern const NSRect ETNullRect;

/** Returns whether the given point is equal to ETNullPoint. */
static inline BOOL ETIsNullPoint(NSPoint aPoint)
{
	return NSEqualPoints(aPoint, ETNullPoint);
}

/** Returns whether rect is equal to ETNullRect. */
static inline BOOL ETIsNullRect(NSRect rect)
{
	return NSEqualRects(rect, ETNullRect);
}

/** Returns a rect with the given origin and size. */
static inline NSRect ETMakeRect(NSPoint origin, NSSize size)
{
	return NSMakeRect(origin.x, origin.y, size.width, size.height);
}

/** Returns a rect that uses aSize as its size and centered inside the given rect.

The returned rect is expressed relative the given rect parent coordinate space.<br />
To get a rect expressed relative the the given rect itself, pass a rect with a zero 
origin: 
<code>
NSRect inRect = NSMakeRect(40, 50, 100, 200);
NSRect centeredRectSize = NSMakeSize(50, 100);
NSRect rect = ETCenteredRect(centeredRectSize, ETMakeRect(NSZeroPoint, inRect.size));
</code>
The resulting rect is equal to { 25, 50, 50, 100 }.

The returned rect origin is valid whether or not your coordinate space is flipped. */
static inline NSRect ETCenteredRect(NSSize aSize, NSRect inRect)
{
	float xOffset = aSize.width * 0.5;
	float x = NSMidX(inRect) - xOffset;
	float yOffset = aSize.height  * 0.5;
	float y = NSMidY(inRect) - yOffset;

	return NSMakeRect(x, y, aSize.width, aSize.height);
}

/** Returns a rect that uses aSize scaled based on the content aspect rule and 
then centered inside the given rect.

The returned rect is expressed relative the given rect parent coordinate space.<br />
To get a rect expressed relative the the given rect itself, see ETCenteredRect().

The returned rect origin is valid whether or not your coordinate space is flipped. */
extern NSRect ETScaledRect(NSSize aSize, NSRect inRect, ETContentAspect anAspect);

/** Returns a size with a width and height multiplied by the given factor. */
static inline NSSize ETScaleSize(NSSize size, float factor)
{	
	size.width *= factor;
	size.height *= factor;

	return size;
}

/** Returns a rect with a width and height multiplied by the given factor and 
by shifting the origin to retain the original rect center location. */
static inline NSRect ETScaleRect(NSRect frame, float factor)
{
	NSSize prevSize = frame.size;
	
	frame.size = ETScaleSize(frame.size, factor);
	// NOTE: frame.origin.x -= (frame.size.width - prevSize.width) / 2;
	//       frame.origin.y -= (frame.size.height - prevSize.height) / 2;
	frame.origin.x += (prevSize.width - frame.size.width) / 2;
	frame.origin.y += (prevSize.height - frame.size.height) / 2;

	return frame;
}

/** Returns a rect with a positive width and height by shifting the origin as 
needed. */
static inline NSRect ETStandardizeRect(NSRect rect)
{
	float minX = NSMinX(rect);
	float minY = NSMinY(rect);
	float width = NSWidth(rect);
	float height = NSHeight(rect);

	if (width < 0)
	{
		minX += width;
		width = -width;
	}
	if (height < 0)
	{
		minY += height;
		height = -height;
	}

	return NSMakeRect(minX, minY, width, height);
}

/** Returns whether rect contains a point expressed in coordinates relative 
to the rect origin. */
static inline BOOL ETPointInsideRect(NSPoint aPoint, NSRect rect)
{
	return ((rect.origin.x + aPoint.x <= rect.size.width) 
		&& (rect.origin.y + aPoint.y <= rect.size.height));
}

/** Returns a new point by summing the x and y coordinates of two points. */
static inline NSPoint ETSumPoint(NSPoint aPoint, NSPoint otherPoint)
{
	return NSMakePoint(aPoint.x + otherPoint.x, aPoint.y + otherPoint.y);
}

/** Returns a new point by summing the point x and y coordinates with the size 
width and height. */
static inline NSPoint ETSumPointAndSize(NSPoint aPoint, NSSize aSize)
{
	return NSMakePoint(aPoint.x + aSize.width, aPoint.y + aSize.height);
}

extern NSRect ETUnionRectWithObjectsAndSelector(NSArray *itemArray, SEL rectSelector);

