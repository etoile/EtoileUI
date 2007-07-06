//
//  PaneController.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 28/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETContainer.h"


@interface PaneController : NSObject
{
    IBOutlet id viewContainer;
	IBOutlet NSView *paneView1;
	IBOutlet NSView *paneView2;
	IBOutlet NSView *paneView3;
	NSMutableArray *paneItems;
}

- (IBAction) changeContentLayout: (id)sender;
- (IBAction) changeSwitcherLayout: (id)sender;
- (IBAction) changeSwitcherPosition: (id)sender;
- (IBAction) switchUsesSource: (id)sender;
- (IBAction) scale: (id)sender;

@end
