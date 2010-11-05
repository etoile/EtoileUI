//
//  ObjectManagerController.h
//  Container
//
//  Created by Quentin Mathé on 31/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>

@class ETController;

@interface ObjectManagerController : NSObject 
{
	IBOutlet ETLayoutItemGroup *mainViewItem;
	IBOutlet ETLayoutItemGroup *pathViewItem;
	ETController *controller;
}

- (IBAction) changeLayout: (id)sender;
- (IBAction) switchUsesScrollView: (id)sender;
- (IBAction) scale: (id)sender;
- (IBAction) search: (id)sender;

@end
