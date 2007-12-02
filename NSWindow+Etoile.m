//
//  NSWindow+Etoile.m
//  Container
//
//  Created by Quentin Mathé on 27/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <EtoileUI/NSWindow+Etoile.h>
#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETCompatibility.h>


@implementation NSWindow (Etoile)

- (IBAction) browse: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init];

	ETLog(@"browse %@", self);
	[browser setBrowsedObject: [self contentView]];
	[[browser panel] makeKeyAndOrderFront: self];
}

@end
