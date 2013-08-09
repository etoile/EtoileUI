/**
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETMutableObjectViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETLayoutItemFactory.h"
#import "ETActionHandler.h"
#import "ETAspectRepository.h"
#import "ETBasicItemStyle.h"
#import "ETColumnLayout.h"
#import "ETFreeLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem+Scrollable.h"
#import "ETLayer.h"
#import "ETLineLayout.h"
#import "ETNumberPicker.h"
#import "ETScrollableAreaItem.h"
#import "ETWindowItem.h"
#import "ETSelectTool.h"
#import "ETStyle.h"
#import "ETShape.h"
#import "ETTableLayout.h"
#import "NSWindow+Etoile.h"
#include <float.h>
#import "ETCompatibility.h"


@implementation ETLayoutItemFactory

static NSMapTable *factorySharedInstances = nil;

/** <override-never />
Returns a shared instance that instantiates new items in a transient object 
graph context.

For each ETLayoutItemFactory subclass, returns a distinct shared instance. 
The object graph context remains the same accross all these shared instances. */
+ (id) factory
{
	return [self factoryWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
}

/** <override-never />
Returns a shared instance that instantiates new items in the given object graph 
context.
 
For each ETLayoutItemFactory subclass and object graph context combination, 
returns a distinct shared instance. */
+ (id) factoryWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	if (factorySharedInstances == nil)
	{
		ASSIGN(factorySharedInstances, [NSMapTable mapTableWithStrongToStrongObjects]);
	}
	
	ETLayoutItemFactory *factory = [factorySharedInstances objectForKey: self];
	
	if (factory == nil)
	{
		factory = AUTORELEASE([[self alloc] initWithObjectGraphContext: aContext]);
		[factorySharedInstances setObject: factory forKey: self];
	}
	else
	{
		ASSIGN(factory->_objectGraphContext, aContext);
	}
	return factory;
}

/** <init />
Intializes and returns an item factory that instantiates new items in the given 
object graph context.
 
For a nil context, raises an NSInvalidArgumentException. */
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	NILARG_EXCEPTION_TEST(aContext);
	INVALIDARG_EXCEPTION_TEST(aContext, [aContext isKindOfClass: [COObjectGraphContext class]]);
	SUPERINIT;
	ASSIGN(_objectGraphContext, aContext);
	ETStyle *barElementStyle =
		[ETBasicItemStyle iconAndLabelBarElementStyleWithObjectGraphContext: aContext];
	[self setCurrentBarElementStyle: barElementStyle];
	[self setCurrentBarElementHeight: [self defaultIconAndLabelBarHeight]];
	return self;
}

- (id) init
{
	return [self initWithObjectGraphContext: nil];
}

- (void) dealloc
{
	DESTROY(_objectGraphContext);
	DESTROY(_currentCoverStyle);
	DESTROY(_currentActionHandler);
	DESTROY(_currentBarElementStyle);
	[super dealloc];
}

- (COObjectGraphContext *)objectGraphContext
{
	return _objectGraphContext;
}

/** Declares a new root object scope.

Can be used to look up shared aspects to set on an item.

For example, cover style or action handler are shared aspects usually.

For each shared aspect, each root object should use its own instance. Aspects 
should usually be shared within a root object graph, but not between several 
root objects.<br />
To share an aspect between several root objects, the aspect has to be turned 
into a root object.

When -isCreatingRootObject returns NO, you should use +sharedInstance on the 
aspect class to get the shared aspect. See -currentCoverStyle and 
-currentActionHandler as examples. */
- (void) beginRootObject
{
	NSAssert(_isCreatingRootObject == NO, @"You must call -endRootObject to declare a new root object now");
	ETAssert(_currentCoverStyle == nil);
	ETAssert(_currentActionHandler == nil);
	_isCreatingRootObject = YES;
}

/** Ends the current root object scope.

See -beginRootObject. */
- (void) endRootObject
{
	_isCreatingRootObject = NO;
	DESTROY(_currentCoverStyle);
	DESTROY(_currentActionHandler);
}

/** Returns whether -beginRootObject has been called but not yet balanced by 
-endRootObject.

By default, returns NO. */
- (BOOL) isCreatingRootObject
{
	return _isCreatingRootObject;
}

