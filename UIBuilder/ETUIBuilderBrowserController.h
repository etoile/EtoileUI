/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETController.h>

@class ETAspectRepository, ETItemValueTransformer, ETUIBuilderController;
@protocol ETUIBuilderEditionCoordinator;

/** @group UI Builder
 
@abstract Controller for the UI builder object browser. */
@interface ETUIBuilderBrowserController : ETController
{

}

@property (nonatomic, readonly) ETUIBuilderController *parentController;

/** @taskunit Editing */

/** Returns -parentController. */
@property (nonatomic, readonly) id <ETUIBuilderEditionCoordinator> editionCoordinator;

@end
