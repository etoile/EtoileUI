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
	ETContainer *_container;
	NSSize _layoutSize;
	BOOL _layoutSizeCustomized;
	BOOL _maxSizeLayout;
}

- (void) setContainer: (ETContainer *)newContainer;
- (ETContainer *) container;

- (BOOL) isAllContentVisible;

- (void) adjustLayoutSizeToContentSize;

- (void) setUsesCustomLayoutSize: (BOOL)flag;
- (BOOL) usesCustomLayoutSize;
- (void) setLayoutSize: (NSSize)size;
- (NSSize) layoutSize;
- (void) setContentSizeLayout: (BOOL)flag;
- (BOOL) isContentSizeLayout;

- (void) render;
- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container;
- (void) renderWithSource: (id)source inContainer: (ETContainer *)container;

- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer;
- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer;
- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container;

// Private use
- (void) adjustLayoutSizeToSizeOfContainer: (ETContainer *)container;

@end
