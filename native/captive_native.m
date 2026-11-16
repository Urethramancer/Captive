/* Original implementation; no Pinball source or assets are used. */
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#include <math.h>
#include <mach-o/dyld.h>
#include <stdlib.h>
#include <string.h>
#include "captive_native.h"

@interface CaptiveCommand : NSObject
@property int kind;
@property NSRect rect;
@property NSRect source;
@property uint32_t rgba;
@property double size;
@property(copy) NSString *text;
@property(strong) id image;
@end
@implementation CaptiveCommand
@end

@interface CaptiveVoice : NSObject
@property(strong) AVAudioPlayerNode *node;
@property uint64_t generation;
@property BOOL busy;
@end
@implementation CaptiveVoice
@end

@interface CaptiveSound : NSObject
@property(strong) NSData *pcm;
@property int rate;
@end
@implementation CaptiveSound
@end

@class CaptiveController;
@interface CaptiveView : NSView
@property(weak) CaptiveController *controller;
@property(strong) NSTrackingArea *tracking;
@end
@interface CaptiveController : NSObject <NSWindowDelegate, NSApplicationDelegate, NSMenuItemValidation> {
@public
	CaptiveEvent events[128];
	unsigned readEvent, writeEvent;
}
@property(strong) NSWindow *window;
@property(strong) CaptiveView *view;
@property(strong) NSMutableArray<CaptiveCommand *> *commands;
@property(copy) NSArray<CaptiveCommand *> *frame;
@property(strong) NSMutableArray *images;
@property(strong) AVAudioEngine *engine;
@property(strong) NSMutableArray<CaptiveVoice *> *voices;
@property(strong) NSMutableArray<CaptiveSound *> *sounds;
@property(strong) NSMutableDictionary<NSString *, NSNumber *> *soundPaths;
@property(copy) NSString *error;
@property uint32_t background;
@property uint32_t frameBackground;
@property BOOL closed;
@property BOOL paused;
@property BOOL fullscreenTransition;
- (void)push:(CaptiveEvent)event;
- (NSPoint)logicalPoint:(NSPoint)point;
- (void)requestClose;
- (void)toggleFullscreen:(id)sender;
@end

