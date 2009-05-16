/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <EtoileFoundation/ETCollection.h>
#import "COUIServer.h"
#import "ETLayoutItem.h"
#import "ETApplication.h"

#define WK [NSWorkspace sharedWorkspace]

@interface COUIServer (Private)
- (id) initWithURL: (NSURL *)storeURL;
- (id) setUpServer;
@end

@interface NSWorkspace (GNUstepPrivate)
- (id) _connectApplication: (NSString *)appName;
@end


@implementation COUIServer

static COUIServer *sharedUIServer = nil;

+ (id) sharedInstance
{
	if (sharedUIServer == nil)
		sharedUIServer = [[self alloc] init];

	return sharedUIServer;
}

/** Returns the base URL of the default object store that must be defined by +localObjectServerClass
	The base URL can be defined in a subclass by overriding 
	+localObjectServerClass. */
+ (NSURL *) defaultStoreURL
{
	// FIMXE: Retrieve the path from a default
	return [NSURL fileURLWithPath: @"~/UIServer"];
}

+ (BOOL) isGroupAtURL: (NSURL *)anURL
{
	return YES;
}

+ (id) objectWithURL: (NSURL *)anURL
{
	return nil;
}

- (id) init
{
	return [self initWithURL: nil];
}

/** <init />
	Instantiates an returns an UI server instance that uses the object store 
	located at the URL passed in parameter.
	Unlike other object servers, storeURL must be a file URL (local to the file 
	system) otherwise an exception is raised. */
- (id) initWithURL: (NSURL *)storeURL
{
	if (storeURL == nil)
		storeURL = [[self class] defaultStoreURL];
	if ([storeURL isFileURL] == NO)
	{
		[NSException raise: NSInvalidArgumentException format: @"UI object "
			@"URL must be a local file URL unlike %@", storeURL];
	}

	// FIXME: When we switch to COGroup as superclass, replace with 
	// [super initWithURL: storeURL];
	self = [super init];

	if (self != nil)
	{
		// FIXME: Replaces the if branch with COObjectServer objectWithURL: and 
		// testing whether nil is returned.
		if ([[CODirectory objectWithURL: storeURL] exists])
		{
			//self = [CODeserializer deserializePath: ]
		}
		else
		{
			ASSIGN(_storeURL, storeURL);
			self = [self setUpServer];
		}
	}

	return self;
}

DEALLOC(DESTROY(_serializerBackend); DESTROY(_storeURL))

- (id) copyWithZone: (NSZone *)aZone
{
	return RETAIN(self);
}

- (BOOL) isCopyPromise
{
	return NO;
}

- (id) setUpServer
{
	return self; // Nothing to do right now
}

/** Returns the URL where the receiver is serialized.
	The returned URL will change if the user moves the receiver object to a 
	different location by the mean of an object manager. */
- (NSURL *) storeURL
{
	return AUTORELEASE([_storeURL copy]);
}

/** Returns the serialisation backend that must be used to push and pull 
	objects from the in-memory object store of the receiver. */
- (Class) serializerBackend
{
	return _serializerBackend;
}

/* Group and Collection protocol */

- (NSArray *) members
{
	NSMutableArray *itemGroups = [NSMutableArray array];

	ETLog(@"Found launched apps: %@", [WK launchedApplications]);

	/* Collect the window group of each application */
	FOREACH([WK launchedApplications], appEntry, NSDictionary *)
	{
		NSString *appName = [appEntry objectForKey: @"NSApplicationName"];
		id app = [WK _connectApplication: appName];

		if ([app respondsToSelector: @selector(layoutItem)])
		{
			ETLog(@"Found layout item %@", [app layoutItem]);
			[itemGroups addObject: [app layoutItem]];
		}
	}

	ETLog(@"Found window groups: %@", itemGroups);

	return RETAIN(itemGroups);
}

/** Not supported because the receiver itself is an immutable collection. */
- (BOOL) addMember: (id)object 
{ 
	return NO;
}

- (BOOL) removeMember: (id)object 
{ 
	return NO;
}

- (BOOL) isGroup
{
	return YES;
}

/** See -addObject:. */
- (BOOL) addGroup: (id <COGroup>)subgroup
{
	return [self addMember: subgroup];
}

/** See -removeObject:. */
- (BOOL) removeGroup: (id <COGroup>)subgroup
{
	return [self addMember: subgroup];
}

// FIXME: Implement
- (NSArray *) groups
{
	return [self members];
}

// FIXME: Implement
- (NSArray *) allObjects
{
	return nil;
}

// FIXME: Implement
- (NSArray *) allGroups
{
	return nil;
}

- (BOOL) isOpaque
{
	return NO;
}

- (NSString *) uniqueID
{
	return nil; // FIXME
}

- (BOOL) matchesPredicate: (NSPredicate *)aPredicate
{
	return NO;
}

- (NSArray *) objectsMatchingPredicate: (NSPredicate *)aPredicate
{
	return [NSArray array];
}

- (NSArray *) properties
{
	return [NSArray array]; // FIXME
}

- (NSDictionary *) metadatas
{
	return nil;
}

- (BOOL) isOrdered
{
	return NO;
}

- (BOOL) isEmpty
{
	return ([[self members] count] == 0);
}

- (id) content
{
	return [self members];
}

- (NSArray *) contentArray
{
	return [self content];
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{
	[self addMember: object];
}

- (void) removeObject: (id)object
{

}

- (void) addObject: (id)object
{

}


/* Utitily methods */

/** <override-subclass />
	Handles any additional objects to be persisted when the receiver is 
	serialised into the local object store and not declared in the instance 
	variables of COObjectServer subclasses. */
- (void) serialise { }

- (void) handleError: (NSError *)error
{
	//NSLog(@"Error: %@ (%@ %@)", error, self, [err methodName]);
	NSLog(@"Error: %@ (%@)", error, self);
	RELEASE(error);
}

@end