/** Sets the item that provides the shared aspects for building bew objects. */
- (void) setAspectProviderItem: (ETLayoutItem *)anItem
{
	ASSIGN(_currentCoverStyle, [anItem coverStyle]);
	ASSIGN(_currentActionHandler, [anItem actionHandler]);
	_isCreatingRootObject = (anItem != nil);
}

/** Returns the shared cover style in the current root object graph.

See also -beginRootObject. */
- (ETStyle *) currentCoverStyle
{
	if ([self isCreatingRootObject] == NO)
		return [ETBasicItemStyle sharedInstanceForObjectGraphContext: [self objectGraphContext]];

	if (_currentCoverStyle == nil)
	{
		_currentCoverStyle = [[ETBasicItemStyle alloc] initWithObjectGraphContext: [self objectGraphContext]];
	}
	return _currentCoverStyle;
}

/** Returns the shared action handler in the current root object graph.

See also -beginRootObject. */
- (ETActionHandler *) currentActionHandler
{
	if ([self isCreatingRootObject] == NO)
		return [ETActionHandler sharedInstanceForObjectGraphContext: [self objectGraphContext]];

	if (_currentActionHandler == nil)
	{
		_currentActionHandler = [[ETActionHandler alloc] initWithObjectGraphContext: [self objectGraphContext]];
	}
	return _currentActionHandler;
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
- (CGFloat) currentBarElementHeight
{
	return _currentBarElementHeight;
}

/** Sets the height to apply to all the bar elements to be built. */
- (void) setCurrentBarElementHeight: (CGFloat)aHeight
{
	_currentBarElementHeight = aHeight;
}

/** Returns the standard bar height to fit labelled bar elements.

This bar height is set as the current bar element height when the receiver is 
initialized.

This height is also identical to the standard toolbar height in Aqua. */
- (CGFloat) defaultIconAndLabelBarHeight
{
	return 53;

}

/* Basic Item Factory Methods */

/** Return a new blank layout item. */
- (ETLayoutItem *) item
{
	return [self itemWithView: nil];
}

/** Returns a new layout item to which the given view gets bound. */
- (ETLayoutItem *) itemWithView: (NSView *)view
{
	ETLayoutItem *item = AUTORELEASE([[ETLayoutItem alloc] initWithView: view
                                                             coverStyle: [self currentCoverStyle]
	                                                      actionHandler: [self currentActionHandler]
	                                                 objectGraphContext: [self objectGraphContext]]);
	[item setIcon: [NSImage imageNamed: @"leaf"]];
	return item;
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
	ETLayoutItem *item = [self item];
	[item setRepresentedObject: object];
	return item;
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
	BOOL isUntitledButtonView =
		(isButtonView && ([view title] == nil || [[view title] isEqual: @""] || [view imagePosition] == NSImageOnly));
	BOOL isImageOnlyButtonView = (isButtonView && isUntitledButtonView && [view image] != nil);
	BOOL needsButtonBehavior = (isImageOnlyButtonView || nil != [anItem image]);

	if (isImageOnlyButtonView)
	{
		/* We replace the icon set in -itemWithView: and -buttonWithXXX */
		[anItem setIcon: [(NSButton *)view image]];
		[anItem setAction: [(NSControl *)view action]];
		[anItem setTarget: [(NSControl *)view target]];
		[anItem setView: nil];
	}
	if (needsButtonBehavior)
	{
		[anItem setActionHandler: [ETButtonItemActionHandler sharedInstanceForObjectGraphContext: [self objectGraphContext]]];
	}

	// TODO: Might not work well if the button view has a title, because the 
	// item will be resized to the button size. Not sure it is the best choice.
	BOOL isLabelled = (aLabel != nil || [aLabel isEqual: @""] == NO);
	BOOL usesFlexibleWidth = (nil != view || isLabelled);

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
	ETLayoutItemGroup *item = AUTORELEASE([[ETLayoutItemGroup alloc] initWithView: nil 
	                                                                   coverStyle: [self currentCoverStyle]
	                                                                actionHandler: [self currentActionHandler]
	                                                           objectGraphContext: [self objectGraphContext]]);
	[item setIcon: [NSImage imageNamed: @"leaf-plant"]];
	return item;
}

/** Returns a new blank layout item group initialized with the given frame. */
- (ETLayoutItemGroup *) itemGroupWithFrame: (NSRect)aRect
{
	ETLayoutItemGroup *item = [self itemGroup];
	[item setFrame: aRect];
	// NOTE: Could be better to tweak ETLayoutItemGroup designated initializer.
	// Don't use -resetLayoutSize that doesn't work for ETTemplateItemLayout.
	[item updateLayoutRecursively: NO];
	return item;
}

/** Returns a new blank layout item group initialized with an origin at zero and 
the given size. */
- (ETLayoutItemGroup *) itemGroupWithSize: (NSSize)aSize
{
	return [self itemGroupWithFrame: ETMakeRect(NSZeroPoint, aSize)];
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
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	[itemGroup addItems: items];
	return itemGroup;
}

/** Returns a new layout item group which represents the given object, usually 
a collection.

The represented object is a model object in an MVC perspective, the layout item 
group normally interacts with it through the Property Value Coding protocol and  
possibly the Collection protocols to traverse the object graph connected to it.

See also -itemWithRepresentedObject:. */
- (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	[itemGroup setRepresentedObject: object];
	return itemGroup;
}

/** Returns a new layout item group set up as a graphics group with 
ETGraphicsGroupStyle as style and ETFreeLayout as layout.

You can use it to build structured graphics editor. e.g. ETSelectTool uses it 
when you request the grouping of several items. */
- (ETLayoutItemGroup *) graphicsGroup
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	[itemGroup setCoverStyle: AUTORELEASE([[ETGraphicsGroupStyle alloc] initWithObjectGraphContext: [self objectGraphContext]])];
	[itemGroup setLayout: [ETFreeLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[itemGroup setIcon: [NSImage imageNamed: @"layers-group"]];
	return itemGroup;
}

/** Returns a new layout item group set up as an bar element group with 
ETBarStyle as style and ETLineLayout as layout.

Also resets the current bar element style to 
-[ETBasicItemStyle iconAndLabelBarElementStyleWithObjectGraphContext:] to ensure 
new bar elements share the same style.<br />
And resets the current bar element height to the given size height.

The returned bar has a flexible width and a fixed height. */
- (ETLayoutItemGroup *) horizontalBarWithSize: (NSSize)aSize
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithFrame: ETMakeRect(NSZeroPoint, aSize)];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	ETStyle *barElementStyle =
		[ETBasicItemStyle iconAndLabelBarElementStyleWithObjectGraphContext: [self objectGraphContext]];
	[self setCurrentBarElementStyle: barElementStyle];
	[self setCurrentBarElementHeight: aSize.height];
	return itemGroup;
}

