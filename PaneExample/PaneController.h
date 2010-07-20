//
//  PaneController.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 28/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/EtoileUI.h>

/* This example are pane support are still work-in-progress. */
@interface PaneController : NSObject
{
    IBOutlet ETLayoutItemGroup *paneItemGroup;
	IBOutlet NSView *paneView1;
	IBOutlet NSView *paneView2;
	IBOutlet ETView *paneView3;
}

- (IBAction) changeContentLayout: (id)sender;
- (IBAction) changeSwitcherLayout: (id)sender;
- (IBAction) changeSwitcherPosition: (id)sender;
- (IBAction) scale: (id)sender;

@end
