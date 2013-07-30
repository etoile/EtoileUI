/** <title>ETIconLayout</title>

	<abstract>A layout subclass to present layout items in an icon view.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
*/

#import <EtoileUI/ETTemplateItemLayout.h>
#import <EtoileUI/ETActionHandler.h>
#import <EtoileUI/ETBasicItemStyle.h>
#import <EtoileUI/ETSelectTool.h>

/** ETIconLayout is a layout that mimicks a Mac OS X Finder-like icon view 
by overriding the existing item aspects as described below:

<deflist>
<term>coverStyle</term><desc>ETIconAndLabelStyle</desc>
<term>actionHandler</term><desc>ETIconAndLabelActionHandler</desc>
<term>contentAspect<em>ETContentAspectComputed</em>
<term>view</term><desc>nil (to ensure no view interaction is possible and the 
item icon is a view snapshot image)</desc>
<term>icon</term><desc>the existing item or represented object icon or a new 
item snapshot image when no icon can be retrieved</desc>
</deflist>

When -[ETLayoutItem styleGroup] is not empty or -[ETLayoutItem style] is not nil, 
they will be drawn under the cover style, hence the result might not be what 
you expect.

ETIconLayout will look up the icon and label on each item represented object 
with -icon and -displayName, or on the item itself when no represented object 
is available. See also ETIconAndLabelStyle.

ETIconLayout doesn't customize ETTemplateItemLayout much.<br />
It overrides -resizeLayoutItems:toScaleFactor: with a sizing policy based on 
-minIconSize and -iconSizeForScaleFactorUnit that ensures the item size is 
extrapolated from the icon size. For example, a 32 * 32 icon size might result 
in 80 * 45 item size once the label and the blank space around the icon is taken 
in account.<br />
In addition, it generates item snapshots and install them as icons when no icon 
is provided.

Most ETIconLayout behavior is implemented in ETIconAndLabelStyle which is a 
custom ETBasicItemStyle initialized with values that results in a good looking 
icon element, and ETIconAndLabelActionHandler which extends ETActionHandler 
with the label editing ability based on the geometry declared in 
ETIconAndLabelStyle.

When the UI requires an icon view with label editing and/or the possibility 
to switch between user-decided and grid-based placement, ETIconLayout is a good 
choice. Otherwise, to create a column or line of views, images etc. you should 
use ETColumnLayout or ETLineLayout instead, and customize each item cover style 
or style to obtain the right item look (see ETBasicItemStyle to do so).<br />
To create a photo view that presents a photo collection, use an ETFlowLayout in 
combination with custom ETBasicItemStyle and ETActionHandler.<br />
For a toolbar-like UI, use -[ETLayoutItemFactory horizontalBarWithSize:],  
-[ETLayoutItemFactory barElementFromItem:withLabel:] and related methods.

Here is a ETIconLayout use case example:

<example>
ETIconLayout *layout = [ETIconLayout layoutWithObjectGraphContext: [itemGroup objectGraphContext]];
[layout setIconSizeForScaleFactorUnit: NSMakeSize(128, 128)];
[layout setMinIconSize: NSMakeSize(64, 64)];
[itemGroup setLayout: layout];
</example>

In this example, here are the icon sizes when the 
-[ETLayoutItemGroup itemScaleFactor] is altered to:

<deflist>
<term>0.5 or below</term><desc>64 * 64 icon size</desc>
<term>1.0<term><desc>128 * 128 icon size</desc>
<term>2.0<term><desc>256 * 256 icon size</desc>
</deflist> */
@interface ETIconLayout : ETTemplateItemLayout
{
	@private
	NSFont *_itemLabelFont;
	NSSize _iconSizeForScaleFactorUnit;
	NSSize _minIconSize;
}

- (void) setItemTitleFont: (NSFont *)font;

/* Icon Sizing */

- (NSSize) iconSizeForScaleFactorUnit;
- (void) setIconSizeForScaleFactorUnit: (NSSize)aSize;
- (NSSize) minIconSize;
- (void) setMinIconSize: (NSSize)aSize;

@end

/** ETIconAndLabelStyle is a ETBasicItemStyle initialized with values that 
results in a good looking icon element as described below:

<deflist>
<term>maxLabelSize</term><desc>150</desc>
<term>labelPosition</term><desc>ETLabelPositionInsideBottom</desc>
<term>labelMargin</term><desc>8</desc>
<term>edgeInset</term><desc>7</desc>
</deflist>

The selection indicator drawn is also not the same than ETBasicItemStyle.

ETIconAndLabelStyle will look up the icon and label on each item represented 
object with -icon and -displayName, or on the item itself when no represented 
object is available. The lookup is done with -[ETLayoutItem icon] and 
-[ETLayoutItem displayName].

It is usually used in conjunction with ETIconAndLabelActionHandler and 
ETIconLayout. */
@interface ETIconAndLabelStyle : ETBasicItemStyle

@end

/** ETIconAndLabelActionHandler is a ETActionHandler extended to support label 
editing on a single click in the label area.

It retrieves the label and icon arrangement geometry from each item cover style. 
The cover style doesn't have to be an ETIconAndLabelStyle instance.

It is usually used in conjunction with ETIconAndLabelStyle and ETIconLayout. */
@interface ETIconAndLabelActionHandler : ETActionHandler
- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
@end

// TODO: Find a better name...
@interface ETSelectAndClickTool : ETSelectTool
{
@private
	BOOL _ignoresBackgroundClick;
}

- (BOOL) ignoresBackgroundClick;
- (void) setIgnoresBackgroundClick: (BOOL)noBackgroundClick;

@end
