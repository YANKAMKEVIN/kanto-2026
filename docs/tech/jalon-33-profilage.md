# Jalon 33 — Profilage Android (T3, 33C)

> Relevé du 2026-10-29 sur `claude/keen-mendel-9dc0bd` (@ `3aaa86e9` + correctifs du script), build **debug**, `tools/profile_s24.sh`. Aucune optimisation, aucun changement de jeu (gel fonctionnel).

## 1. Appareil : A17, pas S24

Le S24 n'était pas disponible (en usage, Ne pas déranger désactivé, non branché) ; **Kevin a demandé l'A17** (Galaxy A17, `R5GYB2R7W2Y`, Mali-G57, écran 2340×1080, branché USB, ≈ 21–28 % de batterie, 32–33 °C, luminosité manuelle 128). L'A17 était retiré depuis le 2026-10-27 (câble instable : il est passé « offline » une fois pendant la mise au point). **Ces chiffres sont une borne basse ; la cible du J33 reste le S24 : à refaire avec `tools/profile_s24.sh` quand il est libre et en Ne pas déranger** (le script refuse sinon ; `--allow-no-dnd` n'a servi que pour l'A17). Sauvegarde : aucune sur l'A17 avant la session ; vérification « identique » (empreintes) à chaque sortie.

L'A17 plafonne à ≈ 50 i/s dehors, même sur un écran vide (déjà noté aux J17–J28) : à lire comme un plafond d'appareil, pas comme une régression.

**Décision de Kevin (2026-10-29) : le S24 ne sert pas de référence pour le moment ; les mesures de l'A17 sont validées comme référence du J33 T3.** Le S24 reste une option pour T7 (script prêt).

## 2. Résultats (run complet de ~20 min, `qa-profilage/run-complet-a17.md`)

| Profil | Départ | i/s moyen | image la + lente | draw max | tex max (Mo) |
|---|---|---|---|---|---|
| Extérieur | `route_6` | 51,1 | 7 i/s (chargement) | 206 | 339 |
| Ville | Céladopole | 49,5 | 7 | 307 | 317 |
| Ville | Safrania | 49,8 | 7 | 238 | 325 |
| Grand donjon | Grotte Azurée 1F | 51,3 | 7 | 174 | 317 |
| Donjon sombre | Grotte Sombre B1F | 48,6 | 11 | 72 | 289 |
| Combat | Route 5 (Rattata N4) | 48,6 | 16 | 239 | 304 |
| Stockage | Centre de Jadielle | 32,8 (menu ouvert) | 7 | 228 | 267 |
| **RP-093** Quai de Carmin | `vermilion_dock` | **51,7** | 24 | 187 | 323 |

(« fenêtres < 55 i/s » : presque toutes, plafond de l'appareil.)

**Mémoire** (échantillon toutes les 20 s, `qa-profilage/run-complet-a17-mem.csv`) : PSS de l'appli 900–955 Mo (pic 976 Mo), graphique ≈ 550–570 Mo, natif ≈ 220–290 Mo, **sans dérive** sur la session (≈ 20 min, 14 cartes relancées) ; creux à 470 Mo dans la Grotte Sombre. Température 32,2 → 33,1 °C sur USB ; la consommation n'est pas mesurable branché (protocole en tête du script : sur batterie, passer en débogage sans fil).

## 3. Registre

- **RP-091** (textures > 64 Mo) : sur l'A17, `tex` vaut **225–339 Mo** selon la carte (extérieurs 295–340, villes 310–325, grottes et intérieurs 225–285 ; Manoir B1F 225). Le compteur est celui du moteur (`RENDER_TEXTURE_MEM_USED`), donc plus large que « carte + voisines » ; le repère de 64 Mo est dépassé partout, **sans lien visible avec la cadence**. Table carte par carte : `run-complet-a17.md`. **Décision pour T7 (à prendre avec les mesures S24)** : soit relever le repère (ex. 350 Mo), soit réduire ; rien n'est justifié par ces mesures.
- **RP-093** (Carmin, quai, 26–27 i/s avant le moteur commun) : **51,7 i/s** sur A17, soit son plafond. Non reproduit ; à confirmer sur S24 (`--profiles rp093`).
- **RP-261** (entrée en combat, flipbooks) : à l'entrée, `tex` passe de 294 à 303 Mo (**+10 Mo**, pas +156), image la plus lente de la fenêtre **16–20 i/s (≈ 50–60 ms)** vs 30–35 hors entrée ; ensuite stable à 47–50 i/s. Pas de problème mesurable sur A17 (`combat-rp261-a17.txt`).
- **RP-263** (1er usage d'un effet) : 1re Morsure : image la plus lente 23 i/s (≈ 43 ms) sur A17 ; rien de comparable aux 8,1 i/s du S24 (Charge) : à remesurer sur S24 avec Charge.
- **RP-266 (nouveau)** : **Stockage** : à l'ouverture, une image de 143 ms (7 i/s) puis **32–33 i/s** tant que le menu est ouvert (fond de scène flouté, draw 228, +14 Mo de textures) — le plus bas de tous les profils (sur A17). À vérifier sur S24 avant toute décision.

## 4. Reproduire

```bash
tools/profile_s24.sh --check                  # protocole seulement
tools/profile_s24.sh                          # S24, ≈ 30 min (DND exigé)
ANDROID_SERIAL=R5GYB2R7W2Y tools/profile_s24.sh --allow-no-dnd --no-build   # A17
```
Sortie : `build/qa/profile_s24/<horodatage>/` ; copies de référence : `docs/tech/qa-profilage/`.