static NSColor *colour(uint32_t rgba)
{
	return [NSColor colorWithSRGBRed:((rgba >> 24) & 255) / 255.0
		green:((rgba >> 16) & 255) / 255.0 blue:((rgba >> 8) & 255) / 255.0
		alpha:(rgba & 255) / 255.0];
}
static int key(unsigned short code)
{
	switch (code) {
	case 13: return CAPTIVE_KEY_W; case 1: return CAPTIVE_KEY_S;
	case 0: return CAPTIVE_KEY_A; case 2: return CAPTIVE_KEY_D;
	case 12: return CAPTIVE_KEY_Q; case 14: return CAPTIVE_KEY_E;
	case 53: return CAPTIVE_KEY_ESCAPE; case 122: return CAPTIVE_KEY_F1;
	case 120: return CAPTIVE_KEY_F2; case 99: return CAPTIVE_KEY_F3;
	case 118: return CAPTIVE_KEY_F4; case 96: return CAPTIVE_KEY_F5;
	case 101: return CAPTIVE_KEY_F9; case 36: return CAPTIVE_KEY_ENTER;
	case 49: return CAPTIVE_KEY_SPACE; default: return CAPTIVE_KEY_UNKNOWN;
	}
}
@implementation CaptiveController
- (void)push:(CaptiveEvent)event
{
	if (event.kind == 7 && writeEvent != readEvent && events[(writeEvent - 1) % 128].kind == 7) {
		events[(writeEvent - 1) % 128] = event;
		return;
	}
	if (writeEvent - readEvent == 128) {
		/* Clear stale held controls when the consumer falls behind. */
		readEvent = writeEvent;
		events[writeEvent++ % 128] = (CaptiveEvent){.kind = 6};
	}
	events[writeEvent++ % 128] = event;
}
- (NSPoint)logicalPoint:(NSPoint)point
{
	double scale = fmin(self.view.bounds.size.width / 1280.0, self.view.bounds.size.height / 800.0);
	if (scale <= 0) return NSMakePoint(-1, -1);
	return NSMakePoint((point.x - (self.view.bounds.size.width - 1280 * scale) / 2) / scale,
		(point.y - (self.view.bounds.size.height - 800 * scale) / 2) / scale);
}
- (void)requestClose
{
	if (self.closed) return;
	self.closed = YES;
	[self push:(CaptiveEvent){.kind = 5}];
	if (NSApp.modalWindow) [NSApp abortModal];
	[self.window orderOut:nil];
}
- (BOOL)windowShouldClose:(NSWindow *)sender
{
	(void)sender;
	[self requestClose];
	return YES;
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	(void)sender;
	[self requestClose];
	// Let the Meh loop unwind and release the window and audio engine.
	return NSTerminateCancel;
}
- (void)toggleFullscreen:(id)sender
{
	(void)sender;
	if (self.closed || self.fullscreenTransition) return;
	self.fullscreenTransition = YES;
	[self.window toggleFullScreen:nil];
}
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if (item.action == @selector(toggleFullscreen:)) {
		item.title = (self.window.styleMask & NSWindowStyleMaskFullScreen)
			? @"Exit Full Screen" : @"Enter Full Screen";
		return !self.closed && !self.fullscreenTransition;
	}
	return !self.closed;
}
- (void)windowWillEnterFullScreen:(NSNotification *)notification { (void)notification; self.fullscreenTransition = YES; }
- (void)windowWillExitFullScreen:(NSNotification *)notification { (void)notification; self.fullscreenTransition = YES; }
- (void)windowDidEnterFullScreen:(NSNotification *)notification { (void)notification; self.fullscreenTransition = NO; }
- (void)windowDidExitFullScreen:(NSNotification *)notification { (void)notification; self.fullscreenTransition = NO; }
- (void)windowDidFailToEnterFullScreen:(NSWindow *)window { (void)window; self.fullscreenTransition = NO; }
- (void)windowDidFailToExitFullScreen:(NSWindow *)window { (void)window; self.fullscreenTransition = NO; }
- (void)windowDidResignKey:(NSNotification *)notification
{
	(void)notification;
	[self push:(CaptiveEvent){.kind = 6}];
}
@end

