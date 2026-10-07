# Menu Dresseur : rapprochement des maquettes

> Plan préparé par Claude le 2026-10-07, **décisions de Kevin le même jour** : ordre tableau de bord → Équipe → Sac (MM.1), puis Carte et Dresseur (MM.2), Paramètres en dernier (MM.3) ; images = artworks officiels pour les Pokémon, portrait peint du héros et illustrations / icônes d'objets par Codex ; l'heure et les badges sont **préparés dès maintenant** (sans attendre la phase 10 ni le J10) ; chantier en parallèle du J8 (qui ne touche pas au menu). Références : `docs/design/reference/menu-*-v1.jpg`, `docs/design/dossier-08-menu-dresseur.md`, `docs/design/ui-ux-bible-v0.1.md`, skill `ui-theme-2026`. Captures du point de départ : `build/captures/menu_actuel/cmp_*.png`.

## Constat (jeu actuel vs maquettes)
La structure des écrans est déjà la bonne (J6, Pokédex refait en octobre). L'écart est visuel :
1. **Images absentes** : cartes du tableau de bord en aplat + icône (maquette : une illustration par carte) ; héros et Pokémon en pixel art (Équipe, Dresseur, carte du Pokémon de tête) ; objets du Sac en icônes génériques.
2. **Fond** : monde assombri derrière des panneaux de verre plus légers dans la maquette ; panneaux opaques et grands dans le jeu.
3. **En-tête** : bandeau d'état en haut à droite (lieu · heure · argent) et retour « < » compact dans la maquette ; × et « RETOUR » encombrants dans le jeu.
4. **Sac** : « Utiliser sur… » avec l'équipe directement dans le panneau de droite (maquette) au lieu d'une étape séparée.
5. **Carte** : étiquettes des lieux, aperçu illustré du lieu, Pokémon observés, frise des zones (maquette).

## Hors champ (règle 10 : l'écrit prime sur la maquette)
« Titres » et « Apparence » du Dresseur ; statistiques de base et talents ; difficulté, Cloud, HDR dans les Paramètres ; « Se rendre ici » sur la Carte ; Pikachu à côté du héros ; noms de Dresseurs ou d'objets non prévus par les dossiers.

## Préparés dès maintenant (décision de Kevin)
- **L'heure** : la puce « heure » du bandeau d'état existe et lit une **horloge du jeu** (`WorldClock`, logique pure, testable) ; tant que le cycle jour/nuit n'existe pas (phase 10), l'horloge n'est pas active et la puce reste **cachée** (aucune heure inventée). La phase 10 n'aura qu'à brancher l'horloge.
- **Les badges** : les 8 badges de Kanto décrits en **données** (`data/badges.json` : identifiant, nom, Champion, ville, ordre ; textes à valider par Kevin) et une vue « badges obtenus » lue depuis l'état de partie (aucun badge obtenu pour l'instant ; pas de nouveau champ de sauvegarde avant le J10 si la vue peut s'en passer, sinon un champ vide rétrocompatible, à décider par l'architecte avec un test de chargement). L'écran Dresseur et la carte du Dresseur affichent les emplacements en silhouette « ??? » (règle de déblocage). Le J10 n'aura qu'à attribuer le badge.

## Découpage (règle 1 : une validation S24 par sous-étape)
| | Contenu | Visible sur S24 |
|---|---|---|
| **MM.0 — art** | Codex : portrait peint du héros en buste (cartes du Dresseur), 6 illustrations du tableau de bord (Équipe : les trois starters ; Pokédex ; Sac ; Carte de Kanto ; carte de Dresseur ; engrenage), icônes peintes des objets existants (`data/items/items.json`). Pokémon : artworks officiels déjà utilisés par le Pokédex (`PokedexArt`). | rien |
| **MM.1 — tableau de bord, Équipe, Sac** | bandeau d'état (lieu · heure préparée · argent), retour « < », fond assombri et panneaux de verre (tokens de `ui-theme-2026`), illustrations des cartes, portrait peint du héros, artworks officiels (Pokémon de tête, liste et grand portrait de l'Équipe, choix de la cible dans le Sac), icônes d'objets ; Sac : « Utiliser sur… » dans le panneau de droite. | les trois écrans |
| **MM.2 — Carte et Dresseur** | Carte : étiquettes des lieux connus, aperçu du lieu (image floutée de sa carte peinte, comme le Pokédex), Pokémon observés, objets trouvés, frise des zones découvertes ; Dresseur : grand portrait peint, emplacements de badges (préparés), progression, équipe en artworks, grands moments. | les deux écrans |
| **MM.3 — Paramètres** | mise en page en colonnes de la maquette, sans réglage nouveau. | l'écran |

## Règles techniques
- Logique et vues existantes **inchangées** (`MenuDirector`, `*Views`, routes, tests) : on change la présentation ; tout nouveau contenu passe par une vue testée.
- Images chargées à la demande et partagées (comme `PokedexArt`) ; budget du menu à mesurer sur S24 (le flou du fond coûte déjà : J6 « Reportés »).
- Textes nouveaux (sous-titres des cartes, bandeau) : repris de la maquette quand ils ne contredisent rien, marqués pour la relecture groupée de Kevin.
- Branche `menu-maquettes` depuis `main`, dossier de travail dédié ; fusion dans `main` après chaque validation.
