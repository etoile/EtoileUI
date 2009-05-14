/*  <title>ETLayoutItem</title>

	ETLayoutItem.m
	
	<abstract>ETLayoutItem is the base class for all node subclasses that can be 
	used in a layout item tree. ETLayoutItem instances are leaf nodes for the
	layout item tree structure.</abstract>
 
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

#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayoutItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem+Events.h"
#import "ETLayoutItemGroup.h"
#import "ETWindowItem.h"
#import "ETStyleRenderer.h"
#import "ETView.h"
#import "ETContainer.h"
#import "ETInspector.h"
#import "ETScrollableAreaItem.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

/* Properties */

NSString *kETAnchorPointProperty = @"anchorPoint";
NSString *kETActionProperty = @"action";
NSString *kETActionHandlerProperty = @"actionHandler";
NSString *kETAutoresizingMaskProperty = @"autoresizingMask";
NSString *kETBoundingBoxProperty = @"boundingBox";
NSString *kETDefaultFrameProperty = @"defaultFrame";
NSString *kETFlippedProperty = @"flipped";
NSString *kETFrameProperty = @"frame";
NSString *kETIconProperty = @"icon";
NSString *kETImageProperty = @"image";
NSString *kETInspectorProperty = @"inspector";
NSString *kETLayoutProperty = @"layout";
NSString *kETNameProperty = @"name";
NSString *kETNeedsDisplayProperty = @"needsDisplay";
NSString *kETParentItemProperty = @"parentItem";
NSString *kETPersistentFrameProperty = @"persistentFrame";
NSString *kETRepresentedObjectProperty = @"representedObject";
NSString *kRepresentedPathBaseProperty = @"representedPathBase";
NSString *kETSelectedProperty = @"selected";
NSString *kETStyleProperty = @"style";
NSString *kETSubtypeProperty = @"subtype";
NSString *kETTargetProperty = @"target";
NSString *kETValueProperty = @"value";
NSString *kETVisibleProperty = @"visible";

#define DETAILED_DESCRIPTION
/* Don't forget that -variableProperties creates the property dictionary */
#define VARIABLE_PROPERTIES ((NSMutableDictionary *)[self variableProperties])

#define ETUTIAttribute @"uti"

@interface ETLayoutItem (Private)
- (NSRect) bounds;
- (void) setBoundsSize: (NSSize)size;
- (NSPoint) centeredAnchorPoint;
- (void) setImage: (NSImage *)img;
- (void) setIcon: (NSImage *)img;
- (void) layoutItemViewFrameDidChange: (NSNotification *)notif;
- (void) checkDecoration;
- (void) checkDecorator;
@end

@interface ETLayoutItem (SubclassVisibility)
- (void) setDisplayView: (ETView *)view;
@end

/** Various approaches exists to customize layout items look rendering. 

	If you don't plan to rely on your object model, you can simply add to each 
	layout item a custom view  that already knows how to render/display itself.
	Usually you want something which allows to uses the object model properties
	and enables less crude or low-level rendering than an NSView subclass.
	
	If you want to render a layout item in a specific way, you can subclass
	ETLayoutItem and override -render method. This works pretty well if you are
	for example creating a photo collection display system. By combining 
	ETPhotoLayoutItem and ETFlowLayout plugged in a container, you can get a 
	full-featured photo view very easily. By subclassing ETFlowLayout in a new
	ETPhotoLayout class you would even gain more finer control on the layout 
	process itself if you think it's necessary.
	
	If you want to share the look of the rendering between several layout item
	kinds and desires the possibility to save it as a style or edit this render 
	process in a textual/script form, the best solution is to implement a 
	distinct ETRendererStyle sublass.
	
	Most of time, you want a quick yet quite flexible solution without any 
	subclassing, that's why the common solution is to implemente ETLayout
	delegate method called -layout:renderLayoutItem:. With this method you will
	be able to customize the rendering of layout items on the fly depending on
	the layout settings which may change between each rendering. */


@implementation ETLayoutItem

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *)theKey 
{
    if ([theKey isEqualToString: kETSelectedProperty]) 
	{
		return NO;
    } 
	else 
	{
		return [super automaticallyNotifiesObserversForKey: theKey];
    }
}

- (id) init
{
	return [self initWithView: nil value: nil representedObject: nil];
}

- (id) initWithValue: (id)value
{
	return [self initWithView: nil value: value representedObject: nil];
}

- (id) initWithRepresentedObject: (id)object
{
	return [self initWithView: nil value: nil representedObject: object];
}

- (id) initWithView: (NSView *)view
{
	return [self initWithView: view value: nil representedObject: nil];
}

- (id) initWithFrame: (NSRect)frame
{
	self = [self initWithView: nil value: nil representedObject: nil];
	[self setFrame: frame];
	return self;
}

- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
	/* For now, we don't call ETStyle designated initializer to avoid extra 
	   complexity in the initialization path. */
    self = [super init];
    
    if (self != nil)
    {
		// TODO: Examine common use cases and see whether we should pass a 
		// capacity hint to improve performances.
		_variableProperties = [[NSMutableDictionary alloc] init];
		_defaultValues = [[NSMutableDictionary alloc] init];
		_parentItem = nil;
		//_decoratorItem = nil;
		[self setTransform: [NSAffineTransform transform]];
		_boundingBox = ETNullRect;
		[self setView: view];
		[self setFlipped: YES]; /* -setFlipped: must follow -setSupervisorView: */
		[self setVisible: NO];
		[self setStyle: [ETBasicItemStyle sharedInstance]];
		[self setActionHandler: [ETActionHandler sharedInstance]];
		[self setValue: value];
		[self setRepresentedObject: repObject];

		if (view == nil)
			[self setFrame: [[self class] defaultItemRect]];
    }
    
    return self;
}

- (void) dealloc
{
	DESTROY(_variableProperties);
	DESTROY(_defaultValues);
	DESTROY(_modelObject);
	DESTROY(_transform);
	_parentItem = nil; /* weak reference */
    
    [super dealloc];
}

/** Returns a shallow copy of the receiver without copying the view, the styles, 
	the represented object and the children items if the receiver is an 
	ETLayoutItemGroup related classes. 
	Take note that a deep copy of the decorators is created and no view 
	reference is kept, -view will return nil for the copied item.
	TODO: Implement decorators copying that is currently missing.*/
- (id) copyWithZone: (NSZone *)zone
{
	ETLayoutItem *item = [[[self class] alloc] initWithView: nil 
	                                                  value: [self value] 
	                                      representedObject: [self representedObject]];

	[item setName: [self name]];
	[item setStyle: [self style]];
	[item setActionHandler: [self actionHandler]];
	[item setFrame: [self frame]];
	[item setAppliesResizingToBounds: [self appliesResizingToBounds]];
	
	return item;
}

/** Returns a deep copy of the receiver by copying the view and all its 
	subview hierarchy, the styles, the decorators, the represented object and 
	all the descendant children items if the receiver is an ETLayoutItemGroup r
	elated classes. 
	All copied collections are mutable (styles, decorators, representedObject, 
	children items). 
	TODO: Implement styles copying that is currently missing (decorators too in 
	-copyWithZone:). */
- (id) deepCopy
{
	ETLayoutItem *item = [self copyWithZone: NULL];
	id repObjectCopy = nil;

	// TODO: We probably want to handle different kind of copies on the model. 
	// For example, with values objects a shallow copy of an array is a bad 
	// idea, so would be a deep copy for an array of entity objects.
	// A good solution may be to override -copyWithZone: and/or 
	// -mutableCopyWithZone: in collection classes to map each 
	// element based on its model description to a particular copy operation:
	// - value object -> copy
	// - entity object -> don't copy 
	// In this way, we could handle copy in a more meaningful way without having 
	// to decide between only the two crude copy styles deep and shallow. To 
	// achieve we need a model description (metamodel) framework like Magritte.
	// We still need to decide what should the default between shallow and deep 
	// for the represented object (model) when no model description is available.
	if ([[self representedObject] conformsToProtocol: @protocol(NSMutableCopying)])
	{
		repObjectCopy = [[self representedObject] mutableCopy];
	}
	else if ([[self representedObject] conformsToProtocol: @protocol(NSCopying)])
	{
		repObjectCopy = [[self representedObject] copy];
	}
	[item setRepresentedObject: AUTORELEASE(repObjectCopy)];

	// NOTE: When a  view like a slider is used, it is interesting to support
	// true copy in order to clone existing layout items. An example could be
	// picking a layout item from an UI object palette (in Gorm-like style 
	// development).
	if ([[self view] respondsToSelector: @selector(copyWithZone:)])
	{
		[item setView: [[self view] copy]];
	}

	return item;
}

- (NSString *) description
{
	NSString *desc = [super description];

#ifdef DETAILED_DESCRIPTION	
	desc = [@"<" stringByAppendingFormat: @"%@ meta: %d id: %@, ipath: %@, "
		@"selected: %d, repobject: %@ view: %@ frame %@>", desc, [self UIMetalevel], 
		[self identifier], [[self indexPath] keyPath], [self isSelected], 
		[[self representedObject] primitiveDescription], [self view], 
		NSStringFromRect([self frame])];
#else
	desc = [@"<" stringByAppendingFormat: @"%@ id: %@, selected:%d>", 
		desc, [self identifier], [self isSelected]];
#endif
	
	return desc;
}

/** Returns the root item of the layout item tree to which the receiver belongs 
to. 

This method never returns nil because the returned value is equal to self when 
the receiver has no parent item. */
- (id) rootItem
{
	if (_parentItem != nil)
	{
		return [_parentItem rootItem];	
	}
	else
	{
		return self;
	}
}

