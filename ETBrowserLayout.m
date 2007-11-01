/*
	ETBrowserLayout.m
	
	Description forthcoming.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <EtoileUI/ETBrowserLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

#import <EtoileUI/FSBrowserCell.h>


#define DEFAULT_ROW_HEIGHT 20

/** ETBrowserLayout wraps AppKit NSBrowser control in term of Container archictecture.
	ETBrowserLayout uses by default a custom NSBrowser that displays icon and 
	text in column rows. If you prefer a different style of row, you can 
	replace ETBrowserCell by your own subclass of NSBrowserCell.
	Defaults settings of ETBrowserLayout are:
	- 130 px column width
	- four visible columns max
	- no column titles
	- double-click replaces the path displayed in browser by putting the 
	  content of double-clicked item in column zero.
      Example:
	  /Applications/Fusion.app/Resources
	  If you double-click 'Resources', the browser path is reset to '/' but
	  this root path is now referencing '/Applications/Fusion.app/Resources' 
	  and not '/'. In other words, the browser doesn't display the
	  whole path anymore but only a portion.    
	  Model encapsulated by ETLayoutItem instances is accessed through the 
	properties classified by decreasing priority order:
	- 'name', 'value' for text part of the row
	- 'icon', 'image' for icon part of the row
	
	NOTE: row resizing based on -[ETContainer itemScaleFactor] isn't yet 
	supported.
*/


@implementation ETBrowserLayout

- (NSString *) nibName
{
	return @"BrowserPrototype";
}

- (void) awakeFromNib
{
	//ETLog(@"Awaking from nib for %@", self);
	
	/* Because this outlet will be removed from its superview, it must be 
	   retained like any other to-one relationship ivars. 
	   If this proto view is later replaced by calling 
	   -setLayoutView:, this retain will be balanced by the release
	   in ASSIGN. */ 
	RETAIN(_displayViewPrototype);

	/* Adjust _displayViewPrototype outlet */
	[self setLayoutView: _displayViewPrototype];
}

- (void) setLayoutView: (NSView *)protoView
{
	[super setLayoutView: protoView];

	NSBrowser *browser = [self browser];
	
	[browser setCellClass: [FSBrowserCell class]];
	[browser setCellPrototype: AUTORELEASE([[FSBrowserCell alloc] init])];
	[browser setAction: @selector(click:)];
	[browser setDoubleAction: @selector(doubleClick:)];
	[browser setTarget: self];
	
	if ([browser delegate] == nil)
		[browser setDelegate: self];
}

- (NSBrowser *) browser
{
	return (NSBrowser *)[self layoutView];
}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items
{
	NSBrowser *browserView = [self browser];
	
	[self setUpLayoutView];
	
	// FIXME: Implement browser cell scaling to get 
	// -resizeLayoutItems:toScaleFactor: works as expected
	//[self resizeLayoutItems: items toScaleFactor: [[self layoutContext] itemScaleFactor]];
	
	if ([browserView delegate] == nil)
		[browserView setDelegate: self];
	// FIXME: The next lines shouldn't be needed but
	// -[ETContainer syncDisplayViewWithContainer] regularly overwrites what have
	// been set in -setLayoutView:
	[browserView setDoubleAction: @selector(doubleClick:)];
	[browserView setAction: @selector(click:)];
	[browserView setTarget: self];		

	// NOTE: -loadColumnZero reloads browser context unlike -setPath: @"/"
	[browserView loadColumnZero];
}

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	// NOTE: Always recompute row height from the original one to avoid really
	// value shifting quickly because of rounding.
	//float rowHeight = DEFAULT_ROW_HEIGHT * factor;
	int numberOfCols = [[self browser] numberOfVisibleColumns];
	NSMatrix *columnMatrix = nil;

	for (int i = 0; i < numberOfCols; i++)
	{
		NSSize newCellSize = NSZeroSize;
		
		columnMatrix = [[self browser] matrixInColumn: i];
		if (columnMatrix != nil)
		{
			newCellSize = [columnMatrix cellSize];
			newCellSize.height = DEFAULT_ROW_HEIGHT * factor;
			[columnMatrix setCellSize: newCellSize];
			NSLog(@"Resize %@ cell size from %@ to %@", columnMatrix, 
				NSStringFromSize([columnMatrix cellSize]), 
				NSStringFromSize(newCellSize));
		}
	}
}

