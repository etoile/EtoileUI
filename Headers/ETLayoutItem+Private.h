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
- (void) stopKVOObservationIfNeeded;

/** @taskunit Initial Values */

- (void) setDefaultValue: (id)aValue forProperty: (NSString *)key;
- (id) defaultValueForProperty: (NSString *)key;

/** @taskunit View Integration */

- (ETView *) supervisorView;
- (void) setSupervisorView: (ETView *)aSupervisorView
                      sync: (ETSyncSupervisorView)syncDirection;

/** @taskunit Decorator Item */
 
 - (ETWindowItem *) provideWindowItem;
 
/** @taskunit Geometry */

- (NSRect) drawingBox;
- (NSRect) contentDrawingBox;
- (NSRect) visibleContentBounds;

/** taskunit Initial Frame */

- (NSRect) defaultFrame;
- (void) setDefaultFrame: (NSRect)frame;
- (void) restoreDefaultFrame;

/** @taskunit Display Update */

- (void) refreshIfNeeded;

/** @taskunit Layout Update Integration */

- (BOOL) usesFlexibleLayoutFrame;
- (void) updateLayoutRecursively: (BOOL)recursively;
- (void) setNeedsLayoutUpdate;

/** @taskunit View and Represented Object Integration */

- (void) didChangeViewValue: (id)newValue;
- (void) didChangeRepresentedObjectValue: (id)newValue;

/** @taskunit Represented Object Editing */

- (NSString *) editedProperty;

/** @taskunit Responder Role  */

- (id) responder;

/** @taskunit Layout Layer Support */

- (BOOL) isLayerItem;

/** The foster parent.

The receiver returns the host item as -parentItem, but doesn't appear in the 
children of the host item.
 
-[ETLayout layerItem] and -[ETFirstResponderSharingArea activeFieldEditorItem] 
are connected to the item tree with -hostItem.
 
See also -addItem: and -parentItem. */
@property (nonatomic, retain) ETLayoutItemGroup *hostItem;

@end
