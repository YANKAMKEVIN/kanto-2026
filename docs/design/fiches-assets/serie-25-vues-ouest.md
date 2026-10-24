# Série 25 — vues générales du chemin ouest et de Parmanie (J22 T9, moitié ouest)

> 2026-10-19, branche `j22-t9-vues-ouest` (depuis `jalon-22`). Vues de **DA et de composition** :
> la **grille fait foi** (`tools/plans/route_16_west.txt`, `route_16_gate.txt`, `route_17.txt`,
> `route_18.txt`, `route_18_gate.txt`, `parmanie.txt`). Les écarts ci-dessous ne seront pas reproduits.

- Génération : `tools/art/generer.sh` (Codex), un prompt par image
  `tools/art/prompts/CONCEPT_<ZONE>_VUE_GENERALE_r1.txt` ; pièces jointes : plan en aplats **sans
  annotation** (`python3 -I tools/art/plan_aplats_j22_codex.py . build/plans/j22o`) + une vue validée
  (Carmin pour les vues paysage et Parmanie, Route 6 pour la Route 17, maison de Léo pour les postes).
  Lumière **neutre** (bloc du J21). Toutes les vues sont des **r1** (aucune itération : quota Codex).
- Planche : `docs/design/reference/j22-vues-ouest-v1.png` (`tools/art/planche_j22_vues_ouest.py`).
- Refus de Codex : aucun. Un premier lancement (15 h 23) a échoué sur la **limite d'usage** de Codex,
  pas sur un refus ; relancé à 16 h 06 en deux vagues de 4.

## Écarts par vue

| Vue | Écarts avec la grille (non reproduits) |
|---|---|
| `route-16-ouest-vue-generale-v1.png` | Poste vu seulement par sa façade sud : la **porte nord** (35..36, 9) vers la voie haute n'est pas peinte ; barrières de la Piste en **lisses fines** au lieu de 2 cases ; alcôves de la falaise et de la forêt à peine marquées ; sortie sud un peu plus à droite. |
| `route-17-vue-generale-v1-t1/t2/t3.png` | La **pente** (`s`) et les paliers (`k`) ont le même béton : la pente ne se lit pas ; barrière centrale en **lisse fine** et non en case pleine ; **tronçon 2** : le **goulet** de 3 cases (rangées 92..95) n'est qu'esquissé (la Piste se resserre sans vraie avancée de forêt) ; alcôves approximatives ; rive rocheuse plus large que 2 cases. |
| `route-18-vue-generale-v1.png` | **Poste** petit et peint comme un pavillon à porte sud : ses portes **ouest et est** (45, 11..12) et (52, 11..12) ne se voient pas ; il fait ≈ 4 cases au lieu de 8 × 9 ; entrée nord de la Piste trop à gauche ; berge pêchable de l'étang non distinguée. |
| `parmanie-vue-generale-v1.png` | Très proche de la grille. Enclos **vides** (abris, abreuvoirs, troncs : décor à reprendre en objets séparés) ; Arène à **porte vitrée** et petit jardin de pins (la porte reste fermée, J23) ; Centre et Boutique **sans emblème** (conforme) ; bâtiments un peu plus petits que leurs emprises ; le muret du couloir sud (colonne 33) est peint, le bord sud reste fermé par la forêt (la grille l'ouvre au J24). |
| `poste-16-v1.png` | Conforme (deux couloirs, deux portes chacun, deux comptoirs, plantes) ; perspective plus plongeante que la grille (murs latéraux visibles) ; dalles claires. |
| `poste-18-v1.png` | Portes **ouest et est** peintes dans les murs latéraux ; comptoir plus long et décalé vers le bas (grille : (2..4, 4)) ; un **tableau** au mur du fond en plus ; plantes conformes. |

Aucun personnage, Pokémon, texte ni emblème dans les huit images (vérifié à l'œil).
