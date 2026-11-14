"""Gera assets/data/catalog.json a partir do MusicBrainz e do Cover Art Archive.

Uso: python3 tools/build_catalog.py
Entrada: tools/seed_albums.txt (uma linha "Artista | Título").
"""
import json
from concurrent.futures import ThreadPoolExecutor
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEED = ROOT / "tools" / "seed_albums.txt"
OUT = ROOT / "assets" / "data" / "catalog.json"
UA = "cadence-catalog/1.0 (https://github.com/danmartsarr/cadence)"
MB = "https://musicbrainz.org/ws/2"
NOISE = {"albums i own", "seen live", "favorite", "favourite", "vinyl", "cd", "lp", "owned", "album"}


def get(url, method="GET"):
    req = urllib.request.Request(url, headers={"User-Agent": UA}, method=method)
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=25) as r:
                return r.status if method == "HEAD" else json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            time.sleep(3 + attempt * 3)
        except Exception:
            time.sleep(3 + attempt * 3)
        finally:
            if url.startswith(MB):
                time.sleep(1.05)
    return None


def lucene(s):
    return re.sub(r'([+\-!(){}\[\]^"~*?:\\/&|])', r"\\\1", s)


def find_release_group(artist, title):
    for extra in (" AND primarytype:album", ""):
        q = f'releasegroup:"{lucene(title)}" AND artist:"{lucene(artist.split(";")[0])}"{extra}'
        data = get(f"{MB}/release-group/?query={urllib.parse.quote(q)}&limit=3&fmt=json")
        hits = (data or {}).get("release-groups", [])
        if hits and hits[0].get("score", 0) >= 80:
            return hits[0]["id"]
    return None


def clean_tags(raw, artist, scale=1.0):
    out = {}
    for t in raw or []:
        name = t["name"].strip().lower()
        if t.get("count", 0) < 1 or name in NOISE or name == artist.lower() or re.fullmatch(r"\d{4}", name):
            continue
        out[name] = out.get(name, 0) + t["count"] * scale
    return out


def pick_release(releases):
    official = [r for r in releases if r.get("status") == "Official"] or releases
    official.sort(key=lambda r: r.get("date") or "9999")
    return official[0]["id"] if official else None


def build(artist_seed, title_seed):
    rgid = find_release_group(artist_seed, title_seed)
    if not rgid:
        return None
    rg = get(f"{MB}/release-group/{rgid}?inc=tags+ratings+releases+artist-credits&fmt=json")
    if not rg:
        return None
    credit = rg.get("artist-credit", [])
    artist = "".join(c["name"] + c.get("joinphrase", "") for c in credit) or artist_seed
    tags = clean_tags(rg.get("tags"), artist)
    if len(tags) < 4 and credit:
        a = get(f"{MB}/artist/{credit[0]['artist']['id']}?inc=tags&fmt=json")
        for k, v in clean_tags((a or {}).get("tags"), artist, 0.5).items():
            tags[k] = tags.get(k, 0) + v
    if len(tags) < 2:
        return None
    cover = f"https://coverartarchive.org/release-group/{rgid}/front-500"
    tracks = []
    rid = pick_release(rg.get("releases", []))
    if rid:
        rel = get(f"{MB}/release/{rid}?inc=recordings&fmt=json") or {}
        for medium in rel.get("media", []):
            for t in medium.get("tracks", []):
                tracks.append({"title": t["title"], "ms": t.get("length")})
    date = rg.get("first-release-date") or ""
    rating = rg.get("rating") or {}
    top = dict(sorted(tags.items(), key=lambda kv: -kv[1])[:15])
    return {
        "mbid": rgid,
        "title": rg["title"],
        "artist": artist,
        "year": int(date[:4]) if date[:4].isdigit() else None,
        "cover": cover,
        "rating": rating.get("value"),
        "votes": rating.get("votes-count", 0),
        "tags": {k: round(v, 2) for k, v in top.items()},
        "tracks": tracks[:30],
    }


def main():
    seeds = [l.split("|") for l in SEED.read_text().splitlines() if "|" in l]
    albums, missed = [], []
    for n, (artist, title) in enumerate(seeds, 1):
        album = build(artist.strip(), title.strip())
        if album and all(a["mbid"] != album["mbid"] for a in albums):
            album["id"] = f"a{len(albums):03d}"
            albums.append(album)
        else:
            missed.append(f"{artist.strip()} | {title.strip()}")
        print(f"{n}/{len(seeds)} ok={len(albums)} {title.strip()}", file=sys.stderr, flush=True)
    with ThreadPoolExecutor(8) as pool:
        has_cover = list(pool.map(lambda a: get(a["cover"], method="HEAD") is not None, albums))
    missed += [f"{a['artist']} | {a['title']} (sem capa)" for a, ok in zip(albums, has_cover) if not ok]
    albums = [a for a, ok in zip(albums, has_cover) if ok]
    for i, a in enumerate(albums):
        a["id"] = f"a{i:03d}"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"source": "MusicBrainz + Cover Art Archive", "albums": albums},
                              ensure_ascii=False, separators=(",", ":")))
    print(f"{len(albums)} álbuns; faltaram: {missed}", file=sys.stderr)


if __name__ == "__main__":
    main()
