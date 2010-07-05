/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETLayoutItemFactory.h"
#import "ETActionHandler.h"
#import "ETBasicItemStyle.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItemGroup.h"
#import "ETLayer.h"
#import "ETLineLayout.h"
#import "ETScrollableAreaItem.h"
#import "ETWindowItem.h"
#import "ETContainer.h"
#import "ETStyle.h"
#import "ETShape.h"
#import "NSWindow+Etoile.h"
#include <float.h>
#import "ETCompatibility.h"


@implementation ETLayoutItemFactory

static NSMapTable *factorySharedInstances = nil;

/** <override-never />
Returns the shared instance that corresponds to the receiver class. */	
+ (id) factory
{
	if (factorySharedInstances == nil)
	{
		ASSIGN(factorySharedInstances, [NSMapTable mapTableWithStrongToStrongObjects]);
	}

	ETLayoutItemFactory *factory = [factorySharedInstances  objectForKey: self];

	if (factory == nil)
	{
		factory = AUTORELEASE([[self alloc] init]);
		[factorySharedInstances setObject: factory forKey: self];
	}

	return factory;
}

- (id) init
{
	SUPERINIT
	[self setCurrentBarElementStyle: [ETBasicItemStyle iconAndLabelBarElementStyle]];
	[self setCurrentBarElementHeight: [self defaultIconAndLabelBarHeight]];
	return self;
}

- (void) dealloc
{
	DESTROY(_currentBarElementStyle);
	[super dealloc];
}

/* Bar Building Settings */

/** Returns the style applied to all the bar elements to be built. */
- (ETStyle *) currentBarElementStyle
{
	return _currentBarElementStyle;
}

/** Sets the style to apply to all the bar elements to be built. */
- (void) setCurrentBarElementStyle: (ETStyle *)aStyle
{
	ASSIGN(_currentBarElementStyle, aStyle);
}

/** Returns the height applied to all the bar elements to be built. */
- (float) currentBarElementHeight
{
	return _currentBarElementHeight;
}

/** Sets the height to apply to all the bar elements to be built. */
- (void) setCurrentBarElementHeight: (float)aHeight
{
	_currentBarElementHeight = aHeight;
}

/** Returns the standard bar height to fit labelled bar elements.

This bar height is set as the current bar element height when the receiver is 
initialized.

This height is also identical to the standard toolbar height in Aqua. */
- (float) defaultIconAndLabelBarHeight
{
	return 53;

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
	return (ETLayoutItem *)AUTORELEASE([[ETLayoutItem alloc] initWithView: view value: nil representedObject: nil]);
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
	return (ETLayoutItem *)AUTORELEASE([[ETLayoutItem alloc] initWithView: nil value: value representedObject: nil]);
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
	return (ETLayoutItem *)AUTORELEASE([[ETLayoutItem alloc] initWithView: nil value: nil representedObject: object]);
}

/** <override-never /> 
Returns the layout item set up as a bar element with the given label and the 
shared style returned by -currentBarElementStyle.  */
- (ETLayoutItem *) barElementFromItem: (ETLayoutItem *)anItem 
                            withLabel: (NSString *)aLabel
{
	return [self barElementFromItem: anItem 
	                      withLabel: aLabel 
	                          style: [self currentBarElementStyle]]; 
}

