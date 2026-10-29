# DAF.4 « Fin du jeu » — part déjà dans `main` (2026-10-27)

**Validé par Kevin le 2026-10-27 (DA-6, planches de contact).** (Arène de Jadielle et son fond de combat.)

Fait avec DAF.3, même branche (`claude/daf-3-4-9713b9`), même outil : la fiche commune est
[../daf-3/fiche.md](../daf-3/fiche.md).

- **Fait** : Arène de Jadielle en modules (dalles, murs, flèches et cases d'arrêt peints) et son fond
  de combat `viridian_gym_sol` — planche [planche-1-arene-jadielle.jpg](planche-1-arene-jadielle.jpg),
  fond dans [../daf-3/planche-6-fonds-combat.jpg](../daf-3/planche-6-fonds-combat.jpg).
## Suite du lot (2026-10-27, branche `claude/daf-4-j29-j31`, depuis `main` @ `ef1fff46`) — **validée par Kevin le 2026-10-27 (DA-6)**

Outils : `tools/art/daf4.py` (prompts, Codex, préparation), `tools/build_daf4_caves.gd` et
`tools/build_daf4_facades.gd` (secondes passes d'image : la logique des cartes ne change pas),
`tools/capture_daf4.sh`, `tools/art/planches_daf4.py`.

| Planche | Contenu |
|---|---|
| [synthese-telephone.jpg](synthese-telephone.jpg) | **à lire en premier, sur le téléphone** |
| [planche-2-route-victoire.jpg](planche-2-route-victoire.jpg) | Route Victoire 1F, 2F, 3F avant / après |
| [planche-3-grotte-azuree.jpg](planche-3-grotte-azuree.jpg) | Grotte Azurée 1F, 2F, B1F avant / après |
| [planche-4-facades-j29.jpg](planche-4-facades-j29.jpg) | poste de la Route 22, bâtiment de la Ligue, Route 23 |
| [planche-5-kit.jpg](planche-5-kit.jpg) | sols, rebords, escaliers, interrupteurs, barrière, trous, façades |
| [planche-6-fonds-combat.jpg](planche-6-fonds-combat.jpg) | fonds Route 23, Route Victoire, Grotte Azurée |

- **Route Victoire 1F–3F et Grotte Azurée 1F, 2F, B1F** : sol peint à deux niveaux, le sol haut
  **nettement plus clair** que le sol bas (RP-133) ; parois du Mont Sélénite ; rebords peints au sud
  et sur les côtés du sol haut, escaliers taillés ; eau de grotte (Grotte Azurée) ; échelles,
  interrupteurs (relevé, enfoncé), barrières, trou (ouvert, bouché) et indices peints à la place des
  dessins provisoires. Couche logique `Ground` gardée (masquée), portails et niveaux inchangés.
- **Façades** : poste de la Ligue sur la Route 22 ouest (5 × 4, même main que le poste de Safrania)
  et bâtiment de la Ligue sur le Plateau Indigo (8 × 6).
- **Fonds de combat dédiés** : `route_23_roche`, `victory_road_grotte` (1F à 3F),
  `cerulean_cave_azuree` (1F, 2F, B1F). **Route 22 ouest** : gardée sur `route_5_6_prairie` [D],
  le fond de la Route 22 du J7 (même route, continuité).
- **Gardes** de la Route 23 : déjà en sprite peint (`guard`), rien à faire.

### Valeurs par défaut [D]
- Parois du Mont Sélénite (gris ardoise) réutilisées dans les deux grottes, sur des sols brun-ocre
  (Route Victoire) et bleu-gris (Grotte Azurée).
- Eau de la Grotte Azurée : la texture d'eau de grotte des Îles Écume, en bandes, sans rivage.
- Échelles : l'échelle montante du Mont Sélénite partout.

### Reste (non fait)
- Cinq salles de la Ligue (J30, hors périmètre).

## Fin du lot : sol de la Route 23 et du Plateau Indigo (2026-10-28, branche `claude/daf-4-route-23-b20c52`) — **validé par Kevin le 2026-10-29, fusionné dans `main`**

Outils : `tools/build_daf4_exterieurs.gd` (seconde passe d'image après `build_daf4_facades.gd`, logique
inchangée : `tools/dump_map_logic.gd` identique avant / après), `tools/capture_daf4.sh`,
`tools/art/planches_daf4_exterieurs.py`. Aucune image nouvelle.

| Planche | Contenu |
|---|---|
| [synthese-telephone-exterieurs.jpg](synthese-telephone-exterieurs.jpg) | **à lire en premier, sur le téléphone** |
| [planche-7-route-23-plateau.jpg](planche-7-route-23-plateau.jpg) | Route 23 sud, milieu, nord et Plateau Indigo avant / après |

- **Sol** : herbe commune, chemin de terre au milieu du Plateau [D], eau des canaux à angles droits,
  berges naturelles de la Route 6 sur toute frontière eau / sol, hautes herbes jaune-vert.
- **Falaises** : paroi de montagne de la série 12 en modules ; les saillies d'une ou deux cases et
  les petits blocs (< 8 cases) deviennent des rochers (grande pierre, rochers, rochers de mer dans
  l'eau) [D] ; aucune paroi sous la façade de la Ligue (gardée).
- **Hors carte** [D] : une colonne de paroi assombrie à l'ouest et à l'est (cartes de 20 cases, plus
  étroites que l'écran : plus de bandes noires sur les côtés).
- Ombre vert sombre (sous-bois) entre les modules au pied des falaises, comme la Route 9.

## Reliquat : sprites du Conseil des 4 (2026-10-30, branche `claude/daf-4-ligue-e02c46`) — **à valider par Kevin** (RP-136)

Outils : `tools/art/daf4_ligue.py` (manifeste, préparation, planche), prompts `tools/art/prompts/daf4_ligue/`,
`tools/capture_daf4_ligue.sh`. Planche : [planche-8-ligue.jpg](planche-8-ligue.jpg).

- Olga, Aldo, Agatha, Peter peints (marche 4 × 4, 128 px, même main que les PNJ de la série 17) ; seuls
  `"sprite"` de `data/npcs/league_*.json` changent (aucune case, aucun déclencheur : gel du J33).
- Le Maître (`rival`) et Chen (`oak`) avaient déjà leur sprite peint ; rien à faire.
- [D] Pas de planche d'attente : colonne 0 de la marche (`IDLE_FROM_WALK`), comme les Médiums.
- [D] Pas de portrait ni de sprite de combat : aucun n'existe pour les Dresseurs de la Ligue (combat par artwork générique).
