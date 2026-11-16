/* This adapter is intentionally compatible with non-ARC @impl objc compilation.
 * The AppKit implementation is built separately with ARC. No managed pointers
 * cross this API: handles are owned until destroy and all strings are borrowed. */
#include "../../native/captive_meh.h"
#include "../../native/captive_native.h"
#include "meh_bridge.h"
#include <stdlib.h>

typedef struct {
	CaptiveHost *host;
	CaptiveEvent event;
} CaptiveMeh;
static CaptiveMeh *state(uint64_t handle) { return (CaptiveMeh *)(uintptr_t)handle; }
static CaptiveHost *host(uint64_t handle) { return handle ? state(handle)->host : NULL; }
uint64_t captive_meh_create(const char *title)
{
	CaptiveMeh *value = calloc(1, sizeof(*value));
	if (!value) return 0;
	value->host = captive_host_create(title);
	if (!value->host) { free(value); return 0; }
	return (uint64_t)(uintptr_t)value;
}
void captive_meh_destroy(uint64_t handle)
{
	if (!handle) return;
	captive_host_destroy(host(handle));
	free(state(handle));
}
int64_t captive_meh_pump(uint64_t handle) { return captive_host_pump(host(handle)); }
int64_t captive_meh_event(uint64_t handle)
{
	if (!handle) return 0;
	CaptiveMeh *value = state(handle);
	value->event = (CaptiveEvent){0};
	return captive_host_event(value->host, &value->event) ? value->event.kind : 0;
}
int64_t captive_meh_code(uint64_t h) { return h ? state(h)->event.code : 0; }
int64_t captive_meh_repeat(uint64_t h) { return h ? state(h)->event.repeat : 0; }
double captive_meh_x(uint64_t h) { return h ? state(h)->event.x : 0; }
double captive_meh_y(uint64_t h) { return h ? state(h)->event.y : 0; }
const char *captive_meh_error(uint64_t h) { return captive_host_error(host(h)); }
const char *captive_meh_resources(void) { return captive_resources(); }
const char *captive_meh_prompt(const char *title, const char *message, const char *initial)
{ return captive_prompt(title, message, initial); }
double captive_meh_mouse_x(uint64_t h) { return captive_mouse_x(host(h)); }
double captive_meh_mouse_y(uint64_t h) { return captive_mouse_y(host(h)); }
void captive_meh_fullscreen(uint64_t h) { captive_host_fullscreen(host(h)); }
void captive_meh_begin(uint64_t h, uint32_t rgba) { captive_frame_begin(host(h), rgba); }
void captive_meh_rect(uint64_t h, double x, double y, double w, double height, uint32_t rgba)
{ captive_frame_rect(host(h), x, y, w, height, rgba); }
void captive_meh_text(uint64_t h, const char *text, double x, double y, double size, uint32_t rgba)
{ captive_frame_text(host(h), text, x, y, size, rgba); }
int64_t captive_meh_load_image(uint64_t h, const char *path) { return captive_image_load(host(h), path); }
void captive_meh_image(uint64_t h, int64_t image, double x, double y, double w, double height)
{
	if (image > 0 && image <= INT32_MAX) captive_frame_image(host(h), (int32_t)image, x, y, w, height);
}
void captive_meh_submit(uint64_t h) { captive_frame_submit(host(h)); }
int64_t captive_meh_capture(uint64_t h, const char *path) { return captive_frame_capture(host(h), path); }
void captive_meh_crop(uint64_t h, int64_t image, double sx, double sy, double sw, double sh,
	double x, double y, double w, double height)
{
	if (image > 0 && image <= INT32_MAX) captive_frame_crop(host(h), (int32_t)image, sx, sy, sw, sh, x, y, w, height);
}
void captive_meh_audio_pause(uint64_t h, int64_t paused) { captive_audio_pause(host(h), paused != 0); }
void captive_meh_audio_clear(uint64_t h) { captive_audio_clear(host(h)); }
int64_t captive_meh_sound_load(uint64_t h, const char *path) { return captive_sound_load(host(h), path); }
int64_t captive_meh_sound_play(uint64_t h, int64_t sound, double gain)
{
	return sound > 0 && sound <= INT32_MAX ? captive_sound_play(host(h), (int32_t)sound, (float)gain) : 0;
}
/* Meh lists are borrowed for this call; copy signed 8-bit PCM into native float
 * storage before returning. The engine copies again into its owned AV buffer. */
int64_t captive_meh_pcm(uint64_t h, meh_list *bytes, int64_t rate, double gain)
{
	if (!h || !bytes || rate < 8000 || rate > 96000 || bytes->length < 1 || bytes->length > rate * 10) return 0;
	float *pcm = malloc((size_t)bytes->length * sizeof(float));
	if (!pcm) return 0;
	for (int64_t i = 0; i < bytes->length; ++i) pcm[i] = (float)(int8_t)(bytes->items[i] & 255) / 128.0f;
	int result = captive_audio_play(host(h), pcm, (int32_t)bytes->length, (int32_t)rate, (float)gain);
	free(pcm);
	return result;
}
