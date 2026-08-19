#!/usr/bin/env python3
"""Insert the Phase 0 Telex/VNI rules into Google Input Tools' layout JS.

Usage: js_phase0.py <layouts-dir>

The rules are the same ones added to the C++ rulebased tables; this file is what
actually serves physical-keyboard typing (see VIETNAMESE-IME.md). Rule order
matters: the engine prefers the earliest rule that matches, so corrections go
before the plain tone rules they override.
"""
import json
import sys
import os

# (anchor to insert before, {pattern: replacement} in order)
TELEX_EARLY = [
    ("\"o\\u001d?w\"", {
        # uo + w horns both vowels: nguowfi -> nguoi with two horns.
        "[uU]\\u001d?[oO]\\u001d?[wW]": "ươ",
        "[uU]\\u001d?[oO]\\u001d?[nN]\\u001d?[gG]\\u001d?[wW]": "ương",
        # double-typing a w escapes it, as dd/aa/ee/oo already could
        "ư\\u001d[wW]": "uw",
        "ă\\u001d[wW]": "aw",
        "ơ\\u001d[wW]": "ow",
    }),
]

TONE_MARKS = {
    "f": "̀", "s": "́", "r": "̉", "x": "̃", "j": "̣",
}
VNI_MARKS = {
    "2": "̀", "1": "́", "3": "̉", "4": "̃", "5": "̣",
}


def correction_rules(keymap, keyclass):
    """Retyping a tone replaces the one already on the syllable."""
    out = {}
    for key, mark in keymap.items():
        others = "".join(m for m in TONE_MARKS.values() if m != mark)
        cls = keyclass(key)
        out["^(.*)([%s])([a-zA-Z\\u001d]*)(%s)" % (others, cls)] = "$1%s$3" % mark
    return out


# Rules to delete outright, as they appear in the file.
TELEX_DROP = [
    # A bare "w" typed anything-but-after-a-vowel produced "u-horn". It is the
    # single most disruptive rule in the table for anyone who also types
    # English: "windows" came out as "u-horn indow". "uw", "aw" and "ow" still
    # produce the horned vowels, which is how Telex is normally taught.
    ',w:"\\u01b0"',
    ',W:"\\u01af"',
]


def patch(path, early, corrections, drop=()):
    src = open(path, encoding="utf-8").read()
    if "colorburst" in src:
        print("  %s already patched" % os.path.basename(path))
        return False

    def as_js(d):
        return "".join('%s:%s,' % (json.dumps(k), json.dumps(v))
                       for k, v in d.items())

    for text in drop:
        assert text in src, "%s: cannot drop %r" % (path, text)
        src = src.replace(text, "", 1)

    for anchor, rules in early:
        assert anchor in src, "%s: anchor %s not found" % (path, anchor)
        src = src.replace(anchor, as_js(rules) + anchor, 1)

    # corrections go first in the transform object, so they win over the plain
    # tone rules that would otherwise stack a second diacritic
    i = src.index("transform:{")
    src = (src[:i] + "transform:{/*colorburst*/" + as_js(corrections)
           + src[i + len("transform:{"):])
    open(path, "w", encoding="utf-8").write(src)
    print("  patched %s" % os.path.basename(path))
    return True


def main():
    d = sys.argv[1]
    patch(os.path.join(d, "vi_telex.js"), TELEX_EARLY,
          correction_rules(TONE_MARKS, lambda k: "[%s%s]" % (k, k.upper())),
          TELEX_DROP)
    patch(os.path.join(d, "vi_vni.js"),
          [("\"(.*)o\\u001d?7\"", {
              "(.*)[uU]\\u001d?[oO]\\u001d?7": "$1ươ",
          })],
          correction_rules(VNI_MARKS, lambda k: k))


if __name__ == "__main__":
    main()
