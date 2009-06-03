/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import "ETUIItemFactory.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItemGroup.h"
#import "ETLayer.h"
#import "ETWindowItem.h"
#import "ETContainer.h"
#import "ETShape.h"
#import "NSWindow+Etoile.h"
#include <float.h>
#import "ETCompatibility.h"


@implementation ETUIItemFactory

/** Creates and returns an autoreleased factory object. */
+ (id) factory
{
	return AUTORELEASE([[self alloc] init]);
}

/* Basic Item Factory Methods */

/** Return a new blank layout item. */
- (ETLayoutItem *) item
{
	return (ETLayoutItem *)AUTORELEASE([[ETLayoutItem alloc] init]);
}

/** Returns a new layout item to which the given view gets bound. */
- (ETLayoutItem *) itemWithView: (NSView *)view
{
	return (ETLayoutItem *)AUTORELEASE([[ETLayoutItem alloc] initWithView: view]);
}

/** Returns a new layout item which represents the given object and treats it 
as a simple value rather than a full-blown model object.

A simple value means the properties of the given object are not exposed by the 
layout item, as it would be with the case with a represented object. e.g. if 
you pass an NSString, the layout item properties won't include
-[NSString allPropertyNames] but only the 'value' property.

See also -[NSObject(Model) isCommonObjectValue] in EtoileFoundation. */
- (ETLayoutItem *) itemWithValue: (id)value
{
	return (ETLayoutItem *)AUTORELEASE([[ETLayoutItem alloc] initWithValue: value]);
}

/** Returns a new layout item which represents the given object.

The represented object is a model object in an MVC perspective, the layout item 
normally interacts with it through the Property Value Coding protocol.

EtoileUI allows to manipulate every objects as a tangible object. To achieve 
that, every object is treated as a model object which can be represented 
on a screen by the mean of a layout item. Which means you can pass a layout 
item itself as a represented object and the returned item will be a proxy or a 
meta representation. */
- (ETLayoutItem *) itemWithRepresentedObject: (id)object
{
	return (ETLayoutItem *)AUTORELEASE([[ETLayoutItem alloc] initWithRepresentedObject: object]);
}

/* Group Factory Methods */

/** Returns a new blank layout item group. */
- (ETLayoutItemGroup *) itemGroup
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] init]);
}

/** Returns a new layout item group which contains the given item as a child .

An NSInvalidArgumentException will be raised if you pass nil. */
- (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item
{
	return [self itemGroupWithItems: [NSArray arrayWithObject: item]];
}

/** Returns a new layout item group which contains the given items as children. */ 
- (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithLayoutItems: items view: nil]);
}

/** Returns a new layout item group which represents the given object, usually 
a collection.

The represented object is a model object in an MVC perspective, the layout item 
group normally interacts with it through the Property Value Coding protocol and  
possibly the Collection protocols to traverse the object graph connected to it.

See also -itemWithRepresentedObject:. */
- (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithRepresentedObject: object]);
}

/** Returns a new layout item group instance based on a container to which 
    you can apply view-based layouts such as ETTableLayout, ETModelViewLayout 
	etc. This is unlike the other item group factory methods that creates 
	instances which only accepts positional layouts such ETFlowLayout, 
	ETLineLayout etc. 
	TODO: In future, we should modify ETLayoutItemGroup to lazily creates the 
	container and inserts if a view-based layout is inserted... at this point,
	the use of this method won't be truly needed anymore. */
- (ETLayoutItemGroup *) itemGroupWithContainer
{
	ETContainer *container = AUTORELEASE([[ETContainer alloc] init]);
	// FIXME: Remove this temporary workaround...
	[container setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	return (ETLayoutItemGroup *)[container layoutItem];
}

/** Returns a new layout item group set up as a graphics group with 
ETGraphicsGroupStyle as style and ETFreeLayout as layout.

You can use it to build structured graphics editor. e.g. ETSelectTool uses it 
when you request the grouping of several items. */
- (ETLayoutItemGroup *) graphicsGroup
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithContainer];
	[itemGroup setStyle: AUTORELEASE([[ETGraphicsGroupStyle alloc] init])];
	[itemGroup setLayout: [ETFreeLayout layout]];
	return itemGroup;
}

/* Widget Factory Methods */

- (id) newItemWithViewClass: (Class)class
{
	id view = AUTORELEASE([[class alloc] init]);

	return [self itemWithView: view];
}

/** Returns a new layout item that uses a NSButton instance as its view. */
- (id) button
{
	return [self newItemWithViewClass: [NSButton class]];
}

