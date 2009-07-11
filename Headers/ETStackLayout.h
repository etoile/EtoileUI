/** <title>ETStackLayout</title>

	<abstract>	A layout class that organize items in a single vertical column 
	or stack.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETComputedLayout.h>

@class ETLayoutLine;


@interface ETStackLayout : ETComputedLayout
{

}

- (void) computeLayoutItemLocationsForLayoutLine: (ETLayoutLine *)line;

@end