/** Returns the layout item set up as a bar element with the given label and item style. */
- (ETLayoutItem *) barElementFromItem: (ETLayoutItem *)anItem 
                            withLabel: (NSString *)aLabel
                                style: (ETStyle *)aStyle
{
	NSSize initialSize = [anItem size];

	[anItem setName: aLabel];
	[anItem setCoverStyle: aStyle];
	[anItem setContentAspect: ETContentAspectComputed];
	//[anItem setBoundingBox: [aStyle boundingBoxForItem: anItem]];
	// NOTE: Must follow -setContentAspect:
	[anItem setHeight: [self currentBarElementHeight]];

	id view = [anItem view];
	BOOL isButtonView = [view isMemberOfClass: [NSButton class]]; 
	BOOL isUntitledButtonView = (isButtonView && ([view title] == nil || [[view title] isEqual: @""]));
	BOOL isImageOnlyButtonView = (isButtonView && isUntitledButtonView && [view image] != nil);
	BOOL needsButtonBehavior = (isImageOnlyButtonView || nil != [anItem image]);
	BOOL usesFlexibleWidth = (nil != view && NO == isImageOnlyButtonView);

	if (isImageOnlyButtonView)
	{
		[anItem setImage: [(NSButton *)view image]];
		[anItem setAction: [(NSControl *)view action]];
		[anItem setTarget: [(NSControl *)view target]];
		[anItem setView: nil];
	}
	if (needsButtonBehavior)
	{
		[anItem setActionHandler: [ETButtonItemActionHandler sharedInstance]];
	}

	if (usesFlexibleWidth)
	{
		[anItem setWidth: [[anItem coverStyle] boundingSizeForItem: anItem 
		                                           imageOrViewSize: initialSize].width];
	}

	return anItem;
}

/* Group Factory Methods */

/** Returns a new blank layout item group. */
- (ETLayoutItemGroup *) itemGroup
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] init]);
}

/** Returns a new blank layout item group initialized with the given frame. */
- (ETLayoutItemGroup *) itemGroupWithFrame: (NSRect)aRect
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithFrame: aRect]);
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
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithItems: items view: nil value: nil representedObject: nil]);
}

/** Returns a new layout item group which represents the given object and 
treats it as a simple value rather than a full-blown model object.

NOTE: This method is still under evaluation. You should rarely need to use it.   
It is useful to organize multiple value items in a hierarchical structure 
with a layout such as ETOutlineLayout. e.g a single column might be allowed to 
be visible at a time, then this column is usually bound to the 'value' property 
and item groups have to be labeled/named with the 'value' property.

See also -itemWithValue:. */
- (ETLayoutItemGroup *) itemGroupWithValue: (id)value
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithView: nil value: value representedObject: nil]);
}

/** Returns a new layout item group which represents the given object, usually 
a collection.

The represented object is a model object in an MVC perspective, the layout item 
group normally interacts with it through the Property Value Coding protocol and  
possibly the Collection protocols to traverse the object graph connected to it.

See also -itemWithRepresentedObject:. */
- (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object
{
	return AUTORELEASE([[ETLayoutItemGroup alloc] initWithView: nil value: nil representedObject: object]);
}

/** Returns a new layout item group set up as a graphics group with 
ETGraphicsGroupStyle as style and ETFreeLayout as layout.

You can use it to build structured graphics editor. e.g. ETSelectTool uses it 
when you request the grouping of several items. */
- (ETLayoutItemGroup *) graphicsGroup
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	[itemGroup setCoverStyle: AUTORELEASE([[ETGraphicsGroupStyle alloc] init])];
	[itemGroup setLayout: [ETFreeLayout layout]];
	return itemGroup;
}

/** Returns a new layout item group set up as an bar element group with 
ETBarStyle as style and ETLineLayout as layout.

Also resets the current bar element style to 
-[ETBasicItemStyle iconAndLabelBarElementStyle] to ensure new bar elements 
share the same style.<br />
And resets the current bar element height to the given size height.

The returned bar has a flexible width and a fixed height. */
- (ETLayoutItemGroup *) horizontalBarWithSize: (NSSize)aSize
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithFrame: ETMakeRect(NSZeroPoint, aSize)];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setLayout: [ETLineLayout layout]];
	[self setCurrentBarElementStyle: [ETBasicItemStyle iconAndLabelBarElementStyle]];
	[self setCurrentBarElementHeight: aSize.height];
	return itemGroup;
}

/* Widget Factory Methods */

/** Returns the basic rect used by the methods that returns widget-based items. 

Many widget factory methods use a custom height, see -defaultWidgetFrameWithHeight:. */
- (NSRect) defaultWidgetFrame
{
	return NSMakeRect(0, 0, 100, 20);
}

/** Returns the same rect than -defaultWidgetFrame but with a custom height. */
- (NSRect) defaultWidgetFrameWithHeight: (float)aHeight
{
	NSRect frame = [self defaultWidgetFrame];
	frame.size.height = aHeight;
	return frame;
}