/** Returns the layout item group which controls the receiver. An item group is
said to be base item that controls descendant items when -representedPathBase
returns a non nil or blank value (see -hasValidRepresentedPathBase).

A base item usually coordinates the event handling, the loading of 
layout items which are provided by a source and the source related mutations, 
for all descendant items that fall under its control. 

All child items are controlled by a common base item until a descendant item is 
declared as a new base item (by providing a represented path base). See also 
-representedPathBase, -representedPath, -[ETLayoutItemGroup source] and related 
setter methods.

An item group is automatically turned into a base item, when you set a source 
or set it as a controller content (see -[ETController setContent:]).

This method will return nil when the receiver isn't a base item, hasn't yet 
been added as a descendant of a base item or has just been removed as a 
descendant of a base item. */
- (ETLayoutItemGroup *) baseItem
{
	if ([self hasValidRepresentedPathBase])
	{
		return (ETLayoutItemGroup *)self;
	}
	else
	{
		return [_parentItem baseItem];
	}
}

/** Returns whether the receiver is a base item or not.

To be a base itemn the receiver must have a valid represented path base set. 
See -setRepresentedPathBase:. */
- (BOOL) isBaseItem
{
	return [self hasValidRepresentedPathBase];
}

/** Returns whether the current -representedPathBase value is valid to qualify 
the receiver as a base item. */
- (BOOL) hasValidRepresentedPathBase
{
	return ([self representedPathBase] != nil 
		&& [[self representedPathBase] isEqualToString: @""] == NO);
}

/** Returns the layout item group to which the receiver belongs to. 
	For the root item as returned by -rootItem, the returned value is always 
	nil. 
	This method will return nil when the receiver hasn't yet been added to an
	item group or has just been removed from an item group. */
- (ETLayoutItemGroup *) parentItem
{
	return _parentItem;
}

/** Returns the layout item group to which the receiver belongs to. 
	If parent parameter is nil, the receiver becomes a root item. 
	You must never call this method directly unless your code belongs to a 
	subclass. If you need to change the parent of a layout item, use -addItem:, 
	-removeFromParent and other similar methods provided to manipulate item 
	collection owned by an item group. */
- (void) setParentItem: (ETLayoutItemGroup *)parent
{
	//ETDebugLog(@"For item %@ with supervisor view %@, modify the parent item from "
	//	"%@ to %@", self, [self supervisorView], _parentItem, parent, self);

	_parentItem = parent;
}

/** Detaches the receiver from the layout item group it belongs to.
	You are in charge of retaining the receiver, otherwise it could be 
	deallocated if no other objects retains it. */
- (void ) removeFromParent
{
	if (_parentItem != nil)
	{
		/* -removeItem: will release us, so to be sure we won't deallocated 
		   right now we use retain/autorelease */
		RETAIN(self);
		[_parentItem removeItem: self];
		AUTORELEASE(self);
	}
}

- (ETContainer *) closestAncestorContainer
{
	if ([[self displayView] isKindOfClass: [ETContainer class]])
		return (ETContainer *)[self displayView];
		
	if (_parentItem != nil)
	{
		return [_parentItem closestAncestorContainer];
	}
	else
	{
		return nil;
	}
}

/** Returns the first layout item bound to a view upwards in the layout item 
tree. 

The receiver itself can be returned. */
- (ETLayoutItem *) closestAncestorItemWithDisplayView
{
	if ([self displayView] != nil)
		return self;

	if (_parentItem != nil)
	{
		return [_parentItem closestAncestorItemWithDisplayView];
	}
	else
	{
		return nil;
	}
}

/** Returns the first display view bound to a layout item upwards in the layout 
item tree. This layout item is identical to the one returned by 
-closestAncestorItemWithDisplayView. 

The receiver display view itself can be returned. */
- (ETView *) closestAncestorDisplayView
{
	ETView *displayView = [self displayView];

	if (displayView != nil)
		return displayView;

	if (_parentItem != nil)
	{
		return [_parentItem closestAncestorDisplayView];
	}
	else
	{
		return nil;
	}
}

/** Returns receiver index path relative to item parameter. 
	The index path is computed by climbing up the layout item tree until we 
	find item parameter and pushing parent relative index of each layout item 
	sequentially into an index path. 
	Passing nil is equivalent to passing the root item as returned by 
	-rootItem. If item is equal to self, the resulting index path is an blank 
	one (relative to itself). */
- (NSIndexPath *) indexPathFromItem: (ETLayoutItem *)item
{
	NSIndexPath *indexPath = nil;
	BOOL baseItemReached = (self == item);

	/* Handle nil item case which implies root item is the base item */
	if (item == nil && self == [self rootItem])
		baseItemReached = YES;
	
	if (_parentItem != nil && item != self)
	{
		indexPath = [_parentItem indexPathFromItem: item];
		if (indexPath != nil)
		{
			indexPath = [indexPath indexPathByAddingIndex: 
				[(ETLayoutItemGroup *)_parentItem indexOfItem: (id)self]];
		}
	}
	else if (baseItemReached)
	{
		indexPath = [NSIndexPath indexPath];
	}

	/* We return a nil index path only if we haven't reached the base item */   	
	return indexPath;
}

/** Returns item index path relative to the receiver.
	This method is equivalent to [item indexFromItem: self].
	If item doesn't belong to the layout item subtree of the receiver, nil is
	returned.
	Passing nil is equivalent to passing the root item as returned by 
	-rootItem, the returned value is always nil because the root item can never
	be a child of the receiver. If item is equal to self, the resulting index 
	path is an blank one (relative to itself). */
- (NSIndexPath *) indexPathForItem: (ETLayoutItem *)item
{
	return [item indexPathFromItem: self];
}

/** Returns absolute index path of the receiver by collecting index of each
	parent layout item until the root layout item is reached (when -parentItem
	returns nil). 
	This method is equivalent to [[self rootItem] indexPathForItem: self]. */
- (NSIndexPath *) indexPath
{
	// TODO: Test whether it is worth to optimize or not
	return [[self rootItem] indexPathForItem: self];
}

/** Returns absolute path of the receiver by collecting the name of each
	parent layout item until the root layout item is reached (when -parentItem
	returns nil). 
	This method is equivalent to [[self rootItem] pathForIndexPath: 
	[[self rootItem] indexPathForItem: self]]. */
- (NSString *) path
{
	/* We rebuild the path by chaining names of the layout item tree to which 
	   we belong. */
	NSString *path = @"/";
	
	if (_parentItem != nil)
	{
		path = [[_parentItem path] 
			stringByAppendingPathComponent: [self identifier]];
	}
	
	return path;
}

/** Returns the represented path which is built with the represented path base 
provided by the base item. */
- (NSString *) representedPath
{
	NSString *path = [self representedPathBase];
	
	if (path == nil)
	{
		if (_parentItem != nil)
		{
			path = [_parentItem representedPath];
			path = [path stringByAppendingPathComponent: [self identifier]];
		}
		else
		{
			path = [self identifier];
		}
	}
	
	return path;
}

/** Returns the represented path base. By default, returns nil.

With a represented path base, an ETLayoutItemGroup instance becomes a base 
item, and provides a path base used by descendant items to build their 
represented paths (see -representedPath). This path base is valid until a 
descendant provides a new represented path base and as such becomes a base item.
See -[ETLayoutItemGroup setRepresentedPathBase:].

Finally take note represented paths are relative to the base item unlike paths 
returned by -path which are absolute paths. */
- (NSString *) representedPathBase
{
	return GET_PROPERTY(kRepresentedPathBaseProperty);
}

/** Returns the identifier associated with the layout item. By default, the 
returned value is the name. 

If -name returns nil or an empty string, the identifier is a string made of 
the index used by the parent item to reference the receiver. */
- (NSString *) identifier
{
	NSString *identifier = [self name];
	
	if (identifier == nil || [identifier isEqual: @""])
	{
		id parentRepObject = [_parentItem representedObject];
		
		// TODO: Should try to retrieve -UniqueID, -UUID and -UUIDString and 
		// simplify the if conditional.
		/* -identifierAtIndex: is implemented by some classes like NSDictionary */
		if ([parentRepObject isCollection] && [parentRepObject isEmpty] == NO
		 && [parentRepObject respondsToSelector: @selector(identifierAtIndex:)]
		 && [_parentItem usesRepresentedObjectAsProvider])
		{
			unsigned int index = [_parentItem indexOfItem: self];
			identifier = [parentRepObject identifierAtIndex: index];
		}
	}

	/*if (identifier == nil || [identifier isEqual: @""])	
		identifier = [self name];*/

	if (identifier == nil || [identifier isEqual: @""])
	{
		identifier = [NSString stringWithFormat: @"%d", 
			[(ETLayoutItemGroup *)_parentItem indexOfItem: (id)self]];
	}
	
	return identifier;
}

/** Returns the display name associated with the receiver. See also 
NSObject(Model) in EtoileFoundation. */
- (NSString *) displayName
{
	id name = [self name];
	
	if (name == nil)
	{
		if ([self view] != nil)
		{
			name = [[self view] description];
		}
		else if ([self value] != nil)
		{
			name = [[self value] stringValue];
		}
		else if ([self representedObject] != nil)
		{
			/* Makes possible to keep an identical display name between an 
			   item and all derived meta items (independently of their meta 
			   levels). */
			name = [[self representedObject] displayName];
		}
		else
		{
			name = [super displayName];
		}
	}
		
	return name;
}

/** Returns the name associated with the layout item.
 
Take note the returned value can be nil or an empty string. */
- (NSString *) name
{
	return GET_PROPERTY(kETNameProperty);
}

/** Sets the name associated with the layout item.
 
Take note the returned value can be nil or an empty string. */
- (void) setName: (NSString *)name
{
	SET_PROPERTY(name, kETNameProperty);
}

