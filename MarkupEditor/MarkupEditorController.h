/*
	MarkupEditorController
	
	An extensible markup editor mainly supporting PLIST and XML.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/EtoileUI.h>


@interface MarkupEditorController : NSObject
{
    IBOutlet ETContainer *viewContainer;
	//NSString *documentPath;
}

- (IBAction) changeLayout: (id)sender;
- (IBAction) openDocument:(id)sender;
- (void) selectDocumentsPanelDidEnd:(NSOpenPanel *)panel 
	returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void) setUpLayoutOfClass: (Class)layoutClass;

- (void) viewContainerDidResize: (NSNotification *)notif;

@end
