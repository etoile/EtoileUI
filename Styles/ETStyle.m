/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETEntityDescription.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <CoreObject/COObjectGraphContext.h>
#import "ETStyle.h"
#import "ETAspectRepository.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"

@implementation ETStyle

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *)theKey 
{
	ETEntityDescription *entity = [[ETModelDescriptionRepository mainRepository] 
		entityDescriptionForClass: self];

    if ([[entity propertyDescriptionNames] containsObject: theKey]) 
	{
		return NO;
    } 
	else 
	{
		return [super automaticallyNotifiesObserversForKey: theKey];
    }
}

static NSMutableSet *stylePrototypes = nil;

/** Registers a prototype for every ETStyle subclasses.

The implementation won't be executed in the subclasses but only the abstract 
base class.

Since [ETUIItem] is an ETStyle subclass, every [ETLayoutItem] and [ETDecoratorItem]
subclass will also get registered as a style (not yet true).

You should never need to call this method.

See also [NSObject(ETAspectRegistration)]. */
+ (void) registerAspects
{
	stylePrototypes = [[NSMutableSet alloc] init];

	for (Class subclass in [self allSubclasses])
	{
		/* -init returns nil in in some ETDecoratorItem subclasses.
		   Astract class like ETUIItem should also not be registered.
		   In the long run we will replace this check by: nil == instance */
		if ([subclass isSubclassOfClass: [ETUIItem class]])	
			continue;

		[self registerStyle:[[subclass alloc]
			initWithObjectGraphContext: [self defaultTransientObjectGraphContext]]];
	}
}

/** Returns 'Style'. */
+ (NSString *) baseClassName
{
	return @"Style";
}

/** Makes the given prototype available to EtoileUI facilities (inspector, etc.) 
that allow to change a style at runtime.

Also publishes the prototype in the shared aspect repository (not yet implemented). 

Raises an invalid argument exception if aStyle class isn't a subclass of ETStyle. */
+ (void) registerStyle: (ETStyle *)aStyle
{
	if ([aStyle isKindOfClass: [ETStyle class]] == NO)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Prototype %@ must be a subclass of ETStyle to get "
		                    @"registered as a style prototype.", aStyle];
	}

	[stylePrototypes addObject: aStyle];

	ETAspectRepository *repo = [ETAspectRepository mainRepository];
	ETAspectCategory *category = [repo aspectCategoryNamed: _(@"Style")];

	if (category == nil)
	{
		category = [[ETAspectCategory alloc] initWithName: _(@"Style")
		                               objectGraphContext: [repo objectGraphContext]];
		[category setIcon: [NSImage imageNamed: @"layer-transparent"]];
		[[ETAspectRepository mainRepository] addAspectCategory: category];
	}
	[category setAspect: aStyle forKey: [[aStyle class] displayName]];
}

/** Returns all the style prototypes directly available for EtoileUI facilities 
that allow to transform the UI at runtime. */
+ (NSSet *) registeredStyles
{
	return [stylePrototypes copy];
}

/** Returns all the style classes directly available for EtoileUI facilities 
that allow to transform the UI at runtime.

These style classes are a subset of the registered style prototypes since 
several prototypes might share the same class. */
+ (NSSet *) registeredStyleClasses
{
	return (NSSet *)[[[self registeredStyles] mappedCollection] class];
}

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	_isShared = YES;
	return self;
}

- (NSImage *) icon
{
	return [NSImage imageNamed: @"layer-transparent"];
}

/** Returns whether the receiver can be shared between several owners.

By default, returns YES.

See also -setIsShared:. */
- (BOOL) isShared
{
	return _isShared;
}

/** Sets whether the receiver can be shared between several owners.

See also -isShared. */
- (void) setIsShared: (BOOL)shared
{
	[self willChangeValueForProperty: @"isShared"];
	_isShared = shared;
	[self didChangeValueForProperty: @"isShared"];
}

/** <override-subclass />
Main rendering method for the custom drawing implemented by subclasses.
    
Renders the receiver in the active graphics context with the given layout item 
in the role of the element on which the style is applied.

item indicates in which item the receiver is rendered. Usually this item is the 
one on which the receiver is indirectly set through -[ETLayoutItem styleGroup]. 
However the item can be unrelated to the style or nil.<br />
See -[ETLayoutItem drawingBoundsForStyle:] to retrieve the right drawing area. 

dirtyRect can be used to optimize the drawing. You only need to redraw what is 
inside that redisplayed area and won't be clipped by the graphics context.

Here is how the method can be implemented in a subclass:

<example>
NSRect bounds = [item drawingBoundsForStyle: self];

[NSGraphicsContext saveGraphicsState];

// Drawing code
[[NSColor redColor] set];
[NSBezierPath fillRect: bounds];
// and more...

[NSGraphicsContext restoreGraphicsState];
</example> */
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
      dirtyRect: (NSRect)dirtyRect
{

}

/** Draws a selection indicator that covers the whole item frame if 
 the given indicator rect is equal to it. */
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect
{
	//ETLog(@"--- Drawing selection %@ in view %@", NSStringFromRect([item drawingBoundsForStyle: self]), [NSView focusView]);
	
	NSGraphicsContext *ctxt = [NSGraphicsContext currentContext];
	BOOL gstateAntialias = [ctxt shouldAntialias];

	/* Disable the antialiasing for the stroked rect */
	[ctxt setShouldAntialias: NO];
	
	/* Align on pixel boundaries for fractional pixel margin and frame. 
	   Fractional item frame results from the item scaling. 
	   NOTE: May be we should adjust pixel boundaries per edge and only if 
	   needed to get a perfect drawing... */
	NSRect normalizedIndicatorRect = NSInsetRect(NSIntegralRect(indicatorRect), 0.5, 0.5);
	NSBezierPath *indicatorPath = [NSBezierPath bezierPathWithRect: normalizedIndicatorRect];

	/* Draw the interior */
	[[[NSColor lightGrayColor] colorWithAlphaComponent: 0.45] setFill];
	[indicatorPath fill];

	/* Draw the outline
	   FIXME: Cannot get the outline precisely aligned on pixel boundaries for 
	   GNUstep. With the current code which works well on Cocoa, the top border 
	   of the outline isn't drawn most of the time and the image drawn 
	   underneath seems to wrongly extend beyond the border. */
	[[[NSColor darkGrayColor] colorWithAlphaComponent: 0.55] setStroke];
	[indicatorPath setLineWidth: 1.0];
	[indicatorPath stroke];

	[ctxt setShouldAntialias: gstateAntialias];
}

/** <override-dummy />
Notifies the receiver that the styled layout item has been resized.

You can override this method to alter the style state. For example, [ETShape]
overrides it to resize/scale the bezier path as needed.

Usually the new bounds corresponds to the item content bounds.<br />
However when the receiver style is used as a cover style, the new bounds 
corresponds to the item size at a zero origin.

See also -[ETLayoutItem contentBounds], -[ETLayoutItem size] and 
-[ETLayoutItem coverStyle]. */
- (void) didChangeItemBounds: (NSRect)bounds
{

}

@end
