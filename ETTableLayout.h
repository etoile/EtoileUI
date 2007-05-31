//
//  ETTableLayout.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETViewLayout.h"

@class ETViewLayoutLine, ETContainer;


@interface ETTableLayout : ETViewLayout
{
	NSMutableDictionary *_layoutItemCacheByContainer;
	NSMutableDictionary *_layoutItemCacheByTableView;
	NSMutableDictionary *_scrollingTableViewsByContainer;
}

- (NSScrollView *) scrollingTableViewForContainer: (ETContainer *)container;
- (NSScrollView *) prebuiltTableView;

@end

// Finally I do it in an other way
// TODO: Write a new two way dictionary data structure (would be safer and reusable)
//NSMutableDictionary *_tableViewsByContainer;
//NSMutableDictionary *_containersByTableView;