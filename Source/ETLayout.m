/*  <title>ETLayout</title>

	ETLayout.m
	
	<abstract>Base class to implement pluggable layouts as subclasses and make 
	possible UI composition and transformation at runtime.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
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

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import "ETLayout.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutLine.h"
#import "ETContainer.h"
#import "ETTableLayout.h"
#import "ETOutlineLayout.h"
#import "ETBrowserLayout.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

@interface ETContainer (PackageVisibility)
- (BOOL) isScrollViewShown;
- (void) setShowsScrollView: (BOOL)scroll;
@end

/*
 * Private methods
 */

@interface ETLayout (Private)
+ (NSString *) baseClassName;
+ (NSString *) stripClassName;
+ (NSString *) stringBySpacingCapitalizedWordsOfString: (NSString *)name;
+ (NSString *) aspectName;
+ (void) registerBuiltInLayoutClasses;
- (BOOL) loadNibNamed: (NSString *)nibName;
/* Utility methods */
- (BOOL) isLayoutViewInUse;
- (NSRect) lineLayoutRectForItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
@end

/*
 * Main implementation
 */

@implementation ETLayout

static NSMutableSet *layoutClasses = nil;

/** Initializes ETLayout class by preparing the registered layout classes. */
+ (void) initialize
{
	if (self == [ETLayout class])
	{
		layoutClasses = [[NSMutableSet alloc] init];
		FOREACH([self allSubclasses], subclass, Class)
		{
			[self registerLayoutClass: subclass];
		}
	}
}

/* Overrides NSObject+Etoile. */
+ (NSString *) typePrefix
{
	return @"ET";
}

/** Returns the display name used to present the receiver or its instances in 
    in various EtoileUI builtin facilities such as an inspector. */
+ (NSString *) displayName
{
	return [self stringBySpacingCapitalizedWordsOfString: [self stripClassName]];
}

+ (NSString *) baseClassName
{
	return @"Layout";
}

/* Removes collision prefix and base suffix of class names. */
+ (NSString *) stripClassName
{
	unsigned int prefixLength = [[self typePrefix] length];
	unsigned int classSuffixLength = [[self baseClassName] length];
	NSString *className = [self className];
	NSRange range = NSMakeRange(prefixLength, 
		[className length] - (prefixLength + classSuffixLength));

	return [className substringWithRange: range];
}

/* Returns a string where all words are separated by spaces for a given string 
   of capitalized words with no spaces at all. 
   Useful to convert a name in camel case into a more user friendly name. */
+ (NSString *) stringBySpacingCapitalizedWordsOfString: (NSString *)name
{
	NSScanner *scanner = [NSScanner scannerWithString: name];
	NSCharacterSet *charset = [NSCharacterSet uppercaseLetterCharacterSet];
	NSString *word = nil;
	NSMutableString *displayName = [NSMutableString stringWithCapacity: 40];
	BOOL beforeLastLetter = NO;

	do
	{
		/* Scan a first capital or an uppercase word */
		BOOL hasScannedCapitals = [scanner scanCharactersFromSet: charset
	                                                  intoString: &word];
		if (hasScannedCapitals)
		{
			beforeLastLetter = ([scanner isAtEnd] == NO);
			BOOL hasFoundUppercaseWord = ([word length] > 1);
			if (hasFoundUppercaseWord && beforeLastLetter)
			{
				[displayName appendString: [word substringToIndex: [word length] - 1]];
				[displayName appendString: @" "]; /* Add a space between each words */
				[displayName appendString: [word substringFromIndex: [word length] - 1]];
			}
			else /* single capital or uppercase word at the end */
			{
				[displayName appendString: word];
			}
		}

		/* Scan lowercase characters, either a full word or what follows the 
		   a capital until the next one */
		BOOL hasFoundNextCapitalOrEnd = [scanner scanUpToCharactersFromSet: charset
	                                                            intoString: &word];
		if (hasFoundNextCapitalOrEnd)
		{
			[displayName appendString: word];

			/* Add a space between each words */
			beforeLastLetter = ([scanner isAtEnd] == NO);
			BOOL beyondFirstCapital = ([scanner scanLocation] > 0);
			if (beyondFirstCapital && beforeLastLetter)
			{
				[displayName appendString: @" "];
			}
		}
	} while (beforeLastLetter);

	return displayName;
}

