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
	IBOutlet ETContainer *pathContainer;
	IBOutlet ETContainer *viewContainer;
	ETLayoutItemGroup *mainViewItem;
	ETLayoutItemGroup *pathViewItem;
	ETController *controller;
	NSString *path;
}

- (IBAction) changeLayout: (id)sender;
- (IBAction) switchUsesScrollView: (id)sender;
- (IBAction) scale: (id)sender;
- (IBAction) search: (id)sender;

@end
