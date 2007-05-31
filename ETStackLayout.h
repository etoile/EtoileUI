//
//  ETStackLayout.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETViewLayout.h"

@class ETViewLayoutLine, ETContainer;


@interface ETStackLayout : ETViewLayout
{

}

- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer;
- (void) computeViewLocationsForLayoutLine: (ETViewLayoutLine *)line inContainer: (ETContainer *)container;

@end