/** Returns the default aspect name used to register a receiver instance in
    the aspect repository. */
+ (NSString *) aspectName
{
	NSString *name = [self stripClassName];

	NSAssert(name != nil, @"+stripClassName must never return nil but an empty string if needed");
	if ([name isEqual: @""])
		return name;

	NSString *lowercasedFirstLetter = [[name substringToIndex: 1] lowercaseString];

#ifdef GNUSTEP
	return [lowercasedFirstLetter stringByAppendingString: [name substringFromIndex: 1]];
#else
	return [name stringByReplacingCharactersInRange: NSMakeRange(0, 1) 
	                                     withString: lowercasedFirstLetter];
#endif
}

/** Registers the given class as a layout class available for various EtoileUI
    facilities that allow to change a layout at runtime, such as an inspector.
    This also results in the publishing of a layout prototype of this class 
    in the default aspect repository (not yet implemented). 
    Raises an invalid argument exception if layoutClass isn't a subclass of 
    ETLayout. */
+ (void) registerLayoutClass: (Class)layoutClass
{
	// TODO: We should have a method -[Class isSubclassOfClass:]. 
	// GSObjCIsKindOf may not work on Cocoa... check.
	if ([layoutClass isSubclassOfClass: [ETLayout class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Class %@ must be a subclass of ETLayout to get "
		                    @"registered as a layout class.", layoutClass, nil];
	}

	[layoutClasses addObject: layoutClass];
	// TODO: Make a class instance available as an aspect in the aspect 
	// repository.
}

/** Returns all the layout classes directly available for EtoileUI facilities 
    that allow to transform the UI at runtime. */
+ (NSSet *) registeredLayoutClasses
{
	return AUTORELEASE([layoutClasses copy]);
}

/* Factory Method */

+ (id) layout
{
	return AUTORELEASE([[[self class] alloc] init]);
}

+ (id) layoutWithLayoutView: (NSView *)layoutView
{
	return AUTORELEASE([[[self  class] alloc] initWithLayoutView: layoutView]);
}

- (Class) layoutClassForLayoutView: (NSView *)layoutView
{
	Class layoutClass = nil;
	NSView *view = layoutView;
	
	if ([layoutView isKindOfClass: [NSScrollView class]])
		view = [(NSScrollView *)layoutView documentView];
	
	// NOTE: Outline test must be done before table test, otherwise table 
	// layout is returned in both cases (NSOutlineView is subclass of 
	// NSTableView)
	if ([view isKindOfClass: [NSOutlineView class]])
	{
		layoutClass = [ETOutlineLayout class];
	}
	else if ([view isKindOfClass: [NSTableView class]])
	{
		layoutClass = [ETTableLayout class];
	}
	else if ([view isKindOfClass: [NSBrowser class]])
	{
		layoutClass = [ETBrowserLayout class];	
	}
	else
	{
		layoutClass = [ETLayout class];
	}
	
	return layoutClass;
}

/** Returns a prototype which is a receiver copy you can freely assign to 
	another container. Because a layout can be bound to only one container, 
	this method is useful for sharing a customized layout between several 
	containers without having to recreate a new instance from scratch each
	time. */
- (id) layoutPrototype
{
	return [self copy];
}

/** <init /> Returns ETLayout instance when layoutView is nil, otherwise 
	returns a concrete subclass with class cluster style initialization.
	The returned layout has both vertical and horizontal constraint on item
	size enabled. The size constraint is set to 256 * 256 px. You can customize
	item size constraint with -setItemSizeConstraint: and 
	-setConstrainedItemSize:. */
- (id) initWithLayoutView: (NSView *)layoutView
{
	self = [super init];
	
	/* Class cluster initialization */
	
	/* ETLayout itself takes the placeholder object role. By removing the 
	   following if statement, concrete subclass would have the possibility
	   to override the concrete subclass... No utility right now. */
	if (layoutView != nil && [self isMemberOfClass: [ETLayout class]])
	{
		/* Find the concrete layout class to instantiate */
		Class layoutClass = [self layoutClassForLayoutView: layoutView];
		
		/* Eventually replaces the receiver by a new concrete instance */
		if (layoutClass != nil)
		{
			if ([self isMemberOfClass: layoutClass] == NO)
			{
				NSZone *zone = [self zone];
				RELEASE(self);
				self = [[layoutClass allocWithZone: zone] initWithLayoutView: layoutView];
			}
		}
		else /* No matching layout class */
		{
			self = nil;
		}
		
		return self; /* Instance already initialized */
	}
  
	/* Concrete instance initialization */
	
	if (self != nil)
	{
		_layoutContext = nil;
		_delegate = nil;
		_isLayouting = NO;
		_layoutSize = NSMakeSize(200, 200); /* Dummy value */
		_layoutSizeCustomized = NO;
		_maxSizeLayout = NO;
		_itemSize = NSMakeSize(256, 256); /* Default max item size */
		/* By default both width and height must be equal or inferior to related _itemSize values */
		_itemSizeConstraintStyle = ETSizeConstraintStyleNone;
		_previousScaleFactor = 1.0; /* Ensures -resizeItems:toScaleFactor: isn't called until the scale changes */
	
		if (layoutView != nil) /* Use layout view parameter */
		{
			[self setLayoutView: layoutView];
		}
		else if ([self nibName] != nil) /* Use layout view in nib */
		{
			if ([self loadNibNamed: [self nibName]] == NO)
				self = nil;
		}
	}
	
	return self;
}

- (NSString *) nibName
{
	return nil;
}

- (BOOL) loadNibNamed: (NSString *)nibName
{
	BOOL nibLoaded = [NSBundle loadNibNamed: nibName owner: self];
	
	if (nibLoaded)
	{
		// TODO: Remove this branch statement once the outlet has been renamed 
		// layoutView
		/* Because this outlet will be removed from its superview, it must be 
	       retained like any other to-one relationship ivars. If this proto view 
		   is later replaced by calling -setLayoutView:, this retain will be 
		   balanced by the release in ASSIGN. */ 
		RETAIN(_displayViewPrototype);
		[self setLayoutView: _displayViewPrototype];
	}
	else
	{
		ETLog(@"WARNING: Failed to load nib %@", nibName);
		AUTORELEASE(self);
	}
	return nibLoaded;
}

- (id) init
{
	return [self initWithLayoutView: nil];
}

- (void) dealloc
{
	/* Neither layout context and delegate have to be retained. For layout 
	   context, only because it retains us and is in charge of us. */
	DESTROY(_displayViewPrototype);
	
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
	ETLayout *proto = [[[self class] alloc] init];
	
	proto->_layoutContext = nil;
	proto->_delegate = nil;
	// FIXME: Probably replace copy by a fake copy (archive/unarchive)
	//proto->_displayViewPrototype = [_displayViewPrototype copy];
	
	proto->_layoutSize = _layoutSize;
	proto->_layoutSizeCustomized = _layoutSizeCustomized;
	proto->_maxSizeLayout  = _maxSizeLayout;
	
	proto->_itemSizeConstraintStyle = _itemSizeConstraintStyle;
	
	return AUTORELEASE(proto);
}

/** Returns the view where the layout happens (by computing locations of a layout item series). */
- (ETContainer *) container;
{
	return (ETContainer *)[[self layoutContext] supervisorView];
}

/** Sets the context where the layout should happen. 

When a layout context is set, with the next layout update the receiver will 
arrange the layout items in a specific style and order. 

The layout context is expected to retain its layout, hence the receiver doesn't 
retain context. */
- (void) setLayoutContext: (id <ETLayoutingContext>)context
{
	ETDebugLog(@"Modify layout context from %@ to %@ in %@", _layoutContext, context, self);

	if (context == nil)
		[self tearDown];

	/* We remove the display views of layout items.
	   Take note they may be invisible by being located outside of the container 
	   bounds.	
	   If we don't and we switch from a computed layout to a view-based layout,
	   they might remain visible as subviews (think ETBrowserLayout on GNUstep 
	   which has transparent areas) because view-based layout are not required 
	   to call -setVisibleItems: when they override -renderWithLayoutItems:XXX:. 
	   By introducing a null layout, we would be able to move that in -tearDown. 
	   That doesn't work presently when we switch from a nil layout to a non-nil 
	   layout, because -setLayoutContext: nil isn't called, hence -tearDown 
	   neither. */
	ETDebugLog(@"Remove views of layout items currently displayed");
	[context setVisibleItems: [NSArray array]];	

	// NOTE: Avoids retain cycle by weak referencing the context
	_layoutContext = context;

	// TODO: May be safer to restore the default frame here rather than relying 
	// on the next layout update and -resizeItems:toScaleFactor:... 
	//[[_layoutContext items] makeObjectsPerformSelector: @selector(restoreDefaultFrame)];
}

/** Returns the context where the layout happens. */
- (id <ETLayoutingContext>) layoutContext
{
	return _layoutContext;
}

/** <override-dummy />Overrides if your subclass requires extra cleanup when the 
layout context is switched to another layout (the receiver stops to be used and 
visible).

The layout context hasn't yet been touched when this method is called.

You must call the superclass implementation if you override this method. */
- (void) tearDown
{
	/* Don't forget to remove existing layout view if we switch from a layout 
	   which reuses a native AppKit control like table layout. */
	// NOTE: Be careful of layout objects which can share a common class but 
	// all differs by their unique display view prototype.
	// May be we should move it into -[layout setContainer:]...
	// Triggers scroll view display which triggers layout render in turn to 
	// compute the content size
	[[self container] setLayoutView: nil]; 
}

// TODO: Pick better names for the following methods:
// -isComputedLayout --> -isComputed, -usesComputedCoordinates, -isRuleBased,
//                       -isRelative
// -isFixed --> isFixed (as is), -usesFixedCoordinates, -isAbsolute

/** Overrides in subclasses to indicate whether the layout is a semantic layout
	or not. Returns NO by default.
	ETTableLayout is a normal layout but ETPropertyLayout (which displays a 
	list of properties) is semantic, the latter works by delegating everything 
	to an existing normal layout and may eventually replace this layout by 
	another one. If you overrides this method to return YES, forwarding of all
	non-overidden methods to the delegate will be handled automatically. */
- (BOOL) isSemantic
{
	return NO;
}

/** Returns YES when the layout conforms to ETPositionalLayout protocol, 
    otherwise returns NO.
    A positional layout doesn't inject a custom UI, it handles the display of 
	the child items bound to the layout context by computing coordinates or 
	by simply using their fixed coordinates. Fixed coordinates are encoded 
	in persistentFrame property of ETLayoutItem. */
- (BOOL) isPositional
{
	return [self conformsToProtocol: @protocol(ETPositionalLayout)];
}

- (BOOL) isComposite
{
	return [self conformsToProtocol: @protocol(ETCompositeLayout)];
}

/** Returns YES when the layout is positional, computes the location of the 
    layout items and updates these locations as necessary by itself. See also
	ETComputedLayout, whose subclasses are all computed layouts.
	By default returns NO, overrides to return YES when a positional layout 
	subclass doesn't allow the user sets the layout item locations. 
	The returned value alters the order in which ETContainer data source 
	methods are called. 
	-[ETLayoutItem setFrame:] checks that the parent item layout is not a 
	computed layout before updating the persistent frame. */
- (BOOL) isComputedLayout
{
	return NO;
}

/** Returns YES when the layout imposes a custom layout and drawing for all 
    rendered layout items; in other words, when the receiver overrides the 
    default drawing styles, views and layouts for the descendant items of the 
    layout context.
    By default returns YES if the receiver uses a layout view. Override it to 
    return NO in case the receiver subclass doesn't let the rendered layout 
    items draw themselves, yet without using a layout view. 
    Typically, all composite layouts are opaque, as layouts that wrap controls 
    of the underlying UI toolkit are (for example ETTableLayout). */
- (BOOL) isOpaque
{
	return ([self layoutView] != nil && [self isLayoutViewInUse]);
}

/** Returns YES if all layout items are visible in the bounds of the related 
	container once the layout has been computed, otherwise returns NO when
	the layout has run out of space.
	Whether all items are visible depends of the layout itself and also whether
	the container is embedded in a scroll view because in such case the 
	container size is altered. */
- (BOOL) isAllContentVisible
{
	int nbOfItems = [[[self layoutContext] items] count];
	
	return [[[self layoutContext] visibleItems] count] == nbOfItems;
}

/** By default layout size is precisely matching frame size of the container to 
	which the receiver is bound to.
	When the container uses a scroll view, layout size is set the mininal size 
	which encloses all the layout item frames once they have been layouted. 
	This size is the maximal layout size you can compute for the receiver with 
	the content provided by the container.
	Whether the layout size is computed in horizontal, vertical direction or 
	both depends of layout kind, settings of the layout and finally scroller 
	visibility in related container.
	If you call -setUsesCustomLayoutSize:, the layout size won't be adjusted anymore by
	the layout and container together until you delegate it again by calling
	-setUsesCustomLayoutSize: with NO as parameter. */ 
- (void) setUsesCustomLayoutSize: (BOOL)flag
{
	_layoutSizeCustomized = flag;
}

- (BOOL) usesCustomLayoutSize
{
	return _layoutSizeCustomized;
}

/** Layout size can be set directly only if -usesCustomLayoutSize returns
	YES.
	In this case, you can restrict layout size to your personal needs by 
	calling -setLayoutSize: and only then -render. */
- (void) setLayoutSize: (NSSize)size
{
	//ETDebugLog(@"-setLayoutSize");
	_layoutSize = size;
}

- (NSSize) layoutSize
{
	return _layoutSize;
}

- (void) setContentSizeLayout: (BOOL)flag
{
	//ETDebugLog(@"-setContentSizeLayout");
	_maxSizeLayout = flag;
}

- (BOOL) isContentSizeLayout
{
	if ([[self layoutContext] isScrollViewShown])
		return YES;

	return _maxSizeLayout;
}

- (void) setDelegate: (id)delegate
{
	_delegate = delegate;
}

- (id) delegate
{
	return _delegate;
}

/* Item Sizing Accessors */

/** If the constraint is different than ETSizeConstraintStyleNone, the 
	autoresizing returned by -[ETLayoutItem autoresizingMask], for each item 
	that is rendered by the receiver, won't be respected. */
- (void) setItemSizeConstraintStyle: (ETSizeConstraintStyle)constraint
{
	_itemSizeConstraintStyle = constraint;
}

- (ETSizeConstraintStyle) itemSizeConstraintStyle
{
	return _itemSizeConstraintStyle;
}

- (void) setConstrainedItemSize: (NSSize)size
{
	_itemSize = size;
}

- (NSSize) constrainedItemSize
{
	return _itemSize;
}

/** Returns whether the receiver can run the layout now. */
- (BOOL) canRender
{
	return ([self layoutContext] != nil && [self isRendering] == NO);
}

/** Returns whether the receiver is currently computing and rendering its 
	layout right now or not.
	You must call this method in your code before calling any Layouting related
	methods. If YES is returned, don't call the method you want to and wait a 
	bit before giving another try to -isRendering. When NO is returned, you are 
	free to call any Layouting related methods. */
- (BOOL) isRendering
{
	return _isLayouting;
}

- (void) render: (NSDictionary *)inputValues
{
	[self render: inputValues isNewContent: YES];
}

/** Renders a collection of items by requesting them to the container to which
	the receiver is bound to.
	Layout items can be requested in two styles: to the container itself or
	indirectly to a data source provided by the container. When the layout 
	items are provided through a data source, the layout will only request 
	lazily the subset of them to be displayed (not currently true). 
	This method is usually called by ETContainer and you should rarely need to
	do it by yourself. If you want to update the layout, just uses 
	-[ETContainer updateLayout]. */
- (void) render: (NSDictionary *)inputValues isNewContent: (BOOL)isNewContent
{
	if ([self layoutContext] == nil)
		ETLog(@"WARNING: No layout context available with %@", self);

	/* Prevent reentrancy. In a threaded environment, it isn't perfectly safe 
	   because _isLayouting test and _isLayouting assignement doesn't occur in
	   an atomic way. */
	if ([self canRender] == NO)
		return;

	_isLayouting = YES;

	/* When the number of layout items is zero and doesn't vary, no layout 
	   update is necessary */
	// TODO: Try some optimizations, in the vein of...
	// if ([[[self layoutContext] items] count] == 0 && _nbOfItemCache != [[[self layoutContext] items] count])
	//	return;

	[self renderWithLayoutItems: [[self layoutContext] items] isNewContent: isNewContent];

	_isLayouting = NO;
}

/** Sets the layout size to the unlayouted content size of the layout context,
    unless -usesCustomLayoutSize returns YES. In this last case, the layout size 
	isn't modified. 
    You call this method to reset the layout size to a value that should be used 
	as a basis to compute the layout. By default, the implementation considers 
	the layout of the content (layout items) should be computed within the 
	boundaries of the layout context size.
	If the layout context is enclosed inside a scroll view, this method will 
	take it in account. */
- (void) resetLayoutSize
{
	/* We always set the layout size which should be used to compute the 
	   layout unless a custom layout has been set by calling -setLayoutSize:
	   before -render. */
	if ([self usesCustomLayoutSize] == NO)
	{
		if ([[self layoutContext] isScrollViewShown])
		{
			/* Better to request the visible rect than the container frame 
			   which might be severely altered by the previouly set layout. */
			[self setLayoutSize: [[self layoutContext] visibleContentSize]];
		}
		else /* Using content layout size without scroll view is supported */
		{
			[self setLayoutSize: [[self layoutContext] size]];
		}
	}
}

/** <override-dummy /> */
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	ETDebugLog(@"Render layout items: %@", items);

	float scale = [[self layoutContext] itemScaleFactor];

	[self resetLayoutSize];
	// TODO: This is a welcome optimization that avoids unecessary computations, 
	// however this shouldn't be mandatory. Currently this is used as a 
	// workaround to handle the fact that the default frame isn't updated if 
	// -setFrame: is called. The correct fix is probably to update the default 
	// frame in -setFrame: when the item is managed by a non-computed layout. 
	// This a little bit tricky to implement cleanly because the layout that 
	// manages the item may not be on the immediate parent but some higher 
	// ancestors. Another downside is that ETLayoutItem will become more 
	// coupled to ETLayoutItemGroup.
	/* Only scale if needed, but if a constraint exists on item width or height, 
	   resizing must be forced in all cases. */
	if (scale != _previousScaleFactor 
	 || [self itemSizeConstraintStyle] != ETSizeConstraintStyleNone)
	{
		[self resizeLayoutItems: items toScaleFactor: scale];
		_previousScaleFactor = scale;
	}
}

