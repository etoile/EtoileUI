/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>

/* In this example, we build a simple photo manager-like application which 
supports multiple presentations (colum, line, flow, list/table etc.) and 
various presentation options such as margin, scaling etc.

Unlike the Collage example where the UI is built with EtoileUI from scratch, 
PhotoViewExample illustrates how to reuse an AppKit UI packaged in a Nib 
(usually built with IB or Gorm).

PhotoViewExample illustrates how an AppKit widget can be reused. Every photo 
item uses an NSImageView returned by -imageViewForImage: to present the image. 
The image view is set with -[ETLayoutItem setView:].<br />
In a real application, use -[ETLayoutItem setImage:] and no view. Using no view 
will substantially improve the overall performance. The image drawing can be 
then customized with ETBasicItemStyle and -[ETLayoutItem setContentAspect:]. 

The entire application behavior is implemented in a single controller object 
(PhotoViewController) which is instantiated/stored in the main Nib and sets as 
the application's delegate.<br />
At launch time, -applicationDidFinishLaunching: is invoked by ETApplication, 
the implementation uses -renderMainNib to turn the AppKit view/window hierarchy 
into a layout item tree. In the Nib, the window contains an ETView instance 
that represents the photoViewItem area. When ETEtoileUIBuilder traverses the 
view hierarchy, this view is automatically assigned to a new ETLayoutItemGroup 
which is then retrieved with [photoView owningItem] once -renderMainNib returns.<br />
Then the method, sets up the photo view item with:
<list>
<item>a source that describes how the item tree is built based on the model</item>
<item>a controller to support drag and drop, sorting, etc.</item>
<item>a layout, the initial photo view presentation</item>
<item>the scroller visibility</item>
</list>
The controller and source roles are played by the PhotoViewExampleController itself.
The controller role is inherited by subclassing ETController and the source 
behavior is supported by implementing -numberOfItemsInItemGroup:, 
-itemGroup:itemAtIndex: and -displayedItemPropertiesInItemGroup: (these methods 
belong to the ETLayoutItemGroupIndexSource informal protocol).<br />
Finally the receiver is customized through its ETController superclass API to 
express the drag and drop constraints.

The multiple presentations supported by the PhotoViewExample are all initialized 
in -configureLayout:. e.g. which columns are visible in the list/table, which is 
the max photo item size etc.

Various actions to adjust the presentation options are directly bound between 
their sender (popup, checkbox etc.) and the PhotoViewExampleController instance 
in the Nib.

Finally PhotoViewExample illustrates how a layout item tree can be built statically. 
When the 'Source' checkbox in the UI is unchecked, the source is set 
to nil on the photoViewItem and the ETLayoutItemGroupIndexSource protocol 
implemented by PhotoViewExampleController is ignored. Instead 
-setUpLayoutItemsDirectly is invoked, it instantiates each photo item all 
at once and add them to photoViewItem immediately.<br />
Both Collage and TableExample shows how to build layout item trees statically too.

A more generic source protocol named ETLayoutItemGroupPathSource is demonstrated 
in ObjectManagerExample. With it, you can provide items to EtoileUI to create a 
tree-structure rather than a simple list.<br />
The most convenient way to build layout item tree by implementing the collection 
protocol on the model classes and letting EtoileUI generate the layout item tree
is shown in MarkupEditorExample. */
@interface PhotoViewController : ETController
{
	IBOutlet ETView *photoView;
	IBOutlet NSSlider *itemMarginSlider;
	IBOutlet NSSlider *borderMarginSlider;
	ETLayoutItemGroup *photoViewItem;
	NSMutableArray *images;
}

- (IBAction) choosePicturesAndLayout:(id)sender;
- (IBAction) changeLayout: (id)sender;
- (IBAction) switchUsesSource: (id)sender;
- (IBAction) switchUsesScrollView: (id)sender;
- (IBAction) scale: (id)sender;
- (IBAction) changeItemMargin: (id)sender;
- (IBAction) changeBorderMargin: (id)sender;

- (id) configureLayout: (id)layoutObject;

/* Private */

- (void) selectPicturesPanelDidEnd: (NSOpenPanel *)panel 
                        returnCode: (int)returnCode
                       contextInfo: (void *)contextInfo;
- (void) setUpLayoutItemsDirectly;
- (NSImageView *) imageViewForImage: (NSImage *)image;

@end
