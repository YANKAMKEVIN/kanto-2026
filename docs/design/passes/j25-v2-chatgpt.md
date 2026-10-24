# J25 — Le secret du Manoir Pokémon : V2 de ChatGPT (reçue le 2026-10-16)

> Reproduite telle que Kevin l'a transmise. Les schémas et illustrations (cartes, vignettes de
> l'équipe d'Auguste) étaient des images, non reproduites. Passe d'alignement :
> `j25-v2-alignement.md`.

Dossier de conception consolidé V2 · 7 arbitrages verrouillés · Audit du dépôt à effectuer

État d'avancement : J22 à J24 sont consolidés sur le plan de la conception. J25 est également
arbitré et prêt pour une passe d'alignement technique avec Claude. Aucune validation
d'implémentation ou de tests sur Galaxy S24 n'est présumée.

L'objectif de J25 est de faire de Cramois'Île un véritable chapitre d'aventure, avec trois
expériences complémentaires : l'exploration mystérieuse du Manoir Pokémon, les découvertes
scientifiques du Laboratoire et le défi d'Auguste.

## 1. Les sept décisions définitives

| Sujet | Arbitrage validé |
|---|---|
| Périmètre | Manoir Pokémon complet + Laboratoire + Arène d'Auguste |
| Manoir | Étages complets, statues, portes et journaux scientifiques |
| Histoire de Mewtwo | Journaux fidèles à Rouge/Bleu, sans apparition de Mewtwo |
| Laboratoire | Échanges et résurrection des fossiles disponibles |
| Arène | Quiz historiques et combats alternatifs, au choix |
| Auguste | Équipe Rouge/Bleu à quatre Pokémon, adaptée au moteur |
| Fin | Badge Volcan obtenu, exploration libre |

Règle fondamentale : après avoir vaincu Auguste, le joueur reste libre de voyager. Aucun événement
ne doit le téléporter, le diriger automatiquement vers Jadielle ou déclencher J26.

## 2. Cramois'Île : organisation générale

Les bâtiments principaux ouverts à J24 deviennent pleinement fonctionnels à J25.

| Bâtiment | Fonction J25 |
|---|---|
| Centre Pokémon | Soins, stockage et point de reprise |
| Boutique | Achats habituels |
| Manoir Pokémon | Exploration, énigmes et Clé Secrète |
| Laboratoire | Échanges fixes et résurrection des fossiles |
| Arène d'Auguste | Quiz, combats et Badge Volcan |
| Accès maritimes | Déplacements libres vers les routes déjà accessibles |

Les cartes doivent respecter la géographie historique de Rouge/Bleu, adaptée à notre direction
artistique 2D HD peinte, orthogonale et sans pixel art.

## 3. Le Manoir Pokémon : donjon complet

Quatre niveaux à construire : rez-de-chaussée, premier étage, deuxième étage et sous-sol.
L'exploration repose sur les escaliers, les trous dans les planchers, les portes commandées par des
statues et les rencontres sauvages.

| Mécanisme | Comportement attendu |
|---|---|
| Statues | Interaction volontaire qui modifie l'état de certaines portes |
| Portes | Apparence et collisions synchronisées |
| Escaliers | Transitions vers le bon étage |
| Trous | Chute vers une position déterminée de l'étage inférieur |
| Journaux | Consultables, avec dialogues courts |
| Dresseurs | Combats classiques, largement facultatifs |
| Pokémon sauvages | Tables de rencontres adaptées à Rouge/Bleu |
| Objets | Objets uniques persistants |
| Clé Secrète | Récupérable dans le sous-sol |

Le puzzle doit être conçu comme un ensemble cohérent. On ne place pas les statues indépendamment des
portes : il faut d'abord vérifier que toutes les configurations nécessaires permettent d'atteindre
la Clé Secrète et de ressortir.

Les journaux scientifiques — l'histoire est racontée par quatre découvertes :

