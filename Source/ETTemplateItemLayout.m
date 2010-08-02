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


@implementation ETTemplateItemLayout

- (id) initWithLayoutView: (NSView *)aView
{
	return [self init];
}

/** <init />
Initializes and return a new template item layout which uses a flow layout as 
its positional layout. 

The positional layout item size contraint style is also set to none.

You are responsible to specify a template item and the template keys on the 
returned instance (usually in a subclass initializer). */ 
- (id) init
{
	self = [super initWithLayoutView: nil];
	if (nil == self)
		return nil;
	
	[self setPositionalLayout: [ETFlowLayout layout]];
	[(ETFlowLayout *)_positionalLayout setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	_renderedItems = [[NSMutableSet alloc] init];
	_templateKeys = [[NSArray alloc] init];
	_localBindings = [[NSMutableDictionary alloc] init];

	return self;
}

- (void) dealloc
{
	DESTROY(_positionalLayout);
	DESTROY(_templateItem);
	DESTROY(_templateKeys);
	DESTROY(_renderedItems);
	DESTROY(_localBindings);
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETTemplateItemLayout *layoutCopy = [super copyWithZone: aZone layoutContext: ctxt];

	layoutCopy->_positionalLayout = [(ETLayout *)_positionalLayout copyWithZone: aZone layoutContext: layoutCopy];
	layoutCopy->_templateItem = [_templateItem deepCopyWithZone: aZone];
	layoutCopy->_templateKeys = [_templateKeys copyWithZone: aZone];
	layoutCopy->_localBindings = [_localBindings mutableCopyWithZone: aZone];
	// TODO: Set up the bindings per item in -setUpCopyWithZone:

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

- (id <ETPositionalLayout>) positionalLayout
{
	return _positionalLayout;
}

- (void) setPositionalLayout: (id <ETPositionalLayout>)layout
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

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
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
	[[self positionalLayout] renderWithLayoutItems: items isNewContent: isNewContent];
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
	[self setLayoutSize: size]; /* To sync the root item geometry */
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
- (float) itemScaleFactor
{

	return ([self ignoresItemScaleFactor] ? 1.0 : [_layoutContext itemScaleFactor]);
}

- (NSSize) visibleContentSize
{
	return [_layoutContext visibleContentSize];
}

- (void) setContentSize: (NSSize)size;
{
	[self setLayoutSize: size]; /* To sync the root item geometry */
	[_layoutContext setContentSize: size];
}

- (BOOL) isScrollViewShown
{
	return [_layoutContext isScrollViewShown];
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

#define CONTROL_VIEW_TAG 0

/* property			value
kETFormLayoutHint	kETLabelAlignment (default) or nil
					kETLeftAlignement
					kETRightAlignment
					kETCenterAligment
					kETPreviousItemAlignement

kETFormLayoutInset	NSZeroRect (default) or nil
					a rect value */

@implementation ETFormLayout

- (id) init
{
	SUPERINIT

	ETLayoutItem *templateItem = [[ETLayoutItemFactory factory] item];;
	ETBasicItemStyle *formStyle = AUTORELEASE([[ETBasicItemStyle alloc] init]);

	[self setTemplateItem: templateItem];
	[formStyle setLabelPosition: ETLabelPositionOutsideLeft];
	[templateItem setCoverStyle: formStyle];
	[templateItem setContentAspect: ETContentAspectComputed];
	/* Icon must precede Style and View to let us snapshot the item in its 
	   initial state. See -setUpTemplateElementWithNewValue:forKey:inItem:
	   View must also be restored after Content Aspect, otherwise the view 
	   geometry computation occurs two times when the items are restored. */
	// FIXME: When View comes before Content Aspect an assertion is raised.
	[self setTemplateKeys: A(@"coverStyle", @"contentAspect")];
	[self setPositionalLayout: [ETColumnLayout layout]];
	[[(id)[self positionalLayout] ifResponds] setIsContentSizeLayout: YES];
	[[(id)[self positionalLayout] ifResponds] setComputesItemRectFromBoundingBox: YES];

	_standaloneTextStyle = [[ETBasicItemStyle alloc] init];
	[_standaloneTextStyle setLabelPosition: ETLabelPositionCentered];

	return self;
}

- (void) dealloc
{
	DESTROY(_standaloneTextStyle);
	[super dealloc];
}

- (float) controlMargin
{
	return 10;
}

- (float) formElementMargin
{
	return 5;
}

- (float) maxLabelWidth
{
	return 300;
}

- (ETBasicItemStyle *) standaloneTextStyle
{
	return _standaloneTextStyle;
}

- (void) setUpTemplateElementsForItem: (ETLayoutItem *)item
{
	if ([item view] == nil)
	{
		[item setCoverStyle: [self standaloneTextStyle]];
	}
	else
	{
		[super setUpTemplateElementsForItem: item];
	}
}

/* -[ETTemplateLayout renderLayoutItems:isNewContent:] doesn't invoke 
-resizeLayoutItems:toScaleFactor: unlike ETLayout, hence we override this method 
to trigger the resizing before ETTemplateItemLayout hands the items to the 
positional layout. */
- (void) willRenderItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	float scale = [_layoutContext itemScaleFactor];
	if (isNewContent || scale != _previousScaleFactor)
	{
		[self resizeLayoutItems: items toScaleFactor: scale];
		_previousScaleFactor = scale;
	}
}

/** Resizes every item to the given scale by delegating it to 
-[ETBasicItemStyle boundingSizeForItem:imageOrViewSize:].

Unlike the inherited implementation, the method ignores every ETLayout 
constraints that might be set such as -constrainedItemSize and 
-itemSizeConstraintStyle.<br />

The resizing isn't delegated to the positional layout unlike in ETTemplateItemLayout. */
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	/* Scaling is always computed from the base image size (scaleFactor equal to 
	   1) in order to avoid rounding error that would increase on each scale change. */
	FOREACH(items, item, ETLayoutItem *)
	{
		//if ([item view] == nil)
		//	continue;
		
		NSSize boundingSize = [[item coverStyle] boundingSizeForItem: item 
		                                             imageOrViewSize: [[item view] frame].size];
		NSRect boundingBox = ETMakeRect(NSZeroPoint, boundingSize);

		// TODO: May be better to compute that in -[ETBasicItemStyle boundingBoxForItem:]
		if ([item view] != nil)
		{
			boundingBox.origin.x = -boundingSize.width + [item width];
			boundingBox.origin.y = -boundingSize.height + [item height];
			[item setBoundingBox: boundingBox];
		}
		else
		{
			[item setSize: boundingSize];
		}

	}
}

@end
