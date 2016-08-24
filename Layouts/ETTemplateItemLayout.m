/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/Macros.h>
#import <CoreObject/COPrimitiveCollection.h>
#import "ETTemplateItemLayout.h"
#import "ETBasicItemStyle.h"
#import "ETColumnLayout.h"
#import "ETComputedLayout.h"
#import "ETFlowLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItem+Private.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETView.h"
// FIXME: Move related code to the Appkit widget backend (perhaps in a category)
#import "ETWidgetBackend.h"
#import "NSView+EtoileUI.h"
#import "ETCompatibility.h"

#pragma GCC diagnostic ignored "-Wprotocol"


@implementation ETTemplateItemLayout

- (void) prepareTransientState
{
	_renderedItems = [NSMutableSet set];
	_renderedTemplateKeys = [NSArray array];
	_needsPrepareItems = YES;
}

/** <init />
Initializes and return a new template item layout which uses a flow layout as 
its positional layout. 

The positional layout item size contraint style is also set to none.

You are responsible to specify a template item and the template keys on the 
returned instance (usually in a subclass initializer). */ 
- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;
	
	[self setPositionalLayout: [ETFlowLayout layoutWithObjectGraphContext: aContext]];
	[(ETFlowLayout *)_positionalLayout setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	_templateKeys = [[COMutableArray alloc] init];
	_localBindings = [[COMutableDictionary alloc] init];
	[self prepareTransientState];

	return self;
}

/** Returns the template item whose property values are used to override the 
equivalent values on every item that gets layouted. 

By default returns nil.

See also -setTemplateItem:.*/
- (ETLayoutItem *) templateItem
{
	return _templateItem;
}

/** Sets the template item whose property values are used to override the 
equivalent values on every item that gets layouted. 

A layouted item property will have its value replaced only when this property 
is listed in the template keys.
 
This setter doesn't call -renderAndInvalidateDisplay to prevent compatibility
issues with -templateKeys.

See -setTemplateKeys:. */
- (void) setTemplateItem: (ETLayoutItem *)item
{
	[self willChangeValueForProperty: @"templateItem"];
	_templateItem = item;
	_needsPrepareItems = YES;
	[self didChangeValueForProperty: @"templateItem"];
}

/** Returns the properties whose value should replaced, on every item that get 
layouted, with the value provided by the template item.

By default returns an empty array.

See also -setTemplateKeys:. */
- (NSArray *) templateKeys
{
	return _templateKeys;
}

/** Sets the properties whose value should be replaced, on every item that get 
layouted, with the value provided by the template item.

Those overriden properties will be restored to their original values when the 
layout is torn down.

This setter doesn't call -renderAndInvalidateDisplay to prevent compatibility
issues with -templateItem.
 
See -setTemplateItem:. */
- (void) setTemplateKeys: (NSArray *)keys
{
	[self willChangeValueForProperty: @"templateKeys"];
	[_templateKeys setArray: keys];
	_needsPrepareItems = YES;
	[self didChangeValueForProperty: @"templateKeys"];
}

- (void) bindTemplateItemKeyPath: (NSString *)templateKeyPath 
               toItemWithKeyPath: (NSString *)itemProperty
{
	[self willChangeValueForProperty: @"localBindings"];
	[_localBindings setObject: itemProperty forKey: templateKeyPath];
	[self didChangeValueForProperty: @"localBindings"];
}

/** Discards all bindings currently set up between the template item and the 
original items which are replaced by the layout. */
- (void) unbindTemplateItem
{
	[self willChangeValueForProperty: @"localBindings"];
	[_localBindings removeAllObjects];
	[self didChangeValueForProperty: @"localBindings"];
}


- (void) setUpTemplateElementWithNewValue: (id)templateValue
                                   forKey: (NSString *)aKey
                                   inItem: (ETLayoutItem *)anItem
{
	[anItem setValue: templateValue forKey: aKey];
}

- (void) setUpTemplateElementsForItem: (ETLayoutItem *)item
{
	if ([_renderedItems containsObject: item])
		return;

	for (NSString *key in _templateKeys)
	{
		id value = [item valueForKey: key];

		/* Remember the original value to be restored later */
		[item setDefaultValue: (nil != value ? value : (id)[NSNull null]) 
		          forProperty: key];

		[self setUpTemplateElementWithNewValue: [_templateItem copyValueForProperty: key]
		                                forKey: key
		                                inItem: item];

	}

	[self setUpKVOForItem: item];
}

- (id <ETComputableLayout>) positionalLayout
{
	return _positionalLayout;
}

- (void) setPositionalLayout: (id <ETComputableLayout>)layout
{
    [layout validateLayoutContext: self];

	/* Must precede -willChangeValueForProperty: which resets the positional 
	   layout context to nil */
	[_positionalLayout tearDown];

    [self willChangeValueForProperty: @"positionalLayout"];
	_positionalLayout = layout;
    [self didChangeValueForProperty: @"positionalLayout"];

	/* Must follow -didChangeValueForProperty: which ensures the positional 
	   layout context is set */
	[layout setUp: NO];

	if (layout == nil)
		return;

	[self renderAndInvalidateDisplay];
}

/* Subclass Hooks */

/** Returns YES when the items must not be scaled automatically based on 
[[self layoutContext] itemScaleFactor], otherwise returns NO when the receiver 
delegates the item scaling to the positional layout.

By default, returns YES.

You can override this method to return NO and lets the positional layout scales 
the items.<br />
Alternatively a subclass can implement its own item scaling by overriding 
-willRenderItems:. */
- (BOOL) ignoresItemScaleFactor
{
	return YES;
}

