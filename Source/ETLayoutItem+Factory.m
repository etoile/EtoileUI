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
#import <EtoileUI/ETWindowItem.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETCompatibility.h>
#include <float.h>

@implementation ETLayoutItem (ETLayoutItemFactory)

/* Basic Item Factory Methods */

+ (ETLayoutItem *) item
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] init]);
}

+ (ETLayoutItem *) itemWithView: (NSView *)view
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithView: view]);
}

+ (ETLayoutItem *) itemWithValue: (id)value
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithValue: value]);
}

+ (ETLayoutItem *) itemWithRepresentedObject: (id)object
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithRepresentedObject: object]);
}

/* Group Factory Methods */

+ (ETLayoutItemGroup *) itemGroup
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] init]);
}

+ (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item
{
	return [ETLayoutItemGroup itemGroupWithItems: [NSArray arrayWithObject: item]];
}

+ (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithLayoutItems: items view: nil]);
}

+ (ETLayoutItemGroup *) itemGroupWithView: (NSView *)view
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithLayoutItems: nil view: view]);
}

+ (ETLayoutItemGroup *) itemGroupWithValue: (id)value
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithValue: value]);
}

/** Returns a new layout item group instance based on a container to which 
    you can apply view-based layouts such as ETTableLayout, ETModelViewLayout 
	etc. This is unlike the other item group factory methods that creates 
	instances which only accepts positional layouts such ETFlowLayout, 
	ETLineLayout etc. 
	TODO: In future, we should modify ETLayoutItemGroup to lazily creates the 
	container and inserts if a view-based layout is inserted... at this point,
	the use of this method won't be truly needed anymore. */
+ (ETLayoutItemGroup *) itemGroupWithContainer
{
	ETContainer *container = AUTORELEASE([[ETContainer alloc] init]);
	
	return (ETLayoutItemGroup *)[container layoutItem];
}

/* Widget Factory Methods */

+ (id) newItemWithViewClass: (Class)class
{
	id view = AUTORELEASE([[class alloc] init]);

	return [ETLayoutItem itemWithView: view];
}

/** Creates and returns a new layout item that uses a NSButton instance as its
    view. */
+ (id) button
{
	return [self newItemWithViewClass: [NSButton class]];
}

