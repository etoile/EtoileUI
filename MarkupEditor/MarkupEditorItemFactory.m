/*
	Copyright (C) 2011 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  February 2011
	License:  Modified BSD (see COPYING)
 */

#import "MarkupEditorItemFactory.h"
#import "MarkupEditorController.h"


@implementation MarkupEditorItemFactory

- (ETTool *) toolWithMultipleAndEmptySelectionAllowed
{
	ETSelectTool *tool = [ETSelectTool tool];

	[tool setAllowsMultipleSelection: YES];
	[tool setAllowsEmptySelection: YES];

	return tool;
}

- (ETLayout *) editorViewLayoutOfClass: (Class)layoutClass
{
	id layoutObject = AUTORELEASE([[layoutClass alloc] init]);
	
	if ([layoutObject isKindOfClass: [ETTableLayout class]])
	{
		[layoutObject setDisplayName: @"Property List" forProperty: @"identifier"];
		[layoutObject setDisplayName: @"Type" forProperty: @"className"];
		[layoutObject setDisplayName: @"Value" forProperty: @"stringValue"];
		[layoutObject setDisplayName: @"Name" forProperty: @"displayName"];
		[layoutObject setDisplayName: @"Description" forProperty: @"description"];
		[layoutObject setDisplayedProperties: [NSArray arrayWithObjects: 
			@"className", @"stringValue", @"description", @"displayName", nil]];
	}

	[layoutObject setAttachedTool: [self toolWithMultipleAndEmptySelectionAllowed]];

	return layoutObject;
}

#define USE_THREE_PANE_LAYOUT

- (ETLayoutItemGroup *) editorViewWithSize: (NSSize)aSize controller: (ETController *)aController
{
	ETLayoutItemGroup *editorView = [self itemGroupWithFrame: NSMakeRect(0, 0, aSize.width, aSize.height)];
	ETPaneLayout *layout = [ETPaneLayout masterContentLayout];
	ETPaneLayout *detailLayout = [ETPaneLayout masterContentLayout];

	[[detailLayout barItem] setLayout: [self editorViewLayoutOfClass: [ETOutlineLayout class]]];
	[detailLayout setBarThickness: 150];
	//[[detailLayout contentItem] setLayout: [ETTextEditorLayout layout]];
	[[detailLayout contentItem] setLayout: [ETOutlineLayout layout]];

	[layout setBarThickness: 400];
	[[layout barItem] setLayout: [self editorViewLayoutOfClass: [ETOutlineLayout class]]];
	[[layout contentItem] setLayout: detailLayout];

	// TODO: Should probably be transparent
	[editorView setShouldMutateRepresentedObject: YES];
	[editorView setSource: editorView];

#ifdef USE_THREE_PANE_LAYOUT
	[layout setBarPosition: ETPanePositionLeft];
	[editorView setLayout: layout];
	[[layout barItem] setIdentifier: @"documentContent"];
#else
	[editorView setLayout: [self editorViewLayoutOfClass: [ETOutlineLayout class]]];
	[editorView setIdentifier: @"documentContent"];
	[editorView setHasVerticalScroller: YES];
	[editorView setHasHorizontalScroller: YES];
#endif

	return editorView;
}

- (ETLayoutItemGroup *) toolbarWithWidth: (float)aWidth controller: (ETController *)aController
{
	ETLayoutItem *addButtonItem = [self buttonWithTitle: _(@"Add Node") 
	                                             target: aController
	                                             action: @selector(add:)];
	ETLayoutItem *removeButtonItem = [self buttonWithTitle: _(@"Remove Node") 
	                                                target: aController
	                                                action: @selector(remove:)];
	/* We use a standard toolbar height */
	NSUInteger barHeight = [self defaultIconAndLabelBarHeight];
	ETLayoutItemGroup *toolbar = [self itemGroupWithFrame: NSMakeRect(0, 0, aWidth, barHeight)];

	[removeButtonItem sizeToFit];

	[toolbar addItems: A(addButtonItem, removeButtonItem)];
	[toolbar setLayout: [ETLineLayout layout]];
	[[toolbar layout] setItemMargin: 12];

	return toolbar;
}

- (ETLayoutItemGroup *) editor
{
	float width = 800;
	float height = 700;
	ETController *controller = AUTORELEASE([[MarkupEditorController alloc] init]);
	ETLayoutItemGroup *toolbar = [self toolbarWithWidth: width controller: controller];
	ETLayoutItemGroup *editorView = [self editorViewWithSize: NSMakeSize(width, height - [toolbar height]) controller: controller];
	ETLayoutItemGroup *editor = [self itemGroupWithItems: A(toolbar, editorView)];

	[editor setController: controller];
	[editor setSize: NSMakeSize(width, height)];
	[editor setLayout: [ETColumnLayout layout]];
	[editor setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];

	return editor;
}

@end
