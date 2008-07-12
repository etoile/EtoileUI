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

#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayer.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETLayoutItem (ETLayoutItemFactory)

/* Basic Item Factory Methods */

+ (ETLayoutItem *) layoutItem
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] init]);
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithView: view]);
}

+ (ETLayoutItem *) layoutItemWithValue: (id)value
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithValue: value]);
}

+ (ETLayoutItem *) layoutItemWithRepresentedObject: (id)object
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithRepresentedObject: object]);
}

/* Special Group Access Methods */

/** Returns the absolute root group usually located in the UI server.
	This root group representing the whole environment is the only layout item 
	with truly no parent. */
+ (id) rootGroup
{
	return nil;
}

/** Returns the local root group which represents the current application.
	This item group is located in the application process and when the UI 
	server parent is running, it belongs to a parent located outside of the 
	present process. When no UI server is available, the local root group will
	have no parent. 
	ETApplication returns this item group when you call -layoutItem method 
	(unless the method has been overriden). */
+ (id) localRootGroup
{
	return nil;
}

static ETLayoutItemGroup *floatingItemGroup = nil;

/** Returns the item group representing floating layout items.
	Layout items are floating when they have no parent. However layout items 
	returned by +rootGroup or +localRootGroup don't qualify as floating even
	though they have no parent. 
	When you create an ETView or an ETContainer, until you inserts it in the 
	layout item tree, its layout item will be attached to the floating item 
	group. */
+ (id) floatingItemGroup
{
	if (floatingItemGroup == nil)
	{
		floatingItemGroup = [[ETLayoutItemGroup alloc] init];
		[floatingItemGroup setName: _(@"Floating Items")];
	}
	
	return floatingItemGroup;
}

/** Returns the item representing the main screen. */
+ (id) screen
{
	return nil;
}

/** Returns the item group representing all screens available (usually the 
	screens connected to the computer). */
+ (id) screenGroup
{
	return nil;
}

/** Returns the item group representing the active project. */
+ (id) project
{
	return nil;
}

/** Returns the item group representing all projects. */
+ (id) projectGroup
{
	return nil;
}

static ETWindowLayer *windowLayer = nil;

/** Returns the item group representing all windows in the current application. */
+ (id) windowGroup
{
	if (windowLayer == nil)
	{
		ASSIGN(windowLayer, [[ETWindowLayer alloc] init]);
		RELEASE(windowLayer);
		[windowLayer setName: _(@"Windows")];
	}
	
	return windowLayer;
}

/** Sets the item group representing all windows in the current application. It
	is usually advised to pass an ETWindowLayer instance in parameter. */
+ (void) setWindowGroup: (ETLayoutItemGroup *)windowGroup
{
	ASSIGN(windowLayer, windowGroup);
}

static ETLayoutItemGroup *pickboardGroup = nil;

/** Returns the item group representing all pickboards including both 
	system-wide pickboards and those local to the application. */
+ (id) pickboardGroup
{
	if (pickboardGroup == nil)
	{
		pickboardGroup = [[ETLayoutItemGroup alloc] init];
		[pickboardGroup setName: _(@"Pickboards")];
	}
	
	return pickboardGroup;
}

@end