/** Returns a value object, that can be used when a single property has to be 
displayed. See also -setValue:. */
- (id) value
{
	return GET_PROPERTY(kETValueProperty);
}

/** Sets a value object, that can be used when a single property has to be 
displayed. For example, in a table layout with a single column or a simple 
positional layout where each basic item style will try to draw it. To know how 
such value object might be used by a layout, see each ETLayout and ETStyle 
subclass documentation.

The value object is typically a string, a number or an image.

Most of time this method can be used as a conveniency which allows to bypass
-valueForProperty: and -setValue:forProperty: when the layout item is used by
combox box, single column table layout, line layout made of simple images etc. */
- (void) setValue: (id)value
{
	// TODO: Should we restrict what values can be accepted...
	/*if ([value isCommonObjectValue] == NO)
	{
		[NSException raise: NSInvalidArgumentException format: @"Value %@ must "
			@"be a common object value to be set in %@", value, self];
		return;
	}*/
	
	SET_PROPERTY(value, kETValueProperty);
}

/** Returns the model object which embeds the data to be displayed and 
represented on screen by the receiver. See also -setRepresentedObject:. */
- (id) representedObject
{
	return _modelObject;
}

/** Sets the model object which embeds the data to be displayed and represented 
on screen by the receiver.

Take note modelObject can be any objects including an ETLayoutItem instance, in 
this case the receiver becomes a meta item and returns YES for -isMetaLayoutItem. */
- (void) setRepresentedObject: (id)modelObject
{
	ASSIGN(_modelObject, modelObject);
}

/** Returns the view associated with the receiver. */
- (NSView *) view
{
	return [[self supervisorView] wrappedView];
}

/** Sets the view associated with the receiver. This view is commonly a 
widget provided by the widget backend. */
- (void) setView: (NSView *)newView
{
	BOOL resizeBoundsActive = [self appliesResizingToBounds];
	id view = [[self supervisorView] wrappedView];
	// NOTE: Frame is lost when newView becomes a subview of an ETView instance
	NSRect newViewFrame = [newView frame];
	
	/* Tear down the current view */
	if (view != nil)
	{
		/* Restore view initial state */
		[view setFrame: [self defaultFrame]];
		/* Stop to observe notifications on current view and reset bounds size */
		[self setAppliesResizingToBounds: NO];
	}
	SET_PROPERTY([NSValue valueWithRect: NSZeroRect], kETDefaultFrameProperty);
	
	/* Inserts the new view */
	
	/* When the view isn't an ETView instance, we wrap it inside a new ETView 
	   instance to have -drawRect: asking the layout item to render by itself.
	   Retrieving the display view automatically returns the innermost display
	   view in the decorator item chain. */
	if (newView != nil && [self supervisorView] == nil)
	{
		ETView *wrapperView = [[ETView alloc] initWithFrame: [newView frame] 
												 layoutItem: self];
		[self setSupervisorView: wrapperView];
		RELEASE(wrapperView);
	}
	[[self supervisorView] setWrappedView: newView];
	
	/* Set up the new view */
	if (newView != nil)
	{
		[self setDefaultFrame: newViewFrame];
		if (resizeBoundsActive)
			[self setAppliesResizingToBounds: YES];
	}
}

/** Returns whether the view used by the receiver is a widget. 

Also returns YES when the receiver uses a layout view which is a widget 
provided by the widget backend. See -[ETLayout layoutView].

See also -[NSView(Etoile) isWidget]. */
- (BOOL) usesWidgetView
{
	return ([[self view] isWidget] || [[[self layout] layoutView] isWidget]);
}

/* Key Value Coding */

- (id) valueForUndefinedKey: (NSString *)key
{
	//ETLog(@"NOTE: -valueForUndefinedKey: %@ called in %@", key, self);
	return GET_PROPERTY(key); /* May return nil */
}

- (void) setValue: (id)value forUndefinedKey: (NSString *)key
{
	//ETLog(@"NOTE: -setValue:forUndefinedKey: %@ called in %@", key, self);
	SET_PROPERTY(value, key);
}

/* Property Value Coding */

/** Returns a value of the model object -representedObject, usually by calling
-valueForProperty: on the represented object. If the represented object is a 
layout item, -valueForKey: will be  called instead of -valueForProperty:. 

-valueForProperty: is implemented by NSObject as part of the 
ETPropertyValueCoding informal protocol. When the represented object is a custom 
model object, it must override -valueForProperty: and -setValue:forProperty: or 
conform to NSKeyValueCoding protocol. See ETPropertyValueCoding to understand 
how to implement your model object.

When the represented object is a layout item, the receiver is a meta layout item 
(see -isMetaItem and -[NSObject(ETLayoutItem) isLayoutItem]). */
- (id) valueForProperty: (NSString *)key
{
	id modelObject = [self representedObject];
	id value = nil;

	/* Basic version which doesn't fetch property value beyond the represented 
	   object, even if this represented object represents another object too. */
	if (modelObject != nil && [[(NSObject *)modelObject properties] containsObject: key])
	{
		if ([modelObject isLayoutItem])
		{
			value = [modelObject valueForKey: key];
		}
		else
		{
			/* We  cannot use -valueForKey here because many classes such as 
			   NSArray, NSDictionary etc. overrides KVC accessors with their own 
			   semantic. */
			value = [modelObject valueForProperty: key];
		}
	}
	else
	{
		value = [self valueForKey: key];
	}	
	
	return value;
}

/** Sets a value identified by key of the model object returned by 
-representedObject. 

See -valueForProperty: for more details. */
- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	id modelObject = [self representedObject];
	BOOL result = YES;

	/* Basic version which doesn't propagate property editing beyond the represented 
	   object, even if this represented object represents another object too. */
	if (modelObject != nil && [[(NSObject *)modelObject properties] containsObject: key])
	{
		if ([modelObject isLayoutItem])
		{
			[modelObject setValue: value forKey: key];
		}
		else
		{
			/* We  cannot use -setValue:forKey here because many classes such as 
			   NSArray, NSDictionary etc. overrides KVC accessors with their own 
			   semantic. */
			result = [modelObject setValue: value forProperty: key];
		}
	}
	else
	{
		[self setValue: value forKey: key];
	}
	
	// FIXME: Implement
	//[self didChangeValueForKey: key];
	
	return result;
}

- (NSArray *) properties
{
	NSArray *properties = A(@"identifier", kETNameProperty, @"x", @"y", @"width", 
		@"height", @"view", kETSelectedProperty, kETLayoutProperty,
		kETImageProperty, kETFrameProperty, kETRepresentedObjectProperty, 
		kRepresentedPathBaseProperty, kETParentItemProperty, 
		kETAutoresizingMaskProperty, kETBoundingBoxProperty, kETActionProperty, 
		kETSubtypeProperty, kETTargetProperty, @"UIMetalevel", @"UIMetalayer");

	properties = [[VARIABLE_PROPERTIES allKeys] arrayByAddingObjectsFromArray: properties];
		
	return [[super properties] arrayByAddingObjectsFromArray: properties];
}

/* Returns a dictionary representation of every property/value pairs not stored 
in ivars.
 
Unless you write a subclass or reflection code, you should never need this 
method, but use the property accessors or Property Value Coding methods to read 
and write the receiver properties. */
- (NSDictionary *) variableProperties
{
	return _variableProperties;
}

/** Returns the metalevel in the UI domain.
	Three metamodel variants exist in Etoile:
	- Object
	- Model
	- UI
	Each metamodel domain is bound to an arbitrary number of metalevels (0, 1, 
	3, etc.). Metalevels are expressed as positive integers and are usually 
	not limited to a max value.
	A new metalevel is entered, each time -setRepresentedObject: is called with 
	an object of the same type than the receiver. The type interpretation of 
	both the receiver and the paremeter varies with the metamodel domain. For UI
	domain, both must include ETLayoutItem type or subtype in their type.
	For example:
	
	id item1 = [ETLayoutItem layoutItem];
	
	item2 = [ETLayoutItem layoutItemWithRepresentedObject: item1];
	item3 = [ETLayoutItem layoutItemWithRepresentedObject: [NSImage image]];
	item4 = [ETLayoutItem layoutItemWithRepresentedObject: item2];
	
	If we call -metalevel method on each item, the output is the following:
	- item1 will return 0
	- item2 will return 1
	- item3 will return 0
	- item4 will return 2 */
- (unsigned int) UIMetalevel
{
	if ([self isMetaLayoutItem])
	{
		unsigned int metalevel = 0;
		id repObject = [self representedObject];
		
		/* An item can be a meta layout item by using a view as represented object */
		if ([repObject respondsToSelector: @selector(UIMetalevel)] )
			metalevel = [repObject UIMetalevel];
		
		return ++metalevel;
	}
	else
	{
		return 0;
	}
}

/** Returns the UI metalayer the receiver belongs to.
	The metalayer is the metalevel which owns the receiver. For UI metamodel 
	domain, the ownership to a metalayer results of existing parent/child 
	relationships in the layout item tree.
	An item has equal UIMetalevel and UIMetalayer when no parent with superior
	UIMetalevel value can be found by climbing up the layout item tree until the
	root item is reached. The root item UI metalevel is 0, thus all descendant
	items can create metalayers by having a superior UI metalevel. 
	A child item can introduce a new metalayer by having a UI metalevel 
	superior to the last parent item defining a UI metalayer. 
	Finally in a metalayer, objects can have arbitrary metalevel. 
	For example:
	
		Item Tree		Metalevel
	
	- root item	0			(0)
	- item 1				(2)
		- child item 11		(1)
			- item 111		(4)
				- item 1111	(4)
				- item 1112	(0)
		- child item 12		(2)
	- item 2				(0)
		- item 21			(0)
		
	Available metalayers:
	- (0) item 0, 2, 21
	- (2) item 1, 11, 12
	- (4) item 1111, 1111, 1112
	
	No metalayer (1) exists with this layout item tree, because the only item
	bound to this metalevel is preempted by the metalayer (2) introduced with 
	'item 1'. */
