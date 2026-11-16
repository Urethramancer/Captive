/* Original Captive host bridge. Project licence remains undecided. */
#ifndef CAPTIVE_NATIVE_H
#define CAPTIVE_NATIVE_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

typedef struct CaptiveHost CaptiveHost;
typedef struct {
	int32_t kind; /* 1 key down, 2 key up, 3 mouse down, 4 mouse up, 5 close, 6 focus lost, 7 mouse moved */
	int32_t code; /* Key code below or mouse button (0 left, 1 right). */
	double x, y; /* Logical 1280 x 800 coordinates; outside letterbox may be negative. */
	int32_t repeat;
} CaptiveEvent;
enum {
	CAPTIVE_KEY_UNKNOWN = 0,
	CAPTIVE_KEY_W = 1, CAPTIVE_KEY_S, CAPTIVE_KEY_A, CAPTIVE_KEY_D,
	CAPTIVE_KEY_Q, CAPTIVE_KEY_E, CAPTIVE_KEY_ESCAPE,
	CAPTIVE_KEY_F1, CAPTIVE_KEY_F2, CAPTIVE_KEY_F3, CAPTIVE_KEY_F4,
	CAPTIVE_KEY_F5, CAPTIVE_KEY_F9, CAPTIVE_KEY_ENTER, CAPTIVE_KEY_SPACE
};

/* All calls, including destruction, must run on the process's main thread.
 * Returns NULL if AppKit cannot create a window. No gameplay runs in the bridge. */
CaptiveHost *captive_host_create(const char *title);
void captive_host_destroy(CaptiveHost *host);
const char *captive_host_error(CaptiveHost *host);
/* Pump without blocking; returns false after close. Poll events until empty. */
int32_t captive_host_pump(CaptiveHost *host);
int32_t captive_host_event(CaptiveHost *host, CaptiveEvent *event);
void captive_host_fullscreen(CaptiveHost *host);
double captive_mouse_x(CaptiveHost *host);
double captive_mouse_y(CaptiveHost *host);
/* Empty for a standalone executable; otherwise the app's Resources directory. */
const char *captive_resources(void);
/* Returns an empty string if cancelled. Copy before the next prompt call. */
const char *captive_prompt(const char *title, const char *message, const char *initial);
/* Begin/submit a complete retained frame. Logical coordinates use a top-left
 * origin. The whole 1280 x 800 canvas scales uniformly and is letterboxed. */
void captive_frame_begin(CaptiveHost *host, uint32_t rgba);
void captive_frame_rect(CaptiveHost *host, double x, double y, double w, double h, uint32_t rgba);
void captive_frame_text(CaptiveHost *host, const char *utf8, double x, double y, double size, uint32_t rgba);
/* Image handles belong to the host; 0 indicates failure. Loading uses ImageIO. */
int32_t captive_image_load(CaptiveHost *host, const char *path);
void captive_frame_image(CaptiveHost *host, int32_t image, double x, double y, double w, double h);
/* Source is normalised 0..1 with a top-left origin, destination is logical. */
void captive_frame_crop(CaptiveHost *host, int32_t image, double sx, double sy, double sw, double sh,
	double x, double y, double w, double h);
void captive_frame_submit(CaptiveHost *host);
/* Save the retained frame as a 1280 x 800 PNG without screen-recording access. */
int32_t captive_frame_capture(CaptiveHost *host, const char *path);
/* Copies finite mono float PCM. 8–96 kHz, 1 frame–10 seconds, at most eight voices;
 * exhaustion rejects a new effect instead of stealing an active voice. */
int32_t captive_audio_play(CaptiveHost *host, const float *pcm, int32_t frames, int32_t sample_rate, float gain);
int32_t captive_sound_load(CaptiveHost *host, const char *path);
int32_t captive_sound_play(CaptiveHost *host, int32_t sound, float gain);
void captive_audio_pause(CaptiveHost *host, int32_t paused);
void captive_audio_clear(CaptiveHost *host);
#ifdef __cplusplus
}
#endif
#endif
