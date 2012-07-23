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
	//[[layout positionalLayout] setItemMargin: 10];
	
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
	[sliderItem setWidth: 200];
	[buttonItem setName: @"Customize:"];
	[textFieldItem setName: @"Title & Author:"];
	[textFieldItem setWidth: 300];

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

- (void) buildSingleSectionForm
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroup];
	ETLayoutItem *labelItem = [itemFactory labelWithTitle: @"Untitled"];
	ETLayoutItem *primitiveItem = [itemFactory item];
	ETLayoutItem *sliderItem = [itemFactory horizontalSlider];
	ETLayoutItem *buttonItem = [itemFactory button];
	ETLayoutItem *progressIndicatorItem = [itemFactory progressIndicator];
	ETLayoutItem *checkboxItem = [itemFactory checkboxWithLabel: @"Walk now..." 
		target: nil action: NULL forProperty: @"" ofModel: nil];
	ETLayoutItem *textFieldItem = [itemFactory textField];
	
	/* When no name is set, the item tends to be invisible, because the label  
	   is too long... -[ETBasicItemStyle labelForItem:] returns the instance 
	   description. */
	[labelItem setName: @"Label:"];
	[primitiveItem setName: @"Primitive Item:"];
	[sliderItem setName: @"Slider:"];
	[buttonItem setName: @"Button:"];
	[progressIndicatorItem setName: @"Progress Indicator:"];
	[checkboxItem setName: @"Checkbox:"];
	[textFieldItem setName: @"TextField:"];

	[sliderItem setWidth: 200];
	[textFieldItem setWidth: 300];

	[itemGroup addItem: labelItem];
	[itemGroup addItem: primitiveItem];
	[itemGroup addItem: sliderItem];
	[itemGroup addItem: buttonItem];
	[itemGroup addItem: progressIndicatorItem];
	[itemGroup addItem: checkboxItem];
	[itemGroup addItem: textFieldItem];
	//[textFieldItem setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];

	[itemGroup setFrame: NSMakeRect(0, 0, 500, 400)];
	[itemGroup setLayout: [self createFormLayout]];

	[[itemFactory windowGroup] addItem: itemGroup];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[ETLayoutItem setShowsBoundingBox: YES];
	[ETLayoutItem setShowsFrame: YES];

	[self buildSingleSectionForm];
	//[self buildMultipleSectionForm];
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
