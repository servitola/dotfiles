-- Changes to BirmanLayer.spoon's table, passed to it as `overrides` by init.lua: nine ⌥ cells
-- Birman leaves empty or fills differently, and a Greek layer he never made. Maintained by hand.
--
-- "*" applies to every layout; an input source id (hs.keycodes.currentSourceID()) applies to
-- that layout only, on top of "*". A row is `[kVK code] = { opt = ..., shift_opt = ... }`
-- (right ⌥ and right ⇧⌥): a string types it, false types nothing, { pass = true } leaves the
-- key to macOS, { dead = "name" } enters a state described under `dead`. Keys may also be
-- QWERTY names (g, [, space). Shape: the Spoon's docs/configuration.md, "Overrides".
--
-- To add a cell: add the row, hs.reload(), then python3 docs/keyboard/generate.py (the keyboard
-- pictures and lint read this file through docs/keyboard/parse_birman.py).
return {
  ["*"] = {
    keys = {
      [5] = { opt = "©" },
      [6] = { opt = "§" },
      [12] = { opt = "·" },
      [21] = { opt = "£" },
      [26] = { opt = "ϗ" },
      [30] = { opt = "»" },
      [33] = { opt = "«" },
      [42] = { opt = "¦" },
      [45] = { opt = "‘" },
    },
  },
  ["com.apple.keylayout.Greek"] = {
    keys = {
      [0] = { shift_opt = "ά" },
      [1] = { shift_opt = "ρ" },
      [2] = { shift_opt = false },
      [3] = { shift_opt = "Π" },
      [4] = { shift_opt = "≠" },
      [5] = { shift_opt = "Ϊ" },
      [6] = { shift_opt = false },
      [7] = { shift_opt = false },
      [8] = { shift_opt = "Χ" },
      [9] = { shift_opt = "Ά" },
      [10] = { shift_opt = false },
      [11] = { shift_opt = false },
      [12] = { shift_opt = "―" },
      [14] = { shift_opt = "Έ" },
      [15] = { shift_opt = "Δ" },
      [16] = { shift_opt = false },
      [17] = { shift_opt = false },
      [18] = { shift_opt = "έ" },
      [19] = { shift_opt = "ί" },
      [20] = { shift_opt = "ή" },
      [21] = { shift_opt = "ό" },
      [22] = { shift_opt = "^" },
      [23] = { shift_opt = "Ώ" },
      [24] = { shift_opt = "+" },
      [25] = { shift_opt = "Κ" },
      [26] = { shift_opt = "Ϗ" },
      [27] = { shift_opt = "_" },
      [28] = { shift_opt = "Ρ" },
      [29] = { shift_opt = "ύ" },
      [31] = { shift_opt = "Τ" },
      [32] = { shift_opt = "Ξ" },
      [34] = { shift_opt = "Ν" },
      [35] = { shift_opt = false },
      [37] = { shift_opt = "·" },
      [38] = { shift_opt = "≥" },
      [39] = { opt = "'", shift_opt = "\"" },
      [40] = { shift_opt = "Ϗ" },
      [41] = { opt = { dead = "dialytika_tonos" }, shift_opt = ":" },
      [42] = { shift_opt = "Ζ" },
      [43] = { shift_opt = false },
      [44] = { shift_opt = "?" },
      [45] = { shift_opt = "Ό" },
      [46] = { shift_opt = "Ύ" },
      [47] = { shift_opt = "ώ" },
      [50] = { shift_opt = "Μ" },
    },
    dead = {
      dialytika_tonos = {
        compose = {
          [" "] = "΅", ["ι"] = "ΐ", ["υ"] = "ΰ",
        },
        keys = {
          [49] = { opt = "΅", shift_opt = "΅" },
        },
      },
    },
    terminators = { dialytika_tonos = "΅" },
  },
}