/** Returns a new layout item that uses a NSButton instance as its view, and 
initializes this button with the given title, target and action. */
- (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector
{
	ETLayoutItem *buttonItem = [self button];
	NSButton *buttonView = (NSButton *)[buttonItem view];

	[buttonView setTitle: aTitle];
	[buttonView setTarget: aTarget];
	[buttonView setAction: aSelector];

	return buttonItem;
}

/** Returns a new layout item that uses a NSButton of type NSRadioButton as its 
view. */
- (id) radioButton
{
	ETLayoutItem *item = [self newItemWithViewClass: [NSButton class]];
	[(NSButton *)[item view] setButtonType: NSRadioButton];
	return item;
}

/** Returns a new layout item that uses a NSButton of type NSSwitchButton as 
its view. */
- (id) checkbox
{
	id item = [self newItemWithViewClass: [NSButton class]];
	[(NSButton *)[item view] setButtonType: NSSwitchButton];
	return item;
}

/** Returns a new label item that uses a NSTextField without border 
and background as its view. */
- (id) labelWithTitle: (NSString *)aTitle
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

/** Returns a new layout item that uses a NSTextField instance as its view. */
- (id) textField
{
	return [self newItemWithViewClass: [NSTextField class]];
}

/** Returns a new layout item that uses a NSSearchField instance as its view. */
- (id) searchField
{
	return [self newItemWithViewClass: [NSSearchField class]];
}

/** Returns a new layout item that uses a NSTextView instance as its view. 
    
WARNING: presently returns a scrollview if you call -view on the returned item. */
- (id) textView
{
	NSScrollView *scrollview = AUTORELEASE([[NSScrollView alloc]
            initWithFrame: [ETLayoutItem defaultItemRect]]);
	NSSize contentSize = [scrollview contentSize];
	NSTextView *textView = [[NSTextView alloc] initWithFrame: ETMakeRect(NSZeroPoint, contentSize)];
	
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
	RELEASE(textView);
	[scrollview setHasVerticalScroller: YES];
	[scrollview setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	/* Finally reinsert the text view as a scroll view */
	ETLayoutItem *textViewItem = [self itemWithView: scrollview];
	/* The item supervisor view must be resized if the enclosing container is 
	   resized. */
	[textViewItem setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

	NSParameterAssert([textView superview] != nil);
	return textViewItem;
}

/** Returns a new layout item that uses a NSProgressIndicator instance as its view. */
- (id) progressIndicator
{
	return [self newItemWithViewClass: [NSProgressIndicator class]];
}

/** Returns a new layout item that uses a vertially oriented NSSlider instance 
as its view. */
- (id) verticalSlider
{
	return [self newItemWithViewClass: [NSSlider class]];
}

/** Returns a new layout item that uses a vertially oriented NSSlider instance 
as its view. */
- (id) horizontalSlider
{
	return [self newItemWithViewClass: [NSSlider class]];
}

/** Returns a new layout item that uses a NSStepper instance as its view. */
- (id) stepper
{
	return [self newItemWithViewClass: [NSStepper class]];
}

/** Returns a new layout item that uses a view whose subviews are a text field 
and a stepper on the right side. */
- (id) textFieldAndStepper
{
	// TODO: Implement
	return nil;
}

/* Decorator Item Factory Methods */

/** Returns a new window item to which the given concrete window gets bound. 

The returned item can be used as a decorator to wrap an existing layout item 
into a window. */
- (ETWindowItem *) itemWithWindow: (NSWindow *)window
{
	return AUTORELEASE([[ETWindowItem alloc] initWithWindow: window]);
}

/** Returns a new window item to which a fullscreen concrete window gets bound.

The returned item can be used as a decorator to make an existing layout item 
full screen. 

The concrete window class used is ETFullScreenWindow. */
- (ETWindowItem *) fullScreenWindow
{
	ETWindowItem *window = [self itemWithWindow: AUTORELEASE([[ETFullScreenWindow alloc] init])];
	[window setShouldKeepWindowFrame: YES];
	return window;
}

/* Layer Factory Methods */

/** Returns a new blank layer. 

See ETLayer to understand the difference between a layer and a layout item group. */
- (ETLayer *) layer
{
	return (ETLayer *)AUTORELEASE([[ETLayer alloc] init]);
}

/** Returns a new layer which contains the given item as a child. */
- (ETLayer *) layerWithItem: (ETLayoutItem *)item
{	
	return [self layerWithItems: [NSArray arrayWithObject: item]];
}

/** Returns a new layer which contains the given items as children. */
- (ETLayer *) layerWithItems: (NSArray *)items
{
	ETLayer *layer = [[ETLayer alloc] init];
	
	if (layer != nil)
	{
		[layer addItems: items];
	}
	
	return (ETLayer *)AUTORELEASE(layer);
}

// TODO: Implement
- (ETLayer *) guideLayer
{
	return (ETLayer *)AUTORELEASE([[ETLayer alloc] init]);
}

// TODO: Implement
- (ETLayer *) gridLayer
{
	return (ETLayer *)AUTORELEASE([[ETLayer alloc] init]);
}

/* Special Group Access Methods */

/** Returns the absolute root group usually located in the UI server.

This root group representing the whole environment is the only layout item 
with truly no parent.

WARNING: Not yet implemented. */
- (id) rootGroup
{
	return nil;
}

//static ETLayoutItemGroup *localRootGroup = nil;

/** Returns the local root group which represents the current work context or 
application.

WARNING: You should avoid to use this method. For now, it returns -windowGroup 
as the local root group, but this probably won't be the case in the future. 
This method might also removed. -windowGroup is the method you are encouraged 
to use.

When the UI server is running, the local root group is inserted as a child in a  
parent located in the UI server process. When no UI server is available, the 
local root group will have no parent.
 
ETApplication returns the same item when you call -layoutItem method 
(unless the method has been overriden). This might not hold in the future either.  */
- (id) localRootGroup
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

/** Returns the item representing the main screen.

TODO: Implement or rethink... */
- (id) screen
{
	return nil;
}

/** Returns the item group representing all screens available (usually the 
screens connected to the computer).

TODO: Implement or rethink... */
- (id) screenGroup
{
	return nil;
}

/** Returns the item group representing the active project.

TODO: Implement or rethink... */
- (id) project
{
	return nil;
}

/** Returns the item group representing all projects. 

TODO: Implement or rethink... */
- (id) projectGroup
{
	return nil;
}

static ETWindowLayer *windowLayer = nil;

/** Returns the item group representing all windows in the current work 
context or application. */
- (ETLayoutItemGroup *) windowGroup
{
	if (windowLayer == nil)
	{
		ASSIGN(windowLayer, [[ETWindowLayer alloc] init]);
		RELEASE(windowLayer);
		[windowLayer setName: _(@"Windows")];
	}
	
	return windowLayer;
}

/** Sets the item group representing all windows in the current work context or 
application. 

It is usually advised to pass an ETWindowLayer instance in parameter. */
- (void) setWindowGroup: (ETLayoutItemGroup *)windowGroup
{
	ASSIGN(windowLayer, windowGroup);
}

static ETLayoutItemGroup *pickboardGroup = nil;

/** Returns the item group representing all pickboards including both 
system-wide pickboards and those local to the current work context or application.

TODO: Finish to implement, the returned group is empty currently... */
- (id) pickboardGroup
{
	if (pickboardGroup == nil)
	{
		pickboardGroup = [[ETLayoutItemGroup alloc] init];
		[pickboardGroup setName: _(@"Pickboards")];
	}
	
	return pickboardGroup;
}

/* Shape Factory Methods */

/* Returns a new layout item which uses a shape as both its represented object 
and style. */
- (ETLayoutItem *) itemWithShape: (ETShape *)aShape inFrame: (NSRect)aRect
{
	NSParameterAssert(NSEqualSizes(aRect.size, [[aShape path] bounds].size));
	ETLayoutItem *item = [self itemWithRepresentedObject: aShape];
	[item setStyle: aShape];
	[item setFrame: aRect];
	return item;
}

/** Returns a new layout item which represents a custom shape based on the given 
bezier path. The shape is used as both the represented object and the style. */
- (ETLayoutItem *) itemWithBezierPath: (NSBezierPath *)aPath
{
	return [self itemWithShape: [ETShape shapeWithBezierPath: aPath]
	                   inFrame: ETMakeRect(NSZeroPoint, [aPath bounds].size)];
}

/** Returns a new layout item which represents a rectangular shape with the 
width and height of the given rect. */
- (ETLayoutItem *) rectangleWithRect: (NSRect)aRect
{
	return [self itemWithShape: [ETShape rectangleShapeWithRect: ETMakeRect(NSZeroPoint, aRect.size)] 
	                   inFrame: aRect];
}

/** Returns a new layout item which represents a rectangular shape with the 
width and height of +[ETShape defaultShapeRect]. */
- (ETLayoutItem *) rectangle
{
	return [self rectangleWithRect: ETMakeRect(NSZeroPoint, [ETShape defaultShapeRect].size)];
}

/** Returns a new layout item which represents an oval shape that fits in the 
width and height of the given rect. */
- (ETLayoutItem *) ovalWithRect: (NSRect)aRect
{
	return [self itemWithShape: [ETShape ovalShapeWithRect: ETMakeRect(NSZeroPoint, aRect.size)]
	                   inFrame: aRect];
}

/** Returns a new layout item which represents an oval shape that fits in the 
width and height of +[ETShape defaultShapeRect]. */
- (ETLayoutItem *) oval
{
	return [self ovalWithRect: ETMakeRect(NSZeroPoint, [ETShape defaultShapeRect].size)];
}


@end
