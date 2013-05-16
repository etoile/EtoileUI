/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETController.h>

@class ETUIBuilderItemFactory;

/** @group UI Builder
 
@abstract Main controller for the UI builder inspector and object browser. */
@interface ETUIBuilderController : ETController
{
	ETUIBuilderItemFactory *_itemFactory;
	ETLayoutItemGroup *_browserItem;
	ETLayoutItemGroup *_aspectInspectorItem;
	ETLayoutItem *_viewPopUpItem;
	ETLayoutItem *_aspectPopUpItem;
}

/** @taskunit Inspector Pane Factory */

@property (nonatomic, retain) ETUIBuilderItemFactory *itemFactory;

/** @taskunit Accessing UI and Model Objects */

@property (nonatomic, retain) ETLayoutItemGroup *browserItem;
@property (nonatomic, retain) ETLayoutItemGroup *aspectInspectorItem;
@property (nonatomic, retain) ETLayoutItem *viewPopUpItem;
@property (nonatomic, retain) ETLayoutItem *aspectPopUpItem;
@property (nonatomic, readonly) id selectedObject;

/** @taskunit Selection Interaction */

- (NSArray *) selectedObjects;

/** @taskunit Actions */

- (IBAction) changePresentationViewFromPopUp: (id)sender;
- (IBAction) changeAspectPaneFromPopUp: (id)sender;

@end
