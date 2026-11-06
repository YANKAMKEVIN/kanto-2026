# Dossier JOH-01 — Systèmes du Chapitre Johto (jalon JOH0, v0.1)

> Conception des systèmes neufs du Chapitre Johto, à partir du cadre
> [`dossier-joh-00-cadre.md`](dossier-joh-00-cadre.md) (JH-1 à JH-20 tranchés par Kevin) et d'un
> relevé du moteur fait le 2026-11-02. Écrit par Claude ; JH-21 à JH-24 tranchés par Kevin le 2026-11-02 ; **le reste est à valider**. Les valeurs
> **[D]** sont des défauts (règle 4 de `CLAUDE.md`) ; les vraies questions sont **JH-21 et
> suivantes** (§12). Le plan technique (`docs/tech/jalon-joh0.md`) viendra après validation.
> **Pas de code avant la fin de Kanto.**

## 1. Périmètre du JOH0

| Système | Réutilise | Neuf |
|---|---|---|
| Heure de jeu (§2) | `WorldClock` (`game/systems/day_night/world_clock.gd`, inactif aujourd'hui) | Lecture de l'heure du téléphone, 3 moments, 7 jours |
| Lumière de Johto (§3) | `LightingLibrary`, `WorldLighting`, profils de `data/world/lighting.json` | 3 profils par moment, choix automatique sur les cartes extérieures de Johto |
| Rencontres par moment (§4) | `EncounterLibrary`, tables de `data/encounters/` | Clé optionnelle `period` |
| Régions (§5) | `data/world/zones.json`, `fly_points.json`, Carte du Menu Dresseur | Champ `region`, seconde page de Carte, Vol entre régions |
| Équipe confisquée (§6) | `GameState` (`party`, `bag`, `storage`) | Section de sauvegarde `confiscated`, Stockage hors ligne |
| Œuf (§7) | `Pokemon`, compteur de pas du joueur | État « œuf », éclosion |
| Lien (§8) | Compagnon (`companion_uid`) | Valeur `bond` par Pokémon, méthode d'évolution `bond` |
| Évolutions par objet et échange (§9) | Terminal d'échange local du J32 (`LocalTrade`) | Règle `trade` + `item` |
| Expérience de l'acte 1 (§10) | `BattleRules.exp_multiplier`, Multi Exp (`exp_all`, lot 32P) | Bonus ×1,5 pendant l'acte 1 |
| Pokédex 202 (§11) | `PokedexLibrary` (taille lue dans les données) | Pokédex national partiel, Diplôme de Johto |
| Sauvegarde v10 (§12) | `SaveSystem.upgrade()` | Migration 9 → 10 |
| Données (§13) | Format des espèces et attaques | 51 espèces, attaques d'Or/Argent |

## 2. Heure de jeu

- **Source** : heure et jour **du téléphone** (JH-6), lus par `WorldClock`, qui devient actif.
  Injectable pour les tests, comme `DeviceClock`.
- **Moments** : `morning` 4 h 00–9 h 59, `day` 10 h 00–17 h 59, `night` 18 h 00–3 h 59 (Or/Argent).
- **Jours** : lundi à dimanche, pour les PNJ et événements datés.
- **Portée** : les règles de l'heure ne jouent **qu'à Johto** (JH-8). À Kanto, `WorldClock` tourne
  mais rien ne le lit **[D]**.
- **Affichage** : l'heure et un petit pictogramme du moment (soleil levant, soleil, lune) dans le
  tableau de bord du Menu Dresseur, à Johto seulement **[D]**.
- **Scènes forcées** : une cinématique peut imposer un moment (arrivée à Oliville de nuit, vol au
  Centre) ; à sa fin, on revient à l'heure réelle **[D]**.
- **Changement d'heure du téléphone** : accepté sans contrôle (jeu personnel) **[D]**.

## 3. Lumière de Johto

- **Trois profils neufs** : `johto_morning` (lumière rasante froide, brume légère), `johto_day`
  (lumière blanche, ombres courtes), `johto_night` (étalonnage bleu, ombres très douces, pas de
  liseré de soleil). Même structure que `golden_hour` ; réglages fins en JOH0 sur captures.
- **Choix automatique** : une carte de Johto déclare `light_profile = &"johto_auto"` ; à l'arrivée
  et à chaque changement de moment, le jeu applique le profil du moment. Les intérieurs gardent
  leur profil fixe (`interior_warm`, grottes…) **[D]**.
- **Transition** en direct : fondu de 10 s entre deux profils si le moment change sur la carte
  **[D]** ; immédiat à l'arrivée sur une carte.
- **Lumières de nuit** : un nœud de points lumineux par carte (fenêtres, lampadaires, phare),
  visible la nuit seulement, posé dans les cartes de Johto.
- **Les décors ne sont peints qu'une fois** (en lumière neutre, mémoire « Codex images ») ;
  l'étalonnage fait le reste. Si la nuit ne tient pas sur une carte, une variante peinte de nuit
  pourra être ajoutée carte par carte (à noter dans « Reportés », pas en JOH0).

## 4. Rencontres par moment

- Clé optionnelle `period` dans une table de `data/encounters/` : `"morning"`, `"day"`,
  `"night"`, ou une liste (`["morning", "day"]`).
- Une table **sans** `period` vaut toute la journée (toutes les tables de Kanto restent valides).
- Pour une même carte et un même terrain : au plus une table par moment ; une table sans `period`
  et une table avec `period` ne peuvent pas coexister (erreur au chargement) **[D]**.
- Kanto n'utilise jamais `period` (JH-8).

## 5. Régions

- **`region`** dans `data/world/zones.json` : `"kanto"` (défaut si absent) ou `"johto"`.
- **Carte du Menu Dresseur** : deux pages, Kanto et Johto, avec un bouton de bascule. La page
  Johto n'apparaît qu'après l'arrivée à Oliville **[D]**. Illustration provisoire comme pour Kanto.
- **Vol** : les points de Vol de Johto (Oliville, Rosalia, Doublonville, Écorcia, Acajou)
  s'ajoutent à `fly_points.json` avec leur région. La liste montre d'abord la région où l'on est.
  **Vol entre régions** possible à partir de l'acte 2 (drapeau `johto_team_returned`) ;
  **interdit pendant l'acte 1** (JH-18), où le joueur n'a de toute façon pas de Pokémon qui vole
  au début.
- **Grotte marine** : bloquée côté Johto pendant l'acte 1 par un courant (texte), ouverte ensuite
  (JH-18).

## 6. Équipe confisquée (JH-1 à JH-3)

### 6.1 Données

Nouvelle section de sauvegarde **`confiscated`**, vide par défaut :
- `party` : les Pokémon de l'équipe au moment du vol (format habituel, uid gardés) ;
- `bag` : les objets **non clés** du sac (identifiant → quantité) ;
- `companion` : l'uid du compagnon de l'époque.

Nouveau drapeau **`storage_offline`** : tant qu'il est posé, le PC refuse l'accès au Stockage
(« Le réseau de Kanto ne répond pas. ») et le terminal d'échange local est fermé **[D]**.

### 6.2 Le vol (une seule opération atomique)

1. Copier l'équipe et les objets non clés dans `confiscated`.
2. Vider l'équipe, retirer les objets non clés du sac, poser `storage_offline`, effacer le
   compagnon.
3. Sauvegarder **en une seule écriture**. Si l'application est tuée avant, rien n'a changé ; après,
   tout a changé. Jamais d'état intermédiaire (équipe vide sans `confiscated`).

Les **objets clés** restent (Vélo, Canne, Multi Exp, CS…). L'**argent**, les **badges** et le
**Pokédex** restent.

### 6.3 L'acte 1 sans équipe

- Entre le vol et le choix du Pokémon de départ, l'équipe est **vide** : le joueur ne peut pas
  sortir du Centre (Orme arrive aussitôt, scène continue) **[D]**.
- Le choix réutilise la mise en scène du choix de Kanto (`StarterChoiceController`), avec une liste
  `starters_johto` dans `data/pokemon/starters.json`.
- Le **compagnon** devient le Pokémon de départ de Johto.
- Pas de Stockage : au-delà de 6 Pokémon, une capture va… nulle part. Règle **[D]** : à 6 Pokémon,
  le jeu refuse de lancer une Poké Ball (« Ton équipe est pleine, et le PC ne répond pas. »).

### 6.4 Le retour (Antre du Dragon, fin de l'arc des Pierres : JH-61, dossier JOH-11 §14)

1. L'équipe de Johto et l'équipe confisquée se rejoignent. Le joueur **choisit les 6** à garder sur
   un écran de sélection ; les autres vont au Stockage, qui se reconnecte au même moment **[D]**.
2. Les sacs fusionnent (quantités additionnées).
3. `confiscated` est vidé, `storage_offline` retiré, `johto_team_returned` posé, une seule écriture.
4. Le compagnon revient au compagnon d'avant le vol s'il est dans les 6, sinon au premier de
   l'équipe **[D]**.

### 6.5 Cas limites

- Application tuée pendant la scène du vol, pendant l'écran de sélection du retour.
- Défaite avec une équipe vide (impossible : l'équipe ne peut pas être vide hors scène).
- Évolution, œuf qui éclot, capture refusée à 6 pendant l'acte 1.
- Sauvegarde v9 chargée par une build v10 (`confiscated` vide, rien ne change).

## 7. L'œuf de Togepi

- Un Pokémon porte un état **œuf** : `egg_steps` restants (par défaut 2 000 pour Togepi **[D]**).
- Dans l'équipe : il compte dans les 6, ne combat pas, ne peut pas être en tête en combat (il est
  sauté), ne peut pas être compagnon, ne gagne pas d'XP.
- Chaque pas du joueur décrémente les œufs de l'équipe ; à 0, **scène d'éclosion** au pas suivant
  hors combat et hors cinématique : Togepi niveau 5, enregistré « capturé » au Pokédex à ce moment.
- Écran Équipe : icône d'œuf, phrase selon le reste (« Il bouge un peu. », « On l'entend
  remuer ! ») **[D]**.
