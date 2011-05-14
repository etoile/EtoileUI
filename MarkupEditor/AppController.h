/*
	MarkupEditorController
	
	An extensible markup editor mainly supporting PLIST and XML.
 
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>


@interface AppController : ETDocumentController
{

}

- (IBAction) newWorkspace: (id)sender;

- (void) showEditorLayoutExample;

@end


@interface PListItemTemplate : ETItemTemplate

@end

@interface XMLItemTemplate : ETItemTemplate

@end