/* Selection */

// FIXME: Implements multiple selection support and sets selection by calling
// -setSelectionIndexPaths:. 
- (BOOL) browser: (NSBrowser *)sender selectCellWithString: (NSString *)title inColumn: (int)column
{
	id delegate = [[self container] delegate];
	BOOL selected = YES;
	NSString *path = [[sender pathToColumn: column] stringByAppendingPathComponent: title];
	ETLayoutItem *item = [[self layoutContext] itemAtPath: path];
	
	if ([delegate respondsToSelector: @selector(browser:selectCellWithString:inColumn:)])
	{
		selected = [delegate browser: sender selectCellWithString: title inColumn: column];
	}
	
	if (selected)
	{
		int row = [[self container] indexOfItem: item];

		// NOTE: Not really sure that's the best way to do it		
		[[self container] setSelectionIndex: row];
	}
	
	return selected;
}

// FIXME: Implements multiple selection support and sets selection by calling
// -setSelectionIndexPaths:. 
// [sender selectedCells]; is probably helpful.
- (BOOL) browser: (NSBrowser *)sender selectRow: (int)row inColumn: (int)column
{
	id delegate = [[self container] delegate];
	BOOL selected = YES;
	
	if ([delegate respondsToSelector: @selector(browser:selectRow:inColumn:)])
	{
		selected = [delegate browser: sender selectRow: row inColumn: column];
	}
	
	// NOTE: Not really sure that's the best way to do it
	[[self container] setSelectionIndex: row];
	
	return selected;
}

/* Data Source */

- (int) browser: (NSBrowser *)sender numberOfRowsInColumn: (int)column
{
	NSString *path = [sender pathToColumn: column];
	ETLayoutItemGroup *item = nil;
	int nbOfItems = 0;
	
	if (path == nil || [path isEqual: @""])
		path = @"/";

	item = (ETLayoutItemGroup *)[[self layoutContext] itemAtPath: path];
	NSAssert(item != nil, @"Parent item must never be nil in -browser:numberOfRowsInColumn:");
	NSAssert([item isGroup], @"Parent item "
		@"must always be of ETLayoutItemGroup class kind");
	
	nbOfItems = [[item items] count];	
	/* First time */
	if (nbOfItems == 0)
	{
		[item reload];
		nbOfItems = [[item items] count];	
	}
	
	//ETLog(@"Returns %d as number of items in browser view %@", nbOfItems, sender);
	
	return nbOfItems;
}

- (void) browser: (NSBrowser *)sender willDisplayCell: (id)cell atRow: (int)row column: (int)column
{
	NSString *path = [sender pathToColumn: column];
	ETLayoutItemGroup *item = nil;
	ETLayoutItem *childItem = nil;
	
	if (path == nil || [path isEqual: @""])
		path = @"/";

	item = (ETLayoutItemGroup *)[[self layoutContext] itemAtPath: path];
	NSAssert(item != nil, @"Parent item must never be nil in -browser:numberOfRowsInColumn:");
	NSAssert([item isGroup], @"Parent item "
		@"must always be of ETLayoutItemGroup class kind");

	childItem = [item itemAtIndex: row];
	if ([childItem isGroup])
	{
		[cell setLeaf: NO];
	}
	else
	{
		[cell setLeaf: YES];
	}
	
	//NSLog(@"Returns %@ as object value in browser view %@", [item valueForProperty: @"name"], sender);
	
	[cell setStringValue: [childItem valueForProperty: @"name"]];

	if ([cell isKindOfClass: [NSBrowserCell class]])
	{
		NSImage *icon = [childItem valueForProperty: @"icon"];
		NSSize cellSize = [[sender matrixInColumn: column] cellSize];
		NSSize updatedIconSize = [icon size];
		
		/* Take care to resize image of brower cell to cell size computed by 
		   -resizeLayoutItems:toScaleFactor: */
		if ([cell isKindOfClass: [FSBrowserCell class]])
		{
			[cell setIconImage: icon];
		}
		else /* NSBrowserCell and other subclasses */
		{
			updatedIconSize.height = cellSize.height;
			updatedIconSize.width = updatedIconSize.height;
			[icon setSize: updatedIconSize];
			[cell setImage: icon];
		}
	}
}