// TODO: Implement NSEditor and NSEditorRegistration protocol, but in ETLayout 
// subclasses or rather in ETLayoutItem itself?
// Since layouts tend to encapsulate large UI chuncks, it could make sense at 
// this level. Well... on ETLayoutItem, it ensures it works easily if we bind 
// a view to its owner item.
- (void) setUpKVOForItem: (ETLayoutItem *)item
{
	FOREACHI([_localBindings allKeys], templateKeyPath)
	{
		id model = ([item representedObject] == nil ? (id)item : [item representedObject]);
		id itemElement = [item valueForKeyPath: templateKeyPath];
		NSString *modelKeyPath = [_localBindings objectForKey: templateKeyPath];

		[itemElement bind: @"value" 
		         toObject: model
			  withKeyPath: modelKeyPath
		          options: nil];//NSKeyValueObservingOptionNew];
	}
}

/** Not needed if -bind:xxx is used since view objects released their bindings 
when they get deallocated. */
- (void) tearDownKVO
{
	/*FOREACHI([_localBindings allKeys], templateKeyPath)
	{
		templateElement = [item valueForKey: templateKeyPath];
		[templateElement bind: @"value"];
	}*/
}

- (void) setUp: (BOOL)isDeserialization
{
	[super setUp: isDeserialization];

	if (isDeserialization)
		return;

	[(ETLayout *)[self positionalLayout] resetLayoutSize];
}

- (void) tearDown
{
	[self restoreAllItems];
	[super tearDown];
}

/** Returns the replaced item for the replacement item found at the given location. */
- (ETLayoutItem *) itemAtLocation: (NSPoint)loc
{
	return [(id)[self positionalLayout] itemAtLocation: loc];
}

/** For each item, replaces the value of every properties matching -templateKeys 
by the value returned by the template item. */
- (void) prepareNewItems: (NSArray *)items
{
	[self restoreAllItems];
	[_renderedItems removeAllObjects];

	for (ETLayoutItem *item in items)
	{
		[self setUpTemplateElementsForItem: item];
	}

	_renderedTemplateKeys = [_templateKeys copy];
	_needsPrepareItems = NO;
}

/** Restores all the items which were rendered since the layout was set up to 
their initial state. */
- (void) restoreAllItems
{
	FOREACH(_renderedItems,item, ETLayoutItem *)
	{
		/* Equivalent to [item setExposed: NO] */
		[[item displayView] removeFromSuperview];

		for (NSString *key in _renderedTemplateKeys)
		{
			id restoredValue = [item defaultValueForProperty: key];

			if ([restoredValue isEqual: [NSNull null]])
				restoredValue = nil;

			[item setValue: restoredValue forKey: key];
		}
	}
	[_renderedItems removeAllObjects];
}

/** <override-dummy />
Overrides to make adjustments to the given items just before they get handed to 
to the positional layout.

For example, ETIconLayout implements a special resizing policy that takes over 
the one provided by the positional layout.

Does nothing by default. */
- (void) willRenderItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{

}

/* Layouting */

- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if (isNewContent || _needsPrepareItems)
	{
		[self prepareNewItems: items];
	}

	[_renderedItems addObjectsFromArray: items];

	NSAssert1([self positionalLayout] != nil, @"Positional layout %@ must "
		@"not be nil in a template item layout", [self positionalLayout]);

	[self willRenderItems: items isNewContent: isNewContent];
	/* Visibility of replaced and replacement items is handled in 
	   -setExposedItems: */
	return [[self positionalLayout] renderWithItems: items isNewContent: isNewContent];
}

/* Used by -[ETLayout render:] to resize the context. */
- (BOOL) isContentSizeLayout
{
	return [[self positionalLayout] isContentSizeLayout];
}

/* Layouting Context Protocol (used by our positional layout delegate) */

- (NSArray *) items
{
	return [[self layoutContext] items];
}

- (NSArray *) arrangedItems
{
	return [[self layoutContext] arrangedItems];
}

- (NSArray *) exposedItems
{
	return [[self layoutContext] exposedItems];
}

- (void) setExposedItems: (NSArray *)exposedItems
{
	[[self layoutContext] setExposedItems: exposedItems];
}

- (NSSize) size
{
	return [[self layoutContext] size];
}

- (void) setLayoutView: (NSView *)aLayoutView
{

}

- (NSView *) view
{
 // FIXME: Remove this cast and solve this properly
	return [(ETLayoutItem *)[self layoutContext] view];
}

/* By default, returns 1 to prevent the positional layout to resize the items. 
e.g. the icon layout does it in its own way by overriding -resizeLayoutItems:toScaleFactor:. */
- (CGFloat) itemScaleFactor
{

	return ([self ignoresItemScaleFactor] ? 1.0 : [[self layoutContext] itemScaleFactor]);
}

- (NSSize) visibleContentSize
{
	return [[self layoutContext] visibleContentSize];
}

- (void) setContentSize: (NSSize)size;
{
	[self setLayoutSize: size]; /* To sync the layer item geometry */
	[[self layoutContext] setContentSize: size];
}

- (BOOL) isScrollable
{
	return [[self layoutContext] isScrollable];
}

- (void) setNeedsDisplay: (BOOL)now
{
	return [[self layoutContext] setNeedsDisplay: now];
}

- (BOOL) isFlipped
{
	return [[self layoutContext] isFlipped];
}

- (BOOL) isChangingSelection
{
	return NO;
}

@end
