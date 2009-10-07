/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2008
	License:  Modified BSD (see COPYING)
 */

#import "FormController.h"


@implementation FormController

- (ETFormLayout *) createFormLayout
{
	ETFormLayout *layout = [ETFormLayout layout];
	
	// NOTE: If you want a form organized on a line rather in a stack:
	// [layout setPositionalLayout: [ETLineLayout layout]];
	[[layout positionalLayout] setItemMargin: 10];
	
	return layout;
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroup];
	ETLayoutItem *sectionLabelItem = [itemFactory item]; // -itemWithName:
	ETLayoutItem *sliderItem = [itemFactory horizontalSlider];
	ETLayoutItem *buttonItem = [itemFactory button];
	//ETLayoutItem *progressIndicatorItem = [itemFactory progressIndicator];
	ETLayoutItem *checkboxItem = [itemFactory checkbox];
	ETLayoutItem *textFieldItem = [itemFactory textField];

	//[itemGroup setRepresentedPath: @"/"]; /* Mandatory to handle drop */
	
	[sectionLabelItem setName: @"Editing:"];
	[sliderItem setName: @"My Slider:"];
	[buttonItem setName: @"My Mysterious Clickability:"];

	[itemGroup addItem: sectionLabelItem];
	[itemGroup addItem: sliderItem];
	[itemGroup addItem: buttonItem];
	//[itemGroup addItem: progressIndicatorItem];
	[itemGroup addItem: checkboxItem];
	[itemGroup addItem: textFieldItem];
	//[textFieldItem setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[itemGroup setFrame: NSMakeRect(0, 0, 500, 400)];
	[itemGroup setLayout: [self createFormLayout]];
	
	/*id slider = AUTORELEASE([[NSSlider alloc] initWithFrame: NSMakeRect(0, 0, 80, 50)]);
	
	[slider setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[[itemGroup supervisorView] addSubview:	slider];*/
	
	[[itemFactory windowGroup] addItem: itemGroup];
}

@end