| Date | Information révélée |
|---|---|
| 5 juillet | Découverte d'un Pokémon inconnu dans une jungle profonde |
| 10 juillet | Ce Pokémon est nommé Mew |
| 6 février | Naissance de Mewtwo |
| 1er septembre | Mewtwo est devenu trop puissant pour être contrôlé |

Ces textes doivent être adaptés à la limite de notre interface : deux lignes d'environ 40
caractères. Les journaux sont consultables à nouveau, mais ne déclenchent ni apparition de Mewtwo,
ni flashback jouable, ni combat. Mewtwo reste réservé à une étape ultérieure de l'aventure.

## 4. La Clé Secrète

Elle se trouve dans le sous-sol du Manoir. Déroulement : 1. le joueur explore le Manoir et manipule
les statues ; 2. il trouve progressivement les passages nécessaires ; 3. il atteint le sous-sol et
récupère la Clé Secrète ; 4. il retourne à l'Arène d'Auguste ; 5. la porte de l'Arène est
déverrouillée définitivement. La clé doit être remise une seule fois et rester enregistrée dans les
objets importants. Si le joueur recharge une sauvegarde après avoir ouvert l'Arène, celle-ci doit
rester ouverte.

## 5. Le Laboratoire : fossiles et échanges

Les scientifiques proposent des échanges fixes et permettent de ressusciter les fossiles déjà
récupérés pendant l'aventure.

| Objet | Pokémon obtenu |
|---|---|
| Fossile Dôme | Kabuto |
| Fossile Nautile | Amonita |
| Vieil Ambre | Ptéra |

Le joueur remet son fossile au scientifique, quitte le bâtiment, puis revient récupérer le Pokémon.
Cette attente est liée à une transition de jeu, sans minuterie réelle. Le système doit empêcher la
duplication des fossiles et des Pokémon, notamment si l'application est fermée entre le dépôt et la
récupération.

Échanges fixes de référence à auditer :

| Pokémon donné | Pokémon reçu |
|---|---|
| Raichu | Électrode |
| Mimitoss | Saquedeneu |
| Ponyta | Otaria |

Les échanges sont réalisés avec des personnages non joueurs, sans connexion réseau. Claude devra
confirmer les espèces, les salles, les conditions et les particularités de la version Rouge/Bleu
retenue, et vérifier que tous les Pokémon concernés possèdent leurs données, illustrations,
capacités et entrées Pokédex.

## 6. L'Arène d'Auguste

L'Arène conserve son principe historique : le joueur peut répondre à des quiz Pokémon pour éviter
certains combats, ou affronter les Dresseurs. Chaque section comporte une machine à quiz et un
Dresseur associé. Une bonne réponse permet de progresser sans combat. Une mauvaise réponse
déclenche le combat. Le joueur peut également choisir de combattre directement. Je recommande de
conserver les six questions historiques, mais de les reformuler en français pour notre interface.
Les réponses doivent être évaluées selon les règles de Rouge/Bleu, et non celles des générations
plus récentes.

Auguste — Champion de Cramois'Île, référence Rouge/Bleu : Caninos N42, Ponyta N40, Galopa N42,
Arcanin N47. Badge Volcan. CT38 Déflagration — remise unique.

Les niveaux historiques sont fixés comme référence. Les capacités exactes, l'IA et l'équilibrage
restent soumis à l'audit du moteur. Nous conservons la présentation générique des Champions et le
Grand moment après la victoire, sans bonus de badge caché.

## 7. Dépendances techniques

| Dépendance | Origine | Vérification |
|---|---|---|
| Cramois'Île accessible | J24 | Raccords maritimes |
| Bâtiments principaux | J24 | Entrées et intérieurs |
| Transitions verticales | J24 / moteur existant | Escaliers et chutes |
| Portes conditionnelles | Systèmes antérieurs | Statues et collisions |
| Fossiles | Mont Sélénite | Objets réellement obtenables |
| Vieil Ambre | Musée d'Argenta | Accès avec Coupe |
| Échanges fixes | À auditer | Transactions et stockage |
| Pokémon du Laboratoire | Pokédex | Données et assets |
| Capacités Feu | Combat | Effets réellement implémentés |
| Sauvegarde | Système existant | Persistance et anti-duplication |