- Pendant l'acte 1, le Stockage étant hors ligne, l'œuf reste dans l'équipe.

## 8. Le lien (JH-11)

### 8.1 Règle

- Chaque Pokémon a une valeur **`bond`** de 0 à 100, **cachée**.
- **Départ** **[D]** : Pokémon capturé 20 ; Pokémon de départ, œuf éclos, Pokémon reçu en cadeau 50 ;
  Pokémon déjà présents dans la sauvegarde au passage en v10 : 50.
- **Gains** **[D]** :
  - +2 quand il participe à un combat gagné ;
  - +1 tous les 256 pas dans l'équipe ;
  - +1 de plus tous les 256 pas s'il est le **compagnon** (le compagnon du J11 prend un rôle).
- **Pas de raccourci** : ni Super Bonbon, ni soin au Centre, ni objet ne font monter le lien ; il
  vient de l'aventure **[D]**.
- **Pertes** **[D]** : −3 quand il tombe K.O.
- **Seuil** : **70**. Avec ces valeurs, un Pokémon gardé dans l'équipe et en combat l'atteint en
  environ 2 à 3 h de jeu ; le compagnon, plus vite.

### 8.2 Évolutions par lien

Nouvelle méthode `bond` dans les données (`{"into": "togetic", "method": "bond"}`), avec un
`period` facultatif. L'évolution se déclenche **au prochain passage de niveau** si `bond ≥ 70` (et
si le moment correspond), comme les évolutions par niveau.

