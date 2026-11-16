/* Scalar ABI adapter for Meh; original Captive implementation. */
#ifndef CAPTIVE_MEH_H
#define CAPTIVE_MEH_H
#include <stdint.h>
uint64_t captive_meh_create(const char *title);
void captive_meh_destroy(uint64_t handle);
int64_t captive_meh_pump(uint64_t handle);
int64_t captive_meh_event(uint64_t handle);
int64_t captive_meh_code(uint64_t handle);
int64_t captive_meh_repeat(uint64_t handle);
double captive_meh_x(uint64_t handle);
double captive_meh_y(uint64_t handle);
const char *captive_meh_error(uint64_t handle);
const char *captive_meh_resources(void);
const char *captive_meh_prompt(const char *title, const char *message, const char *initial);
double captive_meh_mouse_x(uint64_t handle);
double captive_meh_mouse_y(uint64_t handle);
void captive_meh_fullscreen(uint64_t handle);
void captive_meh_begin(uint64_t handle, uint32_t rgba);
void captive_meh_rect(uint64_t handle, double x, double y, double w, double h, uint32_t rgba);
void captive_meh_text(uint64_t handle, const char *text, double x, double y, double size, uint32_t rgba);
int64_t captive_meh_load_image(uint64_t handle, const char *path);
void captive_meh_image(uint64_t handle, int64_t image, double x, double y, double w, double h);
void captive_meh_crop(uint64_t handle, int64_t image, double sx, double sy, double sw, double sh,
	double x, double y, double w, double h);
void captive_meh_submit(uint64_t handle);
int64_t captive_meh_capture(uint64_t handle, const char *path);
void captive_meh_audio_pause(uint64_t handle, int64_t paused);
void captive_meh_audio_clear(uint64_t handle);
int64_t captive_meh_sound_load(uint64_t handle, const char *path);
int64_t captive_meh_sound_play(uint64_t handle, int64_t sound, double gain);
#endif