/** Returns a new layout item group including a collection browser and buttons
 to edit the collection content using actions such as <em>Add</em> and
<em>Remove</em>.
 
Most items that make up the collection editor can be retrieved using 
-[ETLayoutItemGroup itemForIdentifier:] on the returned item group:

<deflist>
<item>collectionEditor</item><desc>the returned item group that encloses the 
collection editor UI</desc>
<item>browser</item><desc>the item group that presents the collection content</desc>
<item>bar</item><desc>the item group that contains the buttons at the bottom of 
the browser</desc>
<item>plusButton</item><desc>the item that calls the -add: action</desc>
<item>minusButton</item><desc>the item that calls the -remove: action</desc>
</deflist>
 
The bar that contains the buttons can be customized as desired. Just retrieve it 
using the right item identifier, and remove or add items to the returned item 
group.<br />
For actions, the items in the bar must use the controller as the target
usually (a nil target is not going to work to send a message to the controller, 
because the controller is not in the bar responder chain).
 
The controller is bound to the browser item. For setting actions or double 
actions, once the method returns, just follow this example:
 
<example>
[[controller content] setDoubleAction: @selector(edit:)];
[[controller content] setTarget: controller];
</example>
 
The returned collection editor has a flexible width and a fixed height. */
- (ETLayoutItemGroup *) collectionEditorWithSize: (NSSize)aSize
                               representedObject: (id <ETCollection>)aCollection
                                      controller: (id)aController
{
	NILARG_EXCEPTION_TEST(aCollection);
	NILARG_EXCEPTION_TEST(aController);

	ETLayoutItemGroup *editor = [self itemGroupWithFrame: ETMakeRect(NSZeroPoint, aSize)];

#ifdef GNUSTEP
	ETLayoutItem *plusButton = [self buttonWithTitle: @"+" target: aController action: @selector(add:)];
	ETLayoutItem *minusButton = [self buttonWithTitle: @"-" target: aController action: @selector(remove:)];
#else
	ETLayoutItem *plusButton = [self buttonWithImage: [NSImage imageNamed: NSImageNameAddTemplate] target: aController action: @selector(add:)];
	ETLayoutItem *minusButton = [self buttonWithImage: [NSImage imageNamed: NSImageNameRemoveTemplate] target: aController action: @selector(remove:)];
	[[[plusButton view] cell] setBezelStyle: NSSmallSquareBezelStyle];
	[[[minusButton view] cell] setBezelStyle: NSSmallSquareBezelStyle];
#endif
	// TODO: Perhaps rather provide -smallButtonWithImage:target:action:
	[plusButton setFrame: [self defaultSmallImageButtonFrame]];
	[minusButton setFrame: [self defaultSmallImageButtonFrame]];
	// FIXME: Set better identifiers perhaps and use constants
	[plusButton setIdentifier: @"plusButton"];
	[minusButton setIdentifier: @"minusButton"];
	
	ETLayoutItemGroup *buttonBar = [self horizontalBarWithSize: NSMakeSize(aSize.width, [plusButton height])];
	NSRect browserFrame = NSMakeRect(0, 0, aSize.width, aSize.height - [plusButton height]);
	ETLayoutItemGroup *browser = [self itemGroupWithFrame: browserFrame];
	ETSelectTool *selectionTool = [ETSelectTool tool];

	[selectionTool setAllowsMultipleSelection: YES];

	// FIXME: Set a better identifiers perhap and use a constant
	[buttonBar setIdentifier: @"bar"];
	[buttonBar setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[buttonBar addItems: A(plusButton, minusButton)];

	[browser setIdentifier: @"browser"];
	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[browser setLayout: [ETTableLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[browser layout] setAttachedTool: selectionTool];
	[browser setHasVerticalScroller: YES];
	[browser setRepresentedObject: aCollection];
	[browser setSource: browser];
	[browser setController: aController];

	[editor setIdentifier: @"collectionEditor"];
	[editor setLayout: [ETColumnLayout layoutWithObjectGraphContext: [self objectGraphContext]]];

	[editor addItems: A(browser, buttonBar)];

	return editor;
}

/* Widget Factory Methods */

/** Returns the basic rect used by the methods that returns widget-based items. 

Many widget factory methods use a custom height, see -defaultWidgetFrameWithHeight:. */
- (NSRect) defaultWidgetFrame
{
	return NSMakeRect(0, 0, 100, 20);
}

/** Returns the same rect than -defaultWidgetFrame but with a custom height. */
- (NSRect) defaultWidgetFrameWithHeight: (CGFloat)aHeight
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

- (NSRect) defaultSmallImageButtonFrame
{
	NSRect frame = [self defaultWidgetFrame];
#ifdef GNUSTEP
	frame.size = NSMakeSize(24, 24);
#else
	frame.size = NSMakeSize(23, 23);
#endif
	return frame;
}

- (CGFloat) defaultButtonHeight
{
#ifdef GNUSTEP
	return 24;
#else
	return 32;
#endif
}

- (CGFloat) defaultCheckboxHeight
{
#ifdef GNUSTEP
	return 16;
#else
	return 18;
#endif
}

- (CGFloat) defaultRadioButtonHeight
{
	return [self defaultCheckboxHeight];
}

- (CGFloat) defaultPopUpMenuHeight
{
#ifdef GNUSTEP
	return 22;
#else
	return 26;
#endif
}

- (CGFloat) defaultProgressIndicatorHeight
{
#ifdef GNUSTEP
	return 18;
#else
	return 20;
#endif
}

- (CGFloat) defaultSliderThickness
{
#ifdef GNUSTEP
	return 16;
#else
	return 21;
#endif
}

- (CGFloat) defaultStepperHeight
{
#ifdef GNUSTEP
	return 23;
#else
	return 27;
#endif
}

- (CGFloat) defaultTextFieldHeight
{
#ifdef GNUSTEP
	return 21;
#else
	return 22;
#endif
}

- (CGFloat) defaultLabelHeight
{
#ifdef GNUSTEP
	return 18;
#else
	return 17;
#endif
}

- (id) makeItemWithViewClass: (Class)class height: (CGFloat)aHeight
{
	id view = AUTORELEASE([[class alloc] initWithFrame: [self defaultWidgetFrameWithHeight: aHeight]]);

	return [self itemWithView: view];
}

/** Returns a new layout item that uses a NSButton instance as its view. */
- (id) button
{
	ETLayoutItem *item = [self makeItemWithViewClass: [NSButton class] height: [self defaultButtonHeight]];
	[item setIcon: [NSImage imageNamed: @"ui-button.png"]];
	return item;
}

/** Returns a new layout item that uses a NSButton instance as its view, and 
initializes this button with the given image, target and action. */
- (id) buttonWithImage: (NSImage *)anImage target: (id)aTarget action: (SEL)aSelector
{
	NSButton *buttonView = AUTORELEASE([[NSButton alloc] initWithFrame: [self defaultImageButtonFrame]]);

	[buttonView setImage: anImage];
	[buttonView setTarget: aTarget];
	[buttonView setAction: aSelector];
	[buttonView setTitle: nil];
	/* -setTitle: resets the image position */
	[buttonView setImagePosition: NSImageOnly];
	
	ETLayoutItem *item = [self itemWithView: buttonView];
	[item setIcon: [NSImage imageNamed: @"ui-button.png"]];
	ETAssert([buttonView imagePosition] == NSImageOnly);
	return item;
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

	if (aModel == nil)
		return item;

	if (aKey == nil)
	{
		[NSException raise: NSInvalidArgumentException
					format: @"Missing property for checkbox model %@", aModel];
	}

	/* Will raise an NSUndefinedKeyException when the model has no such key  */
	NS_DURING

		[aModel valueForKey: aKey];

	NS_HANDLER
		[NSException raise: NSInvalidArgumentException format: @"To be used as a "
			"checkbox model, %@ must be KVC-compliant for %@", aModel, aKey];
	NS_ENDHANDLER


	[item setRepresentedObject: [ETMutableObjectViewpoint viewpointWithName: aKey
	                                                      representedObject: aModel]];
	[[item representedObject] setUsesKeyValueCodingForAccessingValueProperties: YES];

	return item;
}

/** <override-never />
Returns a new layout item that uses a NSButton of type NSSwitchButton as its view.
 
See also -checkboxWithLabel:target:action:forProperty:ofModel:. */
- (id) checkBox
{
	return [self checkboxWithLabel: @"" target: nil action: NULL forProperty: nil ofModel: nil];
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
	[item setIcon: [NSImage imageNamed: @"ui-label"]];

	return item;
}

/** Returns a new layout item that uses a NSTextField instance as its view. */
- (ETLayoutItem *) textField
{
	ETLayoutItem *item = [self makeItemWithViewClass: [NSTextField class] 
	                                          height: [self defaultTextFieldHeight]];
	[item setIcon: [NSImage imageNamed: @"ui-text-field"]];
	return item;
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
	/* Finally reinsert the text view as a scroll view */
	ETLayoutItem *textViewItem = [self itemWithView: scrollview];

	NSParameterAssert([textView superview] != nil);
	return textViewItem;
}

/** Returns a new layout item that uses a NSProgressIndicator instance as its view. */
- (id) progressIndicator
{
	ETLayoutItem *item = [self makeItemWithViewClass: [NSProgressIndicator class] 
	                                          height: [self defaultProgressIndicatorHeight]];
	[item setIcon: [NSImage imageNamed: @"ui-progress-bar"]];
	return item;
}

/** Returns a new layout item that uses a vertically oriented NSSlider instance 
as its view. */
- (id) verticalSlider
{
	NSRect frame = [self defaultWidgetFrame];
	frame.size.height = frame.size.width;
	frame.size.width = [self defaultSliderThickness];
	NSSlider *sliderView = AUTORELEASE([[NSSlider alloc] initWithFrame: frame]);

	ETLayoutItem *item = [self itemWithView: sliderView];
	[item setIcon: [NSImage imageNamed: @"ui-slider-vertical-050"]];
	return item;
}

/** Returns a new layout item that uses a horizontally oriented NSSlider instance 
as its view.

The slider minimum value is set to 0, the maximum value to 100 and the initial 
value to 50. */
- (id) horizontalSlider
{
	// NOTE: Might be better to invoke -horizontalSliderWithWidth:XXX.
	ETLayoutItem *item = [self horizontalSliderWithWidth: [self defaultWidgetFrame].size.width
		minValue: 0 maxValue: 100 initialValue: 50 target: nil action: NULL];
	[item setIcon: [NSImage imageNamed: @"ui-slider-050"]];
	return item;
}

- (id) horizontalSliderWithWidth: (CGFloat)aWidth
                        minValue: (CGFloat)min 
                        maxValue: (CGFloat)max
                    initialValue: (CGFloat)aValue
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
		[item setRepresentedObject: [ETMutableObjectViewpoint viewpointWithName: aKey
		                                                      representedObject: anObject]];
		[[item representedObject] setUsesKeyValueCodingForAccessingValueProperties: YES];
	}

	return item;
}

