#!/usr/bin/env python3
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("check", Path(__file__).with_name("check.py"))
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


def env(text):
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "constants.env"
        path.write_text(text, encoding="utf-8")
        return check.read_env(path)


class ReadEnv(unittest.TestCase):
    def test_value_is_the_rest_of_the_line(self):
        values, problems = env("# note\n\nA_URL=http://x/?a=b\nB_NAME=Visual Studio Code\n")
        self.assertEqual(values, {"A_URL": "http://x/?a=b", "B_NAME": "Visual Studio Code"})
        self.assertEqual(problems, [])

    def test_forms_the_loaders_disagree_on_are_rejected(self):
        for line, word in [
            ("A_KEY=value ", "whitespace"),
            (" A_KEY=value", "not KEY=value"),
            ('A_KEY="value"', "quoted"),
            ("A_KEY=${HOME}/x", "${HOME}"),
            ("A_KEY=value # why", "inline comment"),
            ("a_key=value", "not KEY=value"),
            ("A_KEY", "not KEY=value"),
            ("A_KEY=1\nA_KEY=2", "twice"),
        ]:
            with self.subTest(line=line):
                _, problems = env(line + "\n")
                self.assertEqual(len(problems), 1, problems)
                self.assertIn(word, problems[0])


class Schema(unittest.TestCase):
    def problems(self, values, schema, **kwargs):
        return check.check_schema(values, schema, **kwargs)

    def test_valid(self):
        schema = {"TG_CHAT_X": {"type": "chat_id", "about": "a chat"}}
        self.assertEqual(self.problems({"TG_CHAT_X": "-1001234567890"}, schema), [])

    def test_key_must_be_on_both_sides(self):
        schema = {"ONLY_SCHEMA": {"type": "text", "about": "x"}}
        problems = self.problems({"ONLY_ENV": "x"}, schema)
        self.assertEqual(len(problems), 2)

    def test_value_must_fit_its_type(self):
        for kind, value in [
            ("chat_id", "1234"),
            ("email", "nobody"),
            ("timezone", "Mars/Olympus"),
            ("url", "localhost:4000"),
            ("dir", "projects/x"),
            ("bundle", "Vivaldi"),
            ("host", "two words"),
            ("text", ""),
        ]:
            with self.subTest(kind=kind):
                problems = self.problems({"A_KEY": value}, {"A_KEY": {"type": kind, "about": "x"}})
                self.assertEqual(len(problems), 1, problems)

    def test_unknown_type_and_missing_about(self):
        self.assertIn("unknown type", self.problems({"A_KEY": "x"}, {"A_KEY": {"type": "nope", "about": "x"}})[0])
        self.assertIn("about", self.problems({"A_KEY": "x"}, {"A_KEY": {"type": "text"}})[0])

    def test_machine_checks_only_on_request_and_skip_removable(self):
        values = {"DIR_GONE": "/nonexistent-constants-test"}
        schema = {"DIR_GONE": {"type": "dir", "about": "x"}}
        self.assertEqual(self.problems(values, schema), [])
        self.assertEqual(len(self.problems(values, schema, machine=True)), 1)
        schema["DIR_GONE"]["removable"] = True
        self.assertEqual(self.problems(values, schema, machine=True), [])


class Literals(unittest.TestCase):
    values = {"TG_CHAT_X": "-1001234567890", "HOST_X": "i9", "DIR_WORK": "$HOME/projects/Acme", "APP_X": "Firefox"}
    schema = {
        "TG_CHAT_X": {"private": True},
        "HOST_X": {"private": True},
        "DIR_WORK": {"private": True},
        "APP_X": {},
    }

    def test_needles_are_private_long_values_and_the_home_path(self):
        needles = check.literals(self.values, self.schema)
        self.assertEqual(set(needles), {check.HOME, "-1001234567890", "/projects/Acme"})

    def test_scan_reports_the_line_and_honours_the_allow_list(self):
        needles = check.literals(self.values, self.schema)
        lines = [
            ("cron/a.cron", 3, "send --chat -1001234567890"),
            ("cron/a.cron", 4, "send --chat $" + "TG_CHAT_X"),  # split: check.py would read it as a reference
            ("launchagents/x.plist", 9, f"<string>{check.HOME}/bin</string>"),
        ]
        problems = check.scan(lines, needles, ["launchagents/**"])
        self.assertEqual(problems, ["cron/a.cron:3: hardcodes the value of TG_CHAT_X"])


class Namespaces(unittest.TestCase):
    def test_only_prefixes_shared_by_several_keys(self):
        self.assertEqual(check.namespaces_of(["APP_A", "APP_B", "RAG_COLLECTION", "DIR_A", "DIR_B"]), ["APP", "DIR"])


if __name__ == "__main__":
    unittest.main()
