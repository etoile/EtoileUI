//
//  test_ETObject.m
//  Container
//
//  Created by Quentin Mathé on 09/08/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "test_ETObject.h"


@implementation MyObject

- (id) init
{
#ifdef REPLACE_SELF_BY_SELF_MSG
	[self setSelf: [super init]];
#else
	self = [super init];
#endif
	
	value = @"MyValue";
	
	return self;
}

- (id) logSomething
{
	NSString *log = @"MyObject logs something";
	
	NSLog(@"%@", log);
	NSLog(@"%@ value is %@", self, value);
	
	return log;
}

@end


@implementation MyObjectDelegate1

- (id) init
{
#ifdef REPLACE_SELF_BY_SELF_MSG
	[self setSelf: [super init]];
#else
	self = [super init];
#endif
	
	value = @"DelegateValue1";
	
	return self;
}

- (id) logSomething
{
	NSString *log = @"MyObjectDelegate logs something";
	
	NSLog(@"%@", log);
	NSLog(@"%@ value is %@", self, value);
	
	return log;
}

- (id) delegateFunnyStuff
{
	return [self logSomething];
}

@end

@implementation MyObjectDelegateParent2

- (id) logDate
{
	NSDate *date = [NSDate distantFuture];
	
	NSLog(@"Log distant future date in %@", self);
	
	return date;
}

- (id) logURL
{
	NSURL *url = [NSURL URLWithString: @"http://www.etoile-project.org"];
	
	NSLog(@"Log url %@ in %@", url, self);
	
	return url;
}

@end

@implementation MyObjectDelegate2

- (id) logSomething
{
	NSLog(@"WARNING: Log nothing for something in %@", self);
	
	return nil;
}

- (id) logDate
{
	NSLog(@"-logDate passed to parent class of %@", self);
	return [super logDate];
}

@end

@implementation MyObjectDelegate3

- (id) logSomething
{
	NSLog(@"WARNING: Log nothing for something in %@", self);
	
	return nil;
}

- (id) logNumber
{
	int number = 5;
	
	NSLog(@"Log number in %@", self);
	
	return [NSNumber numberWithInt: number];
}

- (id) logNotJustURL
{
	NSURL *url = [NSURL URLWithString: @"wheverer" relativeToURL: [super logURL]];
	NSDate *date = [self logDate];
	
	[self logSomething];
	
	return [NSString stringWithFormat: @"%@ %@", url, date];
}

@end

@implementation DummyNSObject 

- (void) trySomethingWithSelf
{
#ifndef REPLACE_SELF_BY_CONTEXT_IVAR
	NSLog(@"%@", self);
#endif
}

@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	id object = [[MyObject alloc] init];
	id objectd1 = [[MyObjectDelegate1 alloc] init];
	id objectd2 = [[MyObjectDelegate2 alloc] init];
	id objectd3 = [[MyObjectDelegate3 alloc] init];
	id nsobject = [[DummyNSObject alloc] init];
	
	[object setPrototype: objectd1];
	[objectd1 setPrototype: objectd2];
	[objectd2 setPrototype: objectd3];
	
	[object delegateFunnyStuff];
	[object logDate];
	[object logURL];
	[object logNumber];
	[object logNotJustURL];
	
	[nsobject trySomethingWithSelf];

	[pool release];
    return 0;
}