+ (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector
{
	ETLayoutItem *buttonItem = [self button];
	NSButton *buttonView = (NSButton *)[buttonItem view];

	[buttonView setTitle: aTitle];
	[buttonView setTarget: aTarget];
	[buttonView setAction: aSelector];

	return buttonItem;
}

/** Creates and returns a new layout item that uses a NSButton of type 
    NSRadioButton as its view. */
+ (id) radioButton
{
	ETLayoutItem *item = [self newItemWithViewClass: [NSButton class]];
	[(NSButton *)[item view] setButtonType: NSRadioButton];
	return item;
}

/** Creates and returns a new layout item that uses a NSButton of type 
    NSSwitchButton as its view. */
+ (id) checkbox
{
	id item = [self newItemWithViewClass: [NSButton class]];
	[(NSButton *)[item view] setButtonType: NSSwitchButton];
	return item;
}

/** Creates and returns a new label item that uses a NSTextField without border
    and background as its view. */
+ (id) labelWithTitle: (NSString *)aTitle
{
	id item = [self newItemWithViewClass: [NSTextField class]];
	NSTextField *labelField = (NSTextField *)[item view];

	// NOTE: -setBezeled: is necessary only for GNUstep but not on Cocoa.
	[labelField setBezeled: NO];
	[labelField setDrawsBackground: NO];
	[labelField setBordered: NO];
	[labelField setEditable: NO];
	[labelField setSelectable: YES];
	[labelField setStringValue: aTitle];
	[labelField setFont: [NSFont labelFontOfSize: [NSFont labelFontSize]]];
	// TODO: Evaluate whether the next two choices are the best defaults.
	[labelField setAlignment: NSCenterTextAlignment];
	[labelField setAutoresizingMask: NSViewNotSizable];
	[labelField sizeToFit];
	// TODO: Passing the label field to the item now rather than updating the 
	// item size could be cleaner. Eventually rethink -itemWithView: a bit 
	// and/or modify this method.
	[item setSize: [labelField frame].size];

	return item;
}

/** Creates and returns a new layout item that uses a NSTextField instance as 
    its view. */
+ (id) textField
{
	return [self newItemWithViewClass: [NSTextField class]];
}

/** Creates and returns a new layout item that uses a NSSearchField instance as 
    its view. */
+ (id) searchField
{
	return [self newItemWithViewClass: [NSSearchField class]];
}

/** Creates and returns a new layout item that uses a NSTextView instance as 
    its view. 
    WARNING: presently returns a scrollview if you call -view on the returned 
    instance. */
+ (id) textView
{
	id textViewItem = [self newItemWithViewClass: [NSTextView class]];
	NSTextView *textView = (NSTextView *)[textViewItem view];
	NSScrollView *scrollview = AUTORELEASE([[NSScrollView alloc]
            initWithFrame: [textView frame]]);
	NSSize contentSize = [scrollview contentSize];

	[textView setMinSize: NSMakeSize(0.0, contentSize.height)];
	[textView setMaxSize: NSMakeSize(FLT_MAX, FLT_MAX)];
	[textView setVerticallyResizable: YES];
	[textView setHorizontallyResizable: NO];
	[textView setAutoresizingMask: NSViewWidthSizable];
	[[textView textContainer]
            setContainerSize: NSMakeSize(contentSize.width, FLT_MAX)];
	[[textView textContainer] setWidthTracksTextView: YES];

	// TODO: We should use a scrollview decorator. This is a quick hack.
	[scrollview setDocumentView: textView];
	[scrollview setHasVerticalScroller: YES];
	/* Finally reinsert the text view as a scroll view */
	[textViewItem setView: scrollview];
	/* The item supervisor view must be resized if the enclosing container is 
	   resized. */
	[textViewItem setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

	return textViewItem;
}

/** Creates and returns a new layout item that uses a NSProgressIndicator instance as 
    its view. */
+ (id) progressIndicator
{
	return [self newItemWithViewClass: [NSProgressIndicator class]];
}

/** Creates and returns a new layout item that uses a vertially oriented 
    NSSlider instance as its view. */
+ (id) verticalSlider
{
	return [self newItemWithViewClass: [NSSlider class]];
}

/** Creates and returns a new layout item that uses a vertially oriented 
    NSSlider instance as its view. */
+ (id) horizontalSlider
{
	return [self newItemWithViewClass: [NSSlider class]];
}

/** Creates and returns a new layout item that uses a NSStepper instance as its 
    view. */
+ (id) stepper
{
	return [self newItemWithViewClass: [NSStepper class]];
}

/** Creates and returns a new layout item that uses a view whose subviews are 
    a text field and a stepper on the right side. */
+ (id) textFieldAndStepper
{
	// TODO: Implement
	return nil;
}

/* Decorator Item Factory Methods */

/** Creates a window item with a concrete window. The returned layout item can 
    be used as a decorator to wrap an existing layout item into a window. */
+ (ETWindowItem *) itemWithWindow: (NSWindow *)window
{
	return AUTORELEASE([[ETWindowItem alloc] initWithWindow: window]);
}

/* Layer Factory Methods */

+ (ETLayer *) layer
{
	return (ETLayer *)AUTORELEASE([[ETLayer alloc] init]);
}

+ (ETLayer *) layerWithItem: (ETLayoutItem *)item
{	
	return [ETLayer layerWithItems: [NSArray arrayWithObject: item]];
}

+ (ETLayer *) layerWithItems: (NSArray *)items
{
	ETLayer *layer = [[ETLayer alloc] init];
	
	if (layer != nil)
	{
		[(ETContainer *)[layer view] addItems: items];
	}
	
	return (ETLayer *)AUTORELEASE(layer);
}

+ (ETLayer *) guideLayer
{
	return (ETLayer *)AUTORELEASE([[ETLayer alloc] init]);
}

+ (ETLayer *) gridLayer
{
	return (ETLayer *)AUTORELEASE([[ETLayer alloc] init]);
}

/* Special Group Access Methods */

/** Returns the absolute root group usually located in the UI server.
	This root group representing the whole environment is the only layout item 
	with truly no parent. */
+ (id) rootGroup
{
	return nil;
}

//static ETLayoutItemGroup *localRootGroup = nil;

/** Returns the local root group which represents the current application.
	This item group is located in the application process and when the UI 
	server parent is running, it belongs to a parent located outside of the 
	present process. When no UI server is available, the local root group will
	have no parent. 
	ETApplication returns this item group when you call -layoutItem method 
	(unless the method has been overriden). */
+ (id) localRootGroup
{
	// TODO: Should add -windowGroup... but how the top part of the layout 
	// item tree is organized needs to be worked out in details.
#if 0
	if (localRootGroup == nil)
	{
		localRootGroup = [[ETLayoutItemGroup alloc] init];
		[localRootGroup setName: _(@"Application")];
		[localRootGroup addItem: [self windowGroup]];
	}

	return localRootGroup;
#endif 

	return [self windowGroup];
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

+ (ETLayoutItemGroup *) layoutItemGroupWithView: (NSView *)view
{
	return [self itemGroupWithView: view];
}

+ (ETLayer *) layerWithLayoutItem: (ETLayoutItem *)item
{	
	return [self layerWithItem: item];
}

+ (ETLayer *) layerWithLayoutItems: (NSArray *)items
{
	return [self layerWithItems: items];
}

@end
