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
#ifdef OBJECTMERGING
#import <ObjectMerging/COObject.h>
#endif

@class ETCopier;

@interface ETUIObject : BASEOBJECT <NSCopying>
{
	@protected
#ifndef OBJECTMERGING
	NSMapTable *_variableStorage;
#endif
}

/** @taskunit Aspect Sharing */

- (BOOL) isShared;

/** @taskunit Copying */

- (id) copyWithZone: (NSZone *)aZone 
             copier: (ETCopier *)aCopier 
      isAliasedCopy: (BOOL *)isAliasedCopy;
- (id) copyWithZone: (NSZone *)aZone;
- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone;

/** @taskunit Properties */

- (NSMapTable *) variableStorage;

/** @taskunit Persistency */

- (void) commit;
#ifndef OBJECTMERGING
- (BOOL) isRoot;
- (void) willChangeValueForProperty: (NSString *)aKey;
- (void) didChangeValueForProperty: (NSString *)aKey;
#endif

@end


@protocol ETCopierNode
- (BOOL) isCopyNode;
@end

@interface ETCopier : NSObject
{
	id destinationRootObject;
	id sourceRootObject;
	NSMutableArray *currentNewNodeStack;
	NSMutableArray *currentNodeStack;
	NSMutableArray *currentObjectStack; /* The objects being copied in the source object graph */
	NSUInteger copySteps;
	NSMapTable *objectRefsForCopy;
}

/** @taskunit Initialization */

+ (id) copier;
+ (id) copierWithNewRoot;
+ (id) copierWithDestinationRootObject: (id)aRootObject;
- (id) initWithDestinationRootObject: (id)aRootObject;

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

/** @taskunit Framework Private */

- (void) setSourceRootObject: (id)aRootObject;

@end
