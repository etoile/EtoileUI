/*
	EtoileUI.h
	
	Umbrella header for EtoileUI framework.
 
	Copyright (C) 2007 Quentin Mathe
 
	Authors:  Quentin Mathe <qmathe@club-internet.fr>

	Date:  July 2007
 
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

#import <EtoileUI/ETCompatibility.h>
#import <EtoileUI/ETGeometry.h>

#import <EtoileUI/NSObject+EtoileUI.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/NSWindow+Etoile.h>
#import <EtoileUI/NSImage+Etoile.h>
#import <EtoileUI/Controls+Etoile.h>
#import <EtoileUI/ETObjectRegistry+EtoileUI.h>
#import <EtoileUI/ETInspecting.h>

#import <EtoileUI/ETApplication.h>
#import <EtoileUI/ETLayoutItemBuilder.h>
#import <EtoileUI/ETPickboard.h>

#import <EtoileUI/ETStyle.h>
#import <EtoileUI/ETShape.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETContainers.h>
#import <EtoileUI/ETController.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETLayoutItem+Reflection.h>
#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutItemGroup+Mutation.h>
#import <EtoileUI/ETLayoutItem+Factory.h>
#import <EtoileUI/ETLayer.h>
#import <EtoileUI/ETWindowItem.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETLayoutLine.h>

#import <EtoileUI/ETComputedLayout.h>
#import <EtoileUI/ETFlowLayout.h>
#import <EtoileUI/ETLineLayout.h>
#import <EtoileUI/ETStackLayout.h>

#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETOutlineLayout.h>
#import <EtoileUI/ETBrowserLayout.h>
#import <EtoileUI/FSBrowserCell.h>

#import <EtoileUI/ETPaneLayout.h>
//#import <EtoileUI/ETPaneView.h>
#import <EtoileUI/ETPaneSwitcherLayout.h>

#import <EtoileUI/ETFreeLayout.h>

#import <EtoileUI/ETObjectBrowserLayout.h>
#import <EtoileUI/ETViewModelLayout.h>
#import <EtoileUI/ETTextEditorLayout.h>
#import <EtoileUI/ETInspector.h>

#ifdef COREOBJECT
#import <EtoileUI/ETPersistencyController.h>
#endif
