/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/NSKeyValueObserving.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "ETLayoutItem+KVO.h"
#import "EtoileUIProperties.h"
#import "NSView+Etoile.h"


@implementation ETLayoutItem (KVO)

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

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id)object 
	change: (NSDictionary *)change context: (void *)context
{
	NSView *view = [self view];
	BOOL isWidgetViewChange = ([view isWidget] && object == [(id <ETWidget>)view cell]);

	if (isWidgetViewChange)
	{
		NSParameterAssert([keyPath isEqual: @"objectValue"] || [keyPath isEqual: @"state"]);
		[self didChangeViewValue: [change objectForKey: NSKeyValueChangeNewKey]];
	}
	else /* isRepresentedObjectChange */
	{
		NSParameterAssert(object == _modelObject);

		if ([keyPath isEqual: @"value"] || [keyPath isEqual: @"objectValue"])
		{
			[self didChangeRepresentedObjectValue: [change objectForKey: NSKeyValueChangeNewKey]];
		}
		
		/* Allow the item to redisplay any visual element that depends on the value 
		   e.g. a style or a cell in a layout view */
		[self refreshIfNeeded];
	}
}

/* Returns all the observed properties affected by the change or nil when the 
receiver is not observed.
-didChangeValuesForKeys: must be invoked with the result afterwards. */
- (NSSet *) willChangeRepresentedObjectFrom: (id)newObject to: (id)oldObject
{
	// We could speed it up by putting -observationInfo in an ivar and invoking 
	// -will/DidChange only when the ivar is not nil.
	// What should probably do handle that correctly is to override all 
	// -addObserver:XXX methods and keep track of observed/observer/keyPath 
	// triplet in order to broacast only the necessary changes when the rep 
	// object changes.
	// We could also support batch changes with -[NSObject didChange] that 
	// tells the receiver as globally dirty and posts a normal notification 
	// observed by the layout items bound to this rep object. Then they could 
	// broadcast the changes at a normal KVO granularity to their observers 
	// by leveraging the observation triplet they keep track of.
	BOOL isObserved = ([self observationInfo] != nil);

	if (NO == isObserved)
		return nil;

	NSMutableSet *affectedKeys = [NSMutableSet setWithCapacity: 150];

	/* Add keys for values affected by a represented object change
	   TODO: We probably can remove that once our model object (e.g. COObject, 
	   COFile etc.) correctly override -observableKeyPaths. */
	[affectedKeys addObjectsFromArray: A(kETDisplayNameProperty, kETValueProperty, 
		kETIconProperty, kETRepresentedObjectProperty, kETSubjectProperty)];
	[affectedKeys unionSet: [oldObject observableKeyPaths]];
	[affectedKeys unionSet: [newObject observableKeyPaths]];
	if (nil == oldObject || nil == newObject)
	{
		[affectedKeys unionSet: [self observableKeyPaths]];
	}

	FOREACH(affectedKeys, key, NSString *)
	{
		[self willChangeValueForKey: key];
	}

	return affectedKeys;
}

- (void) didChangeValuesForKeys: (NSSet *)affectedKeys
{
	if (nil == affectedKeys)
		return;

	FOREACH(affectedKeys, key, NSString *)
	{
		[self didChangeValueForKey: key];
	}
}

/* Returns the observable properties which shouldn't be observed.

Non observable properties are -hasValidRepresentedPathBase, -usesWidgetView, 
-closestAncestorDisplayView, -supervisorViewBackedAncestorItem, -windowBackedAncestor
-supervisorView, -ancestorItemForOpaqueLayout, ,-properties, -variableProperties, 
-drawingFrame, -windowDecoratorItem, -firstScrollViewDecoratorItem, -origin,  
-contentSize, and -inspector.

TODO: Move into ETLayoutItem entity description. */
+ (NSSet *) nonObservableProperties
{
	return S(@"hasValidRepresentedPathBase", @"usesWidgetView",	
		@"closestAncestorDisplayView", "supervisorViewBackedAncestorItem", 
		@"windowBackedAncestorItem", @"supervisorView", 
		@"ancestorItemForOpaqueLayout", @"properties", @"variableProperties", 
		@"drawingFrame", @"windowDecoratorItem", @"firstScrollViewDecoratorItem", 
		@"origin",  @"contentSize", @"inspector");
}

