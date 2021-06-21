#include <stdint.h>
#include "annepro2.h"
#include "qmk_ap2_led.h"
#include "config.h"

enum anne_pro_layers {
  _BASE_LAYER,
  _FN1_LAYER,
  _FN2_LAYER,
};

/*/-----__BASE_LAYER___---------------------------------------------------------------------.
* | esc |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  0  |  -  |  =  |    Bksp   |
* |-----------------------------------------------------------------------------------------+
* | Tab    |  q  |  w  |  e  |  r  |  t  |  y  |  u  |  i  |  o  |  p  |  [  |  ]  |   \    |
* |-----------------------------------------------------------------------------------------+
* | FN1    |  a  |  s  |  d  |  f  |  g  |  h  |  j  |  k  |  l  |  ;  |  '  |    Enter     |
* |-----------------------------------------------------------------------------------------+
* | Shift      |  z  |  x  |  c  |  v  |  b  |  n  |  m  |  ,  |  .  |  /  |      Shift     |
* |-----------------------------------------------------------------------------------------+
* | Ctrl  |  Alt  |  L1  |               space             |  Alt  |  Caps  |  FN2  | Ctrl  |
* \-----------------------------------------------------------------------------------------/
* Layer TAP in _BASE_LAYER
* ,-----------------------------------------------------------------------------------------.
* |     |     |     |     |     |     |     |     |     |     |     |     |     |           |
* |-----------------------------------------------------------------------------------------+
* |        |     |     |     |     |     |     |     |     |     |     |     |     |        |
* |-----------------------------------------------------------------------------------------+
* |         |     |     |     |     |     |     |     |     |     |     |     |             |
* |-----------------------------------------------------------------------------------------+
* |            |     |     |     |     |     |     |     |     |     |     |       UP       |
* |-----------------------------------------------------------------------------------------+
* |       |       |       |                                 |       |  LEFT | DOWN  | RIGHT |
* \----------------------------------------------------------------------------------------*/
 const uint16_t keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
 [_BASE_LAYER] = KEYMAP(
    KC_ESC, KC_1, KC_2, KC_3, KC_4, KC_5, KC_6, KC_7, KC_8, KC_9, KC_0, KC_MINS, KC_EQL, KC_BSPC,
    KC_TAB, KC_Q, KC_W, KC_E, KC_R, KC_T, KC_Y, KC_U, KC_I, KC_O, KC_P, KC_LBRC, KC_RBRC, KC_BSLS,
    LT(_FN1_LAYER,KC_LEFT), KC_A, KC_S, KC_D, KC_F, KC_G, KC_H, KC_J, KC_K, KC_L, KC_SCLN, KC_QUOT, KC_ENT,
    KC_LSFT, KC_Z, KC_X, KC_C, KC_V, KC_B, KC_N, KC_M, KC_COMM, KC_DOT, KC_SLSH, RSFT_T(KC_UP),
    KC_LCTL, KC_LALT, KC_LGUI, KC_SPC, KC_RALT, LT(_FN1_LAYER,KC_LEFT), LT(_FN2_LAYER,KC_DOWN), RCTL_T(KC_RGHT)
),\
/*/---__FN1_LAYER___-------------------------------------------------------------------------------------------.
* |  `  |  F1 |  F2 |  F3 |  F4 |  F5 |  F6 |  F7 |  F8 |  F9   |   F10   |   F11   |   F12   |      DELETE    |
* |------------------------------------------------------------------------------------------------------------+
* | Tab  | PGUP | UP | PGDN |  h(r)  |  h(t)  |  h(y)  |  h(u)  |  h(i)  | UP | h(p) | PrevTrack|NextTrack | \ |
* |------------------------------------------------------------------------------------------------------------+
* | FN1     |LEFT |DOWN |RIGHT|  h(f)  |  h(g)  |  h(h)  |  (j)  | LEFT | DOWN  | RIGHT  |  Vol+  |    Enter   |
* |------------------------------------------------------------------------------------------------------------+
* | Shift      | h(z)  |HOME | END |  h(v)  |  h(b)  |  h(n)  | h(m)  |  HOME  |  END  |  Vol- |     Shift     |
* |------------------------------------------------------------------------------------------------------------+
* | Ctrl  |  Alt   |   L1 |             Play/Stop                           |  Alt  |  Caps  |  FN2  | Ctrl    |
* \-----------------------------------------------------------------------------------------------------------*/
 [_FN1_LAYER] = KEYMAP(
    KC_GRV, KC_F1, KC_F2, KC_F3, KC_F4, KC_F5, KC_F6, KC_F7, KC_F8, KC_F9, KC_F10, KC_F11, KC_F12, KC_DEL,
    KC_TRNS, KC_PGUP, KC_UP, KC_PGDN, HYPR(KC_R), HYPR(KC_T), HYPR(KC_Y), HYPR(KC_U), HYPR(KC_I), KC_UP, HYPR(KC_P), KC_MPRV, KC_MNXT, KC_TRNS,
    KC_TRNS, KC_LEFT, KC_DOWN, KC_RGHT, HYPR(KC_F), HYPR(KC_G), HYPR(KC_H), HYPR(KC_J), KC_LEFT, KC_DOWN, KC_RGHT, KC_VOLU, KC_TRNS,
    KC_TRNS, HYPR(KC_Z), KC_HOME, KC_END, HYPR(KC_V), HYPR(KC_B), HYPR(KC_N), HYPR(KC_M), KC_HOME, KC_END, KC_VOLD, KC_TRNS,
    KC_TRNS, KC_TRNS, KC_TRNS, KC_MPLY, KC_TRNS, KC_TRNS, MO(_FN2_LAYER), KC_TRNS
),
/*/--___FN2_LAYER____----------------------------------------------------------------------------------.
* |  ~  | SWAP | UNSWAP | LENON | LEDOFf | LED_INT| LED_SPEED | F7 |F8| F9 | BT1 | BT2 | BT3 |   Bksp  |
* |----------------------------------------------------------------------------------------------------+
* | Tab    |  PGUP  | UP  |  PGDN  |  r  |  t  |  y  |  u  |  i  | UP | h(p) | PrevTrack|NextTrack | \ |
* |----------------------------------------------------------------------------------------------------+
* | Esc     |LEFT |DOWN |RIGHT|  f  |  g  |  h  |  j  |  LEFT  |  DOWN  | RIGHT | Vol+ |     Enter     |
* |----------------------------------------------------------------------------------------------------+
* | Shift      |  z  |  HOME | END  |  v  |  b  |  n  |  m  |  HOME  | END |  Vol- |       Shift       |
* |----------------------------------------------------------------------------------------------------+
* | Ctrl  |  L1   |  Alt  |                space                 |  Alt  |  FN1  |   FN2   |   Ctrl    |
* \---------------------------------------------------------------------------------------------------*/
 [_FN2_LAYER] = KEYMAP(
    KC_GRV, KC_TRNS, MAGIC_UNSWAP_LALT_LGUI, KC_AP_LED_ON, KC_AP_LED_OFF, KC_AP_LED_NEXT_INTENSITY, KC_AP_LED_SPEED, KC_TRNS, KC_TRNS, KC_TRNS, KC_AP2_BT1, KC_AP2_BT2, KC_AP2_BT3, KC_TRNS,
    KC_TRNS, KC_PGUP, KC_UP, KC_PGDN, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_UP, HYPR(KC_P), KC_MPRV, KC_MNXT, KC_TRNS,
    KC_TRNS, KC_LEFT, KC_DOWN, KC_RGHT, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_LEFT, KC_DOWN, KC_RGHT, KC_VOLU, KC_TRNS,
    KC_TRNS, KC_TRNS, KC_HOME, KC_END, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_HOME, KC_END, KC_VOLD, KC_TRNS,
    KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_TRNS, KC_BTN1, MO(_FN2_LAYER), KC_BTN2
 ),
};

const uint16_t keymaps_size = sizeof(keymaps);

void matrix_init_user(void) { }

void matrix_scan_user(void) { }

// Code to run after initializing the keyboard
void keyboard_post_init_user(void) {
    // Here are two common functions that you can use. For more LED functions, refer to the file "qmk_ap2_led.h"

    // annepro2-shine disables LEDs by default. Uncomment this function to enable them at startup.
    annepro2LedEnable();

    // Additionally, it also chooses the first LED profile by default. Refer to the "profiles" array in main.c in
    // annepro2-shine to see the order. Replace "i" with the index of your preferred profile. (i.e the RED profile is index 0)
    annepro2LedSetProfile(1);
}

layer_state_t layer_state_set_user(layer_state_t layer) {
    return layer;
}