/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreObject/CoreObject.h>


@interface COUIServer : NSObject <COGroup, NSCopying>
{
	NSURL *_storeURL;
	Class _serializerBackend;
}

+ (id) sharedInstance;
+ (NSURL *) defaultStoreURL;

- (NSURL *) storeURL;

- (void) serialise;

- (void) handleError: (NSError *)error;

@end
