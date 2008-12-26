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
#import <EtoileFoundation/NSObject+Model.h>
#import "ETLayoutItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem+Events.h"
#import "ETLayoutItemGroup.h"
#import "ETWindowItem.h"
#import "ETStyleRenderer.h"
#import "ETView.h"
#import "ETContainer.h"
#import "ETInspector.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

/* Properties */

NSString *kETAnchorPointProperty = @"anchorPoint";
NSString *kETActionHandlerProperty = @"actionHandler";
NSString *kETDefaultFrameProperty = @"defaultFrame";
NSString *kETFlippedProperty = @"flipped";
NSString *kETFrameProperty = @"frame";
NSString *kETIconProperty = @"icon";
NSString *kETImageProperty = @"image";
NSString *kETNameProperty = @"name";
NSString *kETNeedsDisplayProperty = @"needsDisplay";
NSString *kETPersistentFrameProperty = @"persistentFrame";
NSString *kETStyleProperty = @"style";
NSString *kETValueProperty = @"value";

/* Macros to read and write the receiver or local properties without exposing 
 how the properties are stored. The implicit property owner is self. */
#define SET_PROPERTY(value, property) \
	if (value != nil) \
	{ \
		[_variableProperties setObject: value forKey: property]; \
	} \
	else \
	{ \
		[_variableProperties removeObjectForKey: property]; \
	}
#define GET_PROPERTY(property) [_variableProperties objectForKey: property]
#define HAS_PROPERTY(property) ([_variableProperties objectForKey: property] != nil)

#define DETAILED_DESCRIPTION
/* Don't forget that -variableProperties creates the property dictionary */
#define VARIABLE_PROPERTIES ((NSMutableDictionary *)[self variableProperties])

#define ETUTIAttribute @"uti"

@interface ETLayoutItem (Private)
- (NSRect) bounds;
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

- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
    self = [super init];
    
    if (self != nil)
    {
		// TODO: Examine common use cases and see whether we should pass a 
		// capacity hint to improve performances.
		_variableProperties = [[NSMutableDictionary alloc] init];
		_parentLayoutItem = nil;
		//_decoratorItem = nil;
		_frame = ETNullRect;
		// TODO: Enable next line when well tested...
		//_isFlipped = YES;
		[self setDecoratedItem: nil];
		[self setView: view];
		[self setVisible: NO];
		[self setStyle: [ETBasicItemStyle sharedInstance]];
		[self setActionHandler: [ETActionHandler sharedInstance]];
		[self setValue: value];
		[self setRepresentedObject: repObject];
    }
    
    return self;
}

// NOTE: Mac OS X doesn't always update the ref count returned by 
// NSExtraRefCount if the memory management methods aren't overriden to use
// the extra ref count functions.
#ifndef GNUSTEP
- (id) retain
{
	NSIncrementExtraRefCount(self);
	return self;
}

- (unsigned int) retainCount
{
	return NSExtraRefCount(self) + 1;
}
#endif

- (oneway void) release
{
	/* Note whether the next release call will deallocate the receiver, because 
	   once the receiver is deallocated you have no way to safely learn if self
	   is still valid or not.
	   Take note the retain count is NSExtraRefCount plus one. */
	BOOL isDeallocated = (NSExtraRefCount(self) == 0);
	BOOL hasRetainCycle = (_view != nil);

#ifdef GNUSTEP
	[super release];
#else
	if (NSDecrementExtraRefCountWasZero(self))
		[self dealloc];
#endif

	/* Tear down the retain cycle owned by the receiver.
	   By releasing us, we release _view.
	   If we got deallocated by [super release], self and _view are now
	   invalid and we must never use them (by sending a message for example).  */
	if (hasRetainCycle && isDeallocated == NO
	  && NSExtraRefCount(self) == 0 && NSExtraRefCount(_view) == 0)
	{
		DESTROY(self);
	}
}

