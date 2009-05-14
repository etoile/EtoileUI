/*
	FormController.m
	
	Description forthcoming.
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2008
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
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
	ETLayoutItemGroup *itemGroup = [ETLayoutItem itemGroupWithContainer];
	ETLayoutItem *sectionLabelItem = [ETLayoutItem item]; // -itemWithName:
	ETLayoutItem *sliderItem = [ETLayoutItem horizontalSlider];
	ETLayoutItem *buttonItem = [ETLayoutItem button];
	//ETLayoutItem *progressIndicatorItem = [ETLayoutItem progressIndicator];
	ETLayoutItem *checkboxItem = [ETLayoutItem checkbox];
	ETLayoutItem *textFieldItem = [ETLayoutItem textField];

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
	
	[(ETLayoutItemGroup *)[ETLayoutItem windowGroup] addItem: itemGroup];
}

@end
