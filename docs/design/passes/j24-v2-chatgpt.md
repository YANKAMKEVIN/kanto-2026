# J24 — Les Îles Écume et Artikodin : V2 de ChatGPT (reçue le 2026-10-16)

> Reproduite telle que Kevin l'a transmise. Les schémas et illustrations des sections 2 à 4 étaient
> des images, non reproduites. Passe d'alignement : `j24-v2-alignement.md`.

Consolidation de conception V2 · 7 arbitrages verrouillés · Préparation J25

État d'avancement : J23 est défini sur le plan de la conception (Parc Safari, Surf, Force et Koga).
J24 est maintenant arbitré : nous ouvrons l'exploration maritime, les Îles Écume et l'accès à
Cramois'Île. L'implémentation et la validation sur Galaxy S24 restent à vérifier dans le dépôt.

J24 représente un changement important : l'eau devient un véritable espace d'exploration, et le
joueur découvre son premier grand donjon maritime avec une rencontre légendaire.

## 1. Décisions verrouillées

| Sujet | Décision définitive |
|---|---|
| Périmètre | Routes 19 et 20, Îles Écume, accès maritime à Cramois'Île |
| Donjon | Îles Écume complètes, courants et rochers |
| Artikodin | Rencontre unique et capture possible |
| Surf | Navigation libre, rencontres sauvages, transitions entre cartes |
| Force | Puzzles persistants, sans blocage définitif |
| Cramois'Île | Ville et bâtiments principaux ouverts ; Manoir et Arène plus tard |
| Fin J24 | Exploration libre entre Parmanie, Îles Écume et Cramois'Île |

Aucun combat contre Artikodin n'est obligatoire pour terminer J24. Le joueur peut explorer le
donjon, poursuivre vers Cramois'Île et revenir plus tard.

## 2. Topologie du jalon

La Route 19 part de Parmanie vers le sud, la Route 20 longe les Îles Écume d'est en ouest et
conduit à Cramois'Île.

Attention à la continuité historique : Cramois'Île est également accessible depuis Bourg Palette
par la Route 21. Cette seconde arrivée ne fait pas partie du périmètre géographique principal de
J24, mais elle doit être prise en compte dans les connexions et les tests pour ne pas créer
d'incohérence.

## 3. Les Îles Écume : donjon complet

Organisation historique : deux entrées, plusieurs étages souterrains, des trous permettant de faire
tomber les rochers et des courants qui bloquent certains passages tant que les rochers n'ont pas
été placés correctement.

Je propose de conserver les cinq niveaux historiques : rez-de-chaussée et quatre sous-sols, avec
des cartes orthogonales distinctes.

| Élément | Règle J24 |
|---|---|
| Rochers | Déplaçables avec Force, après obtention du Badge Prisme |
| Trous | Un rocher poussé dans un trou tombe à l'étage inférieur |
| Courants | Empêchent de traverser certaines zones tant que les rochers ne les bloquent pas |
| Persistance | Positions et chutes des rochers sauvegardées |
| Anti-blocage | Aucun placement ne doit rendre la sortie ou la résolution définitivement impossible |
| Retour | Le joueur peut ressortir et revenir sans perdre sa progression utile |

La persistance est une adaptation Kanto 2026. Elle ne doit pas simplement mémoriser chaque
position sans contrôle : les états impossibles doivent être empêchés par la conception des cartes
ou récupérables par une règle locale documentée.

## 4. Artikodin : rencontre légendaire

Artikodin — Niveau 50. Rencontre statique dans les profondeurs des Îles Écume, fidèle à
Rouge/Bleu. Le Pokémon est visible dans le monde avant l'interaction, avec une présentation
particulière mais sans cinématique excessive.

Pour éviter toute ambiguïté, je recommande les règles suivantes :

- Combat déclenché uniquement par interaction volontaire.
- Une seule rencontre légendaire dans cette partie.
- Capture : Artikodin rejoint l'équipe ou le stockage selon les règles existantes.
- K.O. ou fuite : la rencontre est considérée comme terminée, conformément à l'esprit de
  Rouge/Bleu.
- Aucune réapparition après capture ou défaite.
- Aucun verrouillage de la sortie du donjon pendant ou après la rencontre.

La sauvegarde doit être testée avant, pendant et après le combat pour éviter les duplications ou
les réapparitions accidentelles.

## 5. Surf : navigation libre sur l'eau

Le joueur utilise Surf depuis une berge accessible, avec un Pokémon compatible présent dans son
équipe et le Badge Âme obtenu.

| Situation | Comportement attendu |
|---|---|
| Entrer dans l'eau | Apparition d'une monture aquatique générique peinte |
| Se déplacer | Navigation libre dans les quatre directions |
| Rencontre sauvage | Combat classique, avec fond aquatique CB.3 |
| Changement de carte | Transition sans descendre automatiquement de Surf |
| Rejoindre la terre | Descente automatique sur une case praticable |
| Courant des Îles Écume | Déplacement forcé selon la direction du courant |
| Sauvegarder sur l'eau | Reprise sur une case valide, avec Surf restauré |
| Pokémon compatible déposé | Interdiction de se retrouver bloqué au milieu de l'eau |

Adaptation Kanto 2026 : le système doit garantir que le joueur puisse toujours regagner une berge,
y compris après un chargement de sauvegarde.

Pour le Galaxy S24, les contrôles de Surf restent ceux de la marche. Pas de joystick
supplémentaire, ni de bouton permanent occupant l'écran.