Ces dépendances ne sont pas encore vérifiées dans le dépôt.

## 8. Drapeaux persistants

| Identifiant proposé | Rôle |
|---|---|
| mansion_secret_key_taken | Clé Secrète récupérée |
| cinnabar_gym_unlocked | Arène déverrouillée |
| badge_volcano | Badge Volcan obtenu |
| tm38_received | CT38 remise |
| fossil_dome_revived | Kabuto récupéré |
| fossil_helix_revived | Amonita récupéré |
| old_amber_revived | Ptéra récupéré |

Pour les fossiles, un simple booléen peut être insuffisant pendant la période entre dépôt et
récupération. Il faudra prévoir un état transactionnel, par exemple disponible → confié → prêt →
récupéré.

## 9. Tests et cas limites

- Une statue ouvre une porte mais en ferme une autre : le joueur peut toujours progresser.
- Une chute entre étages conduit toujours à une case valide.
- Les objets uniques ne réapparaissent pas après rechargement.
- La Clé Secrète ne peut pas être récupérée deux fois.
- L'Arène reste ouverte après sauvegarde.
- Un fossile confié ne disparaît pas si le jeu est interrompu.
- Un Pokémon ressuscité n'est jamais dupliqué.
- Un échange fixe échoue proprement si ses conditions ne sont pas remplies.
- Les quiz et les combats alternatifs permettent tous deux de progresser.
- Après une défaite contre Auguste, le joueur peut revenir sans perdre les événements déjà résolus.
- Après l'obtention du Badge Volcan, aucun déplacement ou événement n'est imposé.

## 10. Découpage de production

| Lot | Livraison |
|---|---|
| 25.0 | Audit du dépôt et des dépendances |
| 25A | Manoir : quatre niveaux, escaliers, trous et rencontres |
| 25B | Statues, portes, journaux, objets et Clé Secrète |
| 25C | Laboratoire, échanges et fossiles |
| 25D | Arène, quiz et Dresseurs |
| 25E | Auguste, Badge Volcan et CT38 |
| 25F | Sauvegardes, tests automatisés et QA Galaxy S24 |

Le lot 25C nécessite une validation spécifique pour éviter les duplications de Pokémon ou d'objets.
J25 sera terminé lorsque le joueur pourra explorer le Manoir, obtenir la Clé Secrète, utiliser le
Laboratoire, vaincre Auguste et continuer librement son aventure.

## 11. Prompt pour Claude (résumé fidèle)

Décisions verrouillées 1 à 7 ci-dessus, à ne pas rouvrir. Audit demandé : dépôt, dossiers J20–J24,
systèmes existants ; distinguer implémentation vérifiée, conception validée et fonctionnalité
absente ; plans ASCII fonctionnels du Manoir, de l'Arène et du Laboratoire ; journaux, six
questions, Clé Secrète, objets, rencontres ; échanges, fossiles, transactions atomiques ; capacités
réellement implémentées avant les équipes ; simulations d'équilibrage. Livrables 1 à 16 : contrat
d'entrée J24 → J25, plans, statues/portes/chutes, journaux et dialogues, objets et Clé Secrète,
rencontres, Dresseurs, Laboratoire, quiz, Auguste/Badge/CT38, drapeaux et sauvegardes, cas limites
et anti-duplication, assets peints et fonds CB.3, lots 25.0 à 25F, tests et QA S24, questions
ouvertes numérotées avec recommandations. Pour chaque règle : Rouge/Bleu, génération ultérieure,
adaptation Kanto 2026. DA 2D HD peinte, orthogonale, sans pixel art, isométrie, minimap ni flèches
d'objectif. Conception et audit uniquement : ne rien coder avant validation.