@implementation CaptiveView
- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (void)updateTrackingAreas
{
	if (self.tracking) [self removeTrackingArea:self.tracking];
	self.tracking = [[NSTrackingArea alloc] initWithRect:NSZeroRect
		options:NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect owner:self userInfo:nil];
	[self addTrackingArea:self.tracking];
	[super updateTrackingAreas];
}
- (void)keyDown:(NSEvent *)event
{
	if (event.keyCode == 53 && event.isARepeat) return;
	if (event.keyCode == 53 && (self.window.styleMask & NSWindowStyleMaskFullScreen)) {
		[self.controller toggleFullscreen:nil];
		return;
	}
	if (event.modifierFlags & NSEventModifierFlagCommand) {
		if ([event.charactersIgnoringModifiers.lowercaseString isEqualToString:@"a"])
			[self.controller push:(CaptiveEvent){.kind = 8, .code = 1}];
		else [super keyDown:event];
		return;
	}
	[self.controller push:(CaptiveEvent){.kind = 1, .code = key(event.keyCode), .repeat = event.isARepeat}];
	int text = 0;
	switch (event.keyCode) {
		case 36: case 76: text = 13; break;
		case 53: text = 27; break;
		case 51: text = 8; break;
		case 117: text = 127; break;
		case 123: text = 28; break;
		case 124: text = 29; break;
		case 115: text = 30; break;
		case 119: text = 31; break;
		default: if (event.characters.length == 1) text = [event.characters characterAtIndex:0]; break;
	}
	if (text) [self.controller push:(CaptiveEvent){.kind = 8, .code = text, .repeat = event.isARepeat}];
}
- (void)keyUp:(NSEvent *)event
{
	[self.controller push:(CaptiveEvent){.kind = 2, .code = key(event.keyCode)}];
}
- (void)mouse:(NSEvent *)event kind:(int)kind
{
	NSPoint point = [self.controller logicalPoint:[self convertPoint:event.locationInWindow fromView:nil]];
	[self.controller push:(CaptiveEvent){.kind = kind, .code = (int)event.buttonNumber, .x = point.x, .y = point.y, .repeat = event.clickCount >= 2}];
}
- (void)mouseDown:(NSEvent *)event { [self mouse:event kind:3]; }
- (void)mouseUp:(NSEvent *)event { [self mouse:event kind:4]; }
- (void)rightMouseDown:(NSEvent *)event { [self mouse:event kind:3]; }
- (void)rightMouseUp:(NSEvent *)event { [self mouse:event kind:4]; }
- (void)mouseMoved:(NSEvent *)event { [self mouse:event kind:7]; }
- (void)drawRect:(NSRect)dirtyRect
{
	(void)dirtyRect;
	[[NSColor blackColor] setFill];
	NSRectFill(self.bounds);
	double scale = fmin(self.bounds.size.width / 1280.0, self.bounds.size.height / 800.0);
	if (scale <= 0) return;
	[NSGraphicsContext saveGraphicsState];
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:(self.bounds.size.width - 1280 * scale) / 2
		yBy:(self.bounds.size.height - 800 * scale) / 2];
	[transform scaleBy:scale];
	[transform concat];
	NSRectClip(NSMakeRect(0, 0, 1280, 800));
	[colour(self.controller.frameBackground) setFill];
	NSRectFill(NSMakeRect(0, 0, 1280, 800));
	for (CaptiveCommand *command in self.controller.frame) {
		if (command.kind == 1) {
			[colour(command.rgba) setFill];
			NSRectFillUsingOperation(command.rect, NSCompositingOperationSourceOver);
		} else if (command.kind == 2) {
			[command.text drawAtPoint:command.rect.origin withAttributes:@{
				NSFontAttributeName: [NSFont monospacedSystemFontOfSize:command.size weight:NSFontWeightRegular],
				NSForegroundColorAttributeName: colour(command.rgba)}];
		} else if (command.kind == 3) {
			NSImage *image = command.image;
			NSSize size = image.size;
			NSImageInterpolation interpolation = size.width <= 320 && size.height <= 200
				? NSImageInterpolationNone : NSImageInterpolationHigh;
			NSRect source = command.source;
			if (!NSEqualRects(source, NSZeroRect)) source = NSMakeRect(source.origin.x * size.width,
				(1 - source.origin.y - source.size.height) * size.height,
				source.size.width * size.width, source.size.height * size.height);
			[image drawInRect:command.rect fromRect:source operation:NSCompositingOperationSourceOver
				fraction:1 respectFlipped:YES hints:@{NSImageHintInterpolation: @(interpolation)}];
		}
	}
	[NSGraphicsContext restoreGraphicsState];
}
@end

