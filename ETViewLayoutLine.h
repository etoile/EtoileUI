//
//  ETViewLayoutLine.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface ETViewLayoutLine : NSObject
{
	NSMutableArray *_views;
	NSPoint _baseLineLocation;
	BOOL _vertical;
}

+ (id) layoutLineWithViews: (NSArray *)views;

- (NSPoint) baseLineLocation;
- (float) height;

- (BOOL) isVerticallyOriented;
- (void) setVerticallyOriented: (BOOL)vertical;
//- (float) orientation;

// Personal use
- (void) setBaseLineLocation: (NSPoint)location;
- (NSArray *) views;

@end