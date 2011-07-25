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

- (NSInvocation *) initInvocationForCopyWithZone: (NSZone *)aZone;

/** @taskunit Properties */

- (NSMapTable *) variableStorage;

/** @taskunit Persistency */

- (void) commit;
#ifndef OBJECTMERGING
- (void) willChangeValueForProperty: (NSString *)aKey;
- (void) didChangeValueForProperty: (NSString *)aKey;
#endif

@end