- (unsigned int) UIMetalayer
{
	int metalayer = [self UIMetalevel];
	id parent = self;
	
	while ((parent = [parent parentItem]) != nil)
	{
		if ([parent UIMetalevel] > metalayer)
			metalayer = [parent UIMetalevel];
	}
	
	return metalayer;
}

// TODO: Rename -isMetalevelItem
- (BOOL) isMetaLayoutItem
{
	// NOTE: Defining the item as a meta item when a view is the represented 
	// object allows to read and write view values when the item is modified
	// with PVC. If the item is declared as a normal item, PVC will apply to
	// the item itself for all properties common to NSView and ETLayoutItem 
	// (mostly frame related properties).
	// See also -valueForProperty and -setValue:forProperty:
	return ([[self representedObject] isKindOfClass: [ETLayoutItem class]]
		|| [[self representedObject] isKindOfClass: [NSView class]]);
}

#if 0
- (BOOL) isPropertyItem
{
	return [[self representedObject] isKindOfClass: [ETProperty class]];
}
#endif

- (BOOL) isGroup
{
	return NO;
}

/** Sets the display view of the receiver. Never calls this method directly 
	unless you write an ETLayoutItem subclass. 
	You must use -setDecoratorItem: if you want to modify the display view of 
	the receiver. */
- (void) setDisplayView: (ETView *)view
{
	if ([self decoratorItem] == nil)
		[view setLayoutItemWithoutInsertingView: self];
	ASSIGN(_view, view);
}

/** Sets the receiver selection state.

You rarely need to call this method. Take note the new selection state won't be 
apparent until a redisplay occurs. */
- (void) setSelected: (BOOL)selected
{
	if (selected == _selected)
		return;

	[self willChangeValueForKey: kETSelectedProperty];
	_selected = selected;
	ETDebugLog(@"Set layout item selection state %@", self);
	[self didChangeValueForKey: kETSelectedProperty];
}

/** Returns the receiver selection state. See also -setSelected:. */
- (BOOL) isSelected
{
	return _selected;
}

/** Sets whether the receiver should be displayed or not.

Take note the new visibility state won't be apparent until a redisplay occurs. */
- (void) setVisible: (BOOL)visible
{
	_visible = visible;
}

/** Returns whether the receiver should be displayed or not. See also -setVisible:. */
- (BOOL) isVisible
{
	return _visible;
}

/** Returns the receiver UTI type as -[NSObject type], but combines it with the
subtype and the represented object type when available.

When the receiver has a subtype, the returned type is a transient type whose 
supertypes are the class type and the subtype. <br />
When the receiver has a represented object, the returned type is a transient 
type whose supertypes are the class type and the represented object class type.<br />
In case, the receiver has both a represented object and a subtype, the 
returned type will combine both as supertypes. */
- (ETUTI *) type
{
	ETUTI *subtype = [self subtype];
	NSMutableArray *supertypes = [NSMutableArray arrayWithObject: [super type]];

	if (subtype != nil)
	{
		[supertypes addObject: subtype];
	}
	if (_modelObject != nil)
	{
		[supertypes addObject: [_modelObject type]];
	}

	return [ETUTI transientTypeWithSupertypes: supertypes];
}

/** Sets the receiver subtype.

This method can be used to subtype an object (without involving any subclassing).

You can use it to restrict pick and drop allowed types to the receiver type, 
when the receiver is a "pure UI object" without a represented object bound to a 
UI. */
- (void) setSubtype: (ETUTI *)aUTI
{
	SET_PROPERTY(aUTI, kETSubtypeProperty);
}

/** Returns the receiver subtype.

More explanations in -setSubtype. See also -type. */
- (ETUTI *) subtype
{
	return GET_PROPERTY(kETSubtypeProperty);
}

/* Returns the supervisor view associated with the receiver. The supervisor view 
is a wrapper view around the receiver view (see -view). 

You shouldn't use this method unless you write a subclass.

The supervisor view is used internally by EtoileUI to support views or widgets 
provided by the widget backend (e.g. AppKit) within a layout item tree. See 
also ETView. */
- (id) supervisorView
{
	return _view;
}

/** Sets the supervisor view associated with the receiver. 

You should never need to call this method.

See also -supervisorView:. */
- (void) setSupervisorView: (ETView *)supervisorView
{
	[super setSupervisorView: supervisorView];

	[self setFrame: [supervisorView frame]];

	BOOL noDecorator = (_decoratorItem == nil);
	BOOL hasParent = (_parentItem == nil);
	
	if (noDecorator && hasParent)
		[_parentItem handleAttachViewOfItem: self];
}

/* Inserts a supervisor view that is required to be decorated. */
- (void) setDecoratorItem: (ETDecoratorItem *)decorator
{
	BOOL needsInsertSupervisorView = (decorator != nil && [self supervisorView] == nil);
	if (needsInsertSupervisorView)
	{
		[self setSupervisorView: AUTORELEASE([[ETView alloc] initWithFrame: [self frame]])];
	}
	[super setDecoratorItem: decorator];
}

/** When the receiver content is presented inside scrollers, returns the 
decorator item that owns the scrollers provided by the widget backend (e.g. 
AppKit), otherwise returns nil. */
- (ETScrollableAreaItem *) firstScrollViewDecoratorItem
{
	id decorator = self;
	
	while ((decorator = [decorator decoratorItem]) != nil)
	{
		if ([decorator isKindOfClass: [ETScrollableAreaItem class]])
			break;
	}
	
	return decorator;
}

/** When the receiver content is presented inside a window, returns the 
decorator item that ownss the window provided by the widget backend (e.g. 
AppKit), otherwise returns nil. */
- (ETWindowItem *) windowDecoratorItem
{
	id lastDecorator = [self lastDecoratorItem];
	id windowDecorator = nil;
	
	if ([lastDecorator isKindOfClass: [ETWindowItem class]])
		windowDecorator = lastDecorator;
		
	return windowDecorator;
}

/** Returns the content rect in the decorator/receiver? coordinate space.

When the receiver has no decorator, the content rect is equal to the bounds, 
otherwise it corresponds to the positioning and sizing within the outermost 
decorator. No ---> The outermost decorator content rect is always equal to the bounds.

For every items within a decorator chain, frame and bounds don't vary, only the 
content rect does.  */
- (NSRect) contentRect // Move into ETDecoratorItem
{
	ETView *supervisorView = [self supervisorView];

	// TODO: Ugly code...
	if ([supervisorView isKindOfClass: [ETScrollView class]])
	{
		return [[(NSScrollView *)[supervisorView mainView] contentView] frame];
	}
	else if ([supervisorView isKindOfClass: [ETView class]])
	{
		return [[supervisorView wrappedView] frame]; // FIXME: Should [[self view] frame]
	}

	return [self frame];
}

/** Returns the layout associated with the receiver to present its content. */
- (ETLayout *) layout
{
	return GET_PROPERTY(kETLayoutProperty);
}

/** Sets the layout associated with the receiver to present its content. */
- (void) setLayout: (ETLayout *)aLayout
{
	SET_PROPERTY(aLayout, kETLayoutProperty);
}

/** Forces the layout to be recomputed to take in account geometry and content 
related changes since the last layout update. */
- (void) updateLayout
{
	/* See -apply: */
}

/** Allows to compute the layout of the whole layout item tree without any 
	rendering/drawing. The layout begins with layout item leaves which can 
	simply returns their size, then moves up to layout item node which can 
	compute their layout and by side-effect their size. The process is 
	continued until the root layout item associated with a container is 
	reached.
	inputValues is usually nil. */
- (void) apply: (NSMutableDictionary *)inputValues
{
	[self updateLayout];
}

/** Returns the innermost decorator item in the decorator chain which has a 
supervisor view bound to it, thereby can be qualified as an item with a view.
If the receiver has a supervisor view, then the receiver is returned. 

TODO: Implement or remove... */
- (ETLayoutItem *) firstDecoratorItemWithSupervisorView
{
	return nil;
}

/** Returns the rect where the drawing of the layout item must occur, typically 
used by the styles. */
- (NSRect) drawingFrame
{
	ETView *supervisorView = [self supervisorView];

	if (supervisorView != nil && supervisorView != [self displayView])
	{
		NSRect contentBounds = [[self supervisorView] frame];
		contentBounds.origin = NSZeroPoint;
		return contentBounds;
	}
	else
	{
		return [self bounds];
	}
}

/** Propagates rendering/drawing in the layout item tree.
	This method doesn't involve any layout and size computation of the layout 
	items. If you need to do layout or size computation, implement the method
	-apply: in addition to this one.
	You can eventually override this method. If you want to keep the drawing 
	of the receiver, the superclass implementation must be called.
    dirtyRect indicates the portion of the item that needs to be redraw and is 
    expressed in the receiver coordinates. This rect is is usally equal to the 
	item drawing frame, but it may be smaller if only a portion of parent 
	needs to be redrawn and this portion doesn't overlap the whole receiver 
	frame. 
	Unlike in a view, you are free to draw outside of an item frame, 
	yet you should be careful when you draw outside of the boundaries of the  
	receiver and only uses it to draw visual embellishments strictly related to 
	the receiver. This ability to draw beyong the boundaries of a layout item is 
	useful for drawing borders, selection mark, icon badge, control points etc.
	The focus is always locked on view before this method is called.
	inputValues is an dictionary of key/value pairs that is passed by the first 
	ancestor item on which the drawing has begun, you can add or remove values 
	in it to modify the rendering of style/filter attributes in the renderer 
	chain of the receiver or other descendant items. This dictionary is carried 
	downwards through the layout item tree for the length of the drawing 
	session. 
	WARNING: The inputValues is currently reset each time an item with a view 
	is asked to draw, in other words the dictionary handed to its parent item 
	isn't handed to it. */
- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view 
{
	//ETLog(@"Render frame %@ of %@ dirtyRect %@ in %@", 
	//	NSStringFromRect([self drawingFrame]), self, NSStringFromRect(dirtyRect), view);

#ifdef DEBUG_DRAWING
	/* For debugging the drawing of the supervisor view over the item view */
	if ([self displayView] != nil)
	{
		[[NSColor greenColor] set];
		[NSBezierPath setDefaultLineWidth: 3.0];
		[NSBezierPath strokeRect: ETMakeRect(NSZeroPoint, [self size])];
	}
#endif

#ifdef DEBUG_DRAWING
	/* For debugging the drawing of the supervisor view over the item view */
	if ([self displayView] == nil)
	{
		[[NSColor cyanColor] set];
		[NSBezierPath setDefaultLineWidth: 3.0];
		[NSBezierPath strokeRect: ETMakeRect(NSZeroPoint, [self size])];
	}
#endif

	[[self style] render: inputValues layoutItem: self dirtyRect: dirtyRect];
}

/** A shortcut method for -render: inherited from ETStyle. */
- (void) render
{
	[self render: nil];
}

#if 0
/** Looks up the view which can display a rect by climbing up the layout 
item tree until a display view which contains rect is found. This view is 
returned through the out parameter aView and the returned value is the dirty 
rect in the coordinate space of aView.

This method hooks the layout item tree display mechanism into the AppKit view 
hierarchy which implements the underlying display support.

You should never need to call this method, unless you write a subclass which 
needs some special redisplay policy. */
- (NSRect) convertDisplayRect: (NSRect)rect toAncestorDisplayView: (NSView **)aView
{
	NSRect newRect = rect;
	// WARNING: If -[ETWindowItem supervisorView] is changed, the next line must 
	// be updated.
	NSView *topView = [[[self closestAncestorDisplayView] window] contentView];
	NSView *displayView = [self displayView];
	ETLayoutItem *parent = self;

	/* The displayed receiver has no ancestors bound to a view */
	if (topView == nil)
		return NSZeroRect;

	/* We expect topView to be never nil, so that the loop can be entered on a nil displayView. */
	while (displayView != topView 
		&& (displayView == nil || NSContainsRect([parent frame], newRect) == NO))
	{
		ETLayoutItem *child = parent;

		parent = [parent parentItem];
		displayView = [parent supervisorView];
		/* Force the exit when we reach the window layer and newRect isn't fully 
		   contained within the window layer frame.
		   TODO: A more accurate fix could be to override -displayView or 
		   -setNeedsDisplay: and -setNeedsDisplayInRect: in ETWindowLayer since 
		   it cannot use a window decorator item as the root window. */
		if (parent == nil)
			break;

		newRect = [child convertRectToParent: newRect];
	}

	BOOL shouldPatchRect = (displayView == topView);
	if (shouldPatchRect && [[topView layoutItem] decoratorItem] != nil)
	{
		/* Convert newRect to the window content view coordinate space */
		[[[topView layoutItem] lastDecoratorItem] convertDecoratorRectToContent: newRect];
	}

	*aView = displayView;
	return newRect;
}
#endif

#if 0
- (NSRect) convertDisplayRect: (NSRect)rect
        toAncestorDisplayView: (NSView **)aView 
                     rootView: (NSView *)topView
                   parentItem: (ETLayoutItem *)parent
{
	/* The displayed receiver has no ancestors bound to a view */
	if (topView == nil)
		return NSZeroRect;

	NSView *displayView = [self displayView];
	BOOL hasReachedWindow = (displayView == topView);

	BOOL canDisplayRect = (displayView != nil && NSContainsRect([self bounds], rect)) ;

	if (canDisplayRect || hasReachedWindow)
	{
		*aView = displayView;
		return rect;//[[self lastDecoratorItem] displayRectForDecoratorRect: rect];	
	}
	else /* Recurse up in the tree until rect is enclosed by the receiver */
	{
		if (_parentItem != nil)
		{
			NSRect rectInParent = [self convertRectToParent: rect];
			return [_parentItem convertDisplayRect: rectInParent toAncestorDisplayView: aView rootView: topView parentItem: _parentItem];
		}
		else
		{
			// NOTE: -convertDisplayRect:XXX invoked on nil can return a rect
			// with random values rather than a zero rect.
			return NSZeroRect;
		}
	}
}

- (void) setNeedsDisplay: (BOOL)flag
{
	[self setNeedsDisplayInRect: [self bounds]];
}

- (void) display
{
	[self displayRect: [self bounds]];
}

#endif

/** Marks the receiver and the entire layout item tree owned by it to be 
redisplayed the next time an ancestor view receives a display if needed 
request (see -[NSView displayIfNeededXXX] methods). 

More explanations in -display. */
- (void) setNeedsDisplay: (BOOL)flag
{
	[self setNeedsDisplayInRect: [self convertRectToContent: [self boundingBox]]];
}

- (void) setNeedsDisplayInRect: (NSRect)dirtyRect
{
	NSView *displayView = nil;
	NSRect displayRect = [[self firstDecoratedItem] convertDisplayRect: dirtyRect 
	                        toAncestorDisplayView: &displayView
							rootView: [[[self closestAncestorDisplayView] window] contentView]
							parentItem: _parentItem];

[displayView setNeedsDisplayInRect: displayRect];
}

/** Triggers the redisplay of the receiver and the entire layout item tree 
owned by it. 

To handle the display, an ancestor view is looked up and the rect to refresh is 
converted into this ancestor coordinate space. Precisely both the lookup and the 
conversion are handled by -convertDisplayRect:toAncestorDisplayView:.

If the receiver has a display view, this view will be asked to drawby itself.  */
- (void) display
{
	 /* Redisplay the content bounds unless a custom bouding box is set */
	[self displayRect: [self convertRectToContent: [self boundingBox]]];
}

- (void) displayRect: (NSRect)dirtyRect
{
	// NOTE: We could also use the next two lines to redisplay, but 
	// -convertDisplayRect:toAncestorDisplayView: is more optimized.
	//ETLayoutItem *ancestor = [self closestAncestorItemWithDisplayView];
	//[[ancestor displayView] displayRect: [self convertRect: [self boundingBox] toItem: ancestor]];

	NSView *displayView = nil;
	NSRect displayRect = [[self firstDecoratedItem] convertDisplayRect: dirtyRect
	                        toAncestorDisplayView: &displayView
							rootView: [[[self closestAncestorDisplayView] window] contentView]
							parentItem: _parentItem];
	[displayView displayRect: displayRect];
}

/** Redisplays the areas marked as invalid in the receiver and all its descendant 
items.

Areas can be marked as invalid with -setNeedsDisplay: and -setNeedsDisplayInRect:. */
- (void) displayIfNeeded
{
	[[self closestAncestorDisplayView] displayIfNeeded];
}

/** Returns the style object associated with the receiver. By default, returns 
ETBasicItemStyle. */    
- (ETStyle *) style
{
	return	[self nextStyle];
}

/** Sets the style object associated with the receiver.

The style object controls the drawing of the receiver. See ETStyle to 
understand how to customize the layout item look. */
- (void) setStyle: (ETStyle *)aStyle
{
	[self setNextStyle: aStyle];
}

- (void) setDefaultValue: (id)aValue forProperty: (NSString *)key
{
	[_defaultValues setObject: aValue forKey: key];
}

- (id) defaultValueForProperty: (NSString *)key
{
	return [_defaultValues objectForKey: key];
}

/* Geometry */

/** Returns a rect expressed in parent layout item coordinate space equivalent 
to rect parameter expressed in the receiver coordinate space. */
- (NSRect) convertRectToParent: (NSRect)rect
{
	NSRect rectInParent = rect;

	if ([self isFlipped] != [_parentItem isFlipped])
	{
		rectInParent.origin.y = [self height] - rectInParent.origin.y - rectInParent.size.height;
	}

	// NOTE: See -convertRectFromParent:...
	// NSAffineTransform *transform = [NSAffineTransform transform];
	// [transform translateXBy: [self x] yBy: [self y]];
	// rectInParent.origin = [transform transformPoint: rect.origin];
	rectInParent.origin.x = rect.origin.x + [self x];
	rectInParent.origin.y = rect.origin.y + [self y];
	
	return rectInParent;
}

/** Returns a rect expressed in the receiver coordinate space equivalent to
rect parameter expressed in the parent layout item coordinate space. */
- (NSRect) convertRectFromParent: (NSRect)rect
{
	NSRect rectInReceiver = rect; /* Keep the size as is */

	// NOTE: If we want to handle bounds transformations (rotation, translation,  
	// and scaling), we should switch to NSAffineTransform, the current code 
	// would be...
	// NSAffineTransform *transform = [NSAffineTransform transform];
	// [transform translateXBy: -([self x]) yBy: -([self y])];
	// rectInChild.origin = [transform transformPoint: rect.origin];
	rectInReceiver.origin.x = rect.origin.x - [self x];
	rectInReceiver.origin.y = rect.origin.y - [self y];

	if ([self isFlipped] != [_parentItem isFlipped])
	{
		rectInReceiver.origin.y = [self height] - rectInReceiver.origin.y - rectInReceiver.size.height;
	}

	return rectInReceiver;
}