/* No equivalent in Aqua guidelines but the size corresponds to the icon button 
although it is not one (it is more akin a bevel button without a label). */
- (NSRect) defaultImageButtonFrame
{
	NSRect frame = [self defaultWidgetFrame];
	frame.size = NSMakeSize(53, 53);
	return frame;
}

- (float) defaultButtonHeight
{
#ifdef GNUSTEP
	return 24;
#else
	return 32;
#endif
}

- (float) defaultCheckboxHeight
{
#ifdef GNUSTEP
	return 16;
#else
	return 18;
#endif
}

- (float) defaultRadioButtonHeight
{
	return [self defaultCheckboxHeight];
}

- (float) defaultPopUpMenuHeight
{
#ifdef GNUSTEP
	return 22;
#else
	return 26;
#endif
}

- (float) defaultProgressIndicatorHeight
{
#ifdef GNUSTEP
	return 18;
#else
	return 20;
#endif
}

- (float) defaultSliderThickness
{
#ifdef GNUSTEP
	return 16;
#else
	return 21;
#endif
}

- (float) defaultStepperHeight
{
#ifdef GNUSTEP
	return 23;
#else
	return 27;
#endif
}

- (float) defaultTextFieldHeight
{
#ifdef GNUSTEP
	return 21;
#else
	return 22;
#endif
}

- (float) defaultLabelHeight
{
#ifdef GNUSTEP
	return 18;
#else
	return 17;
#endif
}

- (id) makeItemWithViewClass: (Class)class height: (float)aHeight
{
	id view = AUTORELEASE([[class alloc] initWithFrame: [self defaultWidgetFrameWithHeight: aHeight]]);

	return [self itemWithView: view];
}

/** Returns a new layout item that uses a NSButton instance as its view. */
- (id) button
{
	return [self makeItemWithViewClass: [NSButton class] height: [self defaultButtonHeight]];
}

/** Returns a new layout item that uses a NSButton instance as its view, and 
initializes this button with the given image, target and action. */
- (id) buttonWithImage: (NSImage *)anImage target: (id)aTarget action: (SEL)aSelector
{
	NSButton *buttonView = AUTORELEASE([[NSButton alloc] initWithFrame: [self defaultImageButtonFrame]]);

	[buttonView setImagePosition: NSImageOnly];
	[buttonView setImage: anImage];
	[buttonView setTarget: aTarget];
	[buttonView setAction: aSelector];
	[buttonView setTitle: nil];

	return [self itemWithView: buttonView];
}