/** Resizes layout item by scaling of the given factor the -defaultFrame 
    returned by each item, then applying the scaled rect with -setFrame:.
	Once the scaled rect has been computed, right before applying it to the 
	item, this method checks for the item size contraint. If the size constraint 
	is ETSizeConstraintStyleNone, the scaled rect is used as is. For other 
	size constraint values, the scaled rect is checked against 
	-constrainedItemSize for either width, height or both, then altered if the 
	rect width or height is superior to the allowed maximum value. 
	If -itemSizeConstraintStyle returns ETConstraintStyleNone, the layout will 
	respect the autoresizing mask returned by -[ETLayoutItem autoresizingMask],
	otherwise it won't. */
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	FOREACH(items, item, ETLayoutItem *)
	{
		/* Scaling is always computed from item default frame rather than
		   current item view size (or  item display area size) in order to
		   avoid rounding error that would increase on each scale change 
		   because of size width and height expressed as float. */
		NSRect itemFrame = ETScaleRect([item defaultFrame], factor);
		
		/* Apply item size constraint if needed */
		if ([self itemSizeConstraintStyle] != ETSizeConstraintStyleNone 
		 && (itemFrame.size.width > [self constrainedItemSize].width
		 || itemFrame.size.height > [self constrainedItemSize].height))
		{ 
			BOOL isVerticalResize = NO;
			
			if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVerticalHorizontal)
			{
				if (itemFrame.size.height > itemFrame.size.width)
				{
					isVerticalResize = YES;
				}
				else /* Horizontal resize */
				{
					isVerticalResize = NO;
				}
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVertical
			      && itemFrame.size.height > [self constrainedItemSize].height)
			{
				isVerticalResize = YES;	
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleHorizontal
			      && itemFrame.size.width > [self constrainedItemSize].width)
			{
				isVerticalResize = NO; /* Horizontal resize */
			}
			
			if (isVerticalResize)
			{
				float maxItemHeight = [self constrainedItemSize].height;
				float heightDifferenceRatio = maxItemHeight / itemFrame.size.height;
				
				itemFrame.size.height = maxItemHeight;
				itemFrame.size.width *= heightDifferenceRatio;
					
			}
			else /* Horizontal resize */
			{
				float maxItemWidth = [self constrainedItemSize].width;
				float widthDifferenceRatio = maxItemWidth / itemFrame.size.width;
				
				itemFrame.size.width = maxItemWidth;
				itemFrame.size.height *= widthDifferenceRatio;				
			}
		}
		
		/* Apply Scaling */
		itemFrame.origin = [item origin];
		[item setFrame: itemFrame];
		ETDebugLog(@"Scale %@ to %@", NSStringFromRect([item defaultFrame]), 
			NSStringFromRect(ETScaleRect([item defaultFrame], factor)));
	}
}

