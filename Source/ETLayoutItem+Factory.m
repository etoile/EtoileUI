/*  <title>ETLayoutItem+Factory</title>

	ETLayoutItem+Factory.m
	
	<abstract>ETLayoutItem category providing a factory for building various 
	kinds of layout items and keeping track of special nodes of the layout item 
	tree.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
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

#import "ETLayoutItem+Factory.h"
#import "ETUIItemFactory.h"
#import "ETCompatibility.h"
#include <float.h>

#define FACTORY [ETUIItemFactory factory]

@implementation ETLayoutItem (ETLayoutItemFactory)

/* Basic Item Factory Methods */

+ (ETLayoutItem *) item
{
	return [FACTORY item];
}

+ (ETLayoutItem *) itemWithView: (NSView *)view
{
	return [FACTORY itemWithView: view];
}

+ (ETLayoutItem *) itemWithValue: (id)value
{
	return [FACTORY itemWithValue: value];
}

+ (ETLayoutItem *) itemWithRepresentedObject: (id)object
{
	return [FACTORY itemWithRepresentedObject: object];
}

/* Group Factory Methods */

+ (ETLayoutItemGroup *) itemGroup
{
	return [FACTORY itemGroup];
}

+ (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item
{
	return [FACTORY itemGroupWithItem: item];
}

+ (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items
{
	return [FACTORY itemGroupWithItems: items];
}

+ (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object
{
	return [FACTORY itemGroupWithRepresentedObject: object];
}

+ (ETLayoutItemGroup *) itemGroupWithContainer
{
	return [FACTORY itemGroupWithContainer];
}

+ (ETLayoutItemGroup *) graphicsGroup
{
	return [FACTORY graphicsGroup];
}

/* Widget Factory Methods */

+ (id) button
{
	return [FACTORY button];
}

+ (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector
{
	return [FACTORY buttonWithTitle: aTitle target: aTarget action: aSelector];
}

+ (id) radioButton
{
	return [FACTORY radioButton];
}

+ (id) checkbox
{
	return [FACTORY checkbox];
}

+ (id) labelWithTitle: (NSString *)aTitle
{
	return [FACTORY labelWithTitle: aTitle];
}

+ (id) textField
{
	return [FACTORY textField];
}

+ (id) searchField
{
	return [FACTORY searchField];
}

+ (id) textView
{
	return [FACTORY textView];
}

+ (id) progressIndicator
{
	return [FACTORY progressIndicator];
}

+ (id) verticalSlider
{
	return [FACTORY verticalSlider];
}

+ (id) horizontalSlider
{
	return [FACTORY horizontalSlider];
}

+ (id) stepper
{
	return [FACTORY stepper];
}

/* Decorator Item Factory Methods */

+ (ETWindowItem *) itemWithWindow: (NSWindow *)window
{
	return [FACTORY itemWithWindow: window];
}

+ (ETWindowItem *) fullScreenWindow
{
	return [FACTORY fullScreenWindow];
}

/* Special Group Access Methods */

+ (id) localRootGroup
{
	return [FACTORY localRootGroup];
}

+ (ETLayoutItemGroup *) windowGroup
{
	return [FACTORY windowGroup];
}

+ (void) setWindowGroup: (ETLayoutItemGroup *)windowGroup
{
	return [FACTORY setWindowGroup: windowGroup];
}

/* Deprecated */

+ (ETLayoutItem *) layoutItem
{
	return [self item];
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view
{
	return [self itemWithView: view];
}

+ (ETLayoutItem *) layoutItemWithValue: (id)value
{
	return [self itemWithValue: value];
}

+ (ETLayoutItem *) layoutItemWithRepresentedObject: (id)object
{
	return [self itemWithRepresentedObject: object];
}

+ (ETLayoutItemGroup *) layoutItemGroup
{
	return [self itemGroup];
}

+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItem: (ETLayoutItem *)item
{
	return [self itemGroupWithItem: item];
}

+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItems: (NSArray *)items
{
	return [self itemGroupWithItems: items];
}

/* Shape Factory Methods */

+ (ETLayoutItem *) itemWithBezierPath: (NSBezierPath *)aPath
{
	return [FACTORY itemWithBezierPath: aPath];
}

+ (ETLayoutItem *) rectangleWithRect: (NSRect)aRect
{
	return [FACTORY rectangleWithRect: aRect];
}

+ (ETLayoutItem *) rectangle
{
	return [FACTORY rectangle];
}

+ (ETLayoutItem *) ovalWithRect: (NSRect)aRect
{
	return [FACTORY ovalWithRect: aRect];
}

+ (ETLayoutItem *) oval
{
	return [FACTORY oval];
}

@end
