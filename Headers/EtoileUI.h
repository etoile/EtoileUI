/**
 	Umbrella header for EtoileUI framework.

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2007
	License: Modified BSD (see COPYING)
 */

#import <EtoileUI/ETCompatibility.h>

/* Additions */

#import <EtoileUI/EtoileUIProperties.h>
#import <EtoileUI/ETItemValueTransformer.h>
#import <EtoileUI/ETGeometry.h>
#import <EtoileUI/ETLineFragment.h>
#import <EtoileUI/NSObject+EtoileUI.h>
#import <EtoileUI/ETObjectValueFormatter.h>

/* Graphics Backend */

#import <EtoileUI/ETGraphicsBackend.h>

/* Base */

#import <EtoileUI/ETApplication.h>
#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETFragment.h>
#import <EtoileUI/ETResponder.h>
#import <EtoileUI/ETUIObject.h>
#import <EtoileUI/ETUIItem.h>
#import <EtoileUI/ETUIStateRestoration.h>
#import <EtoileUI/ETWidget.h>

/* Decorator Items */

#import <EtoileUI/ETDecoratorItem.h>
#import <EtoileUI/ETScrollableAreaItem.h>
#import <EtoileUI/ETTitleBarItem.h>
#import <EtoileUI/ETWindowItem.h>

/* Layout Items */

#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+KVO.h>
#import <EtoileUI/ETLayoutItem+Scrollable.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutItemGroup+Mutation.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/ETSelectionAreaItem.h>

/* Item Factory */

#import <EtoileUI/ETLayoutItemFactory.h>
#import <EtoileUI/ETLayoutItemFactory+UIPatternAdditions.h>

/* Styles */

#import <EtoileUI/ETBasicItemStyle.h>
#import <EtoileUI/ETShape.h>
#import <EtoileUI/ETStyle.h>
#import <EtoileUI/ETStyleGroup.h>

/* Layouts */

#import <EtoileUI/ETBrowserLayout.h>
#import <EtoileUI/ETColumnLayout.h>
#import <EtoileUI/ETCompositeLayout.h>
#import <EtoileUI/ETComputedLayout.h>
#import <EtoileUI/ETFixedLayout.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/ETFormLayout.h>
#import <EtoileUI/ETFreeLayout.h>
#import <EtoileUI/ETIconLayout.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETLineLayout.h>
#import <EtoileUI/ETOutlineLayout.h>
#import <EtoileUI/ETPaneLayout.h>
#import <EtoileUI/ETPositionalLayout.h>
#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETTemplateItemLayout.h>
#import <EtoileUI/ETTextEditorLayout.h>
#import <EtoileUI/ETTokenLayout.h>

/* Tools */

#import <EtoileUI/ETArrowTool.h>
#import <EtoileUI/ETMoveTool.h>
#import <EtoileUI/ETTool.h>
#import <EtoileUI/ETPaintBucketTool.h>
#import <EtoileUI/ETSelectTool.h>

/* Action Handlers & Coordinators */

#import <EtoileUI/ETActionHandler.h>
#import <EtoileUI/ETPaintActionHandler.h>
#import <EtoileUI/ETPickDropActionHandler.h>
#import <EtoileUI/ETPickDropCoordinator.h>

/* Controllers */

#import <EtoileUI/ETController.h>
#import <EtoileUI/ETDocumentController.h>
#import <EtoileUI/ETItemTemplate.h>
#import <EtoileUI/ETNibOwner.h>

/* Tree Transforms */

#import <EtoileUI/ETLayoutItemBuilder.h>
#import <EtoileUI/ETModelDescriptionRenderer.h>

/* Aspect Repository */

#import <EtoileUI/ETAspectCategory.h>
#import <EtoileUI/ETAspectRepository.h>

/* Core Object */

#ifdef COREOBJECT
#import <EtoileUI/ETLayoutItem+CoreObject.h>
#endif

/* UI Builder */

#import <EtoileUI/ETLayoutItem+UIBuilder.h>
#import <EtoileUI/ETUIBuilderItemFactory.h>