/** Returns a new layout item that uses a horizontally oriented NSSlider instance 
as its view. */
- (id) horizontalSliderWithWidth: (CGFloat)aWidth 
                        minValue: (CGFloat)min 
                        maxValue: (CGFloat)max
                    initialValue: (CGFloat)aValue 
                          target: (id)aTarget 
                          action: (SEL)aSelector
{
	return [self horizontalSliderWithWidth: aWidth minValue: min maxValue: max
		initialValue: aValue target: aTarget action: aSelector forProperty: nil ofModel: nil];
}

/** Returns a new layout item that uses a horizontally oriented NSSlider instance 
as its view. */
- (id) horizontalSliderWithWidth: (CGFloat)aWidth
                        minValue: (CGFloat)min 
                        maxValue: (CGFloat)max
                     forProperty: (NSString *)aKey
                         ofModel: (id)anObject
{
	return [self horizontalSliderWithWidth: aWidth minValue: min maxValue: max
		initialValue: (max - min) target: nil action: NULL forProperty: aKey ofModel: anObject];
}


/** Returns a new layout item that uses a NSStepper instance as its view. */
- (id) stepper
{
	// TODO: Finish to implement or remove
	return [self makeItemWithViewClass: [NSStepper class]
	                           height: [self defaultStepperHeight]];
}

