"""Avaliação offline do recomendador do cadence.

Não há avaliações de usuários reais, então a tarefa-proxy é *recuperação do
artista*: para cada álbum de um artista com 2+ álbuns no catálogo, o artista é
escondido do vetor e os vizinhos mais próximos são calculados só pelas tags.
Se as tags descrevem bem o som, outros álbuns do mesmo artista devem aparecer
no topo. É uma medida conservadora: dois discos do mesmo artista podem soar
diferentes, e álbuns parecidos de artistas diferentes contam como "erro".

Compara três representações:
  - aleatório (piso)
  - contagem bruta das tags (cosseno)
  - TF-IDF normalizado (o que o app usa, lib/shared/recommender/recommender.dart)

Uso: python3 tools/evaluate.py   (sem dependências)
"""
import json
import math
import random
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "assets" / "data" / "catalog.json"
K = 10


def load():
    albums = json.loads(CATALOG.read_text())["albums"]
    return [a for a in albums if a.get("tags")]


def normalize(v):
    n = math.sqrt(sum(x * x for x in v.values()))
    return {k: x / n for k, x in v.items()} if n else v


def dot(a, b):
    if len(a) > len(b):
        a, b = b, a
    return sum(x * b.get(k, 0.0) for k, x in a.items())


def raw_vectors(albums):
    return [normalize(dict(a["tags"])) for a in albums]


def tfidf_vectors(albums):
    n = len(albums)
    df = defaultdict(int)
    for a in albums:
        for t in a["tags"]:
            df[t] += 1
    idf = {t: math.log((1 + n) / (1 + d)) + 1 for t, d in df.items()}
    out = []
    for a in albums:
        m = max(a["tags"].values()) or 1
        out.append(normalize({t: (c / m) * idf[t] for t, c in a["tags"].items()}))
    return out


def evaluate(albums, vectors, rng=None):
    by_artist = defaultdict(list)
    for i, a in enumerate(albums):
        by_artist[a["artist"].lower()].append(i)

    precisions, rrs, hits = [], [], 0
    queries = [i for i, a in enumerate(albums) if len(by_artist[a["artist"].lower()]) > 1]
    for q in queries:
        relevant = set(by_artist[albums[q]["artist"].lower()]) - {q}
        others = [i for i in range(len(albums)) if i != q]
        if rng:
            rng.shuffle(others)
            ranked = others
        else:
            ranked = sorted(others, key=lambda i: dot(vectors[q], vectors[i]), reverse=True)
        top = ranked[:K]
        rel_in_top = sum(1 for i in top if i in relevant)
        precisions.append(rel_in_top / min(K, len(relevant)))
        hits += rel_in_top > 0
        rank = next(r for r, i in enumerate(ranked, 1) if i in relevant)
        rrs.append(1 / rank)
    n = len(queries)
    return {"queries": n, "recall@10": sum(precisions) / n, "hit@10": hits / n, "MRR": sum(rrs) / n}


def main():
    albums = load()
    print(f"{len(albums)} álbuns com tags, tarefa: recuperar o mesmo artista só pelas tags\n")
    rows = [
        ("aleatório", evaluate(albums, None, rng=random.Random(0))),
        ("contagem bruta", evaluate(albums, raw_vectors(albums))),
        ("TF-IDF (app)", evaluate(albums, tfidf_vectors(albums))),
    ]
    print(f"{'representação':<16} {'consultas':>9} {'recall@10':>10} {'hit@10':>8} {'MRR':>7}")
    for name, r in rows:
        print(f"{name:<16} {r['queries']:>9} {r['recall@10']:>10.3f} {r['hit@10']:>8.3f} {r['MRR']:>7.3f}")


if __name__ == "__main__":
    main()
