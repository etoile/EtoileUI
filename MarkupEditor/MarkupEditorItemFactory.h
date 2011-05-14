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


@interface MarkupEditorItemFactory : ETLayoutItemFactory

- (ETLayoutItemGroup *) editorViewWithSize: (NSSize)aSize controller: (ETController *)aController;
- (ETLayoutItemGroup *) toolbarWithWidth: (float)aWidth controller: (ETController *)aController;
- (ETLayoutItemGroup *) editor;

- (ETLayoutItemGroup *) workspaceWithControllerPrototype: (ETController *)aController;

/** @taskunit Composite Layouts */

- (ETCompositeLayout *) editorLayout;

@end

@interface MarkupEditorLayout : ETCompositeLayout
@end