/** Returns a point expressed in parent layout item coordinate space equivalent 
to point parameter expressed in the receiver coordinate space. */
- (NSPoint) convertPointToParent: (NSPoint)point
{
	return [self convertRectToParent: ETMakeRect(point, NSZeroSize)].origin;
}

/** Returns a rect expressed in the receiver coordinate space equivalent to rect 
parameter expressed in ancestor coordinate space.

In case the receiver is not a descendent or ancestor is nil, returns a null rect. */
- (NSRect) convertRect: (NSRect)rect fromItem: (ETLayoutItemGroup *)ancestor
{
	if (self == ancestor)
		return rect;

	if (ETIsNullRect(rect) || ancestor == nil || _parentItem == nil)
		return ETNullRect;

	NSRect newRect = rect;

	if (_parentItem != ancestor)
	{
		newRect = [_parentItem convertRect: rect fromItem: ancestor];
	}

	return [self convertRectFromParent: [_parentItem convertRectToContent: newRect]];
}

/** Returns a rect expressed in ancestor coordinate space equivalent to rect 
parameter expressed in the receiver coordinate space.

In case the receiver is not a descendent or ancestor is nil, returns a null rect. */
- (NSRect) convertRect: (NSRect)rect toItem: (ETLayoutItemGroup *)ancestor
{
	if (ETIsNullRect(rect) || _parentItem == nil || ancestor == nil)
		return ETNullRect;

	NSRect newRect = rect;
	ETLayoutItem *parent = self;

	while (parent != ancestor)
	{
		newRect = [self convertRectToParent: [self convertRectFromContent: newRect]];
		parent = [parent parentItem];
	}

	return newRect;
}

/** Returns whether the receiver uses flipped coordinates to position its 
content. 
 
The returned value will be taken in account in methods related to geometry, 
event handling and drawing. If you want to alter the flipping, you must use 
-setFlipped: and never alter the supervisor view directly with 
-[ETView setFlipped:].  */
- (BOOL) isFlipped
{
	// TODO: Review ETLayoutItem hierarchy to be sure flipped coordinates are 
	// well supported.
	ETView *supervisorView = [self supervisorView];
	
	if (supervisorView != nil)
	{
		// TODO: Enable later...
		/*if (_flipped != [supervisorView isFlipped])
		{
			ETLog(@"WARNING: -isFlipped doesn't match between the layout item "
				"%@ and its supervisor view %@... You may have wrongly called "
				"-setFlipped: on the supervisor view.", supervisorView, self);
		}*/
		return [supervisorView isFlipped];
	}

	return _flipped;
}

/** Sets whether the receiver uses flipped coordinates to position its content. 

This method updates the supervisor view to match the flipping of the receiver.

You must never alter the supervisor view directly with -[ETView setFlipped:]. */
- (void) setFlipped: (BOOL)flip
{
	if (flip == _flipped)
		return;

	_flipped = flip;
	[[self supervisorView] setFlipped: flip];
	[[self decoratorItem] setFlipped: flip];
}

/** Returns a point expressed in the receiver coordinate space equivalent to
point parameter expressed in the parent layout item coordinate space. */
- (NSPoint) convertPointFromParent: (NSPoint)point
{
	return [self convertRectFromParent: ETMakeRect(point, NSZeroSize)].origin;
}

/** Returns whether a point expressed in the parent item coordinate space is 
within the receiver frame. The item frame is also expressed in the parent item 
coordinate space.
 
This method checks whether the parent item is flipped or not. */
- (BOOL) containsPoint: (NSPoint)point
{
	return NSMouseInRect(point, [self frame], [_parentItem isFlipped]);
}

/** Returns whether a point expressed in the receiver coordinate space is inside 
the receiver frame.

If the bounding box is used to test the point location, YES can be returned with 
a point whose y or x values are negative.  */
- (BOOL) pointInside: (NSPoint)point useBoundingBox: (BOOL)extended
{
	if (extended)
	{
		return NSMouseInRect(point, [self boundingBox], [self isFlipped]);	
	}
	else
	{
		return NSMouseInRect(point, [self bounds], [self isFlipped]);
	}
}

// NOTE: For now, private...
- (NSRect) bounds
{
	BOOL hasDecorator = (_decoratorItem != nil);
	NSRect rect = NSZeroRect;

	if (hasDecorator)
	{
		rect.size = [[self lastDecoratorItem] decorationRect].size;
	}
	else
	{
		rect.size = [self contentBounds].size;
	}

	return rect;
}

- (void) setBoundsSize: (NSSize)size
{
	BOOL hasDecorator = (_decoratorItem != nil);

	if (hasDecorator)
	{
		//NSAssert(NSEqualPoints([self origin], [[self lastDecoratorItem] decorationRect].origin);
		[[self lastDecoratorItem] setDecorationRect: ETMakeRect([self origin], size)];
	}
	else
	{
		[self setContentSize: size];
	}
}

/** Returns the persistent frame associated with the receiver. 

This custom frame is used by ETFreeLayout. This property keeps track of the 
fixed location and size that are used for the receiver in the free layout, even 
if you switch to another layout that alters the receiver frame. The current 
frame is returned by -frame in all cases, hence when ETFreeLayout is in use, 
-frame is equal to -persistentFrame. */
- (NSRect) persistentFrame
{
	// TODO: Find the best way to eventually allow the represented object to 
	// provide and store the persistent frame.
	NSValue *value = GET_PROPERTY(kETPersistentFrameProperty);
	
	/* -rectValue wrongly returns random rect values when value is nil */
	if (value == nil)
		return ETNullRect;

	return [value rectValue];
}

/** Sets the persistent frame associated with the receiver. See -persistentFrame. */
- (void) setPersistentFrame: (NSRect) frame
{
	SET_PROPERTY([NSValue valueWithRect: frame], kETPersistentFrameProperty);
}

- (void) updatePersistentGeometryIfNeeded
{
	ETLayout *parentLayout = [_parentItem layout];

	if ([parentLayout isPositional] && [parentLayout isComputedLayout] == NO)
		[self setPersistentFrame: [self frame]];
}

/** Returns the current frame. If the receiver has a view attached to it, the 
returned frame is equivalent to the display view frame.  

This value is always in sync with the persistent frame in a positional and 
non-computed layout such as ETFreeLayout, but is usually different when the 
layout is computed. 
See also -setPersistentFrame: */
- (NSRect) frame
{
	BOOL hasDecorator = (_decoratorItem != nil);

	if (hasDecorator)
	{
		return [[self lastDecoratorItem] decorationRect];
	}
	else
	{
		return ETMakeRect([self origin], [self contentBounds].size);
	}
}

/** Sets the current frame and also the persistent frame if the layout of the 
parent item is positional and non-computed such as ETFreeLayout.

See also -[ETLayout isPositional] and -[ETLayout isComputedLayout]. */
- (void) setFrame: (NSRect)rect
{
	ETDebugLog(@"-setFrame: %@ on %@", NSStringFromRect(rect), self);  

	BOOL hasDecorator = (_decoratorItem != nil);

	if (hasDecorator)
	{
		return [[self lastDecoratorItem] setDecorationRect: rect];
	}
	else
	{
		[self setContentSize: rect.size];
		/* Must follow -setContentSize: to allow the anchor point to be computed */
		[self setOrigin: rect.origin];
	}

	[[self style] didChangeItemBounds: [self contentBounds]];
}

/** Returns the current origin associated with the receiver frame. See also -frame. */
- (NSPoint) origin
{
	NSPoint anchorPoint = [self anchorPoint];
	NSPoint origin = [self position];

	origin.x -= anchorPoint.x;
	origin.y -= anchorPoint.y;

	return origin;
}

/** Sets the current origin associated with the receiver frame. See also -setFrame:. */   
- (void) setOrigin: (NSPoint)origin
{
	NSPoint anchorPoint = [self anchorPoint];
	NSPoint position = origin ;

	position.x += anchorPoint.x;
	position.y += anchorPoint.y;

	[self setPosition: position];
}

/** Returns the current anchor point associated with the receiver content bounds. 
The anchor point is expressed in the receiver content coordinate space.

By default, the anchor point is centered in the content bounds rectangle. See 
-contentBounds.

The item position is relative to the anchor point. See -position. */
- (NSPoint) anchorPoint
{
	if (HAS_PROPERTY(kETAnchorPointProperty) == NO)
	{
		NSPoint anchor = [self centeredAnchorPoint];
		SET_PROPERTY([NSValue valueWithPoint: anchor], kETAnchorPointProperty);
		return anchor;
	}
	return [GET_PROPERTY(kETAnchorPointProperty) pointValue];
}

/* Returns the center of the bounds rectangle in the receiver content coordinate 
space. */
- (NSPoint) centeredAnchorPoint
{
	NSSize boundsSize = [self contentBounds].size;	
	NSPoint anchorPoint = NSZeroPoint;
	
	anchorPoint.x = boundsSize.width / 2.0;
	anchorPoint.y = boundsSize.height / 2.0;
	
	return anchorPoint;
}

/** Sets the current anchor point associated with the receiver content bounds. 
anchor must be expressed in the receiver content coordinate space. */  
- (void) setAnchorPoint: (NSPoint)anchor
{
	ETLog(@"Set anchor point to %@ - %@", NSStringFromPoint(anchor), self);
	SET_PROPERTY([NSValue valueWithPoint: anchor], kETAnchorPointProperty);
}

/** Returns the current position associated with the receiver frame. The 
position is expressed in the parent item coordinate space. See also 
-setPosition:. */
- (NSPoint) position
{
	return _position;
}

- (BOOL) shouldSyncSupervisorViewGeometry
{
	return (_isSyncingSupervisorViewGeometry == NO && [self supervisorView] != nil);
}

