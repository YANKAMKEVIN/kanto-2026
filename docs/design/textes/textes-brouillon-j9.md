# Textes en brouillon — jalon 9, lot système (2026-10-07)

> **57 textes numérotés, à relire par Kevin en une passe** (Q-1 du plan `docs/tech/jalon-09.md`, décision du 2026-10-07). Comme aux J6 et J7 : commente ligne par ligne (numéro + correction) ; **tout ce que tu ne commentes pas est validé tel quel**. Rien de ce lot n'est encore dans `data/` (le test `test_no_draft_in_data` refuse les brouillons) : les tâches T1, T4, T8, T18 le recopieront mot pour mot après ta relecture.
>
> Ce lot ne couvre que ce que le dossier 10 ne fixe pas. Les répliques des gardes, des 5 Dresseurs, des 2 PNJ et des objets cachés sont **déjà verrouillées** (dossier 10, « Textes verrouillés », version de `main` : **Scout Théo**, garde sud « La Boutique de Jadielle vend des Antidotes. »).
>
> Conventions suivies (celles des textes validés) : espace avant `! ? : ;` (espace simple, comme dans tout `data/` aujourd'hui : aucune espace insécable n'y est employée) ; « ... » à trois points comme les messages de combat existants ; `{pokemon}` = surnom ou nom de l'espèce, jamais « ennemi » ; `text_f` = accord au féminin quand le Pokémon de l'événement est une femelle (mécanisme existant de `BattleText`, comme « est blessée par le contrecoup ! »). Longueurs : descriptions Pokédex 66 à 126 signes aujourd'hui, capacités 32 à 92 ; le lot reste dans ces bornes.

## A. Combat — poison (`data/battle/messages.json`, nouveaux modèles de `BattleText`)

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 1 | `templates/status_inflicted_poison` · `text` | Dard-Venin ou Poudre Toxik réussit (`STATUS_INFLICTED`) | « {pokemon} est empoisonné ! » |
| 2 | `templates/status_inflicted_poison` · `text_f` | idem, Pokémon femelle | « {pokemon} est empoisonnée ! » |
| 3 | `templates/status_unchanged_poison` · `text` | Poudre Toxik sur un Pokémon déjà empoisonné (`STATUS_UNCHANGED`) | « {pokemon} est déjà empoisonné ! » |
| 4 | `templates/status_unchanged_poison` · `text_f` | idem, femelle | « {pokemon} est déjà empoisonnée ! » |
| 5 | `templates/status_damaged_poison` · `text` | dégât de fin de tour (`STATUS_DAMAGED`), avec le voile violet et la barre qui descend | « {pokemon} souffre du poison ! » |
| 6 | `templates/status_cured_poison` · `text` | Antidote utilisé en combat, après « Tu utilises Antidote sur {pokemon}. » (`STATUS_CURED`) | « {pokemon} n'est plus empoisonné. » |
| 7 | `templates/status_cured_poison` · `text_f` | idem, femelle | « {pokemon} n'est plus empoisonnée. » |

Déjà validés, réutilisés tels quels : immunité (type Poison) → « Ça n'affecte pas {pokemon}... » ; K.O. par le poison → « {pokemon} est K.O. ! » ; étiquette de statut « PSN » (dossier 08 §2).

## B. Évolution (écran d'évolution, T9)

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| — | `templates/evolution_started` | début de la séquence (≈ 1,5 s) — **déjà validé** (dossier 04 §7), rappelé ici | « Quoi ? {pokemon} évolue ! » |
| 8 | `templates/evolution_finished` | après le flash, la nouvelle espèce en couleurs ; `{species}` = nom de la nouvelle espèce | « Félicitations ! {pokemon} a évolué en {species} ! » |
| 9 | `templates/evolution_cancelled` | le joueur a touché ARRÊTER (ou retour Android) : retour à l'ancienne espèce | « {pokemon} n'évolue plus. » |
| 10 | `templates/evolution_stop` | bouton visible pendant la transformation seulement (≈ 5 s), capitales comme « OUBLIER » / « GARDER » | « ARRÊTER » |

