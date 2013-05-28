/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection.h>
#import <EtoileFoundation/ETUUID.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <EtoileFoundation/Macros.h>
#import "ETUIStateRestoration.h"
#import "ETCompatibility.h"


@implementation ETUIStateRestoration

@synthesize delegate = _delegate;

- (id) init
{
	SUPERINIT;
	_UICreationInvocations = [NSMutableDictionary new];
	return self;
}

- (void) dealloc
{
	DESTROY(_UICreationInvocations);
	[super dealloc];
}

- (NSString *) keyForUserDefaults
{
	return @"UIStateRestoration";
}

- (NSInvocation *) UICreationInvocationForName: (NSString *)aName
{
	return [_UICreationInvocations objectForKey: aName];
}

- (void) setUICreationInvocation: (NSInvocation *)anInv forName: (NSString *)aName
{
	[_UICreationInvocations setObject: anInv forKey: aName];
}

- (NSDictionary *) settings
{
	NSDictionary *settings = [[NSUserDefaults standardUserDefaults] objectForKey: [self keyForUserDefaults]];
	if (settings == nil)
	{
		settings = [NSDictionary dictionary];
	}
	return settings;
}

- (void) setSettings: (NSDictionary *)settings
{
	[[NSUserDefaults standardUserDefaults] setObject: settings forKey: [self keyForUserDefaults]];
}

- (ETUUID *) persistentItemUUIDForName: (NSString *)aName
{
	NSString *UUIDString = [[self settings] objectForKey: aName];
	return (UUIDString != nil ? [ETUUID UUIDWithString: UUIDString] : nil);
}

- (void) setPersistentItemUUID: (ETUUID *)aUUID forName: (NSString *)aName
{
	NSMutableDictionary *settings = AUTORELEASE([[self settings] mutableCopy]);
	[settings setObject: [aUUID stringValue] forKey: aName];
	[self setSettings: settings];
}

- (id) loadItemForUUID: (ETUUID *)aUUID
{
	if (aUUID == nil)
		return nil;

	return [[(id)[self delegate] ifResponds] UIStateRestoration: self
	                                            loadItemForUUID: aUUID];
}

- (void) didLoadItem: (id)item
{
	[[(id)[self delegate] ifResponds] UIStateRestoration: self didLoadItem: item];
}

/* The returned item might be persistent but the UI restoration considers it 
transient, because it is not bound to a UUID/Name pair registered in the 
user application defaults. */
- (id) transientItemForName: (NSString *)aName
{
	NSInvocation *creationInv = [self UICreationInvocationForName: aName];
	id item = nil;

	[creationInv invoke];
	[creationInv getReturnValue: &item];

	if (item != nil)
		return item;

	return [[(id)[self delegate] ifResponds] UIStateRestoration: self
	                                         provideItemForName: aName];
}

- (id) provideItemForName: (NSString *)aName
{
	id item = [self loadItemForUUID: [self persistentItemUUIDForName: aName]];

	if (item != nil)
	{
		[self didLoadItem: item];
		return item;
	}

	item = [self transientItemForName: aName];

	if (item == nil)
	{
		[NSException raise: NSInternalInconsistencyException
		            format: @"Found no item to restore for %@ in %@", aName, self];
	}
	return item;
}

@end
