/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

@class ETUUID;
@class ETUIStateRestoration;

/** @group Base */
@protocol ETUIStateRestorationDelegate
- (id) UIStateRestoration: (ETUIStateRestoration *)restoration
       provideItemForName: (NSString *)aName;
- (id) UIStateRestoration: (ETUIStateRestoration *)restoration
          loadItemForUUID: (ETUUID *)aUUID;
@optional
- (void) UIStateRestoration: (ETUIStateRestoration *)restoration
                didLoadItem: (id)anItem;
@end

/** @group Base */
@interface ETUIStateRestoration : NSObject
{
	@private
	id <ETUIStateRestorationDelegate> _delegate;
	NSMutableDictionary *_UICreationInvocations;
}

@property (nonatomic, assign) id <ETUIStateRestorationDelegate> delegate;

/** @taskunit Marking UI Items as Persistent */

- (ETUUID *) persistentItemUUIDForName: (NSString *)aName;
- (void) setPersistentItemUUID: (ETUUID *)aUUID forName: (NSString *)aName;

/** @taskunit Accessing UI Items */

- (id) provideItemForName: (NSString *)aName;

/** @taskunit Managing UI Item Creation Invocations */

- (NSInvocation *) UICreationInvocationForName: (NSString *)aName;
- (void) setUICreationInvocation: (NSInvocation *)anInv forName: (NSString *)aName;

@end


