-- Ilya Birman's typography layout 3.9 (https://ilyabirman.ru/typography-layout/), read from
-- his own English and Russian builds by gen_typography.py. Do not edit; see README, "Data".
return {
  version = "3.9",
  keys = {
    [0] = { opt = "≈", shift_opt = "⌘" },
    [1] = { opt = "§", shift_opt = "⇧" },
    [2] = { opt = "°", shift_opt = "⌀" },
    [3] = { opt = "£", shift_opt = false },
    [4] = { opt = "₽", shift_opt = { dead = "double_acute" } },
    [5] = { opt = false, shift_opt = "" },
    [6] = { opt = false, shift_opt = { dead = "cedilla" } },
    [7] = { opt = "×", shift_opt = "·" },
    [8] = { opt = "©", shift_opt = "¢" },
    [9] = { opt = "↓", shift_opt = { dead = "caron" } },
    [10] = { opt = "`", shift_opt = { dead = "grave" } },
    [11] = { opt = "ß", shift_opt = "ẞ" },
    [12] = { opt = false, shift_opt = { dead = "breve" } },
    [13] = { opt = "✓", shift_opt = "⌃" },
    [14] = { opt = "€", shift_opt = "⌥" },
    [15] = { opt = "®", shift_opt = { dead = "ring" } },
    [16] = { opt = "ѣ", shift_opt = "Ѣ" },
    [17] = { opt = "™", shift_opt = "#" },
    [18] = { opt = "¹", shift_opt = "¡" },
    [19] = { opt = "²", shift_opt = "¹⁄₂" },
    [20] = { opt = "³", shift_opt = "¹⁄₃" },
    [21] = { opt = "$", shift_opt = "¹⁄₄" },
    [22] = { opt = "↑", shift_opt = { dead = "circumflex" } },
    [23] = { opt = "‰", shift_opt = false },
    [24] = { opt = "≠", shift_opt = "±" },
    [25] = { opt = "←", shift_opt = "‹" },
    [26] = { opt = false, shift_opt = "¿" },
    [27] = { opt = "—", shift_opt = "–" },
    [28] = { opt = "∞", shift_opt = false },
    [29] = { opt = "→", shift_opt = "›" },
    [30] = { opt = "]", shift_opt = "}" },
    [31] = { opt = "ѳ", shift_opt = "Ѳ" },
    [32] = { opt = "ѵ", shift_opt = "Ѵ" },
    [33] = { opt = "[", shift_opt = "{" },
    [34] = { opt = "і", shift_opt = "І" },
    [35] = { opt = "′", shift_opt = "″" },
    [37] = { opt = "”", shift_opt = "’" },
    [38] = { opt = "„", shift_opt = false },
    [39] = { opt = "’", shift_opt = false },
    [40] = { opt = "“", shift_opt = "‘" },
    [41] = { opt = "‘", shift_opt = { dead = "diaeresis" } },
    [42] = { opt = false, shift_opt = false },
    [43] = { opt = "«", shift_opt = "„" },
    [44] = { opt = "…", shift_opt = { dead = "acute" } },
    [45] = { opt = false, shift_opt = { dead = "tilde" } },
    [46] = { opt = "−", shift_opt = "•" },
    [47] = { opt = "»", shift_opt = "“" },
    [49] = { opt = " ", shift_opt = " " },
    [50] = { opt = "`", shift_opt = { dead = "grave" } },
  },
  dead = {
    double_acute = {
      compose = {
        [" "] = "˝", ["A"] = "A̋", ["E"] = "E̋", ["I"] = "I̋", ["M"] = "M̋", ["O"] = "Ő",
        ["U"] = "Ű", ["a"] = "a̋", ["e"] = "e̋", ["i"] = "i̋", ["m"] = "m̋", ["o"] = "ő",
        ["u"] = "ű",
      },
      keys = {
        [4] = { shift_opt = "̋" },
      },
    },
    cedilla = {
      compose = {
        [" "] = "¸", ["C"] = "Ç", ["D"] = "Ḑ", ["E"] = "Ȩ", ["G"] = "Ģ", ["H"] = "Ḩ", ["K"] = "Ķ",
        ["L"] = "Ļ", ["N"] = "Ņ", ["R"] = "Ŗ", ["S"] = "Ş", ["T"] = "Ţ", ["c"] = "ç", ["d"] = "ḑ",
        ["e"] = "ȩ", ["g"] = "ģ", ["h"] = "ḩ", ["k"] = "ķ", ["l"] = "ļ", ["n"] = "ņ", ["r"] = "ŗ",
        ["s"] = "ş", ["t"] = "ţ",
      },
      keys = {
        [6] = { shift_opt = "̧" },
      },
    },
    caron = {
      compose = {
        [" "] = "ˇ", ["A"] = "Ǎ", ["C"] = "Č", ["D"] = "Ď", ["E"] = "Ě", ["G"] = "Ǧ", ["H"] = "Ȟ",
        ["I"] = "Ǐ", ["K"] = "Ǩ", ["N"] = "Ň", ["O"] = "Ǒ", ["R"] = "Ř", ["S"] = "Š", ["T"] = "Ť",
        ["U"] = "Ǔ", ["Z"] = "Ž", ["a"] = "ǎ", ["c"] = "č", ["d"] = "ď", ["e"] = "ě", ["g"] = "ǧ",
        ["h"] = "ȟ", ["i"] = "ǐ", ["j"] = "ǰ", ["k"] = "ǩ", ["n"] = "ň", ["o"] = "ǒ", ["r"] = "ř",
        ["s"] = "š", ["t"] = "ť", ["u"] = "ǔ", ["z"] = "ž",
      },
      keys = {
        [9] = { shift_opt = "̌" },
      },
    },
    grave = {
      compose = {
        [" "] = "`", ["A"] = "À", ["E"] = "È", ["I"] = "Ì", ["N"] = "Ǹ", ["O"] = "Ò", ["U"] = "Ù",
        ["W"] = "Ẁ", ["Y"] = "Ỳ", ["a"] = "à", ["e"] = "è", ["i"] = "ì", ["n"] = "ǹ", ["o"] = "ò",
        ["u"] = "ù", ["w"] = "ẁ", ["y"] = "ỳ",
      },
      keys = {
        [10] = { shift_opt = "̀" },
        [50] = { shift_opt = "̀" },
      },
    },
    breve = {
      compose = {
        [" "] = "˘", ["A"] = "Ă", ["E"] = "Ĕ", ["G"] = "Ğ", ["I"] = "Ĭ", ["O"] = "Ŏ", ["U"] = "Ŭ",
        ["a"] = "ă", ["e"] = "ĕ", ["g"] = "ğ", ["i"] = "ĭ", ["o"] = "ŏ", ["u"] = "ŭ",
      },
      keys = {
        [12] = { shift_opt = "̆" },
      },
    },
    ring = {
      compose = {
        [" "] = "˚", ["A"] = "Å", ["U"] = "Ů", ["a"] = "å", ["u"] = "ů",
      },
      keys = {
        [15] = { shift_opt = "̊" },
      },
    },
    circumflex = {
      compose = {
        [" "] = "ˆ", ["A"] = "Â", ["C"] = "Ĉ", ["E"] = "Ê", ["G"] = "Ĝ", ["H"] = "Ĥ", ["I"] = "Î",
        ["J"] = "Ĵ", ["O"] = "Ô", ["S"] = "Ŝ", ["U"] = "Û", ["W"] = "Ŵ", ["Y"] = "Ŷ", ["Z"] = "Ẑ",
        ["a"] = "â", ["c"] = "ĉ", ["e"] = "ê", ["g"] = "ĝ", ["h"] = "ĥ", ["i"] = "î", ["j"] = "ĵ",
        ["o"] = "ô", ["s"] = "ŝ", ["u"] = "û", ["w"] = "ŵ", ["y"] = "ŷ", ["z"] = "ẑ",
      },
      keys = {
        [22] = { shift_opt = "̂̂" },
      },
    },
    diaeresis = {
      compose = {
        [" "] = "¨", ["A"] = "Ä", ["E"] = "Ë", ["I"] = "Ï", ["O"] = "Ö", ["U"] = "Ü", ["W"] = "Ẅ",
        ["X"] = "Ẍ", ["Y"] = "Ÿ", ["a"] = "ä", ["e"] = "ë", ["i"] = "ï", ["o"] = "ö", ["u"] = "ü",
        ["w"] = "ẅ", ["x"] = "ẍ", ["y"] = "ÿ",
      },
      keys = {
        [41] = { shift_opt = "̈" },
      },
    },
    acute = {
      compose = {
        [" "] = "´", ["A"] = "Á", ["C"] = "Ć", ["E"] = "É", ["G"] = "Ǵ", ["I"] = "Í", ["L"] = "Ĺ",
        ["M"] = "Ḿ", ["N"] = "Ń", ["O"] = "Ó", ["P"] = "Ṕ", ["R"] = "Ŕ", ["S"] = "Ś", ["U"] = "Ú",
        ["W"] = "Ẃ", ["Y"] = "Ý", ["Z"] = "Ź", ["a"] = "á", ["c"] = "ć", ["e"] = "é", ["g"] = "ǵ",
        ["i"] = "í", ["l"] = "ĺ", ["m"] = "ḿ", ["n"] = "ń", ["o"] = "ó", ["p"] = "ṕ", ["r"] = "ŕ",
        ["s"] = "ś", ["u"] = "ú", ["w"] = "ẃ", ["y"] = "ý", ["z"] = "ź",
      },
      keys = {
        [44] = { shift_opt = "́" },
      },
    },
    tilde = {
      compose = {
        [" "] = "˜", ["A"] = "Ã", ["I"] = "Ĩ", ["N"] = "Ñ", ["O"] = "Õ", ["U"] = "Ũ", ["V"] = "Ṽ",
        ["Y"] = "Ỹ", ["a"] = "ã", ["i"] = "ĩ", ["n"] = "ñ", ["o"] = "õ", ["u"] = "ũ", ["v"] = "ṽ",
        ["y"] = "ỹ",
      },
      keys = {
        [45] = { shift_opt = "̃" },
      },
    },
  },
  terminators = { double_acute = "˝", cedilla = "¸", caron = "ˇ", grave = "`", breve = "˘", ring = "˚", circumflex = "ˆ", diaeresis = "¨", acute = "´", tilde = "˜" },
  cyrillic = {
    dead = {
      double_acute = {
        compose = {
          ["У"] = "Ӳ", ["у"] = "ӳ",
        },
      },
      cedilla = {
        compose = {
          ["З"] = "Ҙ", ["С"] = "Ҫ", ["з"] = "ҙ", ["с"] = "ҫ",
        },
      },
      grave = {
        compose = {
          ["Ё"] = "Ѐ", ["Е"] = "Ѐ", ["И"] = "Ѝ", ["Й"] = "Ѝ", ["е"] = "ѐ", ["и"] = "ѝ", ["й"] = "ѝ",
          ["ё"] = "ѐ",
        },
      },
      breve = {
        compose = {
          ["Ё"] = "Ӗ", ["А"] = "Ӑ", ["Е"] = "Ӗ", ["Ж"] = "Ӂ", ["И"] = "Й", ["Й"] = "Й", ["У"] = "Ў",
          ["а"] = "ӑ", ["е"] = "ӗ", ["ж"] = "ӂ", ["и"] = "й", ["й"] = "й", ["у"] = "ў", ["ё"] = "ӗ",
        },
        keys = {
          [50] = { base = { pass = true }, shift = { pass = true } },
        },
      },
      circumflex = {
        keys = {
          [22] = { shift_opt = "̂" },
        },
      },
      diaeresis = {
        compose = {
          ["Ё"] = "Ё", ["А"] = "Ӓ", ["Е"] = "Ё", ["Ж"] = "Ӝ", ["З"] = "Ӟ", ["И"] = "Ӥ", ["Й"] = "Ӥ",
          ["О"] = "Ӧ", ["У"] = "Ӱ", ["Ч"] = "Ӵ", ["Ы"] = "Ӹ", ["Э"] = "Ӭ", ["а"] = "ӓ", ["е"] = "ё",
          ["ж"] = "ӝ", ["з"] = "ӟ", ["и"] = "ӥ", ["й"] = "ӥ", ["о"] = "ӧ", ["у"] = "ÿ", ["ч"] = "ӵ",
          ["ы"] = "ӹ", ["э"] = "ӭ", ["ё"] = "ё",
        },
        keys = {
          [34] = { opt = "ï", shift_opt = "Ї" },
          [50] = { base = { pass = true }, shift = { pass = true } },
        },
      },
      acute = {
        compose = {
          ["Г"] = "Ѓ", ["К"] = "Ќ", ["г"] = "ѓ", ["к"] = "ќ",
        },
      },
    },
  },
  fixups = {
    ["com.apple.keylayout.ABC"] = {
      [10] = { base = "`", shift = "~" },
      [50] = { base = "\\" },
    },
    ["com.apple.keylayout.RussianWin"] = {
      [50] = { shift = "Ё" },
    },
  },
}