| Pokémon | Évolution | Condition |
|---|---|---|
| Togepi | Togetic | lien |
| Leveinard | Leuphorie | lien |
| Nosferalto | Nostenfer | lien |
| Évoli | Mentali | lien, `period` matin ou jour |
| Évoli | Noctali | lien, `period` nuit |

À Kanto (pas d'heure), Évoli ne peut évoluer en Mentali ou Noctali qu'une fois arrivé à Johto
**[D]** : le moment n'est lu qu'à Johto (§2).

### 8.3 Lisibilité

Un PNJ de Doublonville dit ce que le Pokémon de tête pense du joueur, en 4 paliers de texte
(< 30, 30–69, 70–89, ≥ 90), comme la dame du lien d'Or/Argent **[D]**. Pas de jauge visible (JH-21).

## 9. Évolutions par objet et échange

- Règle de données : `{"into": "steelix", "method": "trade", "item": "metal_coat"}`.
- Au **terminal d'échange local** des Centres (J32) : si le Pokémon a une évolution `trade` avec
  `item`, le terminal demande « Utiliser une Peau Métal ? » ; oui → l'objet est consommé et
  l'évolution se fait comme les autres évolutions par échange. Sans l'objet, rien ne se passe.
- Objets neufs (4) : **Peau Métal** (Steelix, Cizayox), **Roche Royale** (Roigada, Tarpaud),
  **Écaille Draco** (Hyporoi), **Améliorator** (Porygon2). Emplacements au cadre §6.
- Les 4 évolutions `trade` de Kanto ne changent pas.

## 10. Expérience de l'acte 1 (JH-13, JH-14)

- Drapeau **`johto_act1`** posé au vol, retiré au retour de l'équipe, donc après l'arc des Pierres (JH-70).
- Pendant l'acte 1, gain d'XP **×1,5** (multiplié avec le ×1,5 des combats de Dresseurs, donc
  ×2,25 contre un Dresseur) **[D]**.
- **Multi Exp** : c'est déjà un **objet clé** (lot 32P), donc **gardé** au vol. Si le joueur ne l'a
  pas, la Tour Radio lui en donne une ; s'il l'a, il reçoit à la place un Super Bonbon ×3 **[D]**.

## 11. Pokédex à 202 espèces

- Numéros **nationaux** (Germignon n° 152 … Celebi n° 251). Le Pokédex liste **seulement les espèces
  du jeu** dans l'ordre des numéros : 1 à 151, puis 152, 153, 154, 155… sans cases vides pour les
  49 espèces absentes **[D]** (JH-22).
- `size` passe à 202 ; affichage « vus · capturés · 202 espèces » (51 espèces de Johto avec Écrémeuh, JH-28).
- Un filtre « Kanto / Johto / Tout » dans le Pokédex **[D]**.
- **Diplôme de Johto** : même mécanisme que celui de Kanto (variante de dialogue
  `if_caught_at_least`), seuil **50** espèces de Johto capturées (Celebi exclu), remis par Orme ou
  son assistant à Oliville **[D]**. Le Diplôme de Kanto ne change pas (150).

## 12. Sauvegarde v10

- Migration **9 → 10** dans `SaveSystem.upgrade()` :
  - ajoute `bond: 50` à chaque Pokémon de l'équipe, du Stockage et de la Pension ;
  - ajoute `confiscated` vide ;
  - rien d'autre (régions, heure : déduits des données et du téléphone).
- **Système risqué** : validé **seul**, en premier sous-jalon (JOH0A), sur une copie de la vraie
  sauvegarde de Kevin, avant tout le reste (règle 1 de `CLAUDE.md`).
- Une build v9 refuse un fichier v10 (comportement actuel).

## 13. Données

- **51 espèces** dans de nouveaux fichiers `data/pokemon/species/johto_*.json`, même format que
  Kanto (`dex`, `name`, `types` modernes, `base_stats` modernes, `learnset`, `evolutions`…).
- **Attaques** : celles des apprentissages d'Or/Argent des 51 espèces et des attaques de Dante et
  des admins, environ **40 attaques neuves** **[D]**, chacune rattachée à une famille d'effets
  existante (`data/battle/move_fx/families.json`).
- **Art** : artwork officiel n° 152–251 pour les 51 (`assets/sprites/pokemon/official/`), dos de
  combat repeints (même chaîne que Kanto), sprites de compagnon pour les espèces éligibles.
- **Sources** : PokeAPI pour les statistiques et apprentissages, comme Kanto.

## 14. Découpage du JOH0

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **JOH0A** | Sauvegarde v10, équipe confisquée (vol et retour, en scène de test), Stockage hors ligne | **Seul** (système risqué) |
| **JOH0B** | Heure (`WorldClock`), 3 profils de lumière, `johto_auto`, lumières de nuit, rencontres par moment | Captures matin / jour / nuit sur une carte de test |
| **JOH0C** | Lien, évolutions `bond` et `trade` + objet, œuf et éclosion, Exp ×1,5 | Lot |
| **JOH0D** | Données des 51 espèces et des attaques, Pokédex 202 et filtre, régions, Carte à 2 pages, Vol entre régions | Lot |

Chaque sous-jalon : tests ciblés, puis CI complète avant fusion (règle 2 de `CLAUDE.md`).

## 15. Arbitrages pour Kevin

| N° | Question | Recommandation de Claude |
|---|---|---|
| JH-21 | ✅ Lien **caché**, évalué par un PNJ de Doublonville (Kevin, 2026-11-02) | — |
| JH-22 | ✅ Pokédex en **liste continue**, sans cases vides, filtre Kanto / Johto / Tout (Kevin) | — |
| JH-23 | ✅ À 6 Pokémon pendant l'acte 1, **lancer refusé** (Kevin) | — |
| JH-24 | ✅ Au retour, le joueur **choisit ses 6** (Kevin) | — |

## Annexe : textes hors dossier validés par Kevin (2026-11-06)

Lot `docs/design/passes/johto-textes-a-valider.md`, validé tel quel.

- `trade_terminal_item` : Utiliser {item} ?
- `johto_return_test_before` : (Scène de test du JOH0.) Les Poké Balls de ton équipe sont là.
- `johto_return_test_after` : Le réseau de Kanto répond de nouveau.
