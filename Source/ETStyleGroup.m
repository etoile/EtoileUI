/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2009
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETStyleGroup.h"
#import "ETCompatibility.h"

@implementation ETStyleGroup

/** Initializes and returns an empty style group. */
- (id) init
{
	return [self initWithCollection: nil];	
}

/** Initializes and returns a style group that only contains a single style. */
- (id) initWithStyle: (ETStyle *)aStyle
{
	return [self initWithCollection: A(aStyle)];	
}

/** <init />Initializes and returns a style group that contains all the styles 
in the given style collection. */
- (id) initWithCollection: (id <ETCollection>)styles
{
	SUPERINIT
	if (styles != nil)
	{
		_styles = [[styles contentArray] mutableCopy];
	}
	else
	{
		_styles = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	DESTROY(_styles);
	[super dealloc];
}

/* Style Collection */

/** Add the style. */
- (void) addStyle: (ETStyle *)aStyle
{
	[_styles addObject: aStyle];
}

/** Inserts a style at the given index. */
- (void) insertStyle: (ETStyle *)aStyle atIndex: (int)anIndex
{
	[_styles insertObject: aStyle atIndex: anIndex];
}

/** Removes the given style. */
- (void) removeStyle: (ETStyle *)aStyle
{
	[_styles removeObject: aStyle];
}

/** Removes all the styles. */
- (void) removeAllStyles
{
	[_styles removeAllObjects];
}

/** Returns whether the receiver contains a style equal to the given style. */
- (BOOL) containsStyle: (ETStyle *)aStyle
{
	return [_styles containsObject: aStyle];
}

/** Returns the first rendered style. */
- (id) firstStyle
{
	return [_styles firstObject];
}

/** Returns the first style of the kind of the given class.

When no style matches, returns nil.  */
- (id) firstStyleOfClass: (Class)aStyleClass
{
	FOREACH(_styles, style, ETStyle *)
	{
		if ([style isKindOfClass: aStyleClass])
		{
			return style;
		}
	}

	return nil;
}

/** Returns the last rendered style. */
- (id) lastStyle
{
	return [_styles lastObject];
}

/* Style Rendering */

/** Renders the styles sequentially from the first to the last in the current 
graphics context. 

The first style is drawn, then the second style is drawn atop, and so on until 
the last one is reached.

item indicates in which item the receiver is rendered. Usually this item is the 
one on which the receiver is set as a style group. However it can be unrelated 
to the style group or nil.

dirtyRect can be used to optimize the drawing. You only need to redraw what is 
inside that redisplayed area and won't be clipped by the graphics context. */
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect
{
	FOREACH(_styles, style, ETStyle *)
	{
		[style render: inputValues layoutItem: item dirtyRect: dirtyRect];
	}
}
	  
/** Notifies every style with -didChangeItemBounds: to let it know that the 
item, to which the receiver is bound to, has been resized. */
- (void) didChangeItemBounds: (NSRect)bounds
{
	FOREACH(_styles, style, ETStyle *)
	{
		[style didChangeItemBounds: bounds];
	}
}

/* Collection Protocol */

/** Returns YES. */
- (BOOL) isOrdered
{
	return YES;
}

- (BOOL) isEmpty
{
	return ([_styles count] == 0);
}

- (unsigned int) count
{
	return [_styles count];
}

- (id) content
{
	return _styles;
}

- (NSArray *) contentArray
{
	return [NSMutableArray arrayWithArray: _styles];
}

- (void) addObject: (id)anObject
{
	[self addStyle: anObject];
}

- (void) insertObject: (id)anObject atIndex: (unsigned int)anIndex
{
	[self insertStyle: anObject atIndex: anIndex];
}

- (void) removeObject: (id)anObject
{
	[self removeStyle: anObject];
}

@end