- (ETLayoutItem *) numberPicker
{
	return [self numberPickerWithWidth: [self defaultWidgetFrame].size.width
		minValue: -DBL_MAX maxValue: DBL_MAX initialValue: 0
		forProperty: nil ofModel: nil];
}

/** Returns a new layout item that uses a view whose subviews are a text field 
and a stepper on the right side. */
- (ETLayoutItem *) numberPickerWithWidth: (CGFloat)aWidth
                                minValue: (double)min
                                maxValue: (double)max
                            initialValue: (double)aValue
                             forProperty: (NSString *)aKey
                                 ofModel: (id)anObject
{
	NSRect frame = [self defaultWidgetFrameWithHeight: [self defaultStepperHeight]];
	ETNumberPicker *picker = AUTORELEASE([[ETNumberPicker alloc]
		initWithFrame: frame textFieldHeight: [self defaultTextFieldHeight]]);
	ETLayoutItem *item = [self itemWithView: picker];
	
	[picker setMinValue: min];
	[picker setMaxValue: max];
	[picker setDoubleValue: aValue];

	[item setWidth: aWidth];
	[item setAutoresizingMask: ETAutoresizingNone];

	if (nil != aKey && nil != anObject)
	{
		[item setRepresentedObject: [ETMutableObjectViewpoint viewpointWithName: aKey
		                                                      representedObject: anObject]];
		[[item representedObject] setUsesKeyValueCodingForAccessingValueProperties: YES];
	}
	
	return item;
}

