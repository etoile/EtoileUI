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
	NSDate *releaseDate;
	NSInteger runningTime;
}

+ (Movie *) movie;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *releaseDate;
@property (nonatomic, assign) NSInteger runningTime;

@end

@interface MovieCollection : NSObject <ETCollection, ETCollectionMutation>
{
	NSString *name;
	NSArray *movies;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, copy) NSArray *movies;

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

- (NSDate *)dateWithYear: (NSInteger)aYear month: (NSInteger)aMonth day: (NSInteger)aDay
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
	NSDateComponents *comps = [[NSDateComponents alloc] init];

	[comps setDay: aDay];
	[comps setMonth: aMonth];
	[comps setYear: aYear];

	return [gregorian dateFromComponents:comps];
}

- (Movie *)randomMovie
{
	Movie *movie = [Movie movie];
	[movie setTitle: @"Gran Torino"];
	[movie setReleaseDate: [self dateWithYear: 2008 month: 0 day: 0]];
	[movie setRunningTime: 300];
	return movie;
}

- (void) buildFormFromModelDescription
{
	ETLayoutItemGroup *itemGroup = [[ETModelDescriptionRenderer renderer] renderObject: [self randomMovie]];
	
	[[[ETLayoutItemFactory factory] windowGroup] addItem: itemGroup];
}

- (void) buildMultipleSectionForm
{
	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 500, 400)];
	ETLayoutItemGroup *firstSectionItem = [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 500, 200)];
	ETLayoutItemGroup *secondSectionItem = [itemFactory itemGroupWithFrame: NSMakeRect(0, 0, 500, 200)];
	ETLayoutItem *sliderItem = [itemFactory horizontalSlider];
	ETLayoutItem *buttonItem = [itemFactory button];
	ETLayoutItem *textFieldItem = [itemFactory textField];

	[sliderItem setName: @"Voice Volume:"];
	[buttonItem setName: @"Random and Untitled Button:"];
	[textFieldItem setName: @"Title & Author:"];

	[sliderItem setWidth: 200];
	[textFieldItem setWidth: 300];

	[firstSectionItem addItem: textFieldItem];
	[firstSectionItem setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[firstSectionItem setLayout: [self createFormLayout]];
	[firstSectionItem setIdentifier: @"section1"];

	[secondSectionItem addItems: A(sliderItem, buttonItem)];
	[secondSectionItem setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[secondSectionItem setLayout: [self createFormLayout]];
	[secondSectionItem setIdentifier: @"section2"];

	[itemGroup addItems: A(firstSectionItem, secondSectionItem)];

	[itemGroup setLayout: [ETColumnLayout layout]];
	//[[itemGroup layout] setBorderMargin: 10];
	[[itemGroup layout] setSeparatorItemEndMargin: 30];
	[[itemGroup layout] setSeparatorTemplateItem: [itemFactory lineSeparator]];
	[[itemGroup layout] setUsesAlignmentHint: YES];
	[itemGroup setIdentifier: @"form"];

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

- (void) showFormGeneratedMetamodelEditors
{
	[[[ETModelDescriptionRepository mainRepository] descriptionForName: @"ETEntityDescription"] view: nil];
	//[[[ETModelDescriptionRepository mainRepository] descriptionForName: @"ETPropertyDescription"] view: nil];
	//[[[ETModelDescriptionRepository mainRepository] descriptionForName: @"ETPackageDescription"] view: nil];
}

- (void) showFormGeneratedItemAndAspectEditors
{
	ETLayoutItem *layoutEntityItem = [[ETModelDescriptionRenderer renderer] renderObject: [ETTableLayout layout]];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: layoutEntityItem];
	
	ETLayoutItem *entityItem = [[ETModelDescriptionRenderer renderer] renderObject: layoutEntityItem];
	[entityItem setHasVerticalScroller: YES];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: entityItem];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[ETLayoutItem setShowsBoundingBox: YES];
	[ETLayoutItem setShowsFrame: YES];

	/*[self buildSingleSectionForm];
	[self buildMultipleSectionForm];
	[self buildFormFromModelDescription];*/

	[self showFormGeneratedMetamodelEditors];
	//[self showFormGeneratedItemAndAspectEditors];

	/*ETLayoutItemGroup *editor = [[ETLayoutItemFactory factory] collectionEditorWithSize: NSMakeSize(400, 500) representedObject: nil controller: self];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: editor];*/
}

@end


@implementation Movie

@synthesize title, releaseDate, runningTime;

static ETEntityDescription *movieEntityDesc = nil;

+ (ETEntityDescription *) newEntityDescription
{
	if (nil != movieEntityDesc)
		return movieEntityDesc;

	movieEntityDesc = [[ETEntityDescription alloc] initWithName: @"Movie"];

	ETPropertyDescription *title = [ETPropertyDescription descriptionWithName: @"title" type: (id)@"NSString"];

	ETPropertyDescription *releaseDate = [ETPropertyDescription descriptionWithName: @"releaseDate" type: (id)@"NSDate"];
	ETNumberRole *releaseDateRole = AUTORELEASE([[ETNumberRole alloc] init]);
	[releaseDateRole setMinimum: 2000];
	[releaseDateRole setMaximum: 2010];
	[releaseDate setRole: releaseDateRole];

	ETPropertyDescription *runningTime = [ETPropertyDescription descriptionWithName: @"runningTime" type: (id)@"NSInteger"];
	ETNumberRole *runningTimeRole = AUTORELEASE([[ETNumberRole alloc] init]);
	[runningTimeRole setMinimum: 2000];
	[runningTimeRole setMaximum: 2010];
	[runningTime setRole: runningTimeRole];

	[movieEntityDesc setPropertyDescriptions: A(title, runningTime)];

	return movieEntityDesc;
}

+ (Movie *) movie
{
	return AUTORELEASE([[self alloc] init]);
}

- (void) dealloc
{
	DESTROY(title);
	DESTROY(releaseDate);
	[super dealloc];
}

@end


@implementation MovieCollection

@synthesize name, movies;

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *entity = [self newBasicEntityDescription];
	
	// For subclasses that don't override -newEntityDescription, we must not add
	// the property descriptions that we will inherit through the parent
	if ([[entity name] isEqual: [MovieCollection className]] == NO)
		return entity;
	
	ETPropertyDescription *name = [ETPropertyDescription descriptionWithName: @"name" type: (id)@"NSString"];
	
	ETPropertyDescription *movies = [ETPropertyDescription descriptionWithName: @"movies" type: (id)@"Movie"];
	ETRelationshipRole *moviesRole = AUTORELEASE([[ETRelationshipRole alloc] init]);
	[movies setRole: moviesRole];
	
	[entity setPropertyDescriptions: A(name, movies)];
	
	return entity;
}

- (void) dealloc
{
	DESTROY(name);
	DESTROY(movies);
	[super dealloc];
}

@end
