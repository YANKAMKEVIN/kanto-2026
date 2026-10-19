#!/usr/bin/env python3
"""Inventorie les effets déclarés mais ignorés et leurs apprentissages, sans modifier le jeu."""

import argparse
import json
from pathlib import Path


def load_entries(folder: Path) -> dict:
    if not folder.is_dir():
        raise FileNotFoundError(folder)
    entries = {}
    for path in sorted(folder.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        duplicates = entries.keys() & data.keys()
        if duplicates:
            raise ValueError(f"Identifiants en double dans {path}: {sorted(duplicates)}")
        entries.update(data)
    if not entries:
        raise ValueError(f"Aucune donnée dans {folder}")
    return entries


def audit(root: Path) -> dict:
    moves = load_entries(root / "data/pokemon/moves")
    species = load_entries(root / "data/pokemon/species")
    result = []
    for move_id, move in sorted(moves.items()):
        if not move.get("pending_effects"):
            continue
        learners = []
        for species_id, pokemon in sorted(species.items()):
            for level, learned_move in pokemon.get("learnset", []):
                if learned_move == move_id:
                    learners.append({"species": species_id, "name": pokemon["name"],
                                     "level": level})
        result.append({"id": move_id, "name": move["name"],
                       "pending_effects": move["pending_effects"], "learners": learners})
    return {"species_count": len(species), "move_count": len(moves), "pending": result}


def markdown(report: dict) -> str:
    lines = ["# Audit des capacités incomplètes", "",
             f"{report['species_count']} espèces, {report['move_count']} capacités, "
             f"{len(report['pending'])} capacités avec effets en attente.", "",
             "Les niveaux ci-dessous sont des apprentissages déclarés dans les données ;",
             "ils ne prouvent pas qu'une espèce est déjà rencontrable dans l'aventure.", "",
             "| Capacité | Effets ignorés | Apprentissages déclarés |",
             "|---|---|---|"]
    for move in report["pending"]:
        learners = ", ".join(f"{p['name']} N{p['level']}" for p in move["learners"])
        lines.append(f"| {move['name']} (`{move['id']}`) | "
                     f"{', '.join(move['pending_effects'])} | {learners or 'Aucun'} |")
    lines.extend(["", "Généré par `python3 tools/audit_pending_moves.py`. Aucun effet n'est",
                  "activé ou remplacé par cet outil. Compléter les règles et leur présentation",
                  "avant de retirer un marqueur `pending_effects`."])
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="Sortie structurée")
    args = parser.parse_args()
    report = audit(Path(__file__).resolve().parents[1])
    print(json.dumps(report, ensure_ascii=False, indent=2) if args.json else markdown(report),
          end="\n" if args.json else "")


if __name__ == "__main__":
    main()
