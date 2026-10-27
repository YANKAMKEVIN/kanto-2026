# DAF.4 « Fin du jeu » — part déjà dans `main` (2026-10-27)

**Validé par Kevin le 2026-10-27 (DA-6, planches de contact).** (Arène de Jadielle et son fond de combat.)

Fait avec DAF.3, même branche (`claude/daf-3-4-9713b9`), même outil : la fiche commune est
[../daf-3/fiche.md](../daf-3/fiche.md).

- **Fait** : Arène de Jadielle en modules (dalles, murs, flèches et cases d'arrêt peints) et son fond
  de combat `viridian_gym_sol` — planche [planche-1-arene-jadielle.jpg](planche-1-arene-jadielle.jpg),
  fond dans [../daf-3/planche-6-fonds-combat.jpg](../daf-3/planche-6-fonds-combat.jpg).
## Suite du lot (2026-10-27, branche `claude/daf-4-j29-j31`, depuis `main` @ `ef1fff46`) — **à valider par Kevin**

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
- **Sol de la Route 23 et du Plateau Indigo** : encore en tuiles provisoires (falaises, herbe, eau) ;
  il faut le kit extérieur des falaises (`pewter_map_kit.gd`) : prochain morceau du lot.
- Cinq salles de la Ligue (J30, hors périmètre).