- (NSRect) boundingBoxForItem: (ETLayoutItem *)item
{
	NSSize boundingSize = [[item coverStyle] boundingSizeForItem: item
												 imageOrViewSize: [item size]];
	NSRect boundingBox = ETMakeRect(NSZeroPoint, boundingSize);

	// TODO: May be better to compute that in -[ETBasicItemStyle boundingBoxForItem:]
	boundingBox.origin.x = ([item width] - boundingSize.width) / 2;

	return boundingBox;
}

- (ETLayoutItemGroup *) numberPairEditorWithWidth: (CGFloat)aWidth
                                 forFirstProperty: (NSString *)aFirstKey
                                   secondProperty: (NSString *)aSecondKey
                                          ofModel: (id)anObject
{
	ETLayoutItem *firstPicker = [self numberPickerWithWidth: aWidth / 2
		minValue: 0 maxValue: CGFLOAT_MAX initialValue: 0
		forProperty: aFirstKey ofModel: anObject];
	ETLayoutItem *secondPicker = [self numberPickerWithWidth: aWidth / 2
		minValue: 0 maxValue: CGFLOAT_MAX initialValue: 0
		forProperty: aSecondKey ofModel: anObject];
	ETBasicItemStyle *coverStyle = AUTORELEASE([ETBasicItemStyle new]);

	// FIXME: If no name is set, the number pickers are not visible
	[firstPicker setName: _(@"1")];
	[coverStyle setLabelPosition: ETLabelPositionOutsideBottom];
	[firstPicker setCoverStyle: coverStyle];
	[firstPicker setBoundingBox: [self boundingBoxForItem: firstPicker]];

	[secondPicker setName: _(@"2")];
	[coverStyle setLabelPosition: ETLabelPositionOutsideBottom];
	[secondPicker setCoverStyle: coverStyle];
	[secondPicker setBoundingBox: [self boundingBoxForItem: secondPicker]];

	NSSize size = NSMakeSize(aWidth, [firstPicker boundingBox].size.height);
	ETLayoutItemGroup *editor = [self itemGroupWithSize: size];

	[editor setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[editor layout] setComputesItemRectFromBoundingBox: YES];
	[editor addItems: A(firstPicker, secondPicker)];
	[editor updateLayout];

	return editor;
}

