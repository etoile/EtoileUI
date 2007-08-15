//
//  test_ETObject.h
//  Container
//
//  Created by Quentin Mathé on 09/08/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ETObject.h"

@interface MyObject : ETObject
{
	NSString *value;
}

- (id) logSomething;
//- (id) logName;

@end


@interface MyObjectDelegate1 : ETObject
{
	NSString *value;
}

- (id) delegateFunnyStuff;
- (id) logSomething;

@end

@interface MyObjectDelegateParent2 : ETObject
{

}

- (id) logDate;
- (id) logURL;

@end

@interface MyObjectDelegate2 : MyObjectDelegateParent2
{
	NSString *value;
}

- (id) logSomething;
- (id) logDate;

@end

@interface MyObjectDelegate3 : MyObjectDelegate2
{

}

- (id) logSomething;
- (id) logNumber;

@end

@interface DummyNSObject : NSObject
{

}

- (void) trySomethingWithSelf;

@end

