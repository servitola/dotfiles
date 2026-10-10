import importlib.util
import os
from pathlib import Path

HERE = Path(__file__).resolve().parent


def load(tmp_path):
    os.environ["DIR_CRON"] = str(tmp_path)
    os.environ["DIR_CRON_JOBS"] = str(tmp_path / "cron_jobs")
    spec = importlib.util.spec_from_file_location("cc", HERE.parent / "cron-calendar.py")
    cc = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(cc)
    return cc


def test_collect_fragments_recurses_like_the_installer(tmp_path):
    jobs = tmp_path / "cron_jobs"
    (jobs / "theme").mkdir(parents=True)
    (jobs / "b.cron").write_text("")
    (jobs / "theme" / "a.private.cron").write_text("")
    (jobs / "theme" / "notes.txt").write_text("")
    cc = load(tmp_path)
    assert [p.name for p in cc.collect_fragments()] == ["a.private.cron", "b.cron"]