- (ETLayoutItemGroup *) pointEditorWithWidth: (CGFloat)aWidth
                                forXProperty: (NSString *)aXKey
                                   yProperty: (NSString *)aYKey
                                     ofModel: (id)anObject
{
	ETLayoutItemGroup *editor = [self numberPairEditorWithWidth: aWidth
	                                           forFirstProperty: aXKey
	                                             secondProperty: aYKey
	                                                    ofModel: anObject];

	[editor setIdentifier: @"pointEditor"];
	[[editor firstItem] setName: _(@"X")];
	[[editor lastItem] setName: _(@"Y")];

	return editor;
}

- (ETLayoutItemGroup *) sizeEditorWithWidth: (CGFloat)aWidth
                           forWidthProperty: (NSString *)aWidthKey
                             heightProperty: (NSString *)aHeightKey
                                    ofModel: (id)anObject
{
	ETLayoutItemGroup *editor = [self numberPairEditorWithWidth: aWidth
	                                           forFirstProperty: aWidthKey
	                                             secondProperty: aHeightKey
	                                                    ofModel: anObject];

	[editor setIdentifier: @"sizeEditor"];
	[[editor firstItem] setName: _(@"Width")];
	[[editor lastItem] setName: _(@"Height")];

	return editor;
}

- (ETLayoutItem *) popUpMenu
{
	return [self popUpMenuWithItemTitles: [NSArray array]
		representedObjects: [NSArray array] target: nil action: NULL];
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

static ETLayoutItemGroup *windowLayer = nil;

/** Returns the item group representing all windows in the current work 
context or application. */
- (ETLayoutItemGroup *) windowGroup
{
	if (windowLayer == nil)
	{
		windowLayer = [[ETWindowLayer alloc]
			initWithObjectGraphContext: [ETUIObject defaultTransientObjectGraphContext]];
		[windowLayer setName: _(@"Windows")];
	}
	
	return windowLayer;
}

static ETLayoutItemGroup *pickboardGroup = nil;

/** Returns the item group representing all pickboards including both 
system-wide pickboards and those local to the current work context or application.

TODO: Finish to implement, the returned group is empty currently... */
- (id) pickboardGroup
{
	if (pickboardGroup == nil)
	{
		pickboardGroup = [[ETLayoutItemGroup alloc] initWithObjectGraphContext: [self objectGraphContext]];
		[pickboardGroup setName: _(@"Pickboards")];
	}
	
	return pickboardGroup;
}

/* Shape Factory Methods */

/* Returns a new layout item which uses a shape as both its represented object 
and style. */
- (ETLayoutItem *) itemWithShape: (ETShape *)aShape inFrame: (NSRect)aRect
{
	NSParameterAssert(ETSizeEqualToSize(aRect.size, [[aShape path] bounds].size));
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
	return [self itemWithShape: [ETShape shapeWithBezierPath: aPath objectGraphContext: [self objectGraphContext]]
	                   inFrame: ETMakeRect(NSZeroPoint, [aPath bounds].size)];
}

/** Returns a new layout item which represents a rectangular shape with the 
width and height of the given rect. */
- (ETLayoutItem *) rectangleWithRect: (NSRect)aRect
{
	ETShape *shape = [ETShape rectangleShapeWithRect: ETMakeRect(NSZeroPoint, aRect.size)
	                              objectGraphContext: [self objectGraphContext]];
	ETLayoutItem *item = [self itemWithShape: shape inFrame: aRect];
	[item setIcon: [NSImage imageNamed: @"layer-shape"]];
	return item;
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
	ETShape *shape = [ETShape ovalShapeWithRect: ETMakeRect(NSZeroPoint, aRect.size)
	                         objectGraphContext: [self objectGraphContext]];
	return [self itemWithShape: shape inFrame: aRect];
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
	NSBox *separatorView = AUTORELEASE([[NSBox alloc] initWithFrame: NSMakeRect(0, 0, 50, kETLineSeparatorMinimumSize)]);
	[separatorView setBoxType: NSBoxSeparator];
	ETLayoutItem *item = [self itemWithView: separatorView];
	[item setName: kETLineSeparatorItemIdentifier];
	return item;
}

/** Returns a new layout item whose size can be adjusted by a computed layout 
based on the layout size and a minimum space size.

The returned separator name is kETSpaceItemIdentitifier.

See separator related methods in [ETComputedLayout] and subclasses. */
- (ETLayoutItem *) spaceSeparator
{
	ETLayoutItem *item = [self item];
	[item setName: kETSpaceSeparatorItemIdentifier];
	return item;
}

/** Returns a new layout item whose size can be adjusted by a computed layout 
based on the layout size and the available space.

A flexible space item can be shrinked to a zero size unlike the -spaceSeparator 
item.

The returned separator identifier is kETFlexibleSpaceItemIdentitifier.

See separator related methods in [ETComputedLayout] and subclasses.*/
- (ETLayoutItem *) flexibleSpaceSeparator
{
	ETLayoutItem *item = [self item];
	[item setIdentifier: kETFlexibleSpaceSeparatorItemIdentifier];
	[item setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	return item;
}

+ (void) registerAspects
{
	ETLayoutItemFactory *factory = [self factory];
	ETAspectRepository *repo = [ETAspectRepository mainRepository];
	ETAspectCategory *category = [repo aspectCategoryNamed: _(@"Items")];

	if (category == nil)
	{
		category = [[ETAspectCategory alloc] initWithName: _(@"Items")
		                               objectGraphContext: [repo objectGraphContext]];
		[category setIcon: [NSImage imageNamed: @"leaf-yellow"]];
		[[ETAspectRepository mainRepository] addAspectCategory: category];
	}

	[category setAspect: [factory item] forKey: _(@"Blank Item")];
	[category setAspect: [factory itemGroup] forKey: _(@"Blank Item Group")];
	
	[category setAspect: [factory buttonWithTitle: _(@"Button") target: nil action: NULL] 
	             forKey: _(@"Push Button")];
	[category setAspect: [factory labelWithTitle: @"Untitled"] forKey: _(@"Label")];
	[category setAspect: [factory textField] forKey: _(@"Text Field")];
	[category setAspect: [factory horizontalSlider] forKey: _(@"Horizontal Slider")];
	[category setAspect: [factory verticalSlider] forKey: _(@"Vertical Slider")];
	[category setAspect: [factory progressIndicator] forKey: _(@"Progress Indicator")];

 	[category setAspect: [factory graphicsGroup] forKey: _(@"Graphics Group")];
	[category setAspect: [factory rectangle] forKey: _(@"Rectangle")];
}

@end

const NSUInteger kETLineSeparatorMinimumSize = 5;
NSString * const kETLineSeparatorItemIdentifier = @"Line Separator";
NSString * const kETSpaceSeparatorItemIdentifier = @"Space Separator";
NSString * const kETFlexibleSpaceSeparatorItemIdentifier = @"Flexible Space Separator";
