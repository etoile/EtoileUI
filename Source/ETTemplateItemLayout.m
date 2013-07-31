/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/Macros.h>
#import "ETTemplateItemLayout.h"
#import "ETBasicItemStyle.h"
#import "ETColumnLayout.h"
#import "ETComputedLayout.h"
#import "ETFlowLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

#define _layoutContext (id <ETLayoutingContext>)_layoutContext
#pragma GCC diagnostic ignored "-Wprotocol"


@implementation ETTemplateItemLayout

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
	
	[self setPositionalLayout: [ETFlowLayout layoutWithObjectGraphContext: nil]];
	[(ETFlowLayout *)_positionalLayout setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	_templateKeys = [[NSArray alloc] init];
	_localBindings = [[NSMutableDictionary alloc] init];
	_renderedItems = [[NSMutableSet alloc] init];

	return self;
}

- (void) dealloc
{
	DESTROY(_positionalLayout);
	DESTROY(_templateItem);
	DESTROY(_templateKeys);
	DESTROY(_localBindings);
	DESTROY(_renderedItems);
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETTemplateItemLayout *layoutCopy = [super copyWithZone: aZone layoutContext: ctxt];

	layoutCopy->_positionalLayout = [(ETLayout *)_positionalLayout copyWithZone: aZone layoutContext: layoutCopy];
	// FIXME: Pass the current copier
	layoutCopy->_templateItem = [_templateItem deepCopyWithCopier: [ETCopier copier]];
	layoutCopy->_templateKeys = [_templateKeys copyWithZone: aZone];
	layoutCopy->_localBindings = [_localBindings mutableCopyWithZone: aZone];
	/* Rendered items are set up in -setUpCopyWithZone:original: */

	return layoutCopy;
}

- (void) setUpCopyWithZone: (NSZone *)aZone 
                  original: (ETTemplateItemLayout *)layoutOriginal
{
	_renderedItems = [[NSMutableSet allocWithZone: aZone] 
		initWithCapacity: [layoutOriginal->_renderedItems count]];

	FOREACH(layoutOriginal->_renderedItems, item, ETLayoutItem *)
	{
		// FIXME: Declare -objectReferencesForCopy in the layouting context protocol
		ETLayoutItem *itemCopy = [[(id)_layoutContext objectReferencesForCopy] objectForKey: item];
	
		NSParameterAssert(itemCopy != nil);
		NSParameterAssert([itemCopy parentItem] == _layoutContext);

		[self setUpKVOForItem: itemCopy];
		[_renderedItems addObject: itemCopy];
	}
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

See -setTemplateKeys:. */
- (void) setTemplateItem: (ETLayoutItem *)item
{
	ASSIGN(_templateItem, item);
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

See -setTemplateItem:. */
- (void) setTemplateKeys: (NSArray *)keys
{
	ASSIGN(_templateKeys, keys);
}

- (void) bindTemplateItemKeyPath: (NSString *)templateKeyPath 
               toItemWithKeyPath: (NSString *)itemProperty
{
	[_localBindings setObject: itemProperty forKey: templateKeyPath];
}

/** Discards all bindings currently set up between the template item and the 
original items which are replaced by the layout. */
- (void) unbindTemplateItem
{
	[_localBindings removeAllObjects];
}

- (void) setUpTemplateElementWithNewValue: (id)templateValue
                                   forKey: (NSString *)aKey
                                   inItem: (ETLayoutItem *)anItem
{
	BOOL shouldCopyValue = ([templateValue conformsToProtocol: @protocol(NSCopying)] 
		|| [templateValue conformsToProtocol: @protocol(NSMutableCopying)]);
	id newValue = (shouldCopyValue ? [templateValue copy] : templateValue);

	[anItem setValue: newValue forKey: aKey];
}

- (void) setUpTemplateElementsForItem: (ETLayoutItem *)item
{
	if ([_renderedItems containsObject: item])
		return;

	FOREACH(_templateKeys, key, NSString *)
	{
		id value = [item valueForKey: key];

		/* Remember the original value to be restored later */
		[item setDefaultValue: (nil != value ? value : (id)[NSNull null]) 
		          forProperty: key];

		[self setUpTemplateElementWithNewValue: [_templateItem valueForKey: key]
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
	[layout setLayoutContext: self];
	ASSIGN(_positionalLayout, layout);
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

- (void) setUp
{
	[super setUp];
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

	FOREACH(items, item, ETLayoutItem *)
	{
		[self setUpTemplateElementsForItem: item];
	}
}

/** Restores all the items which were rendered since the layout was set up to 
their initial state. */
- (void) restoreAllItems
{
	FOREACH(_renderedItems,item, ETLayoutItem *)
	{
		/* Equivalent to [item setVisible: NO] */
		[[item displayView] removeFromSuperview];

		FOREACH(_templateKeys, key, NSString *)
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

- (void) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if (isNewContent)
	{
		[self prepareNewItems: items];
	}

	[_renderedItems addObjectsFromArray: items];

	NSAssert1([self positionalLayout] != nil, @"Positional layout %@ must "
		@"not be nil in a template item layout", [self positionalLayout]);

	[self willRenderItems: items isNewContent: isNewContent];
	/* Visibility of replaced and replacement items is handled in 
	   -setVisibleItems: */
	[[self positionalLayout] renderWithItems: items isNewContent: isNewContent];
}

/* Layouting Context Protocol (used by our positional layout delegate) */

- (NSArray *) items
{
	return [_layoutContext items];
}

- (NSArray *) arrangedItems
{
	return [_layoutContext arrangedItems];
}

- (NSArray *) visibleItems
{
	return [_layoutContext visibleItems];
}

- (void) setVisibleItems: (NSArray *)visibleItems
{
	[_layoutContext setVisibleItems: visibleItems];
}

- (NSSize) size
{
	return [_layoutContext size];
}

- (void) setSize: (NSSize)size
{
	[self setLayoutSize: size]; /* To sync the layer item geometry */
	[_layoutContext setSize: size];
}

- (void) setLayoutView: (NSView *)aLayoutView
{

}

- (NSView *) view
{
 // FIXME: Remove this cast and solve this properly
	return [(ETLayoutItem *)_layoutContext view];
}

/* By default, returns 1 to prevent the positional layout to resize the items. 
e.g. the icon layout does it in its own way by overriding -resizeLayoutItems:toScaleFactor:. */
- (CGFloat) itemScaleFactor
{

	return ([self ignoresItemScaleFactor] ? 1.0 : [_layoutContext itemScaleFactor]);
}

- (NSSize) visibleContentSize
{
	return [_layoutContext visibleContentSize];
}

- (void) setContentSize: (NSSize)size;
{
	[self setLayoutSize: size]; /* To sync the layer item geometry */
	[_layoutContext setContentSize: size];
}

- (BOOL) isScrollable
{
	return [_layoutContext isScrollable];
}

- (void) setNeedsDisplay: (BOOL)now
{
	return [_layoutContext setNeedsDisplay: now];
}

- (BOOL) isFlipped
{
	return [_layoutContext isFlipped];
}

- (BOOL) isChangingSelection
{
	return NO;
}

@end