/** Sets the current position associated with the receiver frame.

When -setPosition: is called, the position is applied relative to -anchorPoint. 
position must be expressed in the parent item coordinate space (exactly as the 
frame). When the position is set, the frame is moved to have the anchor point 
location in the parent item coordinate space equal to the new position value. */  
- (void) setPosition: (NSPoint)position
{
	_position = position;

	// NOTE: Will probably be reworked once layout item views are drawn directly by EtoileUI.
	if ([self shouldSyncSupervisorViewGeometry])
	{
		_isSyncingSupervisorViewGeometry = YES;
		[[self displayView] setFrameOrigin: [self origin]];
		_isSyncingSupervisorViewGeometry = NO;
	}
	
	[self updatePersistentGeometryIfNeeded];
}

/** Returns the current size associated with the receiver frame. See also -frame. */       
- (NSSize) size
{
	return [self bounds].size;
}

/** Sets the current size associated with the receiver frame. See also -setFrame:. */           
- (void) setSize: (NSSize)size
{
	[self setBoundsSize: size];
}

/** Returns the current x coordinate associated with the receiver frame origin. 
See also -frame. */       
- (float) x
{
	return [self origin].x;
}

/** Sets the current x coordinate associated with the receiver frame origin. 
See also -setFrame:. */
- (void) setX: (float)x
{
	[self setOrigin: NSMakePoint(x, [self y])];
}

/** Returns the current y coordinate associated with the receiver frame origin. 
See also -frame. */
- (float) y
{
	return [self origin].y;
}

/** Sets the current y coordinate associated with the receiver frame origin. 
See also -setFrame:. */
- (void) setY: (float)y
{
	[self setOrigin: NSMakePoint([self x], y)];
}

/** Returns the current height associated with the receiver frame size. See also 
-frame. */
- (float) height
{
	return [self size].height;
}

/** Sets the current height associated with the receiver frame size. See also 
-setFrame:. */
- (void) setHeight: (float)height
{
	[self setSize: NSMakeSize([self width], height)];
}

/** Returns the current width associated with the receiver frame size. See also 
-frame. */
- (float) width
{
	return [self size].width;
}

/** Sets the current width associated with the receiver frame size. See also 
-setFrame:. */
- (void) setWidth: (float)width
{
	[self setSize: NSMakeSize(width, [self height])];
}

/** Returns the content bounds associated with the receiver. */
- (NSRect) contentBounds
{
	return _contentBounds;
}

/** Returns the content bounds expressed in the decorator item coordinate space. 
When no decorator is set, the parent item coordinate space is used.

Both decoration rect and content bounds have the same size, because the first 
decorated item is never a decorator and thereby has no decoration. */ 
- (NSRect) decorationRectForContentBounds: (NSRect)bounds
{
	BOOL hasDecorator = (_decoratorItem != nil);

	if (hasDecorator)
	{
		return ETMakeRect([_decoratorItem contentRect].origin, bounds.size);
	}
	else
	{
		return ETMakeRect([self origin], bounds.size);
	}
}

/* Used by ETDecoratorItem */
- (NSRect) decorationRect
{
	return [self decorationRectForContentBounds: [self contentBounds]];
}

/** Sets the content bounds associated with the receiver.

By default, the origin of the content bounds is (0.0, 0.0). You can customize it 
to translate the coordinate system used to draw the receiver. The receiver 
transform, which might include a translation too, won't be altered. Both 
translations are cumulative.

If the flipped property is modified, the content bounds remains identical. */
- (void) setContentBounds: (NSRect)rect
{
	_contentBounds = rect;

	if ([self shouldSyncSupervisorViewGeometry] == NO)
		return;

	BOOL hasDecorator = (_decoratorItem != nil);
	
	_isSyncingSupervisorViewGeometry = YES;
	if (hasDecorator)
	{
		NSRect decorationRect = [self decorationRectForContentBounds: [self contentBounds]];
		_contentBounds.size = [_decoratorItem decoratedItemRectChanged: decorationRect];
	}
	else
	{
		[[self displayView] setFrameSize: _contentBounds.size];
	}
	_isSyncingSupervisorViewGeometry = NO;

	[self updatePersistentGeometryIfNeeded];
}

/** Sets the content size associated with the receiver. */
- (void) setContentSize: (NSSize)size
{
	[self setContentBounds: ETMakeRect([self contentBounds].origin, size)];
}

/** Returns a rect expressed in the receiver coordinate space equivalent 
to rect parameter expressed in the receiver content coordinate space.

The content coordinate space is located inside -contentBounds. */
- (NSRect) convertRectFromContent: (NSRect)rect
{
	id decorator = [self decoratorItem];
	NSRect rectInFrame = rect;

	while (decorator != nil)
	{
		rectInFrame = [decorator convertDecoratorRectFromContent: rectInFrame];
		decorator = [decorator decoratorItem];
	} 

	return rectInFrame;
}

/** Returns a rect expressed in the receiver content coordinate space 
equivalent to rect parameter expressed in the receiver coordinate space.

The content coordinate space is located inside -contentBounds. */
- (NSRect) convertRectToContent: (NSRect)rect
{
	id decorator = [self lastDecoratorItem];
	NSRect rectInContent = rect;

	while (decorator != self)
	{
		rectInContent = [decorator convertDecoratorRectToContent: rectInContent];
		decorator = [decorator decoratedItem];
	} 

	return rectInContent;
}

/** Sets the transform applied within the content bounds. */
- (void) setTransform: (NSAffineTransform *)aTransform
{
	ASSIGN(_transform, aTransform);
}

/** Returns the transform applied within the content bounds. */
- (NSAffineTransform *) transform
{
	return _transform;
}

/* Returns the visible portion of the content bounds in case the receiver 
content is clipped by a decorator.

The returned rect origin is equal to (0, 0) all the time unlike -contentBounds.

Private method to be used or removed later on... */
- (NSRect) visibleContentBounds
{
	NSRect visibleContentBounds = [self contentBounds];
	BOOL hasDecorator = (_decoratorItem != nil);

	if (hasDecorator)
	{
		visibleContentBounds = [_decoratorItem visibleContentRect];
	}

	visibleContentBounds.origin = NSZeroPoint;

	return visibleContentBounds;
}

/** Returns the rect that fully encloses the receiver and represents the maximal 
extent on which hit test is done and redisplay requested. This rect is expressed 
in the receiver content coordinate space.

You must be cautious with the bounding box, since its value is subject to be 
overwritten by the layout in use. See -setBoundingBox:. */
- (NSRect) boundingBox
{
	if (ETIsNullRect(_boundingBox))
		return [self bounds];

	return _boundingBox;
}

/** Sets the rect that fully encloses the receiver and represents the maximal 
extent on which hit test is done and redisplay requested. This rect must be 
expressed in the receiver coordinate space.

The bounding box is used by ETInstrument in the hit test phase. It is also used 
by -display and -setNeedsDisplay: methods to compute the dirty area that needs 
to be refreshed. Hence it can be used by ETLayout subclasses related code to 
increase the area which requires to be redisplayed. For example, ETHandleGroup 
calls -setBoundingBox: on its manipulated object, because its handles are not 
fully enclosed in the receiver frame.

The bounding box must be always be greater or equal to the receiver frame. */
- (void) setBoundingBox: (NSRect)extent
{
	_boundingBox = extent;
}

/** Returns the default frame associated with the receiver. See -setDefaultFrame:.

By default, returns ETNullRect. */
- (NSRect) defaultFrame 
{
	NSValue *value = GET_PROPERTY(kETDefaultFrameProperty);
	
	/* -rectValue wrongly returns random rect values when value is nil */
	if (value == nil)
		return ETNullRect;

	return [value rectValue]; 
}

/** Sets the default frame associated with the receiver and updates the item 
frame to match. The default frame is not touched by layout-related transforms 
(such as item scaling) unlike the item frame returned by -frame. 

If a view is provided to the initializer when the layout item gets instantiated, 
the value is initially set to this view frame, else -defaultFrame returns 
a null rect. */
- (void) setDefaultFrame: (NSRect)frame
{ 
	SET_PROPERTY([NSValue valueWithRect: frame], kETDefaultFrameProperty);
	/* Update display view frame only if needed */
	if (NSEqualRects(frame, [self frame]) == NO)
		[self restoreDefaultFrame];
}

/** Modifies the frame associated with the receiver to match the current default 
frame. */
- (void) restoreDefaultFrame
{ 
	[self setFrame: [self defaultFrame]]; 
}

/** Returns the autoresizing mask that applies to the layout item. This mask is 
identical to the autoresizing mask of the supervisor view if one exists. */
- (unsigned int) autoresizingMask
{
	if ([self displayView] != nil)
	{
		return [[self displayView] autoresizingMask];
	}
	else
	{
		// TODO: Implement
		return 0;
	}
}

/** Sets the autoresizing mask that applies to the layout item. This mask is 
also set as the autoresizing mask of the supervisor view if one exists. */
- (void) setAutoresizingMask: (unsigned int)mask
{
	if ([self displayView] != nil)
	{
		[[self displayView] setAutoresizingMask: mask];
	}
	else
	{
		// TODO: Implement
	}
}


/** When the layout item uses a view, pass YES to this method to have the 
content resize when the view itself is resized (by modifying frame).

Resizing content in a view is possible by simply updating bounds size to match 
the view frame. */
- (void) setAppliesResizingToBounds: (BOOL)flag
{
	_resizeBounds = flag;
	
	if ([self displayView] == nil)
		return;
	
	if (_resizeBounds && [self displayView] != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver: self 
		                                         selector: @selector(layoutItemViewFrameDidChange:) 
												     name: NSViewFrameDidChangeNotification
												   object: [self displayView]];
		/* Fake notification to update bounds size */
		[self layoutItemViewFrameDidChange: nil];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		/* Restore bounds size */
		[[self displayView] setBoundsSize: [[self displayView] frame].size];
		[[self displayView] setNeedsDisplay: YES];
	}
}

