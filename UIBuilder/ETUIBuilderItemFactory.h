/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItemFactory.h>

@class ETModelDescriptionRenderer;

/** @group UI Builder
 
@abstract ETLayoutItemFactory UI building additions to support live development. */
@interface ETUIBuilderItemFactory : ETLayoutItemFactory
{
	@private
	ETModelDescriptionRenderer *renderer;
}

- (ETLayoutItemGroup *) inspectorWithObject: (id)anObject
                                 controller: (id)aController;

- (ETLayoutItemGroup *) basicInspectorWithObject: (id)anObject
                                            size: (NSSize)aSize
                                      controller: (id)aController;

@end


@interface NSObject (UIBuilder)
- (IBAction) inspectUI: (id)sender;
@end
