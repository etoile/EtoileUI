/*
	A basic EtoileUI example that shows to build item trees statically and 
	reuse existing AppKit widgets from a nib.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/EtoileUI.h>


@interface TableController : NSObject
{
	IBOutlet ETView *leftTableAreaView;
	IBOutlet ETView *rightTableAreaView;
	IBOutlet NSScrollView *outlineView;
}

@end
