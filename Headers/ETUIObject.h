/**
	<abstract>EtoileUI basic object class</abstract>

	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.math@gmail.com>
	Date:  July 2011
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETCompatibility.h>
#ifdef COREOBJECT
#import <CoreObject/COObject.h>
#endif

@class ETCopier;

@interface ETUIObject : BASEOBJECT <NSCopying>
{
	@protected
#ifndef COREOBJECT
	NSMapTable *_variableStorage;
#endif
}

/** @taskunit Aspect Sharing */

- (BOOL) isShared;

/** @taskunit Copying */

- (id) copyWithCopier: (ETCopier *)aCopier;
- (id) copyWithZone: (NSZone *)aZone;
- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone;

/** @taskunit Properties */

- (NSMutableDictionary *) variableStorage;
#ifndef COREOBJECT
- (id) primitiveValueForKey: (NSString *)key;
- (void) setPrimitiveValue: (id)value forKey: (NSString *)key;
#endif

/** @taskunit Persistency */

- (NSArray *) commit;
- (NSArray *)commitWithType: (NSString *)type
           shortDescription: (NSString *)shortDescription;
#ifndef COREOBJECT
- (id) commitTrack;
- (BOOL) isRoot;
- (BOOL) isPersistent;
- (void) willChangeValueForProperty: (NSString *)aKey;
- (void) didChangeValueForProperty: (NSString *)aKey;
#endif

@end


@protocol ETCopierNode
- (BOOL) isCopyNode;
@end

/** A copier is a single use object. Each time, you start an object graph copy 
with -copyWithCopier, you must pass a new copier. */
@interface ETCopier : NSObject
{
	id destinationRootObject;
	id sourceRootObject;
	NSMutableArray *currentNewNodeStack;
	NSMutableArray *currentNodeStack;
	NSMutableArray *currentObjectStack; /* The objects being copied in the source object graph */
	NSMutableSet *currentAliasedCopies;
	id lastCopiedObject;
	NSMapTable *objectRefsForCopy;
}

/** @taskunit Initialization */

+ (id) copier;
+ (id) copierWithNewRoot;
+ (id) copierWithDestinationRootObject: (id)aRootObject;
- (id) initWithDestinationRootObject: (id)aRootObject;

/** @taskunit Copy Allocation */

- (id) allocCopyForObject: (id)anObject;
- (id) lookUpAliasedCopyForObject: (id)anObject;
- (BOOL) isAliasedCopy;

/** @taskunit Copy Control */

- (void) beginCopyFromObject: (id)anObject toObject: (id)newObject;
- (void) endCopy;

/** @taskunit Current Copy Area */

- (id) currentNode;
- (id) currentNewNode;

/** @taskunit Root Object Graphs */

- (id) destinationRootObject;
- (id) sourceRootObject;
- (BOOL) isNewRoot;

/** @taskunit Reference Mapping Between Object Graphs */

- (NSMapTable *) objectReferencesForCopy;
- (id) objectReferenceInCopyForObject: (id)anObject;

/** @taskunit Zone */

- (NSZone *) zone;

/** @taskunit Framework Private */

- (void) setSourceRootObject: (id)aRootObject;

@end
