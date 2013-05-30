/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItemFactory.h>
#import <EtoileUI/ETApplication.h>

@class ETModelDescriptionRenderer;

/** @group UI Builder
 
@abstract ETLayoutItemFactory UI building additions to support live development. */
@interface ETUIBuilderItemFactory : ETLayoutItemFactory
{
	@private
	ETModelDescriptionRenderer *_renderer;
	COEditingContext *_editingContext;
}

@property (nonatomic, readonly) COEditingContext *editingContext;

- (ETLayoutItemGroup *) editorWithObject: (id)anObject
                              controller: (id)aController;

- (ETLayoutItemGroup *) inspectorWithObject: (id)anObject
                                 controller: (id)aController;

- (ETLayoutItemGroup *) basicInspectorWithObject: (id)anObject
                                            size: (NSSize)aSize
                                      controller: (id)aController;
- (ETLayoutItemGroup *) basicInspectorContentWithObject: (id)anObject
                                             controller: (id)aController
                                             aspectName: (NSString *)anAspectName;

- (ETLayoutItemGroup *) objectPicker;

@end


@interface NSObject (ETUIBuilder)
- (IBAction) inspectUI: (id)sender;
@end

@interface ETApplication (ETUIBuilder)
- (IBAction) startEditingKeyWindowUI: (id)sender;
- (IBAction) stopEditingKeyWindowUI: (id)sender;
@end