/** Returns a new layout item that uses a NSButton instance as its view, and 
initializes this button with the given title, target and action.

The bezel style is set to NSRoundedBezelStyle on Mac OS X. */
- (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector
{
	ETLayoutItem *buttonItem = [self button];
	NSButton *buttonView = (NSButton *)[buttonItem view];

#ifndef GNUSTEP
	[buttonView setBezelStyle: NSRoundedBezelStyle];
#endif
	[buttonView setTitle: aTitle];
	[buttonView setTarget: aTarget];
	[buttonView setAction: aSelector];

	return buttonItem;
}

/** Returns a new layout item that uses a NSButton of type NSRadioButton as its 
view. */
- (id) radioButton
{
	ETLayoutItem *item = [self makeItemWithViewClass: [NSButton class] 
	                                         height: [self defaultRadioButtonHeight]];
	[(NSButton *)[item view] setButtonType: NSRadioButton];
	return item;
}

/** Returns a new layout item that uses a NSButton of type NSSwitchButton as 
its view, and initializes this checkbox with the given label, target and action.

You can provide a model object on which -setValue:forProperty: will be invoked 
for the given property every time the checkbox state changes.<br />
The model object and property name are used to initialize a property viewpoint 
which is set as the returned item represented object. The property view point 
is also initialized to treat dictionary keys as properties, so you can use a 
dictionary as model.

Both model and property name must be valid objects when they are not nil. */
- (id) checkboxWithLabel: (NSString *)aLabel 
                  target: (id)aTarget 
                  action: (SEL)aSelector
             forProperty: (NSString *)aKey
                 ofModel: (id)aModel 
{
	id item = [self makeItemWithViewClass: [NSButton class]
	                              height: [self defaultCheckboxHeight]];
	NSButton *buttonView = (NSButton *)[item view];

	[buttonView setTitle: aLabel];
	[buttonView setButtonType: NSSwitchButton];
	[buttonView setTarget: aTarget];
	[buttonView setAction: aSelector];

	if (nil != aKey || nil != aModel)
	{
		/* Will raise an NSUndefinedKeyException when the model has no such key  */
		NS_DURING

			[aModel valueForKey: aKey];

		NS_HANDLER
			[NSException raise: NSInvalidArgumentException format: @"To be used as a "
				"checkbox model, %@ must be KVC-compliant for %@", aModel, aKey];
		NS_ENDHANDLER
	}

	[item setRepresentedObject: [ETProperty propertyWithName: aKey
	                                       representedObject: aModel]];
	[[item representedObject] setTreatsAllKeysAsProperties: YES];

	return item;
}

/** Returns a new label item that uses a NSTextField without border 
and background as its view. */
- (id) labelWithTitle: (NSString *)aTitle
{
	id item = [self makeItemWithViewClass: [NSTextField class] 
	                              height: [self defaultLabelHeight]];
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
	return [self makeItemWithViewClass: [NSTextField class] 
	                           height: [self defaultTextFieldHeight]];
}

/** Returns a new layout item that uses a NSSearchField instance as its view, and 
initializes this search field with the given target and action.  */
- (id) searchFieldWithTarget: (id)aTarget action: (SEL)aSelector
{
	NSRect frame = [self defaultWidgetFrameWithHeight: [self defaultTextFieldHeight]];
	NSSearchField *searchField = AUTORELEASE([[NSSearchField alloc] initWithFrame: frame]);
	[searchField setTarget: aTarget];
	[searchField setAction: aSelector];
	return [self itemWithView: searchField];
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
	return [self makeItemWithViewClass: [NSProgressIndicator class] 
	                           height: [self defaultProgressIndicatorHeight]];
}

/** Returns a new layout item that uses a vertically oriented NSSlider instance 
as its view. */
- (id) verticalSlider
{
	NSRect frame = [self defaultWidgetFrame];
	frame.size.height = frame.size.width;
	frame.size.width = [self defaultSliderThickness];
	NSSlider *sliderView = AUTORELEASE([[NSSlider alloc] initWithFrame: frame]);

	return [self itemWithView: sliderView];
}

/** Returns a new layout item that uses a horizontally oriented NSSlider instance 
as its view. */
- (id) horizontalSlider
{
	// NOTE: Might be better to invoke -horizontalSliderWithWidth:XXX.
	return [self makeItemWithViewClass: [NSSlider class]
	                           height: [self defaultSliderThickness]];
}

- (id) horizontalSliderWithWidth: (float)aWidth
                        minValue: (float)min 
                        maxValue: (float)max
                    initialValue: (float)aValue
                          target: (id)aTarget
                          action: (SEL)aSelector
                     forProperty: (NSString *)aKey
                         ofModel: (id)anObject
{
	ETLayoutItem *item = [self makeItemWithViewClass: [NSSlider class]
	                                         height: [self defaultSliderThickness]];
	NSSlider *sliderView = (NSSlider *)[item view];

	[sliderView setMinValue: min];
	[sliderView setMaxValue: max];
	[sliderView setFloatValue: aValue];
	[sliderView setTarget: aTarget];
	[sliderView setAction: aSelector];

	[item setWidth: aWidth];
	[item setAutoresizingMask: ETAutoresizingNone];
	if (nil != aKey && nil != anObject)
	{
		[item setRepresentedObject: [ETProperty propertyWithName: aKey
		                                       representedObject: anObject]];
		[[item representedObject] setTreatsAllKeysAsProperties: YES];
	}

	return item;
}

/** Returns a new layout item that uses a horizontally oriented NSSlider instance 
as its view. */
- (id) horizontalSliderWithWidth: (float)aWidth 
                        minValue: (float)min 
                        maxValue: (float)max
                    initialValue: (float)aValue 
                          target: (id)aTarget 
                          action: (SEL)aSelector
{
	return [self horizontalSliderWithWidth: aWidth minValue: min maxValue: max
		initialValue: aValue target: aTarget action: aSelector forProperty: nil ofModel: nil];
}

/** Returns a new layout item that uses a horizontally oriented NSSlider instance 
as its view. */
- (id) horizontalSliderWithWidth: (float)aWidth
                        minValue: (float)min 
                        maxValue: (float)max
                     forProperty: (NSString *)aKey
                         ofModel: (id)anObject
{
	return [self horizontalSliderWithWidth: aWidth minValue: min maxValue: max
		initialValue: (max - min) target: nil action: NULL forProperty: aKey ofModel: anObject];
}


/** Returns a new layout item that uses a NSStepper instance as its view. */
- (id) stepper
{
	return [self makeItemWithViewClass: [NSStepper class]
	                           height: [self defaultStepperHeight]];
}

/** Returns a new layout item that uses a view whose subviews are a text field 
and a stepper on the right side. */
- (id) textFieldAndStepper
{
	// TODO: Implement
	return nil;
}

// TODO: -popUpMenuWithTitleXXX should return an ETLayoutItemGroup whose layout 
// is ETPopUpMenuLayout.
// Then we could add a method -popUpMenuWithTitle:items:target:action:.

/** Returns a new layout item that uses a NSPopUpButton instance as its view, 
and initializes this pop-up button with the given title, target, action and 
entries to be put in the menu. 

When entryModels is not nil, each element is set as the represented object of 
the menu entry with the same index in entryTitles. You can pass [NSNull null] 
to set no represented object on a menu entry. */
- (id) popUpMenuWithItemTitles: (NSArray *)entryTitles 
            representedObjects: (NSArray *)entryModels 
                        target: (id)aTarget 
                        action: (SEL)aSelector
{
	NSRect frame = [self defaultWidgetFrameWithHeight: [self defaultPopUpMenuHeight]];
	NSPopUpButton *popUpView = AUTORELEASE([[NSPopUpButton alloc] initWithFrame: frame]);

	[popUpView addItemsWithTitles: entryTitles];

	for (int i = 0; i < [popUpView numberOfItems] && i < [entryModels count]; i++)
	{
		id repObject = [entryModels objectAtIndex: i];

		if ([repObject isEqual: [NSNull null]])
		{
			repObject = nil;
		}
		[[popUpView itemAtIndex: i] setRepresentedObject: repObject];
	}

	[popUpView setTarget: aTarget];
	[popUpView setAction: aSelector];

	return [self itemWithView: popUpView];
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
	[item setCoverStyle: nil];
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


/* Seperator Factory Methods */

/** Returns a new layout item that uses a NSBox instance as its view.

The returned separator is initially an horizontal line, but by resizing with a 
height greater than its width, it becomes a vertical line. */
- (ETLayoutItem *) lineSeparator
{
	NSBox *separatorView = AUTORELEASE([[NSBox alloc] initWithFrame: NSMakeRect(0, 0, 50, 5)]);
	[separatorView setBoxType: NSBoxSeparator];
	return [self itemWithView: separatorView];
}

- (ETLayoutItem *) spaceSeparator
{
	return [self oval];
}

- (ETLayoutItem *) flexibleSpaceSeparator
{
	return [self oval];
}

/* Deprecated */

/** Deprecated. You must use -itemGroup now. */
- (ETLayoutItemGroup *) itemGroupWithContainer
{
	ETContainer *container = AUTORELEASE([[ETContainer alloc] init]);
	// FIXME: Remove this temporary workaround...
	[container setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	return (ETLayoutItemGroup *)[container layoutItem];
}

@end


@implementation ETUIItemFactory

- (ETWindowItem *) itemWithWindow: (NSWindow *)window
{
	return [ETWindowItem itemWithWindow: window];
}

- (ETWindowItem *) fullScreenWindow
{
	return [ETWindowItem fullScreenItem];
}

- (ETWindowItem *) transparentFullScreenWindow
{
	return [ETWindowItem transparentFullScreenItem];
}

- (ETScrollableAreaItem *) itemWithScrollView: (NSScrollView *)scrollView
{
	return [ETScrollableAreaItem itemWithScrollView: scrollView];
}

@end
