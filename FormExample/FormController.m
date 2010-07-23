/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2008
	License:  Modified BSD (see COPYING)
 */

#import "FormController.h"

@interface Movie : NSObject
{
	NSString *title;
	NSUInteger releaseDate;
}

+ (Movie *) movieWithTitle: (NSString *)aTitle releaseDate: (NSUInteger)aDate;
- (NSString *) title;
- (NSUInteger) releaseDate;

@end


@implementation FormController

- (ETFormLayout *) createFormLayout
{
	ETFormLayout *layout = [ETFormLayout layout];
	
	// NOTE: If you want a form organized on a line rather in a stack:
	// [layout setPositionalLayout: [ETLineLayout layout]];
	[[layout positionalLayout] setItemMargin: 10];
	
	return layout;
}

- (void) buildUIFromModelDescription
{
	Movie *movie = [Movie movieWithTitle: @"Gran Torino" releaseDate: 2008];
	ETLayoutItemGroup *itemGroup = [[ETModelDescriptionRenderer renderer] renderModel: movie];
	
	[[[ETLayoutItemFactory factory] windowGroup] addItem: itemGroup];
}

- (void) buildMultipleSectionForm
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroup];
	ETLayoutItemGroup *firstSectionItem = [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 500, 200)];
	ETLayoutItemGroup *secondSectionItem = [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 500, 200)];
	ETLayoutItem *sliderItem = [itemFactory horizontalSlider];
	ETLayoutItem *buttonItem = [itemFactory button];
	ETLayoutItem *textFieldItem = [itemFactory textField];

	[sliderItem setName: @"Voice Volume:"];
	[buttonItem setName: @"Customize:"];
	[textFieldItem setName: @"Title & Author:"];

	[firstSectionItem addItem: textFieldItem];
	[firstSectionItem setLayout: [self createFormLayout]];
	[secondSectionItem addItems: A(sliderItem, buttonItem)];
	[secondSectionItem setLayout: [self createFormLayout]];
	
	[itemGroup addItems: A(firstSectionItem, secondSectionItem)];

	[itemGroup setFrame: NSMakeRect(0, 0, 500, 400)];
	[itemGroup setLayout: [ETColumnLayout layout]];
	[[itemGroup layout] setBorderMargin: 10];
	[[itemGroup layout] setSeparatorItemEndMargin: 15];
	[[itemGroup layout] setSeparatorTemplateItem: [itemFactory lineSeparator]];
	
	[[itemFactory windowGroup] addItem: itemGroup];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
#if 0
	[ETLayoutItem setShowsBoundingBox: YES];
	[ETLayoutItem setShowsFrame: YES];

	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroup];
	ETLayoutItem *sectionLabelItem = [itemFactory item];
	ETLayoutItem *sliderItem = [itemFactory horizontalSlider];
	ETLayoutItem *buttonItem = [itemFactory button];
	//ETLayoutItem *progressIndicatorItem = [itemFactory progressIndicator];
	//ETLayoutItem *checkboxItem = [itemFactory checkbox];
	ETLayoutItem *textFieldItem = [itemFactory textField];

	//[itemGroup setRepresentedPath: @"/"]; /* Mandatory to handle drop */
	
	[sectionLabelItem setName: @"Editing:"];
	[sliderItem setName: @"My Slider:"];
	[buttonItem setName: @"My Mysterious Clickability:"];
	[textFieldItem setName: @"Book Title & Author"];

	[itemGroup addItem: sectionLabelItem];
	[itemGroup addItem: sliderItem];
	[itemGroup addItem: buttonItem];
	/*[itemGroup addItem: progressIndicatorItem];
	[itemGroup addItem: checkboxItem];*/
	[itemGroup addItem: textFieldItem];
	//[textFieldItem setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	[itemGroup setFrame: NSMakeRect(0, 0, 500, 400)];
	[itemGroup setLayout: [self createFormLayout]];
	
	/*id slider = AUTORELEASE([[NSSlider alloc] initWithFrame: NSMakeRect(0, 0, 80, 50)]);
	
	[slider setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	[[itemGroup supervisorView] addSubview:	slider];*/
	
	[[itemFactory windowGroup] addItem: itemGroup];
#endif
	[self buildMultipleSectionForm];
}

@end


@implementation Movie

static ETEntityDescription *movieEntityDesc = nil;

+ (ETEntityDescription *) entityDescription
{
	if (nil != movieEntityDesc)
		return movieEntityDesc;

	movieEntityDesc = [[ETEntityDescription alloc] initWithName: @"Movie"];

	ETPropertyDescription *titleDesc = [ETPropertyDescription descriptionWithName: @"title"];
	ETPropertyDescription *releaseDateDesc = [ETPropertyDescription descriptionWithName: @"releaseDate"];
	ETNumberRole *releaseDateRole = AUTORELEASE([[ETNumberRole alloc] init]);

	[releaseDateRole setMinimum: 2000];
	[releaseDateRole setMaximum: 2010];
	[releaseDateDesc setRole: releaseDateRole];

	[movieEntityDesc setPropertyDescriptions: A(titleDesc, releaseDateDesc)];

	return movieEntityDesc;
}

+ (Movie *) movieWithTitle: (NSString *)aTitle releaseDate: (NSUInteger)aDate
{
	Movie *newMovie = AUTORELEASE([[self alloc] init]);

	ASSIGN(newMovie->title, aTitle);
	newMovie->releaseDate = aDate;

	return newMovie;
}

DEALLOC(DESTROY(title))

- (NSString *) title
{
	return title;
}

- (NSUInteger) releaseDate
{
	return releaseDate;
}

@end
