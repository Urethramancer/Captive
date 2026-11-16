#import <AppKit/AppKit.h>
#import "../captive_native.h"
#include <assert.h>
#include <math.h>
#include <unistd.h>
static void le32(uint8_t *bytes, uint32_t value)
{
	for (int i = 0; i < 4; ++i) bytes[i] = (uint8_t)(value >> (8 * i));
}
int main(void)
{
	@autoreleasepool {
		CaptiveHost *host = captive_host_create("Captive — native bridge check");
		assert(host);
		captive_frame_begin(host, 0x111820ff);
		captive_frame_rect(host, 32, 32, 1216, 560, 0x223544ff);
		captive_frame_text(host, "Captive / native bridge", 64, 64, 32, 0xe1dabdff);
		for (int i = 0; i < 4; ++i) {
			captive_frame_rect(host, 32 + i * 308, 624, 292, 144, 0x35494aff);
			captive_frame_text(host, "DROID", 48 + i * 308, 640, 18, 0xd9e3d1ff);
		}
		captive_frame_submit(host);
		assert(captive_host_pump(host));
		NSWindow *window = NSApp.windows.firstObject;
		assert(window);
		NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
		assert([[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]);
		NSBitmapImageRep *source = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
			pixelsWide:2 pixelsHigh:2 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
			colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:8 bitsPerPixel:32];
		uint8_t pixels[] = {255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255};
		memcpy(source.bitmapData, pixels, sizeof(pixels));
		NSString *imagePath = [directory stringByAppendingPathComponent:@"quadrants.png"];
		assert([[source representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:imagePath atomically:YES]);
		int image = captive_image_load(host, imagePath.UTF8String);
		assert(image > 0);
		captive_frame_begin(host, 0x111820ff);
		captive_frame_crop(host, image, 0, 0, 0.5, 0.5, 64, 160, 80, 80);
		captive_frame_submit(host);
		NSBitmapImageRep *capture = [window.contentView bitmapImageRepForCachingDisplayInRect:window.contentView.bounds];
		[window.contentView cacheDisplayInRect:window.contentView.bounds toBitmapImageRep:capture];
		NSColor *pixel = [[capture colorAtX:104 y:200] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
		assert(pixel.redComponent > 0.8 && pixel.blueComponent < 0.2);
		NSString *capturePath = [directory stringByAppendingPathComponent:@"capture.png"];
		assert(captive_frame_capture(host, capturePath.UTF8String));
		NSBitmapImageRep *saved = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:capturePath]];
		assert(saved.pixelsWide == 1280 && saved.pixelsHigh == 800);
		pixel = [[saved colorAtX:104 y:200] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
		assert(pixel.redComponent > 0.8 && pixel.blueComponent < 0.2);
		NSEvent *press = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
			modifierFlags:0 timestamp:0 windowNumber:window.windowNumber context:nil
			characters:@"w" charactersIgnoringModifiers:@"w" isARepeat:NO keyCode:13];
		[window.contentView keyDown:press];
		CaptiveEvent input;
		BOOL found = NO;
		while (captive_host_event(host, &input)) if (input.kind == 1 && input.code == CAPTIVE_KEY_W) found = YES;
		assert(found);
		/* Letterboxing and Retina-independent hit coordinates share the same scale. */
		[window setContentSize:NSMakeSize(1600, 800)];
		NSView *view = window.contentView;
		NSPoint target = [view convertPoint:NSMakePoint(260, 80) toView:nil];
		NSEvent *mouse = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown location:target
			modifierFlags:0 timestamp:0 windowNumber:window.windowNumber context:nil
			eventNumber:0 clickCount:1 pressure:1];
		[view mouseDown:mouse];
		found = NO;
		while (captive_host_event(host, &input)) if (input.kind == 3) {
			assert(fabs(input.x - 100) < 0.01 && fabs(input.y - 80) < 0.01);
			found = YES;
		}
		assert(found);
		[window setContentSize:NSMakeSize(1280, 800)];
		/* Stalled consumers receive a focus-reset event before fresh input. */
		for (int i = 0; i < 129; ++i) [window.contentView keyDown:press];
		assert(captive_host_event(host, &input) && input.kind == 6);
		while (captive_host_event(host, &input)) { }
		assert(!captive_audio_play(host, NULL, 0, 8000, 1));
		float bad[] = {NAN};
		assert(!captive_audio_play(host, bad, 1, 8000, 1));
		float silence[800] = {0};
		uint8_t wave[44 + 2205] = {'R', 'I', 'F', 'F', 0, 0, 0, 0, 'W', 'A', 'V', 'E', 'f', 'm', 't', ' ',
			16, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 8, 0, 'd', 'a', 't', 'a'};
		le32(wave + 4, sizeof(wave) - 8);
		le32(wave + 24, 22050);
		le32(wave + 28, 22050);
		le32(wave + 40, 2205);
		memset(wave + 44, 128, 2205);
		NSString *soundPath = [directory stringByAppendingPathComponent:@"unsigned8.wav"];
		assert([[NSData dataWithBytes:wave length:sizeof(wave)] writeToFile:soundPath atomically:YES]);
		int sound = captive_sound_load(host, soundPath.UTF8String);
		assert(sound > 0 && sound == captive_sound_load(host, soundPath.UTF8String));
		assert(captive_sound_play(host, sound, 0));
		captive_audio_clear(host);
		assert(captive_audio_play(host, silence, 800, 8000, 0));
		captive_audio_pause(host, 1);
		assert(!captive_audio_play(host, silence, 800, 8000, 0));
		captive_audio_clear(host);
		captive_audio_pause(host, 0);
		for (int i = 0; i < 8; ++i) assert(captive_audio_play(host, silence, 800, 8000, 0));
		assert(!captive_audio_play(host, silence, 800, 8000, 0));
		captive_audio_clear(host);
		assert(captive_audio_play(host, silence, 800, 8000, 0));
		for (int i = 0; i < 20; ++i) {
			assert(captive_host_pump(host));
			CaptiveEvent event;
			while (captive_host_event(host, &event)) { }
			usleep(10000);
		}
		[window performClose:nil];
		assert(!captive_host_pump(host));
		captive_host_destroy(host);
		assert([[NSFileManager defaultManager] removeItemAtPath:directory error:nil]);
	}
	return 0;
}