/* Wrapping Existing View */

/** Returns a layout item when the receiver is an aggregate layout which 
	doesn't truly layout items but rather wraps a predefined view (aka layout 
	view) or layout item. By default, returns nil.
	When a layout is such an aggregate, layout items passed to the receiver are
	handled by the layout item descendants of -layoutItem. These layout item 
	descendents are commonly subviews. 
	See ETUIComponent to understand how an aggregate layout can be wrapped in
	standalone and self-sufficient component which may act as live filter in 
	the continous model object flows. */
- (ETLayoutItem *) rootItem
{
	// FIXME: Implement
	return nil;
}

- (void) setLayoutView: (NSView *)protoView
{
	// FIXME: Horrible hack to work around the fact Gorm doesn't support 
	// connecting an outlet to the content view of a window. Hence we connect 
	// _displayViewPrototype to the window embedding the view and retrieve the 
	// layout view when this method is called during the nib awaking.
	// This hack isn't used anymore, so it could probably be removed...
	if ([protoView isKindOfClass: [NSWindow class]])
	{
		ETLog(@"NOTE: -setLayoutView: received a window as parameter");
		ASSIGN(_displayViewPrototype, [(NSWindow *)protoView contentView]);
	}
	else
	{
		ASSIGN(_displayViewPrototype, protoView);
	}

	[_displayViewPrototype removeFromSuperview];
}

