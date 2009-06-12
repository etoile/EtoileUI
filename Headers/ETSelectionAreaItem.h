/**	<title>ETSelectionAreaItem/title>

	<abstract>Layout item to represent any kind of selection area.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

/** ETSelectionAreaItem is a layout item which can be used to represent any 
selection area indepently of:
<list>
<item>the instrument/tool currently in use and how the selection was created</item>
<item>the selection shape (rectangular, circle, polygonal etc.)</item>
</list> 

ETSelectionAreaItem is initialized with a rectangular ETShape, but the shape 
can be customized with -setStyle:. For example:
<code>
[selectionAreaItem setStyle: [ETShape ovalShapeWithRect: [selectionAreaItem contentBounds]];
</code>

An ETInstrument subclass is expected to provide a prototype which can be 
customized (color, shape, opacity etc.). See -[ETSelectionTool selectionAreaItem] 
and ETShape to learn what you can customize.

ETSelectionTool used ETSelectionAreaItem to implement visual feedback when the 
selection is underway (aka rubber-banding). */
@interface ETSelectionAreaItem : ETLayoutItem
{

}

@end
