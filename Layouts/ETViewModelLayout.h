/** <title>ETViewModelLayout</title>
	
	<abstract>A property inspector implemented as a pluggable layout which 
	supports introspecting an object as both view and model.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETInstanceVariableMirror.h>
#import <EtoileUI/ETCompositeLayout.h>
#import <EtoileUI/ETWidgetBackend.h>

// FIXME: Don't expose ETView in the public API.
@class ETVIew;

/** See -setDisplayMode:. */
typedef enum _ETLayoutDisplayMode {
	ETLayoutDisplayModeViewProperties = 1,
	ETLayoutDisplayModeViewContent = 2,
	ETLayoutDisplayModeViewObject = 3,
	ETLayoutDisplayModeModelProperties = 4,
	ETLayoutDisplayModeModelContent = 5,
	ETLayoutDisplayModeModelObject = 6
} ETLayoutDisplayMode;


/** When a view model layout is in use, you can change the represented object 
on its layout context. The represented object will usually be exposed in the 
model-related display modes. Alternative behaviors can be obtained with 
-setShouldInspectItself: and -setShouldInspectRepresentedObjectAsView:.

However you shouldn't change the layout context source or invoke -reload or 
similar methods on it as required by ETCompositeLayout. */
@interface ETViewModelLayout : ETCompositeLayout
{
	@private
	IBOutlet ETView *propertyView;
	ETLayoutItemGroup *propertyViewItem;
	IBOutlet NSPopUpButton *popup;
	ETLayoutDisplayMode _displayMode;
	BOOL _shouldInspectRepresentedObjectAsView;
	BOOL _shouldInspectItself;
	/* We don't use a dictionary to ensure keys won't be copied since they can  
	   be arbitrary objects. */
	NSMapTable *_mirrorCache; 
}


// NOTE: Could be better named -shouldInspectInitialContent
- (BOOL) shouldInspectItself;
- (void) setShouldInspectItself: (BOOL)inspectLayout;
- (BOOL) shouldInspectRepresentedObjectAsView;
- (void) setShouldInspectRepresentedObjectAsView: (BOOL)flag; 
- (ETLayoutItem *) inspectedItem;

- (ETLayoutDisplayMode) displayMode;
- (void) setDisplayMode: (ETLayoutDisplayMode)mode;
- (void) switchDisplayMode: (id)sender;

@end
