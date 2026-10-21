# Kanto 2026 — J27 : Les défis de Safrania

> Passe de conception ChatGPT V2, transmise par Kevin le 2026-10-19, **avant le lancement du J27**
> (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages verrouillés. Les images
> de la passe d'origine ne sont pas reprises ici. Les notes de la session de coordination sont à la
> fin.

Le J27 complète Safrania avec deux défis distincts : l'Arène de Morgane, spécialiste du type Psy, et
le Dojo de Combat, où le joueur peut obtenir Kicklee ou Tygnon. On conserve l'architecture
historique de Rouge/Bleu, adaptée au jeu 2D HD peint et aux contrôles tactiles du Galaxy S24.

## 1. Les sept décisions définitives

| Sujet | Décision verrouillée |
|---|---|
| Périmètre | Arène de Morgane complète + Dojo de Combat |
| Arène | Salles et téléporteurs fidèles à Rouge/Bleu |
| Dresseurs | Combats facultatifs selon le chemin emprunté |
| Morgane | Équipe historique de quatre Pokémon |
| Dojo | Défi complet, choix unique Kicklee ou Tygnon |
| Récompenses | Badge Marais, CT46 Vague Psy et Pokémon du Dojo |
| Fin | Exploration libre, sans transition forcée |

Les décisions ci-dessus sont verrouillées. Les détails techniques qui suivent sont des
spécifications proposées, à vérifier contre le dépôt.

## 2. Structure générale

Deux défis indépendants dans Safrania, dans l'ordre choisi par le joueur :

- **Arène Psy** : téléporteurs, Morgane, Badge Marais, CT46 Vague Psy.
- **Dojo de Combat** : Dresseurs et maître, choix unique Kicklee ou Tygnon.

Fin du J27 : exploration libre, aucune téléportation ni événement imposé.

## 3. L'Arène de Morgane

Une énigme de navigation : plusieurs salles reliées par des téléporteurs. Le joueur découvre les
bonnes connexions pour atteindre Morgane, sans minimap, sans flèche et sans solution affichée.

### Contrat des téléporteurs

Le réseau reproduit la topologie historique de Rouge/Bleu :

- chaque téléporteur mène à une destination fixe ;
- le joueur peut revenir sur ses pas ;
- plusieurs salles comportent des Dresseurs évitables ;
- la salle de Morgane n'est accessible qu'en empruntant le bon parcours ;
- les transitions ne déclenchent jamais de boucle automatique ;
- l'orientation et la position du personnage restent cohérentes après chaque arrivée.

Sur mobile, une activation par entrée sur la case est acceptable, avec un court verrouillage à
l'arrivée empêchant la réactivation immédiate. Aucun raccourci moderne ne remplace le puzzle
historique.

### Dresseurs

Principalement des Pokémon Psy ou liés à la thématique. Équipes, niveaux, placements et dialogues
repris de Rouge/Bleu après audit. Combats facultatifs si un parcours permet de les contourner. Un
Dresseur vaincu ne relance pas son combat après un retour dans la salle ou un chargement.

## 4. Morgane : équipe historique

| Pokémon | Niveau |
|---|---|
| Kadabra | 38 |
| M. Mime | 37 |
| Aéromite | 38 |
| Alakazam | 43 |

Récompenses : **Badge Marais** et **CT46 Vague Psy**. Le combat met en valeur la vitesse et les
capacités spéciales, sans mécanique absente du moteur. Capacités précises et IA à confronter au
moteur existant. La victoire remet une seule fois le Badge et la CT, puis Morgane reste « vaincue ».

## 5. Le Dojo de Combat

Un défi indépendant, pas une huitième Arène : ses propres Dresseurs, son maître et une récompense
au choix. Fidèle à Rouge/Bleu : Dresseurs du Dojo, puis le maître ; après la victoire, choix de
**Kicklee** (coups de pied) ou **Tygnon** (coups de poing).

### Règles du choix

- Le joueur peut examiner les deux Pokémon avant de décider.
- Une confirmation explicite évite une sélection accidentelle sur écran tactile.
- Un seul Pokémon est remis ; l'autre n'est plus disponible.
- Équipe complète : remise par le stockage ou un mécanisme de récupération sécurisé ; la sauvegarde
  empêche toute duplication.
- Le Dojo ne dépend pas de la victoire contre Giovanni : il reste accessible selon ses propres
  conditions, même si l'Arène de Morgane est encore bloquée.

## 6. Dépendances J26 → J27

| Dépendance | Origine | Règle J27 |
|---|---|---|
| Safrania | Jalons antérieurs | Ville et bâtiments correctement raccordés |
| Libération de la Sylphe SARL | J26 | Condition d'accès à l'Arène de Morgane |
| Dojo de Combat | Safrania | Indépendant de Giovanni |
| Téléporteurs | J26 | Réutiliser le composant, avec un nouveau graphe |
| Dresseurs et combats | Moteur existant | Victoires persistantes |
| Starter initial | Système existant | Aucun impact sur l'équipe fixe de Morgane |
| Badge Marais | Système de badges | Ajout sans modifier les badges précédents |
| CT46 Vague Psy | Inventaire et combat | Capacité à vérifier ou implémenter |
| Kicklee / Tygnon | Pokédex et stockage | Deux espèces disponibles, un seul cadeau |
| Sauvegarde | Système existant | Récompenses uniques et états stables |

### Règles historiques à surveiller

- Dans Rouge/Bleu, le Badge Marais fait obéir les Pokémon échangés jusqu'au niveau 70 ; il ne
  débloque pas de CS de terrain. Préserver le modèle hybride des CS du J16, sans prérequis
  artificiel.
- En première génération, le Psy est particulièrement puissant et la table des types diffère des
  générations modernes. L'audit confirme quelle table Kanto 2026 utilise.

## 7. Persistance et anti-duplication

| Identifiant proposé | Fonction |
|---|---|
| `saffron_gym_unlocked` | Arène accessible après J26 |
| `sabrina_defeated` | Morgane vaincue |
| `badge_marsh` | Badge Marais obtenu |
| `tm46_received` | CT46 remise |
| `fighting_dojo_master_defeated` | Maître du Dojo vaincu |
| `fighting_dojo_reward_choice` | `none`, `hitmonlee` ou `hitmonchan` |
| `fighting_dojo_reward_received` | Pokémon effectivement remis |

Les identifiants réels suivent la convention du dépôt. Chaque Dresseur a son propre état de
victoire. Le choix et la remise du Dojo forment une **transaction** : si le jeu s'interrompt pendant
la confirmation, le joueur ne perd pas son Pokémon et n'en reçoit pas deux.

## 8. QA et tests Galaxy S24

| Test | Résultat attendu |
|---|---|
| Téléporteur activé | Destination exacte, aucune boucle |
| Retour par téléporteur | Parcours réversible selon la carte historique |
| Dresseur évité | Aucun combat forcé hors de sa zone de détection |
| Défaite contre Morgane | Combat rejouable, Badge non attribué |
| Victoire contre Morgane | Badge et CT remis une seule fois |
| Dojo avant Giovanni | Accessible |
| Choix Kicklee | Tygnon indisponible ensuite |
| Équipe complète | Récompense conservée sans duplication |
| Redémarrage de l'application | Tous les états restaurés |
| Retour à la Sylphe SARL | Libération J26 inchangée |

Interface tactile : zones d'interaction confortables, dialogues courts, retours visuels lisibles,
aucun élément important coupé sur Galaxy S24.

## 9. Découpage de production

| Lot | Livrable |
|---|---|
| 27.0 | Audit du dépôt et références Rouge/Bleu |
| 27A | Arène : salles, téléporteurs et connexions |
| 27B | Dresseurs de l'Arène et objets |
| 27C | Morgane, Badge Marais et CT46 |
| 27D | Dojo : carte, Dresseurs et maître |
| 27E | Choix Kicklee/Tygnon et stockage sécurisé |
| 27F | Sauvegardes, non-régression et QA Galaxy S24 |

**« J27 terminé »** : le joueur parcourt toute l'Arène, trouve et bat Morgane, reçoit le Badge
Marais et la CT46, relève le défi du Dojo et obtient exactement un Pokémon parmi Kicklee et Tygnon.
Les deux défis restent indépendants, rejouables seulement quand c'est approprié, et compatibles avec
les sauvegardes.

## 10. Prompt de transmission à Claude (au lancement du J27)

> **Kanto 2026 — J27 : audit et conception technique.** Prépare le jalon J27 consacré à l'Arène de
> Morgane et au Dojo de Combat de Safrania.
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Arène de Morgane complète et Dojo de Combat.
> 2. Salles et téléporteurs fidèles à Rouge/Bleu. 3. Dresseurs de l'Arène facultatifs selon le
> parcours. 4. Équipe historique de Morgane : Kadabra N38, M. Mime N37, Aéromite N38, Alakazam N43.
> 5. Dojo complet avec choix unique Kicklee ou Tygnon. 6. Badge Marais, CT46 Vague Psy et Pokémon du
> Dojo. 7. Exploration libre après les défis, sans transition imposée.
>
> **Travail demandé** : auditer le dépôt, les jalons précédents et les ressources présentes ;
> reconstituer le plan historique de l'Arène, le graphe exact de ses téléporteurs, les positions des
> Dresseurs et les chemins vers Morgane ; vérifier équipes, niveaux, capacités et dialogues
> historiques de l'Arène et du Dojo ; auditer espèces, sprites, capacités Psy et Combat, badges, CT,
> équipe et stockage ; prévoir un choix Kicklee/Tygnon transactionnel, confirmé sur mobile, sans
> duplication ni perte en cas de fermeture ; préserver l'indépendance du Dojo vis-à-vis de la
> Sylphe (l'Arène devient accessible après le J26) ; respecter les CS hybrides du J16 et les règles
> de progression validées.
>
> **Livrables** : contrat d'entrée J26 → J27 ; plans fonctionnels de l'Arène et du Dojo ; graphe
> complet des téléporteurs ; Dresseurs, équipes et capacités ; combat contre Morgane ; Badge Marais
> et CT46 ; combat contre le maître du Dojo ; choix unique Kicklee/Tygnon ; drapeaux, sauvegardes et
> anti-duplication ; assets 2D HD peints et fonds de combat ; lots 27.0 à 27F ; tests automatisés
> et QA Galaxy S24 ; questions ouvertes et risques techniques. Distinguer les faits historiques
> Rouge/Bleu, les adaptations Kanto 2026 et ce qui est réellement présent dans le dépôt.
>
> Conception et audit uniquement. Ne rien coder avant validation.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 27.0

Premier repérage, à confirmer par l'audit :

- **Téléporteurs** : le dossier les fait venir du J26 ; depuis la décision de Kevin du 2026-10-19,
  ils sont codés par la **passe systèmes 2**. Le J27 ne fournit que le graphe de l'Arène (données).
- **Table des types** (question du §6) : `data/pokemon/types.json` sur `main` suit la table
  **moderne** (Ténèbres, Acier, Fée ; Spectre super efficace sur Psy), pas celle de la première
  génération. La question est donc déjà tranchée par le dépôt, sauf décision contraire de Kevin.
- **Badge Marais** : déjà déclaré dans `data/badges.json` (`marsh`, drapeau `badge_marsh`).
- **CT46** : `data/pokemon/tm_compatibility.json` associe la CT46 à `psywave`, mais la capacité
  **Vague Psy** n'a pas été trouvée dans `data/pokemon/moves/moves.json` : à implémenter (dégâts
  variables selon le niveau).
- **Équipe complète** : le don de Pokémon du J20 (`game/systems/gift/pokemon_gift.gd`, branche
  `jalon-20`) envoie déjà au stockage. À réutiliser pour Kicklee/Tygnon après la fusion du J20,
  avec la transaction du §7 en plus.
- **Art** (entre-deux, levier 4) : grilles et une vue générale de l'Arène et du Dojo avant le code ;
  le reste (Morgane, Kadabra, M. Mime, Aéromite, Alakazam, Kicklee, Tygnon, fonds de combat) va
  dans un lot d'art.
