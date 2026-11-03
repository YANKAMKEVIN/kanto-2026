# Série Johto — vues générales de l'acte 1 (JOH1 à JOH5)

> 2026-11-03, branche `claude/johto-vues-acte1` depuis `main`. Vues de **DA et de composition** ; la
> géométrie vient des grilles validées de `tools/plans/` (JOH1 à JOH9 validées par Kevin les 2026-11-02 et
> 2026-11-03), qui **font foi**. Les écarts ci-dessous ne seront pas reproduits au code.

Méthode (modèle du J22, T9) : `python3 tools/art/vues_johto_acte1.py --plans johN` (plans en aplats SANS
annotation, joints à Codex, `build/art/PLAN_*_codex.png`), puis `tools/art/generer.sh` avec un prompt versionné
par image (`tools/art/prompts/CONCEPT_<ZONE>_VUE_GENERALE_r*.txt` : ADN v1, **lumière NE** (les profils
`johto_*` du JOH0 portent l'éclairage), aucun personnage ni Pokémon, aucun texte). Plans annotés qui font foi :
`--plans-annotes johN` → `docs/design/reference/plans-johto/<carte>-plan-v1.png`. Planche de relecture :
`--planche johN` → `docs/design/reference/johN-vues-v1.png` (chaque vue à côté de son plan annoté).

Défauts pris **[D]**, à confirmer par Kevin sur la planche du JOH1 :

- **Kit de bâtiments de Kanto repris tel quel à Johto** : Centre (toit rouge) et Boutique (toit bleu)
  identiques à ceux de Kanto, maisons de même facture ; aucun dossier Johto ne demande une architecture
  propre.
- **Rues pavées** à Oliville (la grille les note `p` pavé), là où Kanto a des rues de terre battue.
- **Grottes marines** : roche sombre humide, eau turquoise au bord et bleu profond au large, rais de lumière
  tombant des fissures (dossier JOH-02 §3.2 : profil `cave_1f` éclairci de bleu) ; référence de style jointe
  = Îles Écume B4F (même roche, même eau, sans glace).
- **Ombre de Lugia** peinte dans la salle 2 (silhouette floue sous l'eau profonde), seule entorse à
  « aucun Pokémon » : la cinématique O-6 la montrera en jeu, la vue sert de repère.

## JOH1 — grotte marine et Oliville (planche `joh1-vues-v1.png`)

| Vue | Essai retenu | Référence(s) jointe(s) |
|---|---|---|
| `grotte-marine-1-vue-generale-v1.png` | r1 / 1 | `iles-ecume-b4f-vue-generale-v1.png` |
| `grotte-marine-2-vue-generale-v1.png` | r1 / 1 | salle 1 (ci-dessus) + `iles-ecume-b4f-vue-generale-v1.png` |
| `oliville-vue-generale-v1.png` | r1 / 1 | `carmin-vue-generale-v1.png` |

Codex : aucun refus, trois images en un essai chacune (≈ 2 min par image).

### Écarts avec les grilles (la grille fait foi)

- **Grotte marine, salle 1** : les groupes de rochers isolés sont rendus en une rangée de trois rochers
  (grille : blocs de 3 × 2 au nord-est et 3 × 3 au sud-ouest) ; le chenal de sortie sud paraît un peu plus
  large que ses 2 cases ; le courant est peint en deux traînées d'écume (lisible, conforme au sens).
- **Grotte marine, salle 2** : les groupes de rochers sont rendus en 2 × 2 (grille : 3 × 3) ; le chenal du
  courant est peint comme une **cascade** qui descend vers la plage, alors que la grille le veut **à plat**,
  au niveau de l'eau (le jeu y posera une glissade sur l'eau, sans dénivelé) ; la brèche de sortie, l'îlot du
  sud-est et le gouffre central sont conformes.
- **Oliville** : l'avenue s'arrête contre la forêt avant le bord est (la grille sort par le bord, x 49,
  vers la Route 39) ; le dessus de la falaise ouest et du promontoire est couvert de verdure (grille :
  rochers nus) ; la rue du quai et le quai sont un peu plus courts à l'ouest ; la petite haie du nord-est
  (y 23) est rendue à droite de l'avenue, conforme ; phare, bouche de grotte, plage de galets, deux pontons,
  caisses, récifs du sud et leur ouverture centrale : conformes.
- **Toutes** : lumière neutre respectée (Oliville blanche et diffuse ; grottes en pénombre bleue froide).

## JOH2 à JOH5

À faire après validation du style sur le JOH1 (Routes 39 et 38, Rosalia ; Routes 37, 36, 35, Doublonville,
souterrain ; Route 34, Bois aux Chênes, Écorcia, Puits Ramoloss ; Tour Radio 1F à 5F).