/* Actions */

/* NSBrowser action */
- (IBAction) click: (id)sender
{
	int row = [sender selectedRowInColumn: [sender selectedColumn]];
	
	ETLog(@"-click: row %d and column %d in %@", row, [sender selectedColumn], self);
	
	[[self container] setSelectionIndex: row];
}

- (IBAction) doubleClick: (id)sender
{
	int row = [sender selectedRowInColumn: [sender selectedColumn]];
	
	ETLog(@"-doubleClick: row %d and column %d in %@", row, [sender selectedColumn], self);
	
	[[NSApplication sharedApplication] sendAction: [[self container] doubleAction] 
	                                           to: [[self container] target] 
											  from: sender];
}

- (ETLayoutItem *) doubleClickedItem
{
	NSString *path = [[self browser] path];
	ETLayoutItem *item = [[self layoutContext] itemAtPath: path];
	
	NSLog(@"-doubleClickedItem %@ in %@ with browser path %@", item, self, path);
	
	return item;
}

@end


// FIXME: We should remove this hack to simulate we are a scrollview.
@interface NSBrowser (EtoileETBrowserLayout)
- (NSView *) documentView;
@end

@implementation NSBrowser (EtoileETBrowserLayout)

/* ETContainer expects -displayView to be a scroll view, so we fake NSBrowser 
   to respond like NSScrollView. See -[ETContainer syncDisplayViewWithContainer] */
- (NSView *) documentView
{
	return self;
}

@end

//
// Unused NSBrowser data source implementation
//

#if 0
- (void) browser:(NSBrowser *)sender createRowsForColumn: (int)column inMatrix: (NSMatrix *)matrix
{
	NSString *path = [sender pathToColumn: column];
	NSIndexPath *indexPath = nil;
	ETContainer *container = [self container];
	int count = 0;
	
	if (path == nil || [path isEqual: @""])
		path = @"/";
	
	indexPath = [[container layoutItem] indexPathForPath: path];
	NSAssert(indexPath != nil, @"Index path must never be nil in -browser:numberOfRowsInColumn:");
	
	count = [[container source] container: container numberOfItemsAtPath: indexPath];
	
	NSLog(@"Returns %d as number of items in browser view %@", count, sender);
	
	//NSMutableArray *columnCells = [NSMutableArray array];
	NSSize newCellSize = [matrix cellSize];
	
	for (int i = 0; i < count; i ++)
		[matrix putCell: [[sender cellPrototype] copy] atRow: i column: column];
	
	//NSLog(@"Adds column cells %@ based on %@", columnCells, [[sender cellPrototype] copy]);
	
	// NOTE: Unable to make -addColumnWithCells: work so -putCell:atRow:column 
	// is used instead
	//[matrix addColumnWithCells: columnCells];
	
	newCellSize.height = DEFAULT_ROW_HEIGHT * [container itemScaleFactor];
	NSLog(@"Resize %@ cell size from %@ to %@", matrix, 
				NSStringFromSize([matrix cellSize]), 
				NSStringFromSize(newCellSize));
	[matrix setCellSize: newCellSize];
}
#endif