static CaptiveController *controller(CaptiveHost *host) { return (__bridge CaptiveController *)host; }
static void failure(CaptiveController *host, NSString *message)
{
	host.error = message;
	fprintf(stderr, "Captive native: %s\n", message.UTF8String);
}
CaptiveHost *captive_host_create(const char *title)
{
	if (![NSThread isMainThread]) return NULL;
	@autoreleasepool {
		[NSApplication sharedApplication];
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
		CaptiveController *host = [CaptiveController new];
		host.commands = [NSMutableArray new];
		host.images = [NSMutableArray new];
		host.voices = [NSMutableArray new];
		host.sounds = [NSMutableArray new];
		host.soundPaths = [NSMutableDictionary new];
		host.error = @"";
		host.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1280, 800)
			styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
			backing:NSBackingStoreBuffered defer:NO];
		if (!host.window) return NULL;
		host.window.releasedWhenClosed = NO;
		host.window.title = title ? [NSString stringWithUTF8String:title] ?: @"Captive" : @"Captive";
		host.window.contentMinSize = NSMakeSize(640, 400);
		host.window.acceptsMouseMovedEvents = YES;
		host.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
		host.window.delegate = host;
		NSApp.delegate = host;
		NSMenu *menu = [NSMenu new];
		NSMenuItem *appItem = [menu addItemWithTitle:@"Captive" action:NULL keyEquivalent:@""];
		appItem.submenu = [[NSMenu alloc] initWithTitle:@"Captive"];
		NSMenuItem *quit = [appItem.submenu addItemWithTitle:@"Quit Captive" action:@selector(terminate:) keyEquivalent:@"q"];
		quit.target = NSApp;
		NSMenuItem *fileItem = [menu addItemWithTitle:@"File" action:NULL keyEquivalent:@""];
		fileItem.submenu = [[NSMenu alloc] initWithTitle:@"File"];
		NSMenuItem *close = [fileItem.submenu addItemWithTitle:@"Close Window" action:@selector(performClose:) keyEquivalent:@"w"];
		close.target = host.window;
		NSMenuItem *viewItem = [menu addItemWithTitle:@"View" action:NULL keyEquivalent:@""];
		viewItem.submenu = [[NSMenu alloc] initWithTitle:@"View"];
		NSMenuItem *fullscreen = [viewItem.submenu addItemWithTitle:@"Enter Full Screen" action:@selector(toggleFullscreen:) keyEquivalent:@"f"];
		fullscreen.keyEquivalentModifierMask = NSEventModifierFlagControl | NSEventModifierFlagCommand;
		fullscreen.target = host;
		NSApp.mainMenu = menu;
		host.view = [[CaptiveView alloc] initWithFrame:NSMakeRect(0, 0, 1280, 800)];
		host.view.controller = host;
		host.window.contentView = host.view;
		[host.window center];
		[host.window makeKeyAndOrderFront:nil];
		[host.window makeFirstResponder:host.view];
		[NSApp finishLaunching];
		[NSApp activateIgnoringOtherApps:YES];
		return (__bridge_retained CaptiveHost *)host;
	}
}
void captive_host_destroy(CaptiveHost *handle)
{
	@autoreleasepool {
		if (!handle) return;
		CaptiveController *host = (__bridge_transfer CaptiveController *)handle;
		captive_audio_clear((__bridge CaptiveHost *)host);
		[host.engine stop];
		host.window.delegate = nil;
		if (NSApp.delegate == host) { NSApp.delegate = nil; NSApp.mainMenu = nil; }
		host.view.controller = nil;
		[host.window close];
	}
}
const char *captive_host_error(CaptiveHost *host) { return host ? controller(host).error.UTF8String : "No native host"; }
int32_t captive_host_pump(CaptiveHost *handle)
{
	if (!handle) return 0;
	@autoreleasepool {
		NSEvent *event;
		while (!controller(handle).closed && (event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:[NSDate distantPast]
			inMode:NSDefaultRunLoopMode dequeue:YES])) [NSApp sendEvent:event];
		[NSApp updateWindows];
		return !controller(handle).closed;
	}
}
int32_t captive_host_event(CaptiveHost *handle, CaptiveEvent *event)
{
	if (!handle || !event) return 0;
	CaptiveController *host = controller(handle);
	if (host->readEvent == host->writeEvent) return 0;
	*event = host->events[host->readEvent++ % 128];
	return 1;
}
void captive_host_fullscreen(CaptiveHost *host)
{
	@autoreleasepool {
		if (host) [controller(host) toggleFullscreen:nil];
	}
}
int32_t captive_host_is_fullscreen(CaptiveHost *host)
{
	return host && (controller(host).window.styleMask & NSWindowStyleMaskFullScreen) != 0;
}
double captive_mouse_x(CaptiveHost *handle)
{
	if (!handle) return -1;
	CaptiveController *host = controller(handle);
	NSPoint point = [host.view convertPoint:host.window.mouseLocationOutsideOfEventStream fromView:nil];
	return [host logicalPoint:point].x;
}
double captive_mouse_y(CaptiveHost *handle)
{
	if (!handle) return -1;
	CaptiveController *host = controller(handle);
	NSPoint point = [host.view convertPoint:host.window.mouseLocationOutsideOfEventStream fromView:nil];
	return [host logicalPoint:point].y;
}
const char *captive_resources(void)
{
	@autoreleasepool {
		static char *path;
		if (!path) {
			NSBundle *bundle = NSBundle.mainBundle;
			NSString *resources = [bundle.bundlePath.pathExtension isEqualToString:@"app"] ? bundle.resourcePath : @"";
			path = strdup(resources.UTF8String);
		}
		return path ?: "";
	}
}
const char *captive_executable_directory(void)
{
	@autoreleasepool {
		static char *directory;
		if (!directory) {
			uint32_t size = 0;
			_NSGetExecutablePath(NULL, &size);
			if (!size || size > 1048576) return "";
			char *path = malloc(size);
			if (!path) return "";
			if (_NSGetExecutablePath(path, &size) == 0) {
				NSString *executable = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];
				NSString *parent = executable.stringByResolvingSymlinksInPath.stringByDeletingLastPathComponent;
				directory = strdup(parent.UTF8String);
			}
			free(path);
		}
		return directory ?: "";
	}
}
void captive_frame_begin(CaptiveHost *handle, uint32_t rgba)
{
	@autoreleasepool {
		if (!handle) return;
		CaptiveController *host = controller(handle);
		[host.commands removeAllObjects];
		host.background = rgba;
	}
}
static CaptiveCommand *command(CaptiveHost *handle, int kind, NSRect rect)
{
	if (!handle || controller(handle).commands.count >= 8192 || !isfinite(rect.origin.x) || !isfinite(rect.origin.y)
		|| !isfinite(rect.size.width) || !isfinite(rect.size.height)) return nil;
	CaptiveCommand *item = [CaptiveCommand new];
	item.kind = kind;
	item.rect = rect;
	[controller(handle).commands addObject:item];
	return item;
}
void captive_frame_rect(CaptiveHost *host, double x, double y, double w, double h, uint32_t rgba)
{
	@autoreleasepool {
		command(host, 1, NSMakeRect(x, y, w, h)).rgba = rgba;
	}
}
void captive_frame_text(CaptiveHost *host, const char *utf8, double x, double y, double size, uint32_t rgba)
{
	@autoreleasepool {
		if (!utf8 || !isfinite(size) || size < 1 || size > 512) return;
		NSString *text = [NSString stringWithUTF8String:utf8];
		if (!text || text.length > 16384) return;
		CaptiveCommand *item = command(host, 2, NSMakeRect(x, y, 0, 0));
		item.text = text;
		item.size = size;
		item.rgba = rgba;
	}
}
int32_t captive_image_load(CaptiveHost *handle, const char *path)
{
	@autoreleasepool {
		if (!handle || !path) return 0;
		CaptiveController *host = controller(handle);
		NSString *file = [NSString stringWithUTF8String:path];
		if (!file || host.images.count >= 1024) return 0;
		CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:file], NULL);
		CGImageRef image = source ? CGImageSourceCreateImageAtIndex(source, 0, NULL) : NULL;
		if (source) CFRelease(source);
		if (!image) { failure(host, [@"Cannot load image: " stringByAppendingString:file]); return 0; }
		NSImage *native = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
		CGImageRelease(image);
		[host.images addObject:native];
		return (int32_t)host.images.count;
	}
}
void captive_frame_image(CaptiveHost *host, int32_t image, double x, double y, double w, double h)
{
	@autoreleasepool {
		if (!host || image < 1 || (NSUInteger)image > controller(host).images.count) return;
		command(host, 3, NSMakeRect(x, y, w, h)).image = controller(host).images[image - 1];
	}
}
void captive_frame_crop(CaptiveHost *host, int32_t image, double sx, double sy, double sw, double sh,
	double x, double y, double w, double h)
{
	@autoreleasepool {
		if (!host || image < 1 || (NSUInteger)image > controller(host).images.count
			|| !isfinite(sx) || !isfinite(sy) || !isfinite(sw) || !isfinite(sh)
			|| sx < 0 || sy < 0 || sw <= 0 || sh <= 0 || sx + sw > 1.000001 || sy + sh > 1.000001) return;
		CaptiveCommand *item = command(host, 3, NSMakeRect(x, y, w, h));
		item.source = NSMakeRect(sx, sy, sw, sh);
		item.image = controller(host).images[image - 1];
	}
}
void captive_frame_submit(CaptiveHost *handle)
{
	@autoreleasepool {
		if (!handle) return;
		CaptiveController *host = controller(handle);
		host.frame = [host.commands copy];
		host.frameBackground = host.background;
		host.view.needsDisplay = YES;
		[host.view displayIfNeeded];
	}
}
int32_t captive_frame_capture(CaptiveHost *handle, const char *path)
{
	if (!handle || !path) return 0;
	@autoreleasepool {
		CaptiveController *host = controller(handle);
		NSString *name = [NSString stringWithUTF8String:path];
		if (!name) return 0;
		NSBitmapImageRep *capture = [host.view bitmapImageRepForCachingDisplayInRect:host.view.bounds];
		if (!capture) { failure(host, @"Cannot allocate frame capture"); return 0; }
		[host.view cacheDisplayInRect:host.view.bounds toBitmapImageRep:capture];
		NSBitmapImageRep *output = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
			pixelsWide:1280 pixelsHigh:800 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
			colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:1280 * 4 bitsPerPixel:32];
		if (!output) { failure(host, @"Cannot allocate PNG output"); return 0; }
		NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:output];
		CGContextSetInterpolationQuality(context.CGContext, kCGInterpolationHigh);
		CGContextDrawImage(context.CGContext, CGRectMake(0, 0, 1280, 800), capture.CGImage);
		NSData *png = [output representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
		NSError *error = nil;
		if (!png || ![png writeToFile:name options:NSDataWritingAtomic error:&error]) {
			failure(host, error.localizedDescription ?: @"Cannot write PNG capture");
			return 0;
		}
		return 1;
	}
}
int32_t captive_audio_play(CaptiveHost *handle, const float *pcm, int32_t frames, int32_t rate, float gain)
{
	@autoreleasepool {
		if (!handle || !pcm || rate < 8000 || rate > 96000 || frames < 1 || frames > rate * 10
			|| !isfinite(gain) || gain < 0 || gain > 1) return 0;
		CaptiveController *host = controller(handle);
		if (host.paused) return 0;
		for (int32_t i = 0; i < frames; ++i) if (!isfinite(pcm[i]) || fabsf(pcm[i]) > 1) return 0;
		@try {
		if (!host.engine) {
			host.engine = [AVAudioEngine new];
			/* Each node reserves an equal share of full scale for bounded summation. */
			for (int i = 0; i < 8; ++i) {
				CaptiveVoice *voice = [CaptiveVoice new];
				voice.node = [AVAudioPlayerNode new];
				[host.engine attachNode:voice.node];
				[host.voices addObject:voice];
			}
		}
		CaptiveVoice *slot = nil;
		for (CaptiveVoice *candidate in host.voices) if (!candidate.busy) { slot = candidate; break; }
		if (!slot) return 0;
		AVAudioPlayerNode *voice = slot.node;
		AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:rate channels:1];
		AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:(AVAudioFrameCount)frames];
		if (!buffer) { failure(host, @"Cannot allocate audio effect"); return 0; }
		buffer.frameLength = (AVAudioFrameCount)frames;
		memcpy(buffer.floatChannelData[0], pcm, (size_t)frames * sizeof(float));
		[host.engine disconnectNodeOutput:voice];
		[host.engine connect:voice to:host.engine.mainMixerNode format:format];
		NSError *error = nil;
		if (!host.engine.isRunning && ![host.engine startAndReturnError:&error]) {
			failure(host, error.localizedDescription ?: @"Cannot start audio engine");
			return 0;
		}
		voice.volume = gain / 8;
		/* Completion is delivered on the main queue; node graph changes stay there. */
		slot.busy = YES;
		uint64_t generation = ++slot.generation;
		__weak CaptiveVoice *weakSlot = slot;
		[voice scheduleBuffer:buffer completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack
			completionHandler:^(AVAudioPlayerNodeCompletionCallbackType type) {
				(void)type;
				dispatch_async(dispatch_get_main_queue(), ^{
					CaptiveVoice *completed = weakSlot;
					if (completed && completed.generation == generation) {
						completed.busy = NO;
						[completed.node stop];
					}
				});
			}];
		[voice play];
		return 1;
		} @catch (NSException *exception) {
			failure(host, [@"Audio unavailable: " stringByAppendingString:exception.reason ?: exception.name]);
			host.engine = nil;
			[host.voices removeAllObjects];
			return 0;
		}
	}
}
int32_t captive_sound_load(CaptiveHost *handle, const char *path)
{
	if (!handle || !path) return 0;
	@autoreleasepool {
		CaptiveController *host = controller(handle);
		NSString *name = [NSString stringWithUTF8String:path];
		if (!name) return 0;
		NSNumber *cached = host.soundPaths[name];
		if (cached) return cached.intValue;
		if (host.sounds.count >= 128) { failure(host, @"Too many cached sound files"); return 0; }
		@try {
			NSError *error = nil;
			AVAudioFile *file = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:name]
				commonFormat:AVAudioPCMFormatFloat32 interleaved:NO error:&error];
			if (!file) { failure(host, error.localizedDescription ?: @"Cannot open sound file"); return 0; }
			double rate = file.processingFormat.sampleRate;
			if (file.processingFormat.channelCount != 1 || rate < 8000 || rate > 96000
				|| file.length < 1 || file.length > rate * 10) {
				failure(host, @"Sound must be mono, 8–96 kHz and at most ten seconds");
				return 0;
			}
			AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:file.processingFormat
				frameCapacity:(AVAudioFrameCount)file.length];
			if (!buffer || ![file readIntoBuffer:buffer error:&error] || buffer.frameLength != file.length) {
				failure(host, error.localizedDescription ?: @"Cannot read complete sound file");
				return 0;
			}
			CaptiveSound *sound = [CaptiveSound new];
			sound.rate = (int)rate;
			sound.pcm = [NSData dataWithBytes:buffer.floatChannelData[0] length:(NSUInteger)buffer.frameLength * sizeof(float)];
			[host.sounds addObject:sound];
			host.soundPaths[name] = @((int32_t)host.sounds.count);
			return (int32_t)host.sounds.count;
		} @catch (NSException *exception) {
			failure(host, exception.reason ?: @"Cannot decode sound file");
			return 0;
		}
	}
}
int32_t captive_sound_play(CaptiveHost *handle, int32_t number, float gain)
{
	if (!handle || number < 1 || (NSUInteger)number > controller(handle).sounds.count) return 0;
	CaptiveSound *sound = controller(handle).sounds[number - 1];
	return captive_audio_play(handle, sound.pcm.bytes, (int32_t)(sound.pcm.length / sizeof(float)), sound.rate, gain);
}
void captive_audio_pause(CaptiveHost *handle, int32_t paused)
{
	@autoreleasepool {
		if (!handle) return;
		CaptiveController *host = controller(handle);
		host.paused = paused != 0;
		@try {
		if (host.paused) [host.engine pause];
		else if (host.engine) {
			NSError *error = nil;
			if (![host.engine startAndReturnError:&error]) failure(host, error.localizedDescription ?: @"Cannot resume audio");
		}
		} @catch (NSException *exception) {
			failure(host, [@"Cannot change audio state: " stringByAppendingString:exception.reason ?: exception.name]);
		}
	}
}
void captive_audio_clear(CaptiveHost *handle)
{
	@autoreleasepool {
		if (!handle) return;
		for (CaptiveVoice *voice in controller(handle).voices) {
			++voice.generation;
			voice.busy = NO;
			[voice.node stop];
		}
	}
}