- (NSView *) layoutView
{
	return _displayViewPrototype;
}

/** Returns YES if the layout view is presently visible in the layout item tree 
    of the layout context, otherwise returns NO.
    A layout view can be inserted in a superview bound to a parent item and 
    yet not be visible. For example, if an ancestor item of the parent uses an 
    opaque layout, the layout view can be inserted in the parent view but the 
    parent view (or another ancestor superview which owns it) might not be 
    inserted as a subview in the visible view hierarchy of the layout item 
    tree. */
- (BOOL) isLayoutViewInUse
{
	// NOTE: A visible view hierarchy is always rooted in a window, itself bound 
	// to the layout item representing the content view.
	return ([[self layoutView] window] == nil);
}

/** You should call this method in -renderWithLayoutItems:isNewContent: if you 
	write a view-based layout subclass.
	This method may be overriden by subclasses to handle view-specific 
	configuration before the view gets injected in the layout context. You must  
	then call the superclass method to have the layout view added as a subview 
	to the container associated with the layout context. */
- (void) setUpLayoutView
{
	id layoutView = [self layoutView];
	
	NSAssert1(layoutView != nil, @"Layout view to set up must not be nil in %@", self);
	
	if ([layoutView superview] == nil)
	{
		[layoutView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
		// NOTE: If a container is used as a layout view, we need to enable hit
		// test on it in order subviews can receive events like mouse click.
		if ([layoutView respondsToSelector: @selector(setEnablesHitTest:)])
			[layoutView setEnablesHitTest: YES];
		[[self container] setLayoutView: layoutView];
	}
	else if ([[layoutView superview] isEqual: [self container]] == NO)
	{
		ETLog(@"WARNING: Table view of table layout should never have another "
			  @"superview than container parameter or nil.");
	}
}

/** <override-dummy />
	Returns the selected items reported by the layout, which can be different 
	from selected items of the layout context. For example, an outline layout
	reports selected items in all expanded items and not only selected items of 
	the root item (unlike layout context whose selection is restricted to 
	immediate child items).
	Returns an empty array when no items are selected.
	Returns nil when the layout doesn't implement its own set of selected items.
	You can override this method to implement a layout-based selection in your
	subclass. This method is called by 
	-[ETLayoutItemGroup selectedItemsInLayout]. */
- (NSArray *) selectedItems
{
	return nil;
}

/** Returns the index paths for the selected items by taking account these 
	index paths must be relative to the layout context.
	If a layout view is used, this method is useful to synchronize the selection 
	state of the layout item tree with the selection reported by -selectedItems. 
	You can synchronize the selection between a layout view and the layout item 
	tree with the following code: 
	[[self layoutContext] setSelectionIndexPaths: [self selectionIndexPaths]]
	TODO: We need more control over the way we set the selection in the layout 
	item tree. Calling -setSelectionIndexPaths: presently resets the selection 
	state of all descendent items even the hidden ones in the layout (like the 
	children of a collapsed row in an outline view). Various new methods could 
	be introduced like -extendsSelectionIndexPaths: and 
	-restrictsSelectionIndexPaths: to synchronize the selection by delta for 
	newly selected and deselected items. Another possibility would be a method 
	like -setSelectionIndexPathsInLayout:, but its usefulness is more limited. */
- (NSArray *) selectionIndexPaths
{
	NSMutableArray *indexPaths = [NSMutableArray array];

	FOREACH([self selectedItems], item, ETLayoutItem *)
	{
		[indexPaths addObject: [item indexPathFromItem: (id)[self layoutContext]]];
	}

	return indexPaths;
}

/** <override-dummy /> Overrides in opaque layout subclasses, if the receiver
    needs to keep in sync internal objects with the selection state of the 
	layout context. 
    You usually override this method if you need to reflect the selected items 
	of the layout context on the custom UI encapsulated in the receiver.
	For example, ETItemTemplateLayout overrides it to keep in sync its 
	replacement items with the child items of the layout context. 
	Note: We could eventually handle that by binding internal items or state of 
	the receiver to the 'selected' property of the child items of the layout 
	context. By doing so, this method wouldn't be necessary/ */
- (void) selectionDidChangeInLayoutContext
{

}

/* 
 * Utility methods
 */
 
// FIXME: Implement or remove
// - (NSRect) lineLayoutRectForItem:
// - (NSRect) lineLayoutRectAtLocation:
- (NSRect) lineLayoutRectForItemIndex: (int)index 
{ 
	return NSZeroRect; 
}

/** Returns the layout item positioned at location point and inside the visible 
	part of the receiver layout (equals or inferior to the layout context 
	frame). 
	If several items overlap at this location, then the topmost item owned by 
	the layout is returned. This implies a topmost item which isn't an immediate 
	child of the layout context may not be be matched if it is owned by another 
	layout object. For example -[ETOutlineLayout itemAtLocation:] can match
	descendant items unlike ETFlowLayout which only matches immediate child
	items. Take note topmost item on screen is the deepest descendant item if 
	you view it in layout item tree perspective.
	Location must be expressed in the coordinates of the container presently 
	associated with the receiver. If the point passed in parameter is located
	beyond the layout size, nil is returned. */
- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	FOREACH([[self layoutContext] visibleItems], item, ETLayoutItem *)
	{
		if ([item displayView] != nil)
		{
			/* When items are layouted and displayed directly into the layout 
			   and not routed into some subview part of the layout view. */
			if ([self layoutView] == nil)
			{
				/* Item display view must be a direct subview of our container, 
				   otherwise NSPointInRect test is going to be meaningless. */
				NSAssert1([[[self container] subviews] containsObject: [item displayView]],
					@"Item display view must be a direct subview of %@ to know "
					@"whether it matches given location", [self container]);
			}
			
			if (NSPointInRect(location, [[item displayView] frame]))
				return item;
		}
		else /* Layout items uses no display view */
		{
			if (NSPointInRect(location, [item frame]))
				return item;
		}
	}
	
	return nil;
}

/** Returns the display area of the layout item passed in parameter. 
	Returned rect is expressed in the coordinates of the container presently 
	associated with the receiver.*/
- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	if ([item displayView] != nil)
	{
		return [[item displayView] frame];
	}
	else
	{
		// FIXME: Take in account any item decorations drawn by layout directly
		return NSZeroRect;
	}
}

/* Item Property Display */

/** <override-dummy /> */
- (NSArray *) displayedProperties
{
	return nil;
}

/** <override-dummy /> */
- (void) setDisplayedProperties: (NSArray *)properties
{
	
}

/** <override-dummy /> */
- (id) styleForProperty: (NSString *)property
{
	return nil;
}

/** <override-dummy /> */
- (void) setStyle: (id)style forProperty: (NSString *)property
{

}

// NOTE: Extensions probably not really interesting...
//- (NSRange) layoutItemRangeForLineLayout:
//- (NSRange) layoutItemForLineLayoutWithIndex: (int)lineIndex

@end
