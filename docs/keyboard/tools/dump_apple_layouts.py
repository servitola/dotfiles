#!/usr/bin/env python3
"""Dump the base, Shift, ⌥ and ⇧⌥ layers of Apple's ABC, Russian, Russian – PC and Greek layouts.

Writes docs/keyboard/apple-layouts/<layout>.json through UCKeyTranslate, for the
keyboard type this Mac reports. parse_birman.py takes the plain and Shift labels of
the keyboard pictures and lint from these files.

Usage:
  python3 dump_apple_layouts.py
"""
import ctypes
import ctypes.util
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(os.path.dirname(HERE), "apple-layouts")
LAYOUTS = ("ABC", "Russian", "RussianWin", "Greek")
KEYS = range(0, 51)
# UCKeyTranslate takes (EventRecord modifiers >> 8): shiftKey is bit 9 → 2, optionKey bit 11 → 8.
MODIFIERS = {"base": 0, "shift": 2, "option": 8, "shift_option": 10}
K_UC_KEY_ACTION_DOWN = 0
# kUCKeyTranslateNoDeadKeysBit: a dead key yields its spacing accent, which is
# also what the Birman side resolves a dead key to through its terminators.
K_NO_DEAD_KEYS = 1

vp = ctypes.c_void_p
_cf = ctypes.CDLL(ctypes.util.find_library("CoreFoundation"))
_carbon = ctypes.CDLL("/System/Library/Frameworks/Carbon.framework/Carbon")
_cf.CFStringCreateWithCString.restype = vp
_cf.CFStringCreateWithCString.argtypes = [vp, ctypes.c_char_p, ctypes.c_uint32]
_cf.CFDictionaryCreate.restype = vp
_cf.CFDictionaryCreate.argtypes = [vp, ctypes.POINTER(vp), ctypes.POINTER(vp), ctypes.c_long, vp, vp]
_cf.CFArrayGetCount.restype = ctypes.c_long
_cf.CFArrayGetCount.argtypes = [vp]
_cf.CFArrayGetValueAtIndex.restype = vp
_cf.CFArrayGetValueAtIndex.argtypes = [vp, ctypes.c_long]
_cf.CFDataGetBytePtr.restype = vp
_cf.CFDataGetBytePtr.argtypes = [vp]
_carbon.TISCreateInputSourceList.restype = vp
_carbon.TISCreateInputSourceList.argtypes = [vp, ctypes.c_bool]
_carbon.TISGetInputSourceProperty.restype = vp
_carbon.TISGetInputSourceProperty.argtypes = [vp, vp]
_carbon.LMGetKbdType.restype = ctypes.c_uint8
_carbon.UCKeyTranslate.restype = ctypes.c_int32
_carbon.UCKeyTranslate.argtypes = [vp, ctypes.c_uint16, ctypes.c_uint16, ctypes.c_uint32, ctypes.c_uint32,
                                   ctypes.c_uint32, ctypes.POINTER(ctypes.c_uint32), ctypes.c_ulong,
                                   ctypes.POINTER(ctypes.c_ulong), ctypes.POINTER(ctypes.c_uint16)]
K_CF_STRING_ENCODING_UTF8 = 0x08000100


def _layout_data(name):
    """Include non-enabled sources: Russian and Greek are not enabled on this Mac."""
    key = vp.in_dll(_carbon, "kTISPropertyInputSourceID").value
    value = _cf.CFStringCreateWithCString(None, f"com.apple.keylayout.{name}".encode(), K_CF_STRING_ENCODING_UTF8)
    query = _cf.CFDictionaryCreate(None, (vp * 1)(key), (vp * 1)(value), 1,
                                   ctypes.addressof(vp.in_dll(_cf, "kCFTypeDictionaryKeyCallBacks")),
                                   ctypes.addressof(vp.in_dll(_cf, "kCFTypeDictionaryValueCallBacks")))
    sources = _carbon.TISCreateInputSourceList(query, True)
    if not sources or _cf.CFArrayGetCount(sources) != 1:
        raise SystemExit(f"input source com.apple.keylayout.{name} not found")
    source = _cf.CFArrayGetValueAtIndex(sources, 0)
    data = _carbon.TISGetInputSourceProperty(source, vp.in_dll(_carbon, "kTISPropertyUnicodeKeyLayoutData").value)
    return _cf.CFDataGetBytePtr(data)


def _translate(layout, code, modifiers, kbd_type):
    dead, length, buf = ctypes.c_uint32(0), ctypes.c_ulong(0), (ctypes.c_uint16 * 8)()
    err = _carbon.UCKeyTranslate(layout, code, K_UC_KEY_ACTION_DOWN, modifiers, kbd_type, K_NO_DEAD_KEYS,
                                 ctypes.byref(dead), len(buf), ctypes.byref(length), buf)
    if err:
        raise SystemExit(f"UCKeyTranslate failed for key {code}: {err}")
    return bytes(buf)[:length.value * 2].decode("utf-16-le")


def dump(name, kbd_type):
    layout = _layout_data(name)
    return {"kbd_type": kbd_type,
            **{layer: {str(code): _translate(layout, code, mods, kbd_type) for code in KEYS}
               for layer, mods in MODIFIERS.items()}}


def main():
    kbd_type = _carbon.LMGetKbdType()
    os.makedirs(OUT_DIR, exist_ok=True)
    for name in LAYOUTS:
        path = os.path.join(OUT_DIR, f"{name}.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(dump(name, kbd_type), fh, ensure_ascii=False, indent=1)
            fh.write("\n")
        print(f"dump_apple_layouts: wrote {os.path.relpath(path)} (keyboard type {kbd_type})")


if __name__ == "__main__":
    main()
