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
	ETLayoutItem *_documentContentItem;
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
/** The editing area that presents and contains the document content item. */
@property (nonatomic, readonly) ETLayoutItemGroup *contentAreaItem;
/** The edited or inspected UI root item (the document model object).

For the inspector, this item is the browser item represented object (aka the 
inspected item).<br />
For the editor, this item is enclosed inside the content area item. */
@property (nonatomic, retain) ETLayoutItem *documentContentItem;
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
