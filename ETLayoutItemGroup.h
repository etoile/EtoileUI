//
//  ETLayoutItemGroup.h
//  Container
//
//  Created by Quentin Mathé on 31/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETLayoutItem.h"


@interface ETLayoutItemGroup : ETLayoutItem
{

}

+ (ETLayoutItemGroup *) layoutItemGroup;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItem: (ETLayoutItem *)item;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItems: (NSArray *)items;

// NOTE: Note sure it's really doable to provide such methods. May only work in
// a safe way if we provide it as part of ETContainer API
- (NSArray *) ungroup;
/* Take a note +group: is +layoutItemGroupWithLayoutItems: */

/* Stacking */

- (void) stack;
- (void) unstack;

@end
