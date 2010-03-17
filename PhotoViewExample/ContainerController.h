/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>


@interface ContainerController : ETController
{
	IBOutlet ETContainer *viewContainer;
	IBOutlet NSSlider *itemMarginSlider;
	IBOutlet NSSlider *borderMarginSlider;
	ETLayoutItemGroup *photoViewItem;
	NSMutableArray *images;
}

- (IBAction) choosePicturesAndLayout:(id)sender;
- (IBAction) changeLayout: (id)sender;
- (IBAction) switchUsesSource: (id)sender;
- (IBAction) switchUsesScrollView: (id)sender;
- (IBAction) scale: (id)sender;
- (IBAction) changeItemMargin: (id)sender;
- (IBAction) changeBorderMargin: (id)sender;

- (id) configureLayout: (id)layoutObject;

/* Private */

- (void) selectPicturesPanelDidEnd: (NSOpenPanel *)panel 
                        returnCode: (int)returnCode
                       contextInfo: (void  *)contextInfo;
- (void) setUpLayoutItemsDirectly;
- (NSImageView *) imageViewForImage: (NSImage *)image;

@end
