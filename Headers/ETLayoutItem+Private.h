/**
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2014
	License:  Modified BSD (see COPYING)
 */

#import <EtoileUI/ETLayoutItem.h>

/** @group Layout Items
@abstract Framework Private Additions to ETLayoutItem */
@interface ETLayoutItem ()

/** @taskunit Initialization */

- (void) prepareTransientState;

/** @taskunit KVO Control */

- (void) stopKVOObservation;

/** @taskunit Initial Values */

- (void) setDefaultValue: (id)aValue forProperty: (NSString *)key;
- (id) defaultValueForProperty: (NSString *)key;

- (void) setInitialValue: (id)aValue forProperty: (NSString *)key;
- (id) initialValueForProperty: (NSString *)key;
- (id) removeInitialValueForProperty: (NSString *)key;

/** @taskunit View Integration */

@property (nonatomic, readonly, strong) ETView *supervisorView;

- (void) setSupervisorView: (ETView *)aSupervisorView
                      sync: (ETSyncSupervisorView)syncDirection;

/** @taskunit Decorator Item */
 
 - (ETWindowItem *) provideWindowItem;

/** @taskunit Visibility and Layout Interaction */

@property (nonatomic, getter=isExposed) BOOL exposed;
 
/** @taskunit Geometry */

@property (nonatomic, readonly) NSRect drawingBox;
@property (nonatomic, readonly) NSRect contentDrawingBox;
@property (nonatomic, readonly) NSRect visibleContentBounds;

/** taskunit Initial Frame */

- (NSRect) defaultFrame;
- (void) setDefaultFrame: (NSRect)frame;
- (void) restoreDefaultFrame;

/** @taskunit Display Update */

- (void) refreshIfNeeded;

/** @taskunit Layout Update Integration */

@property (nonatomic, readonly) BOOL usesFlexibleLayoutFrame;

- (void) updateLayoutRecursively: (BOOL)recursively;
- (void) setNeedsLayoutUpdate;

/** @taskunit View and Represented Object Integration */

- (void) didChangeViewValue: (id)newValue;
- (void) didChangeRepresentedObjectValue: (id)newValue;

/** @taskunit Represented Object Editing */

@property (nonatomic, readonly) NSString *editedProperty;

/** @taskunit Responder Role  */

@property (nonatomic, readonly) id responder;

/** @taskunit Layout Layer Support */

@property (nonatomic, readonly) BOOL isLayerItem;

/** The foster parent.

The receiver returns the host item as -parentItem, but doesn't appear in the 
children of the host item.
 
-[ETLayout layerItem] and -[ETFirstResponderSharingArea activeFieldEditorItem] 
are connected to the item tree with -hostItem.
 
See also -addItem: and -parentItem. */
@property (nonatomic, retain) ETLayoutItemGroup *hostItem;

@end
