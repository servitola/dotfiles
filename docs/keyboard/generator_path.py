"""Puts karabiner/generator on sys.path: the key tables, the layers.toml grammar and the rules live there."""
import os
import sys

sys.path.insert(0, os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                 "..", "..", "karabiner", "generator")))
