/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETController.h>

@class ETUIBuilderItemFactory, ETAspectRepository;

/** @group UI Builder
 
@abstract Main controller for the UI builder inspector and object browser. */
@interface ETUIBuilderController : ETController
{
	ETUIBuilderItemFactory *_itemFactory;
	ETLayoutItem *_editedItem;
	ETLayoutItemGroup *_browserItem;
	ETLayoutItemGroup *_aspectInspectorItem;
	ETLayoutItem *_viewPopUpItem;
	ETLayoutItem *_aspectPopUpItem;
	ETAspectRepository *_aspectRepository;
	BOOL _isChangingSelection;
	NSString *_editedProperty;
}

/** @taskunit Inspector Pane Factory */

@property (nonatomic, retain) ETUIBuilderItemFactory *itemFactory;

/** @taskunit Accessing UI */

@property (nonatomic, readonly) ETLayoutItemGroup *objectPickerItem;
@property (nonatomic, readonly) ETLayoutItemGroup *contentAreaItem;
@property (nonatomic, retain) ETLayoutItem *editedItem;
@property (nonatomic, retain) ETLayoutItemGroup *browserItem;
@property (nonatomic, retain) ETLayoutItemGroup *aspectInspectorItem;
@property (nonatomic, retain) ETLayoutItem *viewPopUpItem;
@property (nonatomic, retain) ETLayoutItem *aspectPopUpItem;

/** @taskunit Aspect Repository */

@property (nonatomic, retain) ETAspectRepository *aspectRepository;

/** @taskunit Selection Interaction */

@property (nonatomic, readonly) NSArray *selectedObjects;

- (void) browserSelectionDidChange: (NSNotification *)aNotif;

/** @taskunit Actions */

- (IBAction) changePresentationViewFromPopUp: (id)sender;
- (IBAction) changeAspectPaneFromPopUp: (id)sender;
- (IBAction) changeAspectRepositoryFromPopUp: (id)sender;

@end
