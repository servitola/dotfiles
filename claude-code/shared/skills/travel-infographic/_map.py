"""Shared map utilities: Web Mercator math, great-circle interp, tile fetch."""

from __future__ import annotations

import math

TILE = 256
CARTO_TILE_URL = (
    "https://basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}.png"
)
USER_AGENT = "travel-infographic/1.0 (dotfiles skill)"


def latlon_to_world(lat: float, lon: float, zoom: int) -> tuple[float, float]:
    n = TILE * (1 << zoom)
    x = (lon + 180.0) / 360.0 * n
    sin_lat = math.sin(math.radians(lat))
    y = (0.5 - math.log((1 + sin_lat) / (1 - sin_lat)) / (4 * math.pi)) * n
    return x, y


def world_to_pixel(
    wx: float, wy: float, cx: float, cy: float, width: int, height: int
) -> tuple[float, float]:
    return wx - cx + width / 2.0, wy - cy + height / 2.0


def fit_zoom_center(
    stops: list[tuple[float, float]],
    width: int,
    height: int,
    padding: int = 80,
) -> tuple[int, float, float]:
    """Find max zoom and center that fits all stops within width x height (px) with padding."""
    if not stops:
        raise ValueError("empty stops")
    lats = [s[0] for s in stops]
    lons = [s[1] for s in stops]
    cx_lat = (min(lats) + max(lats)) / 2.0
    cx_lon = (min(lons) + max(lons)) / 2.0
    for zoom in range(18, 0, -1):
        xs = [latlon_to_world(la, lo, zoom)[0] for la, lo in stops]
        ys = [latlon_to_world(la, lo, zoom)[1] for la, lo in stops]
        if (max(xs) - min(xs)) < (width - 2 * padding) and (max(ys) - min(ys)) < (
            height - 2 * padding
        ):
            cwx, cwy = latlon_to_world(cx_lat, cx_lon, zoom)
            return zoom, cwx, cwy
    cwx, cwy = latlon_to_world(cx_lat, cx_lon, 1)
    return 1, cwx, cwy


def great_circle(
    lat1: float, lon1: float, lat2: float, lon2: float, n: int = 60
) -> list[tuple[float, float]]:
    if n < 2:
        return [(lat1, lon1), (lat2, lon2)]
    lat1r, lon1r = math.radians(lat1), math.radians(lon1)
    lat2r, lon2r = math.radians(lat2), math.radians(lon2)
    d = 2 * math.asin(
        math.sqrt(
            math.sin((lat2r - lat1r) / 2) ** 2
            + math.cos(lat1r) * math.cos(lat2r) * math.sin((lon2r - lon1r) / 2) ** 2
        )
    )
    if d == 0:
        return [(lat1, lon1)] * n
    pts = []
    for i in range(n):
        f = i / (n - 1)
        a = math.sin((1 - f) * d) / math.sin(d)
        b = math.sin(f * d) / math.sin(d)
        x = a * math.cos(lat1r) * math.cos(lon1r) + b * math.cos(lat2r) * math.cos(lon2r)
        y = a * math.cos(lat1r) * math.sin(lon1r) + b * math.cos(lat2r) * math.sin(lon2r)
        z = a * math.sin(lat1r) + b * math.sin(lat2r)
        lat = math.atan2(z, math.sqrt(x * x + y * y))
        lon = math.atan2(y, x)
        pts.append((math.degrees(lat), math.degrees(lon)))
    return pts


def straight_line(
    lat1: float, lon1: float, lat2: float, lon2: float, n: int = 40
) -> list[tuple[float, float]]:
    return [
        (lat1 + (lat2 - lat1) * i / (n - 1), lon1 + (lon2 - lon1) * i / (n - 1))
        for i in range(n)
    ]


def fetch_base_map(width: int, height: int, zoom: int, cwx: float, cwy: float):
    """Render base map via staticmap using our pre-computed zoom + center."""
    import math as _m
    from staticmap import StaticMap

    n_tiles = 1 << zoom
    world_size = TILE * n_tiles
    center_lon = cwx / world_size * 360.0 - 180.0
    yf = cwy / world_size
    center_lat = _m.degrees(_m.atan(_m.sinh(_m.pi * (1 - 2 * yf))))
    m = StaticMap(width, height, url_template=CARTO_TILE_URL)
    img = m.render(zoom=zoom, center=(center_lon, center_lat))
    return img.convert("RGBA")
