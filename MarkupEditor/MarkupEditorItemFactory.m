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
		[layoutObject setDisplayedProperties: 
			A(@"className", @"stringValue", @"description", @"displayName")];
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
	//[[detailLayout contentItem] setLayout: [ETTextEditorLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[detailLayout contentItem] setLayout: [ETOutlineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];

	[layout setBarThickness: 400];
	[[layout barItem] setLayout: [self editorViewLayoutOfClass: [ETOutlineLayout class]]];
	[[layout contentItem] setLayout: detailLayout];

	// TODO: Should probably be transparent
	[editorView setShouldMutateRepresentedObject: YES];
	[editorView setSource: editorView];
	// FIXME: ETAutoresizingFlexibleHeight doesn't work
	[editorView setAutoresizingMask: ETAutoresizingFlexibleWidth];// | ETAutoresizingFlexibleHeight];

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

- (ETLayoutItemGroup *) toolbarWithWidth: (CGFloat)aWidth controller: (ETController *)aController
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
	[toolbar setLayout: [ETLineLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[toolbar layout] setItemMargin: 12];
	[toolbar setAutoresizingMask: ETAutoresizingFlexibleWidth];

	return toolbar;
}

- (ETLayoutItemGroup *) editor
{
	CGFloat width = 800;
	CGFloat height = 700;
	ETController *controller = AUTORELEASE([[MarkupEditorController alloc] init]);
	ETLayoutItemGroup *toolbar = [self toolbarWithWidth: width controller: controller];
	ETLayoutItemGroup *editorView = [self editorViewWithSize: NSMakeSize(width, height - [toolbar height]) controller: controller];
	ETLayoutItemGroup *editor = [self itemGroupWithItems: A(toolbar, editorView)];

	[editor setController: controller];
	[editor setSize: NSMakeSize(width, height)];
	[editor setLayout: [ETColumnLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[editor setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];

	return editor;
}

- (ETLayoutItemGroup *) workspaceWithControllerPrototype: (ETController *)aController
{
	ETController *controller = AUTORELEASE([aController copy]);
	ETLayoutItemGroup *workspace = [self itemGroupWithFrame: NSMakeRect(50, 100, 1000, 700)];

	// TODO: We should set the controller on the workspace rather the bar item
	//[workspace setController: controller;

	[workspace setLayout: [ETPaneLayout masterDetailLayout]];
	[[workspace layout] setBarThickness: 200];
	[[workspace layout] setBarPosition: ETPanePositionLeft];
	[[workspace layout] setEnsuresContentFillsVisibleArea: YES];

	//[[[workspace layout] barItem] setLayout: [ETFlowLayout layoutWithObjectGraphContext: [self objectGraphContext]]];
	[[[workspace layout] barItem] setController: controller];

	return workspace;
}

// TODO: This method is used by -registerLayout: in -applicationDidFinishLaunching but the registered 
// prototypes is ignored. We currently use an explicit to get it visible in 
// the layout popup menu of the inspector.
// Once we get the aspect repository, we won't require the explicit class which 
// duplicates the code below.
- (ETCompositeLayout *) editorLayout
{
	ETLayoutItemGroup *editor = [self editor];
	id documentContent = [editor itemForIdentifier: @"documentContent"];
	return [[ETCompositeLayout alloc] initWithRootItem: editor
	                             firstPresentationItem: documentContent];
}

@end

@implementation MarkupEditorLayout

- (id) initWithRootItem: (ETLayoutItemGroup *)rootItem 
  firstPresentationItem: (ETLayoutItemGroup *)targetItem
{
	ETLayoutItemGroup *editor = [[MarkupEditorItemFactory factory] editor];
	id documentContent = [editor itemForIdentifier: @"documentContent"];
	return [super initWithRootItem: editor firstPresentationItem: documentContent];
}

@end