## 6. Dépendances J23 → J24

Voici le contrat d'entrée à vérifier avant de coder.

| Dépendance | Origine attendue | Vérification |
|---|---|---|
| hm03_surf | J23, Maison Secrète | Objet obtenu une seule fois |
| hm04_strength | J23, Gardien | Dents d'Or remises |
| badge_soul | J23, Koga | Autorise Surf dans le monde |
| badge_rainbow | J20, Erika | Autorise Force dans le monde |
| Compatibilités CS | Système hybride | Pokémon présent dans l'équipe |
| Rencontres aquatiques | J23 et moteur existant | Espèces et tables disponibles |
| Captures légendaires | Moteur de combat | Rencontre statique unique |
| Transitions | Moteur de cartes | Conservation de l'état Surf |
| Sauvegarde | Système existant | Positions des rochers et état d'Artikodin |

Les noms des drapeaux ci-dessus sont des identifiants proposés. Ils doivent être rapprochés des
identifiants réels du dépôt.

Trois points nécessitent particulièrement l'audit de Claude :

1. Le Badge Prisme : son obtention doit être effective, pas seulement prévue dans le dossier J20.
2. La Route 21 : son raccord depuis Bourg Palette ne doit pas introduire une deuxième entrée
   incohérente dans Cramois'Île.
3. La capture d'Artikodin : l'équipe, le stockage et la sauvegarde doivent supporter un Pokémon
   unique sans duplication.

## 7. Cas limites et anti-blocage

| Cas | Résultat attendu |
|---|---|
| Le joueur pousse un rocher au mauvais endroit | Il existe une récupération locale documentée |
| Un rocher tombe dans un trou | Sa nouvelle position persiste après changement d'étage |
| Le joueur quitte le donjon | Les progrès utiles sont conservés |
| Le joueur sauvegarde dans un courant | Reprise sur une position sûre |
| Le joueur ferme l'application pendant le combat d'Artikodin | Retour à un état stable, sans duplication |
| Artikodin est capturé | Il disparaît définitivement du monde |
| Artikodin est mis K.O. | Il ne réapparaît pas |
| L'équipe est pleine | Capture transférée au stockage selon les règles existantes |
| Le joueur atteint Cramois'Île | Aucun événement narratif automatique |

Une précision importante : « rochers persistants » ne signifie pas « toutes les positions sont
irréversibles ». La sauvegarde conserve l'état des puzzles, mais une solution de récupération doit
exister lorsqu'une configuration serait autrement impossible à résoudre.

## 8. Découpage technique J24

| Lot | Livraison |
|---|---|
| 24.0 | Audit du dépôt, contrats J23 et topologie historique |
| 24A | Surf, navigation, rencontres et transitions |
| 24B | Routes 19–20, nageurs et objets |
| 24C | Îles Écume : cartes, courants, Force et rochers |
| 24D | Artikodin : rencontre unique, capture et sauvegarde |
| 24E | Cramois'Île, bâtiments et raccords |
| 24F | QA Galaxy S24 et non-régression |

Le lot 24C devra être testé séparément, car la combinaison Force + chutes de rochers + courants +
sauvegarde est la partie la plus risquée du jalon.

## 9. Prompt d'audit transmis à Claude

Kanto 2026 — J24 : passe d'alignement technique. Décisions verrouillées (ne pas rouvrir) :
1. Routes 19–20, Îles Écume complètes et accès maritime vers Cramois'Île. 2. Donjon avec courants,
rochers, trous et puzzles de Force. 3. Artikodin : rencontre légendaire unique et capturable.
4. Surf : navigation libre, rencontres sauvages et transitions entre cartes. 5. Rochers
persistants, avec prévention et récupération des situations de blocage. 6. Cramois'Île
accessible, bâtiments principaux ouverts ; Manoir et Arène réservés à un jalon ultérieur. 7. Fin
libre, sans événement narratif forcé.

Vérifications obligatoires : auditer le dépôt et les dossiers J20 à J23 (implémenté, documenté,
testé sur S24, absent) ; identifiants réels des CS03 et CS04, des Badges Âme et Prisme et des
compatibilités ; topologie Rouge/Bleu des Routes 19–20, des deux entrées des Îles Écume et de leurs
cinq niveaux, accès alternatif par la Route 21 ; courants, trous, rochers, états persistants et
anti-blocage, plans ASCII fonctionnels par carte sans coordonnées présentées comme implémentées ;
rencontre d'Artikodin N50 (équipe, capacités, capture, K.O., fuite, interruption, sauvegarde) ;
navigation Surf (entrée, sortie, collision, rencontres, transitions, contrôles tactiles,
chargement).

Livrables : contrat d'entrée J23 → J24 ; plans fonctionnels et connexions ; règles de Surf et
Force ; tables de rencontres et Dresseurs ; puzzles étage par étage ; fiche d'Artikodin ; objets et
dialogues ; drapeaux et sauvegardes ; inventaire des espèces, capacités et assets ; lots 24.0 à
24F avec tests et QA S24 ; questions ouvertes numérotées et recommandations. Classer les mécaniques
selon Rouge/Bleu, génération ultérieure ou adaptation Kanto 2026. DA 2D HD peinte, orthogonale,
sans pixel art, isométrie, minimap ni flèches d'objectif. Conception et audit uniquement : ne rien
coder avant validation.