/** Returns the observable properties. 

This method is only invoked when -addObserver: is used. e.g. ETPropertyViewpoint 
doesn't use it to observe a layout item. 

We also expose some NSObject properties as observable such as -UTI.

You must call the superclass implementation when you override this method.

You must not make weak references observable unless you nullify them explicitly 
when the object they reference is going to be deallocated.<br />
You must not use a setter to nullify a weak reference, because this can result  
in a KVO notification when the setter owner is currently being observed.<br />
e.g. Nullifying the 'parentItem' backward pointer with [item setParentItem: nil] 
results in a KVO notification when the child is observed by some other object. 
The issue is that the old 'parentItem' value can be retained by the KVO change 
dictionary when the 'parentItem' deallocation is underway. Which means, that 
when the change dictionary is released, the 'parentItem' will be sent -release 
too. At this point, the parent item retain count is zero and -dealloc will be 
incorrectly reentered. */
- (NSSet *) observableKeyPaths
{
	return S(kETRootItemProperty, kETBaseItemProperty, kETIsBaseItemProperty, 
		kETParentItemProperty, kETIndexPathProperty, kETPathProperty, 
		kETRepresentedPathProperty, kETRepresentedPathBaseProperty,
		kETIdentifierProperty, kETNameProperty, kETDisplayNameProperty, 
		kETValueProperty, kETViewProperty, kETImageProperty, kETIconProperty, 
		kETRepresentedObjectProperty, kETSubjectProperty,  kETSelectedProperty, 
		kETVisibleProperty, kETUTIProperty, kETSubtypeProperty, kETLayoutProperty, 
		kETStyleGroupProperty, kETStyleProperty, kETCoverStyleProperty, kETFlippedProperty, 
		kETPersistentFrameProperty, kETFrameProperty, kETAnchorPointProperty, 
		kETPositionProperty, kETXProperty, kETYProperty, kETWidthProperty, 
		kETHeightProperty, kETContentBoundsProperty, kETTransformProperty, 
		kETBoundingBoxProperty, kETDefaultFrameProperty, 
		kETAutoresizingMaskProperty, kETActionHandlerProperty, 
		kETAcceptsActionsProperty, kETTargetProperty, kETNextResponderProperty,
		kETActionProperty);
}

/* Only -observableKeyPaths are checked as dependent keys whose value can be 
affected. */
+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *)aKey
{
	// TODO: Take in account that -identifier can vary based on its index in
	// its parent item or its parent represented object.
	// The issue also exists with -indexPath, -representedPath and -path.
	NSSet *geometryDependentKeys = S(kETViewProperty, kETFrameProperty, 
		kETXProperty, kETYProperty, kETWidthProperty, kETHeightProperty);
	NSSet *parentDependentKeys = S(kETRootItemProperty, kETIsBaseItemProperty, 
		kETBaseItemProperty, kETRepresentedPathProperty, kETPathProperty, 
		kETIndexPathProperty);
	NSSet *nameDependentKeys = S(kETIdentifierProperty, kETRepresentedPathProperty, 
		kETPathProperty, kETDisplayNameProperty);
	NSMutableSet *triggerKeys = [NSMutableSet set];
	
	if ([geometryDependentKeys containsObject: aKey])
	{
		[triggerKeys unionSet: S(kETContentBoundsProperty, kETPositionProperty)];
	}
	if ([parentDependentKeys containsObject: aKey])
	{
		[triggerKeys unionSet: S(kETParentItemProperty)];
	}
	if ([nameDependentKeys containsObject: aKey])
	{
		[triggerKeys unionSet: S(kETNameProperty)];
	}
	// NOTE: When ETUIItem will support implement basic KVO support, we might 
	// need [triggerKeys unionSet: [super keyPathsForValuesAffectingValuesForKey: aKey]];

	return triggerKeys;
}

+ (NSSet *) keyPathsForValuesAffectingStyle
{
	return S(kETStyleGroupProperty);
}

+ (NSSet *) keyPathsForValuesAffectingSubject
{
	return S(kETRepresentedObjectProperty);
}

+ (NSSet *) keyPathsForValuesAffectingUTI
{
	return S(kETSubtypeProperty);
}

// NOTE: The represented path varies on the 'identifier' property rather than
// kETNameProperty... We might eventually improve that.
+ (NSSet *) keyPathsForValuesAffectingRepresentedPath
{
	return S(kETParentItemProperty, kETNameProperty);
}

@end
