# Kanto 2026 — Roadmap globale

> Vue macro du projet, du prologue à la Ligue et au post-game. Validée par Kevin le 2026-09-29.
> Objectif : avancer par **grandes phases** et par **systèmes**, pas route par route, pour ne pas
> découvrir au jalon 12 qu'un système fondamental (Pokédex, économie, sauvegarde…) n'a pas été
> prévu. L'état détaillé et la prochaine étape concrète restent dans [`docs/tech/etat-projet.md`](../tech/etat-projet.md).

## Principe directeur

Construire un jeu dont l'**architecture grandit proprement**, pas un prototype qui accumule des
fonctionnalités. On verrouille d'abord Route 1 et la boucle fondamentale ; on ne conçoit pas dix
villes en avance. Une fois les systèmes principaux posés, on **fabrique du contenu avec ces
systèmes** plutôt que de réinventer le moteur à chaque ville.

**Règle « données avant interface »** : un système commence à **enregistrer ses données dès qu'il
est pertinent**, même si son écran arrive plus tard. Exemple appliqué dès le jalon 5 : le Pokédex
enregistre `seen` / `caught` et les persiste dans la sauvegarde ; l'écran Pokédex du jalon 6 n'est
alors qu'une interface sur des données déjà collectées, jamais un système greffé après coup.

## Phases

### Phase 1 — Fondations du jeu (J0 → J4) — ✅ terminé
Déplacement, caméra, collisions, interactions, bâtiments/intérieurs, PNJ, dialogues, cinématiques,
données Pokémon, starter, moteur de combat, première UI de combat. Résultat : prologue jouable
jusqu'au premier combat.

### Phase 2 — Boucle Pokémon fondamentale (J5) — 🔥 en cours : Route 1
- **5A** — la carte de la Route 1
- **5B** — rencontres sauvages (le combat du 4B réutilisé en extérieur, « le monde devient la scène »)
- **5C** — XP / niveaux / apprentissage de capacités
- **5C.5** — **sauvegarde** (avant la capture : fermer/relancer l'app restaure équipe, XP, sac, progression, position)
- **5D** — première capture
- **5E** — défaite sauvage → fondu → réveil à Bourg Palette, Pokémon soignés par Maman
- **5F** — QA complète « joueur » (scénario de bout en bout, 60 fps, sans perte de données)

À la fin : **Explorer → rencontrer → combattre → gagner de l'XP → capturer → sauvegarder → continuer.**
Le cœur de Pokémon fonctionne.

### Phase 3 — Le système joueur (J6) — Menu principal
Avant d'étendre Kanto. Chaque entrée du menu devient un vrai système (UI 2026, pas une boîte texte) :
- **6A Équipe** : Pokémon possédés, PV, niveau, XP, types, capacités, stats, ordre de l'équipe, examen.
- **6B Sac** : catégories (objets, soins, Poké Balls, CT, objets clés), quantité, description, UTILISER.
  **Le même Sac en exploration et en combat**, pas deux systèmes.
- **6C Pokédex** : Vu / Capturé (données déjà collectées depuis le J5) ; plus tard habitat, taille,
  description, formes, évolutions découvertes, zones observées.
- **6D Carte** : Bourg Palette, Route 1, Jadielle, puis Kanto se dévoile. Comprendre le monde, pas
  une checklist de `?`.
- **6E Profil dresseur** : nom, avatar, temps de jeu, Pokédex, badges, argent ; plus tard Ligue, stats.
- **6F Paramètres** : audio, musique, vibrations, vitesse du texte, accessibilité, commandes,
  perfs. Accessibilité pensée dès ici, pas à la fin.

### Phase 4 — Premier hub (J7) — Jadielle
- **Centre Pokémon** : soin + animation ; **point de retour après défaite** (dernier Centre utilisé,
  plus systématiquement Maman à partir d'ici).
- **Boutique** : premiers achats (Poké Balls, Potions, antidotes…).
- **Économie** : argent, prix, achats, ventes, récompenses des combats de Dresseurs.

### Phase 5 — Route 2 / Forêt de Jade (J8 – J9)
Nouveaux Pokémon, premiers vrais Dresseurs, poison / antidotes, plus d'objets, capture plus
intéressante, équipe qui se construit, premier apprentissage de nouvelles capacités, premières
évolutions selon les niveaux.

### Phase 6 — Argenta + première Arène (J10)
Ville d'Argenta (musée, habitants, Centre, Boutique, Arène). **Système de badges** : victoire →
Badge Roche → profil dresseur mis à jour, progression narrative, réactions des PNJ. Première grande
boucle longue : Bourg Palette → routes → captures → ville → préparation → Arène → badge.

### Phase 7 — Systèmes avancés Pokémon (J11) — grande passe avant d'étendre Kanto
- **Évolutions** jouables et visibles (montée de niveau → « Salamèche évolue ! », animation 2026,
  annulation possible, nouvelles stats, Pokédex).
- **CT** : trouver, Sac → CT, Pokémon compatibles, apprentissage.
- **Statuts complets** : poison, paralysie, sommeil, brûlure, gel.
- **Changement de Pokémon en combat** (équipe → choisir → transition).
- **Compagnon Pokémon** : sortir de sa Ball et suivre le joueur, proprement (comportements par
  espèce, vitesse, obstacles, intérieurs, réactions, animations, rappel automatique, interactions).
  Pas un sprite collé derrière le joueur.

### Phase 8 — Kanto devient un monde (J12+)
Les systèmes principaux existent : on produit le contenu. Mont Sélénite, Azuria (Léo), Carmin-sur-Mer
(Major Bob), Océane, Lavanville, Céladopole (Erika), Team Rocket, Safrania (Morgane), Parmanie (Koga),
Cramois'Île (Auguste), Jadielle finale (Giovanni), Route Victoire, Ligue.

### Phase 9 — Fin de jeu
Conseil 4, Rival Maître, générique, retour à Bourg Palette, monde post-Ligue (Champions améliorés),
Grotte Azurée / Mewtwo, puis le mystère Mew.

## Ordre immédiat

```
J5  Route 1 + boucle Pokémon
J6  Menu / Équipe / Sac / Pokédex / Carte / Profil   ← ICI
J7  Jadielle + Centre + Boutique + économie
J8  Route 2
J9  Forêt de Jade
J10 Argenta + Arène Pierre + Badge
J11 Grande passe systèmes (évolutions / CT / statuts / équipe avancée / compagnon)
J12+ Expansion de Kanto → Ligue → post-game
```
