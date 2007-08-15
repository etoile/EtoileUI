//
//  ETViewLayoutLine.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// NOTE: May be rename it ETViewLayoutBox
@interface ETViewLayoutLine : NSObject
{
	NSMutableArray *_items;
	NSPoint _baseLineLocation;
	NSPoint _topLineLocation;
	BOOL _vertical;
}

+ (id) layoutLineWithViews: (NSArray *)views;
+ (id) layoutLineWithLayoutItems: (NSArray *)items;

- (NSArray *) items;

- (NSPoint) baseLineLocation;
/** In flipped layout, top line location is rather than base line location. */ 
- (float) height;
- (float) width;

- (BOOL) isVerticallyOriented;
- (void) setVerticallyOriented: (BOOL)vertical;
//- (float) orientation;

// Personal use
- (void) setBaseLineLocation: (NSPoint)location;
/** Any changes to top line location is reflected on base line location */
- (NSArray *) views;

@end