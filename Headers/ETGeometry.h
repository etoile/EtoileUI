/*
	ETGeometry.h
	
	Geometry utility functions and constants.
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2008
 
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/** The null point which is not equal to NSZeroPoint. It can be returned 
when a point value is undefined and is a nil-like marker for NSPoint primitive. */
extern const NSPoint ETNullPoint;
/** The null size which is not equal to NSZeroSize. It can be returned 
when a size value is undefined and is a nil-like marker for NSSize primitive. */
extern const NSSize ETNullSize;
/** The null rectangle which is not equal to NSZeroRect. It can be returned 
when a rect value is undefined and is a nil-like marker for NSRect primitive. */
extern const NSRect ETNullRect;

/** Returns whether rect is equal to ETNullRect. */
static inline BOOL ETIsNullRect(NSRect rect)
{
	return NSEqualRects(rect, ETNullRect);
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

extern NSRect ETUnionRectWithObjectsAndSelector(NSArray *itemArray, SEL rectSelector);