- (BOOL) appliesResizingToBounds
{
	return _resizeBounds;
}

- (void) layoutItemViewFrameDidChange: (NSNotification *)notif
{
	NSAssert1([self displayView] != nil, @"View of %@ cannot be nil on view notification", self);
	NSAssert1([self appliesResizingToBounds] == YES, @"Bounds resizing must be set on view notification in %@", self);
	
	ETDebugLog(@"Receives NSViewFrameDidChangeNotification in %@", self);
	
	// FIXME: the proper way to handle such scaling is to use an 
	// NSAffineTransform and applies to item view in 
	// -resizeLayoutItems:scaleFactor: when -appliesResizingToBounds returns YES
	[[self displayView] setBoundsSize: [self defaultFrame].size];
	[[self displayView] setNeedsDisplay: YES];
}

/** Returns the image representation associated with the receiver.

By default this method, returns by decreasing order of priority:
<enum>
<item>the receiver image (aka ETImageProperty), if -setImage: was called previously</item>
<item>the receiver value, if -value returns an NSImage object</item>
<item>nil, if none of the above conditions are met</item>
</enum>.
The returned image can be overriden by calling -setImage:. 
 
See also -icon. */
- (NSImage *) image
{
	NSImage *img = GET_PROPERTY(kETImageProperty);
	
	if (img == nil && [[self value] isKindOfClass: [NSImage class]])
		img = [self value];
		
	return img;
}

/** Sets the image representation associated with the receiver and updates both 
the default frame and the frame to match the image size.

If img is nil, then the default behavior of -image is restored and the returned 
image should not be expected to be nil. */
- (void) setImage: (NSImage *)img
{
	SET_PROPERTY(img, kETImageProperty);

	// TODO: Think about whether this is really the best to do...
	if (img != nil)
	{
		[self setDefaultFrame: ETMakeRect(NSZeroPoint, [img size])];
	}
	else if ([self displayView] == nil)
	{
		[self setDefaultFrame: NSZeroRect];
	}
}

// NOTE: May be we should have -displayIcon (or -customIcon, -setCustomIcon:) to 
// eliminate the lack of symetry between -icon and -setIcon:.
/** Returns the image to be displayed when the receiver must be represented in a 
	symbolic style. This icon is commonly used by some layouts and also if the 
	receiver represents another layout item (when -isMetaLayoutItem returns YES).

	By default, this method returns by decreasing order of priority:
    <enum>
    <item>the receiver icon (aka ETIconProperty), if -setIcon: was called previously</item>
    <item>the receiver image (aka ETImageProperty), if -image doesn't return nil</item>
	<item>a view snapshot, if -view doesn't return nil</item>
	<item>the represented object icon, if the represented object and the icon 
    associated with it are not nil</item>
    <item>nil, if none of the above conditions are met</item>
    </enum>. 
	The returned image can be overriden by calling -setIcon:.

	-image and -icon can be considered as symetric equivalents of -name and 
	-displayName methods. */
- (NSImage *) icon
{
	NSImage *icon = GET_PROPERTY(kETIconProperty);
	
	if (icon == nil)
		icon = [self image];

	if (icon == nil && [self displayView] != nil)
		icon = [[self displayView] snapshot];
		
	if (icon == nil && [self representedObject] != nil)
		icon = [[self representedObject] icon];
		
	if (icon == nil)
		ETDebugLog(@"Icon missing for %@", self);
		
	return icon;
}

/** Sets the image to be displayed when the receiver must be represented in a 
    symbolic style. See also -icon.

    If img is nil, then the default behavior of -icon is restored and the 
    icon image should not be expected to be nil. */
- (void) setIcon: (NSImage *)img
{
	SET_PROPERTY(img, kETIconProperty);
}

/* Events & Actions */

/** Returns the action handler associated with the receiver. See ETInstrument to 
know more about event handling in the layout item tree. */
- (id) actionHandler
{
	return GET_PROPERTY(kETActionHandlerProperty);
}

/** Sets the action handler associated with the receiver. */
- (void) setActionHandler: (id)anHandler
{
	SET_PROPERTY(anHandler, kETActionHandlerProperty);
}

/** Returns NO when the receiver should be ignored by the instruments for both 
hit tests and action dispatch. By default, returns YES, otherwise NO when 
-actionsHandler returns nil. */
- (BOOL) acceptsActions
{
	return (GET_PROPERTY(kETActionHandlerProperty) != nil);
}

/** Controls the automatic enabling/disabling of UI elements (such as menu 
items) that uses the responder chain to validate themselves, based on whether 
the receiver or its action handler can respond to the selector action that would 
be sent by the UI element in the EtoileUI responder chain. */
- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>)anItem
{
// TODO: Remove when validation works correctly on GNUstep
#ifndef GNUSTEP
	SEL action = [anItem action];
	SEL twoParamSelector = NSSelectorFromString([NSStringFromSelector(action) 
		stringByAppendingString: @"onItem:"]);

	if ([self respondsToSelector: action])
		return YES;

	if ([[self actionHandler] respondsToSelector: twoParamSelector])
		return YES;

	return NO;
#endif
	return YES;
}

- (BOOL) respondsToSelector: (SEL)aSelector
{
	if ([super respondsToSelector: aSelector])
		return YES;
		
	SEL twoParamSelector = NSSelectorFromString([NSStringFromSelector(aSelector) 
		stringByAppendingString: @"onItem:"]);
	if ([[self actionHandler] respondsToSelector: twoParamSelector])
		return YES;

	return NO;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
	NSMethodSignature *sig = [super methodSignatureForSelector: aSelector];
	
	if (sig == nil)
	{
		SEL twoParamSelector = NSSelectorFromString([NSStringFromSelector(aSelector) 
		stringByAppendingString: @"onItem:"]);

		sig = [[self actionHandler] methodSignatureForSelector: twoParamSelector];
	}

	return sig;
}

- (void) forwardInvocation: (NSInvocation *)inv
{
	SEL selector = [inv selector];

	if ([self respondsToSelector: selector] == NO)
	{
		[self doesNotRecognizeSelector: selector];
		return;
	}

	SEL twoParamSelector = NSSelectorFromString([NSStringFromSelector(selector) 
		stringByAppendingString: @"onItem:"]);
	NSInvocation *twoParamInv = nil;
	id sender = nil;
	id actionHandler = GET_PROPERTY(kETActionHandlerProperty);
	
	[inv getArgument: &sender atIndex: 2];
	twoParamInv = [NSInvocation invocationWithMethodSignature: 
	[actionHandler methodSignatureForSelector: twoParamSelector]];
	[twoParamInv setSelector: twoParamSelector];
	[twoParamInv setArgument: &sender atIndex: 2];
	[twoParamInv setArgument: &self atIndex: 3];

	[twoParamInv invokeWithTarget: actionHandler];
}

/** Sets the target to which actions should be sent.

The target is not retained. */
- (void) setTarget: (id)aTarget
{
	SET_PROPERTY(aTarget, kETTargetProperty);
	RELEASE(aTarget); // NOTE: target is a weak reference
	[[self layout] syncLayoutViewWithItem: self];
}

/** Returns the target to which actions should be sent. */
- (id) target
{
	return GET_PROPERTY(kETTargetProperty);
}

/** Sets the action that can be sent by the action handler associated with 
the receiver.

This won't alter the action set on the receiver view, both are completely 
distinct. */
- (void) setAction: (SEL)aSelector
{
	/* NULL and nil are the same, so a NULL selector removes any existing entry */
	SET_PROPERTY(kETActionProperty, NSStringFromSelector(aSelector));
	[[self layout] syncLayoutViewWithItem: self];
}

/** Returns the action that can be sent by the action handler associated with 
the receiver. 

See also -setAction:. */
- (SEL) action
{
	NSString *selString = GET_PROPERTY(kETActionProperty);

	if (selString == nil)
		return NULL;

	return NSSelectorFromString(selString);
}

/** Returns the next responder in the responder chain. 

The next responder is the parent item unless specified otherwise. */
- (id) nextResponder
{
	return _parentItem;
}

/** Returns the custom inspector associated with the receiver. By default, 
returns nil.

-[NSObject(EtoileUI) inspect:] will show this inspector, unless nil is returned. */
- (id <ETInspector>) inspector
{
	id <ETInspector> inspector = GET_PROPERTY(kETInspectorProperty);
	[inspector setInspectedObjects: A(self)];
	return inspector;
}


/** Sets the custom inspector associated with the receiver. */
- (void) setInspector: (id <ETInspector>)inspector
{
	SET_PROPERTY(inspector, kETInspectorProperty);
}

/* Live Development */

- (void) beginEditingUI
{
	id view = [self supervisorView];
	
	/* Notify to view */
	if (view != nil && [view respondsToSelector: @selector(beginEditingUI)])
		[view beginEditingUI];

	/* Notify decorator item chain */
	[[self decoratorItem] beginEditingUI];
}

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

- (ETLayoutItemGroup *) parentLayoutItem
{
	return [self parentItem];
}

- (void) setParentLayoutItem: (ETLayoutItemGroup *)parent
{
	[self setParentItem: parent];
}

@end


@implementation NSObject (ETLayoutItem)

/** Returns YES if the receiver is an ETLayoutItem class or subclass instance, 
otherwise returns NO. */
- (BOOL) isLayoutItem
{
	return ([self isKindOfClass: [ETLayoutItem class]]);
}

@end
