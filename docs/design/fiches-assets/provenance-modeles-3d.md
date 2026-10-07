# Provenance des modèles 3D (dos des Pokémon en combat)

Les dos des Pokémon du joueur en combat sont **rendus** à partir des modèles 3D de *Pokémon X/Y*
(Nintendo 3DS, 2013) par `tools/art/blender/rendre_pokemon.py`, avec les réglages de
`tools/art/blender/dos_pokemon.json` (lancement : `tools/art/blender/rendre_lot.py`).

## 1. D'où viennent les modèles

- **Ce sont des fichiers extraits du jeu** (« rips »), pas des créations libres. Chaque archive
  porte un `Tag.txt` ou un `info.txt` : jeu, copyright, auteur de l'extraction, hébergeur.
- **Copyright : Nintendo, Game Freak, Creatures Inc.** Le fait qu'ils soient téléchargeables
  publiquement ne les rend pas libres de droits.
- **Hébergement** : The Models Resource (communauté The VG Resource),
  `https://models.spriters-resource.com/3ds/pokemonxy/` ; l'URL de chaque modèle est notée dans
  `dos_pokemon.json` (champ `source`).
- **Extraction** : Random Talking Bush (la plupart ; « remerciements à Ploaj »), TheBen et
  Random Talking Bush (Roucool, Tentacool), Mystie (Nosferapti, qui demande à être créditée).
- **Couverture** : 149 Pokémon de la première génération sur 151 sur la page X/Y ; **manquent
  Fantominus (n° 092) et Hypnomade (n° 097)**.

| N° | Pokémon | Extraction | Fichier utilisé |
|---|---|---|---|
| 001 | Bulbizarre | Random Talking Bush | SMD |
| 004 | Salamèche | Random Talking Bush | SMD |
| 007 | Carapuce | Random Talking Bush | SMD |
| 012 | Papilusion | Random Talking Bush | SMD (mâle) |
| 016 | Roucool | TheBen, Random Talking Bush | Collada |
| 025 | Pikachu | Random Talking Bush | SMD (mâle) |
| 041 | Nosferapti | Mystie | Collada (mâle) |
| 072 | Tentacool | TheBen, Random Talking Bush | Collada |
| 081 | Magnéti | (non précisé dans l'archive) | Collada |
| 093 | Spectrum | (non précisé dans l'archive) | Collada |
| 095 | Onix | (non précisé dans l'archive) | Collada |
| 109 | Smogo | (non précisé dans l'archive) | Collada |
| 129 | Magicarpe | Random Talking Bush | SMD (mâle) |

## 2. Ce que le projet en garde

- **Les modèles ne sont pas versionnés** : ils restent sur le Mac de Kevin, hors du dépôt, dans
  `~/dev/kanto-2026-modeles/art-pokemon-pilote/modeles/` (déplacés là le 2026-10-07 depuis
  `build/art/modeles/` de l'ancienne copie de travail `art-pokemon`, supprimée ; le même dossier
  garde les autres sorties du pilote : `ia/`, `officiel/`, `s21_pilote2/`). On le passe en premier
  argument de `tools/art/blender/rendre_lot.py`. Seuls les **rendus** (`assets/sprites/pokemon/battle_proto/dos3d_*.png`)
  et les **réglages** entrent dans le dépôt.
- Les rendus restent des **œuvres dérivées** de modèles sous copyright ; ils ont le même statut
  que les artworks officiels (PokeAPI) et que tout le reste du remake.

## 3. Ce que cela implique

- **Kanto 2026 est un projet personnel, jamais distribué** : ni APK publié, ni dépôt public, ni
  boutique. Cette dépendance ne change pas tant que cela reste vrai.
- **Si le projet devait un jour être partagé ou publié**, ces rendus (comme les artworks
  officiels, les noms et les designs des Pokémon) devraient être remplacés : la chaîne de rendu
  ne règle pas la question des droits.
- **Créditer** les auteurs des extractions (ci-dessus) dans les notes du projet ; Mystie le
  demande explicitement.
- Avant tout nouveau lot, noter la source et l'auteur de chaque modèle dans
  `dos_pokemon.json` et dans ce tableau.

## 4. Modèles d'IA du repeint (notebook Colab)

Tous téléchargés depuis Hugging Face par le notebook, sur la machine de Colab (rien n'est
versionné) :

| Rôle | Modèle | Source |
|---|---|---|
| Modèle d'illustration (Stable Diffusion 1.5) | AnyLoRA | `Lykon/AnyLoRA` |
| Style Pokémon (LoRA, entraîné sur des artworks officiels) | pokemon-lora | `juliensimon/stable-diffusion-v1-5-pokemon-lora` |
| Guidage par la profondeur | ControlNet v1.1 depth | `lllyasviel/control_v11f1p_sd15_depth` |
| Guidage par les traits | ControlNet v1.1 lineart anime | `lllyasviel/control_v11p_sd15s2_lineart_anime` |
| Référence de style (artwork officiel de face) | IP-Adapter SD 1.5 | `h94/IP-Adapter` |

Le LoRA « Pokémon » a été entraîné sur des images Pokémon sous copyright : même statut que le
reste (projet personnel, jamais distribué).
