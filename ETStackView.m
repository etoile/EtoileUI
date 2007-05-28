//
//  ETStackView.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETStackView.h"
#import "ETStackLayout.h"
#import "GNUstep.h"


@implementation ETStackView

- (id) initWithFrame: (NSRect)frame 
{
    self = [super initWithFrame: frame];
	
    if (self != nil) 
	{
		[self setLayout: (ETViewLayout *)AUTORELEASE([[ETStackLayout alloc] init])];
    }
	
    return self;
}

@end
