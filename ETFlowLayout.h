//
//  ETFlowLayout.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETViewLayout.h"

@class ETViewLayoutLine, ETContainer;


@interface ETFlowLayout : ETViewLayout 
{
	BOOL _grid;
}

- (BOOL) usesGrid;
- (void) setUsesGrid: (BOOL)constraint;

@end