Déjà validés, réutilisés : capacités de la nouvelle espèce → « {pokemon} apprend {move} ! » et tout le déroulé « oublier » ; consigne « Touchez l'écran pour continuer » ; toast « Évolution découverte ».
Note technique : `{species}` n'existe pas encore dans `BattleText.PLACEHOLDERS` (T8). Avec un surnom : « Félicitations ! Flammy a évolué en Reptincel ! » ; sans surnom : « Félicitations ! Chenipan a évolué en Chrysacier ! ».
Variante possible pour le n° 9, en écho au « Quoi ? » : « Hein ? {pokemon} n'évolue plus. » (proposé : sans « Hein ? »).

## C. Antidote (`data/items/items.json`, `BagQuery`)

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 11 | `antidote` · `name` | nom (Sac, Boutique, combat, toast), masculin | « Antidote » |
| 12 | `antidote` · `plural` | pluriel (Boutique, toasts) | « Antidotes » |
| 13 | `antidote` · `description` | fiche du Sac et de la Boutique (même registre que « Restaure les PV d'un Pokémon. ») | « Soigne un Pokémon empoisonné. » |
| 14 | `BagQuery` · résultat d'un soin de statut | ligne de résultat après usage depuis le Sac (le soin de PV affiche « +20 PV — Salamèche 33/51 ») | « %s n'est plus empoisonné. » |
| 15 | `BagQuery` · idem, féminin | Pokémon femelle | « %s n'est plus empoisonnée. » |

Déjà validés, réutilisés : toast « Antidote ×1 — Ajouté au Sac » (format existant) ; refus « Sans effet » / « Cela n'aurait aucun effet sur %s. » ; « Ce Pokémon est K.O. ».
Variante courte possible pour 14–15, calquée sur le soin de PV et sans accord : « Poison soigné — %s » (proposé : la phrase complète, identique au combat).

## D. Capacités (`data/pokemon/moves/moves.json`)

Noms officiels français (rappelés pour validation, comme au J7). Descriptions : registre des 47 capacités existantes ; une capacité dont l'effet n'est pas encore joué porte la mention habituelle « … dans le moteur actuel. » quand la capacité **entière** est sans effet ou n'a qu'un coup (règle de Cyclone, Puissance, Furie, Double Pied) ; un effet secondaire encore absent (paralysie, confusion) est décrit sans mention, comme « Peut la brûler. » pour Flammèche.

| # | Clé cible | Contexte (données prévues au T1, valeurs actuelles) | Texte proposé |
|---:|---|---|---|
| 16 | `string_shot` · `name` | Insecte, statut | « Sécrétion » |
| 17 | `string_shot` · `description` | Vitesse −2 (valeur actuelle ; si le T1 garde −1 : « Baisse sa Vitesse. ») | « Un fil de soie gluant entrave la cible. Baisse beaucoup sa Vitesse. » |
| 18 | `harden` · `name` | Normal, statut | « Armure » |
| 19 | `harden` · `description` | Défense +1 (appris à l'évolution par Chrysacier et Coconfort, Q-5) | « Le lanceur contracte tout son corps pour le durcir. Augmente sa Défense. » |
| 20 | `thunder_shock` · `name` | Électrik, 40 | « Éclair » |
| 21 | `thunder_shock` · `description` | paralysie 10 % (en attente, J11) | « Une décharge électrique frappe la cible. Peut la paralyser. » |
| 22 | `thunder_wave` · `name` | Électrik, statut | « Cage-Éclair » |
| 23 | `thunder_wave` · `description` | paralysie (en attente, J11 : sans effet au J9) | « Une faible onde électrique paralyse la cible. Sans effet dans le moteur actuel. » |
| 24 | `confusion` · `name` | Psy, 50 | « Choc Mental » |
| 25 | `confusion` · `description` | confusion 10 % (en attente) | « Une faible vague psychique frappe la cible. Peut la rendre confuse. » |
| 26 | `stun_spore` · `name` | Plante, statut | « Para-Spore » |
| 27 | `stun_spore` · `description` | paralysie (en attente : sans effet au J9) | « Une poudre qui engourdit et paralyse la cible. Sans effet dans le moteur actuel. » |
| 28 | `supersonic` · `name` | Normal, statut | « Ultrason » |
| 29 | `supersonic` · `description` | confusion (en attente : sans effet au J9) | « Des ondes étranges rendent la cible confuse. Sans effet dans le moteur actuel. » |
| 30 | `psybeam` · `name` | Psy, 65 | « Rafale Psy » |
| 31 | `psybeam` · `description` | confusion 10 % (en attente) | « Un étrange rayon psychique frappe la cible. Peut la rendre confuse. » |
| 32 | `twineedle` · `name` | Insecte, 25 × 2 | « Double-Dard » |
| 33 | `twineedle` · `description` | poison 20 % (réel au T4) ; deux coups (en attente) | « Deux coups de dard venimeux. Peut empoisonner la cible. Un seul coup dans le moteur actuel. » |
| 34 | `pin_missile` · `name` | Insecte, 25 × 2 à 5 | « Dard-Nuée » |
| 35 | `pin_missile` · `description` | coups multiples (en attente) | « Lance deux à cinq dards pointus sur la cible. Un seul coup dans le moteur actuel. » |
| 36 | `swift` · `name` | Normal, 60, précision 0 = ne rate jamais (règle existante, comme Hâte) | « Météores » |
| 37 | `swift` · `description` | | « Des rayons en forme d'étoile frappent la cible. N'échoue jamais. » |
| 38 | `thunder` · `name` | Électrik, 110, précision 70 | « Fatal-Foudre » |
| 39 | `thunder` · `description` | paralysie 30 % (en attente) | « Une foudre violente s'abat sur la cible. Peut la paralyser. » |

## E. Pokédex (`data/pokedex/kanto.json`)

Descriptions originales (observation de terrain, jamais les textes officiels). Comme pour les 24 espèces existantes, **les formes de base ont une note** débloquée à la première rencontre (`"unlock": { "seen": 1 }`) et les évolutions n'en ont pas ; les notes 41, 45 et 49 suivent cette règle (à retirer d'un mot si tu n'en veux pas). Taille et poids : valeurs officielles (T1).

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 40 | `species/caterpie` · `description` | Chenipan, n° 010 | « Il grignote les feuilles du matin au soir. Inquiet, il dresse son antenne rouge et répand une odeur qui fait fuir les curieux. » |
| 41 | `species/caterpie/notes/0` · `text` (`caterpie_leaf`) | note de terrain ; fait écho au Chenipan d'ambiance qui relève la tête | « Immobile sur une feuille, il se confond avec elle. On ne le remarque que lorsqu'il relève la tête. » |
| 42 | `species/metapod` · `description` | Chrysacier, n° 011 | « Sa coque durcit pour protéger le corps tendre qui se transforme à l'intérieur. Il bouge à peine et attend son heure. » |
| 43 | `species/butterfree` · `description` | Papilusion, n° 012 | « Ses ailes sèment une fine poudre à chaque battement. Il passe de fleur en fleur dans les clairières, loin des sentiers. » |
| 44 | `species/weedle` · `description` | Aspicot, n° 013 | « Le dard de sa tête est venimeux. Il reste caché sous les feuilles et ne s'en sert que lorsqu'on le dérange. » |
| 45 | `species/weedle/notes/0` · `text` (`weedle_curl`) | note de terrain ; écho à l'Aspicot d'ambiance qui se rétracte | « Dérangé sur son tronc, il se recroqueville aussitôt vers le feuillage, le dard tourné vers l'intrus. » |
| 46 | `species/kakuna` · `description` | Coconfort, n° 014 | « Accroché aux branches, il semble dormir dans son cocon. Pourtant, il sent tout ce qui bouge autour de lui. » |
| 47 | `species/beedrill` · `description` | Dardargnan, n° 015 | « Il fond sur les intrus dans un bourdonnement sourd, ses trois dards pointés en avant. Il défend son nid avec acharnement. » |
| 48 | `species/pikachu` · `description` | Pikachu, n° 025 | « Les poches de ses joues crépitent quand il est inquiet. On l'aperçoit rarement, au détour d'un sous-bois, avant qu'il ne file. » |
| 49 | `species/pikachu/notes/0` · `text` (`pikachu_scorch`) | note de terrain (Pikachu rare, jamais scénarisé : la note ne dit pas où il vit) | « Des feuilles roussies au pied d'un arbre trahissent parfois son passage. » |
| 50 | `species/raichu` · `description` | Raichu, n° 026 (visible seulement s'il est vu un jour ; jamais obtenu au J9) | « Quand il a accumulé trop d'électricité, il plante le bout de sa queue dans la terre pour s'en délester, puis redevient calme. » |

## F. Zone « Forêt de Jade » (`data/world/zones.json`, `data/trainer/moments.json`)

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 51 | `zones/viridian_forest` · `subtitle` | Carte, sous le nom (la Route 1 a « Bourg Palette — Jadielle », la Route 2 « Jadielle — Forêt de Jade ») | « Jadielle — Argenta » |
| 52 | `zones/viridian_forest` · `description` | panneau de zone de la Carte (registre de Jadielle et des routes) | « Une forêt profonde et fraîche, où la lumière ne tombe qu'entre les cimes. Les Pokémon Insecte y foisonnent, et la route paraît vite très loin. » |
| 53 | `zone_arrivals/viridian_forest` · `title` | **facultatif** : Grand moment à l'arrivée (sans lui : « Forêt de Jade » / « Une nouvelle zone découverte. », déjà validé) | « Entrée dans la Forêt de Jade » |
| 54 | `zone_arrivals/viridian_forest` · `detail` | idem | « Les arbres se referment sur le sentier. » |

## G. Noms affichés (`speaker` des dialogues)

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 55 | `forest_gate_south_guard`, `forest_gate_north_guard` · `speaker` | les deux gardes des postes | « Garde » |
| 56 | `forest_naturalist` · `speaker` | P1, près de la grande souche | « Naturaliste » |

Déjà validés, réutilisés : « Randonneuse » (P2, nom validé au J8) ; noms des Dresseurs « Scout Théo », « Scout Noé », « Gamin Tom », « Scout Milo », « Scout Éli » (dossier 10 : ce sont les `name` de `data/trainers/`, aussi `speaker` de leurs répliques ; aucune classe de Dresseur n'est affichée à part, « Scout » et « Gamin » n'ont pas besoin d'entrée propre).

## H. Divers

| # | Clé cible | Contexte | Texte proposé |
|---:|---|---|---|
| 57 | warp de la porte nord du poste nord · `coming_soon` | écran provisoire « <destination> — À venir » (build de développement, en capitales à l'écran : « ROUTE 2 NORD — À venir ») ; disparaît au J10 | « Route 2 nord » |

## Questions liées au lot (pas des textes)

- **Mention « Sans effet dans le moteur actuel. »** : proposée pour Cage-Éclair, Para-Spore et Ultrason (sans effet jusqu'au J11, comme Cyclone). Poudre Dodo, validée au J7, est dans le même cas **sans** la mention : l'ajouter aussi (« Une poudre soporifique qui endort la cible. Sans effet dans le moteur actuel. ») ou retirer la mention des trois nouvelles ? *Proposé : ajouter la mention à Poudre Dodo, pour la cohérence ; elle disparaît au J11.*
- **Grands moments** : une « première victoire contre un Dresseur » ou une « première évolution » dans le profil Dresseur ne sont prévues ni par le dossier 08 ni par le dossier 10 ; rien n'est proposé ici. À décider si tu les veux (elles demanderaient leurs propres textes et un drapeau).
