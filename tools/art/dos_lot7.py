#!/usr/bin/env python3
"""Sept dos de combat par la voie 3D (RP-010) : Tortank, Rondoudou, Kadabra, Alakazam, Ossatueur,
Voltali, Mew, refusés par Codex et ChatGPT. Mêmes étapes que `dos_t13.py`, autre lot.

Dossier de travail (hors dépôt) : ~/dev/kanto-2026-modeles/dos_lot7/.

Usage :
  tools/art/dos_lot7.py installer [zip ...]  extrait les archives X/Y de ~/Downloads
  tools/art/dos_lot7.py rendre [--vues]      passes couleur et profondeur ; --vues : orientation
  tools/art/dos_lot7.py notebook             écrit kanto_dos_lot7.ipynb (Colab)
  tools/art/dos_lot7.py importer [zip] [--retenir 009=ipa0_g7 ...]
                                             zip Colab, puis copie dans assets/sprites/pokemon/dos/
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

os.environ.setdefault("DOS_T13", str(Path.home() / "dev/kanto-2026-modeles/dos_lot7"))
import dos_t13  # noqa: E402

dos_t13.LOT = {
	"009": ("blastoise", "Blastoise"), "039": ("jigglypuff", "Jigglypuff"),
	"064": ("kadabra", "Kadabra"), "065": ("alakazam", "Alakazam"), "105": ("marowak", "Marowak"),
	"135": ("jolteon", "Jolteon"), "151": ("mew", "Mew"),
}
dos_t13.SANS_IPA = ",".join(dos_t13.LOT)  # le dos diffère de la face : pas d'artwork de face
dos_t13.ZIP_COLAB = "kanto_dos_lot7.zip"
dos_t13.PROTO = dos_t13.RACINE / "assets/sprites/pokemon/dos"

if __name__ == "__main__":
	if sys.argv[1:2] == ["hypno-prompts"]:
		sys.exit(__doc__)
	dos_t13.main()
