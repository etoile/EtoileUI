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
	[self refreshIfNeeded];
}

/* Returns the observable properties which shouldn't be observed.

Non observable properties are -hasValidRepresentedPathBase, -usesWidgetView, 
-closestAncestorDisplayView, -closestAncestorItemWithDisplayView, 
-supervisorView, -ancestorItemForOpaqueLayout, ,-properties, -variableProperties, 
-drawingFrame, -windowDecoratorItem, -firstScrollViewDecoratorItem, -origin,  
-contentSize, and -inspector.

TODO: Move into ETLayoutItem entity description. */
+ (NSSet *) nonObservableProperties
{
	return S(@"hasValidRepresentedPathBase", @"usesWidgetView",	
		@"closestAncestorDisplayView", "closestAncestorItemWithDisplayView", 
		@"supervisorView", @"ancestorItemForOpaqueLayout", @"properties", 
		@"variableProperties", @"drawingFrame", @"windowDecoratorItem", 
		@"firstScrollViewDecoratorItem", @"origin",  @"contentSize", 
		@"inspector");
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
		kETStyleGroupProperty, kETStyleProperty, kETFlippedProperty, 
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
