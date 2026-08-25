import json
import re

from yt_dlp.extractor.common import InfoExtractor
from yt_dlp.utils import ExtractorError

# Fixed sitewide CDN bucket id, verified empirically to be identical across
# unrelated series (the-mentalist, friends, breaking-bad) — not per-video.
_CDN_BUCKET_ID = '1568697914'


def build_manifest_url(slug, season, episode):
    return (
        f'https://cdn3.puzzle-movies.com/{_CDN_BUCKET_ID}/series/video/'
        f'{slug}/s{season}e{episode}/video_hd.mp4/master.m3u8'
    )


def extract_seasons_json(webpage):
    match = re.search(r'var\s+episodes\s*=\s*(\[.+?\]);', webpage, re.DOTALL)
    if not match:
        raise ValueError('episodes JSON blob not found on page')
    return json.loads(match.group(1))


def select_episodes(seasons, season=None, episode=None):
    matched = []
    for season_block in seasons:
        if season is not None and season_block.get('season') != season:
            continue
        for ep in season_block.get('episodes', []):
            if episode is not None and ep.get('episode') != episode:
                continue
            matched.append({**ep, 'season': season_block.get('season')})
    return matched


class PuzzleMoviesIE(InfoExtractor):
    IE_NAME = 'puzzlemovies'
    _VALID_URL = (
        r'https?://(?:www\.)?puzzle-movies\.com/(?P<slug>[\w-]+)'
        r'(?:#(?P=slug)-s(?P<season>\d+)(?:e(?P<episode>\d+))?)?/?$'
    )

    def _real_extract(self, url):
        match = self._match_valid_url(url)
        slug = match.group('slug')
        season = int(match.group('season')) if match.group('season') else None
        episode = int(match.group('episode')) if match.group('episode') else None

        webpage = self._download_webpage(f'https://puzzle-movies.com/{slug}', slug)
        try:
            seasons = extract_seasons_json(webpage)
        except ValueError as e:
            raise ExtractorError(f'puzzlemovies: {e}', video_id=slug, expected=True) from e

        episodes = select_episodes(seasons, season=season, episode=episode)
        if not episodes:
            raise ExtractorError(
                f'puzzlemovies: no matching episode(s) for season={season} episode={episode}',
                video_id=slug, expected=True)

        if episode is not None:
            return self._episode_info(slug, episodes[0])

        return self.playlist_result(
            [self._episode_info(slug, ep) for ep in episodes],
            playlist_id=slug,
            playlist_title=slug,
        )

    def _episode_info(self, slug, ep):
        season, episode = ep['season'], ep['episode']
        manifest_url = build_manifest_url(slug, season, episode)
        formats = self._extract_m3u8_formats(
            manifest_url, str(ep['ID']), 'mp4',
            headers={'Referer': 'https://puzzle-movies.com/'})
        return {
            'id': str(ep['ID']),
            'title': f"{slug} S{season}E{episode} - {ep.get('title_en') or ep.get('post_name')}",
            'duration': ep.get('duration'),
            'formats': formats,
            'season_number': season,
            'episode_number': episode,
        }
