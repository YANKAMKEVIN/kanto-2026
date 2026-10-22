# Série 25 — vues générales du chemin est (jalon 22, T9, moitié est)

> 2026-10-19, branche `j22-t9-vues-est` depuis `jalon-22`. Vues de **DA et de composition** ; la
> géométrie vient des grilles validées (`tools/plans/route_12_sud.txt`, `route_13.txt`, `route_14.txt`,
> `route_15.txt`, `route_15_gate.txt`), qui **font foi**. Les écarts ci-dessous ne seront pas reproduits.

Méthode : `python3 tools/art/vues_est_j22.py --plans` (plans en aplats SANS annotation, joints à Codex,
`build/art/PLAN_*_codex.png`), puis `tools/art/generer.sh` avec un prompt versionné par image
(`tools/art/prompts/CONCEPT_<ZONE>_VUE_GENERALE_r*.txt` : ADN v1, **lumière NE**, aucun personnage ni
Pokémon, aucun texte). Planche : `--planche` → `docs/design/reference/j22-vues-est-v1.png` (chaque vue à
côté de son plan annoté). Codex : **aucun refus** ; une limite d'usage (levée à 15 h 56) a retardé la passe.

| Vue | Essai retenu | Référence jointe |
|---|---|---|
| `route-12-sud-vue-generale-v1.png` | r1 / 1 | vue de la Route 12 nord (J21) |
| `route-13-vue-generale-v1.png` | r1 / 1 | `route-25-vue-generale-v1.png` |
| `route-14-vue-generale-v1.png` | r1 / 1 | `route-6-vue-generale-v1.png` |
| `route-15-vue-generale-v1.png` | r2 / 2 (r1 : portes latérales du poste illisibles) | `route-25` + r1 |
| `poste-15-v1.png` | r1 / 1 | `maison-leo-v1.png` |

## Écarts avec les grilles (la grille fait foi)

- **Route 12 sud** : la bande pêchable (`f`) n'a pas de teinte distincte ; le ponton du nord est un peu
  plus long que la grille et le petit ponton de pêche plus court ; l'alcôve du Jeune Dresseur (y 32, à
  l'est du chemin) et l'éperon de la Pépite sont à peine marqués ; quelques nasses et une canne ajoutées
  contre la maison (accessoires, pas de collision).
- **Route 13** : la bande d'eau pêchable de la berge n'est pas plus claire ; les clôtures verticales
  de l'ouest sont plus courtes et leurs passages approximatifs ; les deux courts tronçons verticaux de
  l'est sont décalés ; les bosquets carrés sont rendus en buissons groupés.
- **Route 14** : les trouées de la rangée d'arbres (vers les herbes) ne se lisent pas ; la pelouse en
  haut de la bande d'herbes est plus courte ; les bosquets carrés sont rendus en arbres ronds isolés.
- **Route 15** : le poste est **trop bas** (≈ 4 cases au lieu de 9 : la grille le prolonge au sud du
  chemin, rangées 13..16) et sans le dégagement d'herbe à l'ouest (x 37..40) ; la poche nord de la CT20
  (x 10..13, y 3..4) est réduite ; les portes latérales sont bien présentes (r2).
- **Poste 15** : l'étage montre aussi deux paillassons latéraux alors qu'il n'a pas de porte ; les
  fenêtres de l'étage sont dans le mur du fond (la grille ne fixe que les jumelles en (15, 3) et
  (20, 3)) ; plante et table conformes ; pièces un peu plus profondes que 5 rangées de sol.
- **Toutes** : lumière plus chaude que la variante NE demandée sur la Route 14 (légère teinte dorée) ;
  Godot porte l'éclairage.
