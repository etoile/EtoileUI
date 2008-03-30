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


@interface ObjectManagerController : NSObject 
{
    IBOutlet ETContainer *pathContainer;
	IBOutlet ETContainer *viewContainer;
	NSString *path;
}

- (IBAction) changeLayout: (id)sender;
- (IBAction) switchUsesScrollView: (id)sender;
- (IBAction) scale: (id)sender;

- (NSImageView *) imageViewForImage: (NSImage *)image;

@end
