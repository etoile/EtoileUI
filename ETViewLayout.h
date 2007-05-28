//
//  ETViewLayout.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETContainer, ETViewLayoutLine;


@interface ETViewLayout : NSObject
{
    /*NSView *_container;
    NSMutableArray *_views;*/
}

/*- (id) initWithContainer: (ETContainer *)viewContainer;

- (ETContainer *) container;
- (void) setContainer: (ETContainer *)viewContainer;
- (NSArray *) views;
- (void) setViews: (NSArray *)views;

- (void) layout;*/

- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container;

- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer;
- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer;
- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container;

@end
