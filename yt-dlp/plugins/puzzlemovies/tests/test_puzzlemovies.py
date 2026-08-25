from unittest import mock

import pytest

from yt_dlp.utils import ExtractorError
from yt_dlp_plugins.extractor.puzzlemovies import (
    PuzzleMoviesIE,
    build_manifest_url,
    extract_seasons_json,
    select_episodes,
)

SAMPLE_WEBPAGE = '''
<html><body>
<script type="text/javascript">
  var episodes = [{"season":1,"episodes":[
    {"ID":30403,"post_name":"the-mentalist-s1e1","episode":1,"season":1,"title_en":"Pilot","duration":2667},
    {"ID":30404,"post_name":"the-mentalist-s1e2","episode":2,"season":1,"title_en":"Red Hair and Silver Tape","duration":2567}
  ]},{"season":2,"episodes":[
    {"ID":30500,"post_name":"the-mentalist-s2e1","episode":1,"season":2,"title_en":"Pretty Red Balloon","duration":2610}
  ]}];
</script>
</body></html>
'''


def test_build_manifest_url():
    assert build_manifest_url('the-mentalist', 1, 2) == (
        'https://cdn3.puzzle-movies.com/1568697914/series/video/'
        'the-mentalist/s1e2/video_hd.mp4/master.m3u8'
    )


def test_extract_seasons_json():
    seasons = extract_seasons_json(SAMPLE_WEBPAGE)
    assert len(seasons) == 2
    assert seasons[0]['season'] == 1
    assert len(seasons[0]['episodes']) == 2
    assert seasons[1]['episodes'][0]['ID'] == 30500


def test_extract_seasons_json_missing_raises():
    with pytest.raises(ValueError):
        extract_seasons_json('<html>no episodes here</html>')


def test_select_episodes_single():
    seasons = extract_seasons_json(SAMPLE_WEBPAGE)
    matched = select_episodes(seasons, season=1, episode=2)
    assert len(matched) == 1
    assert matched[0]['ID'] == 30404
    assert matched[0]['season'] == 1


def test_select_episodes_season():
    seasons = extract_seasons_json(SAMPLE_WEBPAGE)
    matched = select_episodes(seasons, season=1)
    assert {ep['episode'] for ep in matched} == {1, 2}


def test_select_episodes_all():
    seasons = extract_seasons_json(SAMPLE_WEBPAGE)
    matched = select_episodes(seasons)
    assert len(matched) == 3


def test_select_episodes_no_match():
    seasons = extract_seasons_json(SAMPLE_WEBPAGE)
    assert select_episodes(seasons, season=9) == []


def test_valid_url_series():
    m = PuzzleMoviesIE._match_valid_url('https://puzzle-movies.com/the-mentalist')
    assert m.group('slug') == 'the-mentalist'
    assert m.group('season') is None
    assert m.group('episode') is None


def test_valid_url_season():
    m = PuzzleMoviesIE._match_valid_url(
        'https://puzzle-movies.com/the-mentalist#the-mentalist-s1')
    assert m.group('season') == '1'
    assert m.group('episode') is None


def test_valid_url_episode():
    m = PuzzleMoviesIE._match_valid_url(
        'https://puzzle-movies.com/the-mentalist#the-mentalist-s1e2')
    assert m.group('season') == '1'
    assert m.group('episode') == '2'


def test_valid_url_rejects_other_domain():
    assert PuzzleMoviesIE._match_valid_url('https://example.com/the-mentalist') is None


def test_real_extract_single_episode():
    ie = PuzzleMoviesIE()
    with mock.patch.object(PuzzleMoviesIE, '_download_webpage', return_value=SAMPLE_WEBPAGE), \
         mock.patch.object(PuzzleMoviesIE, '_extract_m3u8_formats', return_value=[{'format_id': 'hls-0'}]) as mock_formats:
        info = ie._real_extract('https://puzzle-movies.com/the-mentalist#the-mentalist-s1e2')

    expected_url = build_manifest_url('the-mentalist', 1, 2)
    mock_formats.assert_called_once_with(
        expected_url, '30404', 'mp4', headers={'Referer': 'https://puzzle-movies.com/'})

    assert info['id'] == '30404'
    assert info['season_number'] == 1
    assert info['episode_number'] == 2
    assert info['duration'] == 2567
    assert info['title'] == 'the-mentalist S1E2 - Red Hair and Silver Tape'
    assert info['formats'] == [{'format_id': 'hls-0'}]


def test_real_extract_season_playlist():
    ie = PuzzleMoviesIE()
    with mock.patch.object(PuzzleMoviesIE, '_download_webpage', return_value=SAMPLE_WEBPAGE), \
         mock.patch.object(PuzzleMoviesIE, '_extract_m3u8_formats', return_value=[]):
        result = ie._real_extract('https://puzzle-movies.com/the-mentalist#the-mentalist-s1')

    assert result['_type'] == 'playlist'
    entries = list(result['entries'])
    assert len(entries) == 2
    assert {e['episode_number'] for e in entries} == {1, 2}


def test_real_extract_whole_series_playlist():
    ie = PuzzleMoviesIE()
    with mock.patch.object(PuzzleMoviesIE, '_download_webpage', return_value=SAMPLE_WEBPAGE), \
         mock.patch.object(PuzzleMoviesIE, '_extract_m3u8_formats', return_value=[]):
        result = ie._real_extract('https://puzzle-movies.com/the-mentalist')

    entries = list(result['entries'])
    assert len(entries) == 3


def test_real_extract_missing_episodes_json_raises():
    ie = PuzzleMoviesIE()
    with mock.patch.object(PuzzleMoviesIE, '_download_webpage', return_value='<html>no data</html>'):
        with pytest.raises(ExtractorError):
            ie._real_extract('https://puzzle-movies.com/prices')