- (void) dealloc
{
	DESTROY(_variableProperties);
	/* Don't release decorated item (weak reference) */
	if (_decoratorItem != self)
		DESTROY(_decoratorItem);
    DESTROY(_view);
	DESTROY(_modelObject);
	_parentLayoutItem = nil; /* weak reference */
    
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

/** Returns the root item of the layout item tree to which the receiver
	belongs to. 
	This method never returns nil because the returned value is equal to self
	when the receiver has no parent item. */
- (id) rootItem
{
	if ([self parentLayoutItem] != nil)
	{
		return [[self parentLayoutItem] rootItem];	
	}
	else
	{
		return self;
	}
}

/** Returns the layout item group which controls the receiver. An item group
	is said to control descendant items when -representedPathBase returns a non
	nil or blank value.
	A base item usually handles events and data source mutation for all 
	descendant items belonging to it. All child items are controlled by a common 
	base item until a descendant item is declared as a new base item (by 
	providing a represented path base). See also -representedPathBase, 
	-[ETContainer representedPath], -[ETContainer source], -[ETLayoutItemGroup 
	baseContainer].
	If an item group uses a source, it is automatically bound to a represented 
	path base.
	This method will return nil when the receiver isn't a base item, hasn't yet 
	been added as a descendant of a base item or has just been removed as a 
	descendant of a base item. */
- (id) baseItem
{
	if ([self hasValidRepresentedPathBase])
	{
		return self;
	}
	else
	{
		return [[self parentLayoutItem] baseItem];
	}
}

- (BOOL) hasValidRepresentedPathBase
{
	return ([self representedPathBase] != nil 
		&& [[self representedPathBase] isEqual: @""] == NO);
}

/** Returns the layout item group to which the receiver belongs to. 
	For the root item as returned by -rootItem, the returned value is always 
	nil. 
	This method will return nil when the receiver hasn't yet been added to an
	item group or has just been removed from an item group. */
- (ETLayoutItemGroup *) parentItem
{
	return _parentLayoutItem;
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
	//	"%@ to %@", self, [self supervisorView], _parentLayoutItem, parent, self);

	_parentLayoutItem = parent;
}

/** Detaches the receiver from the layout item group it belongs to.
	You are in charge of retaining the receiver, otherwise it could be 
	deallocated if no other objects retains it. */
- (void ) removeFromParent
{
	if ([self parentLayoutItem] != nil)
	{
		/* -removeItem: will release us, so to be sure we won't deallocated 
		   right now we use retain/autorelease */
		RETAIN(self);
		[[self parentLayoutItem] removeItem: self];
		AUTORELEASE(self);
	}
}

- (ETContainer *) closestAncestorContainer
{
	if ([[self displayView] isKindOfClass: [ETContainer class]])
		return (ETContainer *)[self displayView];
		
	if ([self parentLayoutItem] != nil)
	{
		return [[self parentLayoutItem] closestAncestorContainer];
	}
	else
	{
		ETLog(@"WARNING: Found no ancestor container by ending lookup on %@", self);
		return nil;
	}
}

- (ETView *) closestAncestorDisplayView
{
	if ([self displayView] != nil)
		return [self displayView];

	if ([self parentLayoutItem] != nil)
	{
		return [[self parentLayoutItem] closestAncestorDisplayView];
	}
	else
	{
		ETLog(@"WARNING: Found no ancestor display view by ending lookup on %@", self);
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
	
	if ([self parentLayoutItem] != nil && item != self)
	{
		indexPath = [[self parentLayoutItem] indexPathFromItem: item];
		if (indexPath != nil)
		{
			indexPath = [indexPath indexPathByAddingIndex: 
				[(ETLayoutItemGroup *)[self parentLayoutItem] indexOfItem: (id)self]];
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
	
	if ([self parentLayoutItem] != nil)
	{
		path = [[[self parentLayoutItem] path] 
			stringByAppendingPathComponent: [self identifier]];
	}
	
	return path;
}

/** Returns the represented path. */
- (NSString *) representedPath
{
	NSString *path = [self representedPathBase];
	
	if (path == nil)
	{
		if ([self parentLayoutItem] != nil)
		{
			path = [[self parentLayoutItem] representedPath];
			path = [path stringByAppendingPathComponent: [self identifier]];
		}
		else
		{
			path = [self identifier];
		}
	}
	
	return path;
}

/** Returns the represented path base which is nil by default. This represented
	path base can be provided by a container, then allowing to build 
	represented paths for every descendant layout items which don't specify 
	their own custom represented path base (in other words when this method 
	returns nil). 
	By setting the represented path of a container, the related layout item 
	group is able to provide a represented path base automatically used by 
	descendant items. This represented path base is valid until a descendant 
	provides a new represented path base. */
- (NSString *) representedPathBase
{
	return nil;
}

/** Returns the identifier associated with the layout item. By default, the
	returned value is the name. If -name returns nil or an empty string, the
	identifier is a string made of the index used by the parent item to 
	reference the receiver. */
- (NSString *) identifier
{
	NSString *identifier = [self name];
	
	if (identifier == nil || [identifier isEqual: @""])
	{
		id parentRepObject = [[self parentLayoutItem] representedObject];
		
		// TODO: Should try to retrieve -UniqueID, -UUID and -UUIDString and 
		// simplify the if conditional.
		/* -identifierAtIndex: is implemented by some classes like NSDictionary */
		if ([parentRepObject isCollection] && [parentRepObject isEmpty] == NO
		 && [parentRepObject respondsToSelector: @selector(identifierAtIndex:)]
		 && [[self parentLayoutItem] usesRepresentedObjectAsProvider])
		{
			unsigned int index = [[self parentLayoutItem] indexOfItem: self];
			identifier = [parentRepObject identifierAtIndex: index];
		}
	}

	/*if (identifier == nil || [identifier isEqual: @""])	
		identifier = [self name];*/

	
	if (identifier == nil || [identifier isEqual: @""])
	{
		identifier = [NSString stringWithFormat: @"%d", 
			[(ETLayoutItemGroup *)[self parentLayoutItem] indexOfItem: (id)self]];
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

- (NSView *) view
{
	id wrappedView = [[self supervisorView] wrappedView];
	
	if (wrappedView != nil)
	{
		// FIXME: Simplify by hiding these details, the next two branches could
		// be removed now I think...
		if ([wrappedView isKindOfClass: [NSScrollView class]])
		{
			return [wrappedView documentView];
		}
		else if ([wrappedView isKindOfClass: [NSBox class]])
		{
			return [wrappedView contentView];
		}
		else
		{
			return wrappedView;
		}
	}
	else
	{
		return [self supervisorView];
	}
}

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
		//[view setRenderer: nil];
		/* Stop to observe notifications on current view and reset bounds size */
		[self setAppliesResizingToBounds: NO];
	}
	SET_PROPERTY([NSValue valueWithRect: NSZeroRect], kETDefaultFrameProperty);
	
	/* Inserts the new view */
	
	/* When the view isn't an ETView instance, we wrap it inside a new ETView 
	   instance to have -drawRect: asking the layout item to render by itself.
	   Retrieving the display view automatically returns the innermost display
	   view in the decorator item chain. */
	if ([newView isKindOfClass: [ETView class]])
	{
		[self setSupervisorView: (ETView *)newView];
	}
	else if ([newView isKindOfClass: [NSView class]])
	{
		if ([self supervisorView] == nil)
		{
			ETView *wrapperView = [[ETView alloc] initWithFrame: [newView frame] 
													 layoutItem: self];
			[self setSupervisorView: wrapperView];
			RELEASE(wrapperView);
		}
		[[self supervisorView] setWrappedView: newView];
	}
	
	/* Set up the new view */
	if (newView != nil)
	{
		//[newView setRenderer: self];
		[self setDefaultFrame: newViewFrame];
		if (resizeBoundsActive)
			[self setAppliesResizingToBounds: YES];
	}
}

- (void) setDecoratedView: (NSView *)newView
{
	id view = [[self supervisorView] wrappedView];
	// NOTE: Frame is lost when newView becomes a subview of an ETView instance
	NSRect newViewFrame = [newView frame];
	
	/* Tear down the current view */
	if (view != nil)
	{
		/* Restore view initial state */
		[view setFrame: [self defaultFrame]];  /* -defaultFrame returns display view frame */
	}
	
	/* Inserts the new view */
	
	if ([self supervisorView] == nil)
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
	}
}

/* Key Value Coding */

- (id) valueForUndefinedKey: (NSString *)key
{
	//ETLog(@"WARNING: -valueForUndefinedKey: %@ called in %@", key, self);
	return GET_PROPERTY(key); /* May return nil */
}

- (void) setValue: (id)value forUndefinedKey: (NSString *)key
{
	//ETLog(@"WARNING: -setValue:forUndefinedKey: %@ called in %@", key, self);
	SET_PROPERTY(value, key);
}

/* Property Value Coding */

/** Returns a value of the model object -representedObject, usually by 
	calling -valueForProperty: else -valueForKey: with key parameter. By default 
	the model object is a simple dictionary which gets returned by both this 
	method and -representedObject method.
	When the model object is a custom one, it must implement -valueForProperty:
	and -setValue:forProperty: or conform to NSKeyValueCoding protocol. */
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
			value = [modelObject valueForProperty: key];
		}
		//value = [modelObject valueForKey: key];
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
			result = [modelObject setValue: value forProperty: key];
		}
		//[modelObject setValue: value forKey: key];
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
	NSArray *properties = [NSArray arrayWithObjects: @"identifier", @"name", 
		@"x", @"y", @"width", @"height", @"view", @"selected", 
		@"visible", @"image", @"frame", @"representedObject", 
		@"parentLayoutItem", @"UIMetalevel", @"UIMetalayer", nil];

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
	
	while ((parent = [parent parentLayoutItem]) != nil)
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

- (void) didChangeValueForKey: (NSString *)key
{

}

/** Returns the display view of the receiver. The display view is the last
	supervisor view of the decorator item chain. Display view is an instance of 
	ETView class or subclasses.
	You can retrieve the outermost decorator of decorator item chain by calling
	-lastDecoratorItem.
	Take note there is usually only one decorator which is commonly used to 
	support scroll view. 
	See -setDecoratorItem: to know more. */
- (ETView *) displayView
{
	return [[self lastDecoratorItem] supervisorView];
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
    You rarely need to call this method. Take note the new selection state won't 
	be visible until a redisplay occurs. */
- (void) setSelected: (BOOL)selected
{
	_selected = selected;
	ETDebugLog(@"Set layout item selection state %@", self);
}

/** Returns the receiver selection state. */
- (BOOL) isSelected
{
	return _selected;
}

- (void) setVisible: (BOOL)visible
{
	_visible = visible;
}

- (BOOL) isVisible
{
	return _visible;
}

/** Commonly used to select items which can be dragged or dropped in a dragging operation */
- (ETUTI *) type
{
	if ([self representedObject] == nil
	 && [[self representedObject] isKindOfClass: [NSDictionary class]] == NO)
	{
		// FIXME: Replace by [ETUTI typeForClass: [self class]]
		return NSStringFromClass([self class]);
	}	
	else if ([[self representedObject] valueForProperty: ETUTIAttribute] != nil)
	{
		return [[self representedObject] valueForProperty: ETUTIAttribute];
	}
	else
	{
		// FIXME: Replace by [ETUTI typeForClass: [self class]]
		return NSStringFromClass([[self representedObject] class]);
	}
}

/** Returns the decorator item when the receiver uses a view. The decorator 
	item is the receiver itself by default. 
	The decorator item is in charge of managing the item view and must not 
	break the following rules:
	- [self displayView] must return [[self decoratorItem] view]
	- [self view] must return [[[self decoratorItem] view] wrappedView] */
- (ETLayoutItem *) decoratorItem
{
	return _decoratorItem;
}

- (void) checkDecoration
{
	id decorator = [self decoratorItem];
	
	if (decorator == nil)
		return;

	/* Verify the proper set up of the current decorator */
	[decorator checkDecorator];

	// NOTE: Next assertion would fail if -[NSWindowItem supervisorView] is 
	// modified to return nil.
	NSAssert1([self displayView] != nil, @"Display view must no be nil when a "
		@"decorator is set on item %@", self);
	NSAssert2([[decorator displayView] isEqual: [self displayView]], 
		@"Decorator display view %@ must be decorated item display view %@", 
		[decorator displayView], [self displayView]);

}

- (void) checkDecorator
{
	NSAssert2([self parentLayoutItem] == nil, @"Decorator %@ "
		@"must have no parent %@ set", self, [self parentLayoutItem]);

	// TODO: If there is a window item in the decorator chain, the receiver 
	// supervisor view or the outermost supervisor view (display view) don't 
	// match the expectation of the following assertions. Find a way to get rid 
	// of this special case. See -[ETWindowItem superisorView] too..
	if ([self isMemberOfClass: [ETLayoutItem class]])
	{
		NSAssert2([[self supervisorView] isKindOfClass: [ETView class]], 
			@"Decorator %@ must have a supervisor view %@ of type ETView", 
			self, [self supervisorView]);
	}
	if ([[self lastDecoratorItem] isMemberOfClass: [ETLayoutItem class]])
	{
		NSAssert2([[self displayView] isKindOfClass: [ETView class]], 
			@"Decorator %@ must have display view %@ of type ETView", 
			self, [self displayView]);
	}
}

/** Sets the decorator item in order to customize the item view border. The 
	decorator item is typically used to display a title bar making possible to
	manipulate the item directly (by drag and drop). The other common use is 
	putting the item view inside a scroll view. 
	By default, the decorator item is nil. */
- (void) setDecoratorItem: (ETLayoutItem *)decorator
{
	[self checkDecoration]; /* Ensure existing decorator is valid */

	if ([decorator isEqual: [self decoratorItem]])
		return;

	if ([decorator canDecorateItem: self] || decorator == nil)
	{
		/* Memorize our decorator to let the new decorator inserts itself into it */
		id existingDecorator = [self decoratorItem];
		/* Item could have a decorator, so [[item supervisorView] superview] would
	       not give the parent view in this case but the decorator view. */
		id parentView = [[self displayView] superview];
		NSRect frame = [[self displayView] frame];
		// parentView isEqual: [[item parentLayoutItem] view]
		
		[[self displayView] removeFromSuperview];

		// NOTE: Important to retain decorator before calling 
		// -setDecoratedItem: which is going to decrease its retain count
		// by removing it from its parent
		RETAIN(existingDecorator);
		RETAIN(decorator);
		
		/* Must be done before dismantling the existing decorator, otherwise 
		   -handleDecorateItem: nil inView: parentView doesn't remove the 
		   existing decorator view. More precisely, it doesn't reinserts the
		   receiver supervisor view but the one currently in use. */
		ASSIGN(_decoratorItem, decorator),

		/* Dismantle existing decorator */
		[existingDecorator setDecoratedItem: nil];
		[existingDecorator handleDecorateItem: nil inView: nil];
		
		/* Set up new decorator */
		[decorator setDecoratedItem: self];
		[decorator handleDecorateItem: self inView: parentView];

		if ([self respondsToSelector: @selector(container)])
		{
			[[(id)self container] didChangeDecoratorOfItem: self];
		}
		else
		{
			ETLog(@"WARNING: Item %@ doesn't use a container", self);
		}
		
		/* Restore supervisor view as display view if no decorator is set */
		if (decorator == nil) // && [self view] != nil
		{
			NSAssert2([[self displayView] superview] == nil, @"If %@ decorator "
				@"was just removed without being replaced, the display view of "
				@"%@ must have no superview", existingDecorator, self);
			[parentView addSubview: [self displayView]];
			/* When a decorator view has been resized and/moved, we must reflect 
			   it on the embedded view which may not have been resized.
			   Not updating the frame is especially visible when the view is 
			   used as a document view within a scroll view and this scroll view 
			   frame is modified. Switching to a layout view reveals the issue
			   even more clearly. */
			[self setFrame: frame];
		}
		else
		{
				/* Verify new decorator has been correctly inserted */
		/* Tested by -checkDecoration...
		NSAssert3([[self displayView] isEqual: [decorator displayView]], @"New "
			@"display view %@ of item %@ must be the display view of the new "
			@"decorator %@", [self displayView], self, [decorator displayView]);*/
		
		// If window is bound directly to a layout item with a window item, this 
		// assertion fails because existingDecorator is nil and 
		// [existingDecorator handleDecorateItem: nil inView: nil]; won't 
		// dismantle the window
		/*NSAssert3([[[self supervisorView] superview] isEqual: parentView] == NO,
			@"New parent view %@ of item %@ must not be its old parent view %@", 
			[[self supervisorView] superview], self, parentView);*/
		}
		
		RELEASE(existingDecorator);
		RELEASE(decorator);
		
		[self checkDecoration];
	}
}

- (ETLayoutItem *) decoratedItem
{
	return _decoratedItem;
}

- (void) setDecoratedItem: (ETLayoutItem *)item
{
	/* Weak reference because decorator retains us */
	_decoratedItem = item;
	[self removeFromParent]; /* Just to be sure the decorator has no parent */
}

- (ETLayoutItem *) lastDecoratorItem
{
	id decorator = [self decoratorItem];
	
	if (decorator != nil)
	{
		return [decorator lastDecoratorItem];
	}
	else
	{
		return self;
	}
}

- (ETLayoutItem *) firstDecoratedItem
{
	id decorator = [self decoratedItem];
	
	if (decorator != nil)
	{
		return [decorator firstDecoratedItem];
	}
	else
	{
		return self;
	}
}

/** <override /> */
- (BOOL) canDecorateItem: (ETLayoutItem *)item
{
	return [item acceptsDecoratorItem: self];
}

/** <override />
	ETLayoutItem instances accept all decorator kinds.
	You can override this method to decide otherwise in your subclasses. For 
	example, ETWindowItem returns NO because a window unlike a view cannot 
	be decorated. */
- (BOOL) acceptsDecoratorItem: (ETLayoutItem *)item
{
	return YES;
}

/** <override-dummy /> 
    You can manipulate the receiver decorator chain in this method and access 
	both view and supervisor view of the decorated item, but you must not 
	manipulate item related decorator chain (by calling -[item displayView], 
	-[item decoratorItem] etc.) 
	Take in account that parentView and item can be nil. */
- (void) handleDecorateItem: (ETLayoutItem *)item inView: (ETView *)parentView 
//	oldDecorator: (ETLayoutItem *)existingDecorator
{
	/* Inserts decorated view */
	[self setDecoratedView: [item supervisorView]];
	
	/* If the decorated item display view was part of view tree, inserts the 
	   new display view into the existing parent view.
	   We don't insert the decorator supervisor view because this decorator 
	   could be a decorator chain (by being decorated itself too). The new 
	   display view is thus the supervisor view of the last decorator item. */
	if (parentView != nil)
	{
		/* No need to update the layout since the new display view will have 
		   the size and location of the previous one. Unlike when you add or
		   or remove an item which involves to recompute the layout. */
		//[self handleAttachViewOfItem: item];
		//ETDebugLog(@"parent %@ parent view %@ item display view %@", [item parentLayoutItem],
		//	parentView, [item displayView]);
		[parentView addSubview: [self displayView]]; // More sure than [item displayView]
	}
	/*else
	{
		[[self displayView] removeFromSuperview];
	}*/

// -setDecoratorItem: isn't -insertDecoratorItem: so disabled the code below
#if 0	
	/* Inserts decorator view (as decorated view into the old item decorator) */
	if (existingDecorator != nil) // [[item displayView] isEqual: [item supervisorView]]
	{
		[self setDecoratorItem: existingDecorator];
	}
#endif
}

- (id) supervisorView
{
	return _view;
}

- (void) setSupervisorView: (ETView *)supervisorView
{
	id parent = [self parentLayoutItem];

	//if ([self decoratorItem] == nil)
		[supervisorView setLayoutItemWithoutInsertingView: self];
	ASSIGN(_view, supervisorView);
	
	if ([self decoratorItem] != nil)
	{
		id parentView = [[self displayView] superview];
		/* Usually results in [[self decoratorItem] setView: supervisorView] */
		[[self decoratorItem] handleDecorateItem: self inView: parentView];
	}
	else if (parent != nil)
	{
		[parent handleAttachViewOfItem: self];
	}
}

- (ETLayoutItem *) firstScrollViewDecoratorItem
{
	id decorator = self;
	
	while ((decorator = [decorator decoratorItem]) != nil)
	{
		if ([[decorator supervisorView] isKindOfClass: [ETScrollView class]])
			break;
	}
	
	return decorator;
}

- (ETWindowItem *) windowDecoratorItem
{
	id lastDecorator = [self lastDecoratorItem];
	id windowDecorator = nil;
	
	if ([lastDecorator isKindOfClass: [ETWindowItem class]])
		windowDecorator = lastDecorator;
		
	return windowDecorator;
}

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
	TODO: Implement. */
- (ETLayoutItem *) firstDecoratorItemWithSupervisorView
{
	return nil;
}

/** Returns the rect where the drawing of the layout item must occur, typically 
    used by the styles. */
- (NSRect) drawingFrame
{
	ETView *drawingView = [self supervisorView];
	NSRect drawingFrame = [self frame];
	drawingFrame.origin = NSZeroPoint;

	// FIXME: This code doesn't work as desired...
#if 0
	if (drawingView != nil) /* Has supervisor view */
	{
		/* Exclude the title bar area */
		drawingFrame = [[drawingView wrappedView] frame];
	}
	else /* Has supervisor view in the decorator chain (a supervisor view may exist before the display view if several decorators are set) */
	{
		drawingView = [[self firstDecoratorItemWithSupervisorView] supervisorView];
		if (drawingView != nil)
			drawingFrame = [[drawingView wrappedView] frame];
	}
#endif

	return drawingFrame;
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
	//ETLog(@"Render frame %@ of %@ dirtyRect %@ in %@", NSStringFromRect([self drawingFrame]), 
	//	self, NSStringFromRect(dirtyRect), view);

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

/** See also -display. */
- (void) setNeedsDisplay: (BOOL)flag
{
	NSRect displayRect = [self frame];
	
	/* If the layout item has a display view, this view will be asked to draw
	   by itself, so the rect to refresh must be expressed in display view
	   coordinates system and not the one of its superview. */
	if ([self displayView] != nil)
		displayRect.origin = NSZeroPoint;
		
	[[self closestAncestorDisplayView] setNeedsDisplayInRect: displayRect];
}

/** Triggers the redisplay of the receiver and the entire layout item tree 
owned by it. */
- (void) display
{
	// FIXME: Minimize the display work
	//[[self closestAncestorDisplayView] setNeedsDisplayInRect: displayRect];
	[[self closestAncestorDisplayView] display];
}

/** Returns the style object associated with the receiver. By default, returns 
ETBasicItemStyle. */    
- (ETStyle *) style
{
	return _style;
}

/** Sets the style object associated with the receiver.

The style object controls the drawing of the receiver. See ETStyle to 
understand how to customize the layout item look. */
- (void) setStyle: (ETStyle *)aStyle
{
	ASSIGN(_style, aStyle);
}

/* Geometry */

/** Returns a rect expressed in parent layout item coordinate space equivalent 
	to rect parameter expressed in the receiver coordinate space. */
- (NSRect) convertRectToParent: (NSRect)rect
{
	NSRect rectInParent = rect;

	// NOTE: See -convertRectFromParent:...
	// NSAffineTransform *transform = [NSAffineTransform transform];
	// [transform translateXBy: [self x] yBy: [self y]];
	// rectInParent.origin = [transform transformPoint: rect.origin];
	rectInParent.origin.x = rect.origin.x + [self x];
	rectInParent.origin.y = rect.origin.y + [self y];
	
	ETLayoutItem *parent = [self parentItem];
	if ([self isFlipped] != [parent isFlipped])
	{
		rectInParent.origin.y = [parent height] - rectInParent.origin.y - rectInParent.size.height;
	}
	
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

	if ([self isFlipped] != [[self parentItem] isFlipped])
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
		if (_flipped != [supervisorView isFlipped])
		{
			ETLog(@"WARNING: -isFlipped doesn't match between the layout item "
				"%@ and its supervisor view %@... You may have wrongly called "
				"-setFlipped: on the supervisor view.", supervisorView, self);
		}
		return [supervisorView isFlipped];
	}

	return _flipped;
}

/** Sets whether the receiver uses flipped coordinates to position its content. 

This method updates the supervisor view to match the flipping of the receiver.
The anchor point location is also adjusted if needed.

You must never alter the supervisor view directly with -[ETView setFlipped:]. */
- (void) setFlipped: (BOOL)flip
{
	if (flip == _flipped)
		return;

	_flipped = flip;
	[[self supervisorView] setFlipped: flip];
	if (HAS_PROPERTY(kETAnchorPointProperty))
	{
		NSPoint anchorPoint = [self anchorPoint];
		anchorPoint.y -= [self bounds].size.height;
		[self setAnchorPoint: anchorPoint];
	}
}

/** Returns a point expressed in the receiver coordinate space equivalent to
	point parameter expressed in the parent layout item coordinate space. */
- (NSPoint) convertPointFromParent: (NSPoint)point
{
	return [self convertRectFromParent: ETMakeRect(point, NSZeroSize)].origin;
}

/** Returns whether a point expressed in the parent item coordinate space is 
    is within the receiver frame. The item frame is also expressed in the parent 
	item coordinate space.
 
	This method checks whether the parent item is flipped or not. */
- (BOOL) containsPoint: (NSPoint)point
{
	return NSMouseInRect(point, [self frame], [[self parentItem] isFlipped]);
}

/** Returns whether a point expressed in the receiver coordinate space is inside 
    the receiver bounds.
 
	For now, the bounds size is always equal to the item frame and the origin 
	to zero.
 
	TODO: Ensure the next paragraph really holds...
	If you convert a point expressed in the parent coordinate space to the 
	receiver coordinate space with -convertPointFromParent:, if the receiver 
	is flipped, the point will be adjusted as needed. Hence you can safely pass 
	a point once converted without worrying whether the parent or the receiver 
	are flipped. */
- (BOOL) pointInside: (NSPoint)point
{
	return NSPointInRect(point, [self bounds]);
}

- (NSRect) bounds
{
	NSRect bounds = [self frame];
	bounds.origin = NSZeroPoint;
	return bounds;
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

/** Returns the current frame. If the receiver has a view attached to it, the 
returned frame is equivalent to the display view frame.  

This value is always in sync with the persistent frame in a positional and 
non-computed layout such as ETFreeLayout, but is usually different when the 
layout is computed. 
See also -setPersistentFrame: */
- (NSRect) frame
{
	if ([self displayView] != nil)
	{
		return [[self displayView] frame];
	}
	else
	{
		return _frame;
	}
}

/** Sets the current frame and also the persistent frame if the layout of the 
parent item is positional and non-computed such as ETFreeLayout.

See also -[ETLayout isPositional] and -[ETLayout isComputedLayout]. */
- (void) setFrame: (NSRect)rect
{
	ETDebugLog(@"-setFrame: %@ on %@", NSStringFromRect(rect), self);  

	if ([self displayView] != nil)
	{
		[[self displayView] setFrame: rect];
	}
	else
	{
		_frame = rect;
	}

	ETLayout *parentLayout = [[self parentItem] layout];
	if ([parentLayout isPositional] && [parentLayout isComputedLayout] == NO)
		[self setPersistentFrame: rect];
}

/** Returns the current origin associated with the receiver frame. See also -frame. */
- (NSPoint) origin
{
	return [self frame].origin;
}

/** Sets the current origin associated with the receiver frame. See also -setFrame:. */   
- (void) setOrigin: (NSPoint)origin
{
	NSRect newFrame = [self frame];
	
	newFrame.origin = origin;
	[self setFrame: newFrame];
}

/** Returns the current anchor point associated with the receiver bounds. The 
anchor point is expressed in the receiver coordinate space.

By default, the anchor point is centered in the bounds rectangle.

The item position is relative to the anchor point. */
- (NSPoint) anchorPoint
{
	if (HAS_PROPERTY(kETAnchorPointProperty) == NO)
		return [self centeredAnchorPoint];

	return [GET_PROPERTY(kETAnchorPointProperty) pointValue];
}

/* Returns the center of the bounds rectangle in the receiver coordinate space. */
- (NSPoint) centeredAnchorPoint
{
	NSSize boundsSize = [self bounds].size;	
	NSPoint anchorPoint = NSZeroPoint;
	
	anchorPoint.x = boundsSize.width / 2.0;
	anchorPoint.y = boundsSize.height / 2.0;
	
	return anchorPoint;
}

/** Sets the current anchor point associated with the receiver bounds. anchor 
must be expressed in the receiver coordinate space. */  
- (void) setAnchorPoint: (NSPoint)anchor
{
	SET_PROPERTY([NSValue valueWithPoint: anchor], kETAnchorPointProperty);
}

/** Returns the current position associated with the receiver frame. The 
position is expressed in the parent item coordinate space. See also 
-setPosition:. */
- (NSPoint) position
{
	NSPoint anchorPoint = [self anchorPoint];
	NSPoint position = [self frame].origin;

	position.x += anchorPoint.x;
	position.y += anchorPoint.y;

	return position;
}

/** Sets the current position associated with the receiver frame.

When -setPosition: is called, the position is applied relative to -anchorPoint. 
position must be expressed in the parent item coordinate space (exactly as the 
frame). When the position is set, the frame is moved to have the anchor point 
location in the parent item coordinate space equal to the new position value. */  
- (void) setPosition: (NSPoint)position
{
	NSPoint anchorPoint = [self anchorPoint];
	NSPoint origin = position;

	origin.x -= anchorPoint.x;
	origin.y -= anchorPoint.y;
	
	[self setOrigin: origin];
}

/** Returns the current size associated with the receiver frame. See also -frame. */       
- (NSSize) size
{
	return [self frame].size;
}

/** Sets the current size associated with the receiver frame. See also -setFrame:. */           
- (void) setSize: (NSSize)size
{
	NSRect newFrame = [self frame];
	
	newFrame.size = size;
	[self setFrame: newFrame];
}

/** Returns the current x coordinate associated with the receiver frame origin. 
See also -frame. */       
- (float) x
{
	return [self frame].origin.x;
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
	return [self frame].origin.y;
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
	Resizing content in a view is possible by simply updating bounds size to 
	match the view frame. 
	Presently uses in ETPaneSwitcherLayout. */
- (void) setAppliesResizingToBounds: (BOOL)flag
{
	_resizeBounds = flag;
	
	if ([self displayView] == nil)
	{
		NSLog(@"WARNING: -setAppliesResizingToBounds: called with no view for %@", self);
		return;
	}
	
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

/** Sets the image representation associated with the receiver.

If img is nil, then the default behavior of -image is restored and the returned 
image should not be expected to be nil. */
- (void) setImage: (NSImage *)img
{
	SET_PROPERTY(img, kETImageProperty);

	// TODO: Think about whether this is really the best to do...
	if (img != nil)
	{
		[self setSize: [img size]];
	}
	else if ([self displayView] == nil)
	{
		[self setSize: NSZeroSize];
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

/** Shows the inspector associated with the receiver. See also -inspector. */
- (void) showInspectorPanel
{
	[[[self inspector] panel] makeKeyAndOrderFront: self];
}

/** Returns the inspector associated with the receiver. */
- (id <ETInspector>) inspector
{
	ETContainer *container = [self closestAncestorContainer];
	id <ETInspector> inspector = nil;
	
	if (container != nil)
		inspector = [container inspector];
		
	if (inspector != nil)
		[inspector setInspectedItems: [NSArray arrayWithObject: self]];
		
	return inspector;
}

/* Live Development */

- (void) beginEditingUI
{
	id view = [self view];
	
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

/** Returns the event handler associated with the receiver. The returned object
 must implement ETEventHandler protocol.
 By default the receiver returns itself. See ETLayoutItem+Events to know 
 more about event handling in the layout item tree. */
- (id <ETEventHandler>) eventHandler
{
	return self;
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
