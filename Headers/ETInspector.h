/** <title>ETInspector</title>

	<abstract>Inspector protocol and related Inspector representation class 
	which can be used as an inspector view wrapper.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETInspecting.h>

@class ETView, ETContainer;


@interface ETInspectorLayout : ETLayout
{

}

- (id) inspectedObject;

@end

@interface ETInspector : ETLayoutItem <ETInspector>
{
	IBOutlet ETContainer *itemGroupView;
	IBOutlet ETContainer *propertyView;
	IBOutlet NSPopUpButton *layoutPopup;
	IBOutlet NSPopUpButton *instrumentPopup;
	IBOutlet NSWindow *window;
	IBOutlet id viewModelLayout;
	ETLayoutItemGroup *masterViewItem;
	ETLayoutItemGroup *detailViewItem;

	NSArray *_inspectedObjects;
}

- (NSArray *) inspectedObjects;
- (void) setInspectedObjects: (NSArray *)objects;

- (NSWindow *) window;
- (NSPanel *) panel;

- (IBAction) changeLayout: (id)sender;
- (IBAction) changeInstrument: (id)sender;
- (IBAction) inspect: (id)sender;

@end
