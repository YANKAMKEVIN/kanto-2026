# J19 — Les mystères de la Tour Pokémon : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-14. Conception seulement : aucune ligne de code. V2 reproduite dans
> `j19-v2-chatgpt.md`.
>
> **Relu contre** :
> - `vision.md`, `roadmap.md` et les dossiers 05, 06, 14, 15 et 16 ;
> - le code de `origin/main` (`4f0ee90`, J13 terminé) et des branches `jalon-14` et `jalon-15` ;
> - la passe J16 (`origin/ccr-fa255d49-wvvacc`), la passe J17 (`docs/dossier-20-j17`), la passe
>   J18 (`docs/dossier-j18`, arbitrages I-1 à I-26) et la passe J20 (`docs/dossier-23-j20`).
>
> **Faits Rouge/Bleu vérifiés dans le désassemblage `pret/pokered`** :
> - `data/wild/maps/PokemonTower*.asm` ;
> - `data/maps/objects/PokemonTower*.asm` et `scripts/PokemonTower*.asm` ;
> - `engine/battle/core.asm` (`IsGhostBattle`, `PrintGhostText`, `TryRunningFromBattle`) ;
> - `engine/items/item_effects.asm` et `data/trainers/parties.asm` ;
> - les espèces, recoupées avec PokeAPI (`red-blue`).
>
> Rouge et Bleu sont identiques partout dans la Tour. Ce qui n'est pas vérifié est marqué « à
> recouper ».
>
> **Numéro de dossier : 22** (`dossier-22-tour-pokemon.md`). 19 = J16, 20 = J17, 21 = J18 et
> 23 = J20, comme le retiennent déjà les passes J18 et J20. Branche : `docs/dossier-j19`.
>
> **Arbitrages K-1 à K-20.** H est pris deux fois (J17 et J20) et I par le J18. On saute J pour ne
> pas le confondre avec « jalon ». Les références J19-A à J19-I de la V2 sont gardées telles quelles.
>
> **Origine des règles** : **RB** = Rouge/Bleu, **G+** = génération plus récente, **K26** = invention
> de Kanto 2026. **[D]** = valeur par défaut, notée et non bloquante.
>
> **Vocabulaire des étages.** La V2 compte les « niveaux » de 1 à 7. En français, RB dit
> « rez-de-chaussée » pour 1F, puis « 1er étage » pour 2F, et ainsi de suite jusqu'au 6e étage
> (7F). Dans cette passe, **« 2F » = 2e niveau de la V2 = 1er étage**. Les identifiants de cartes
> suivent RB : `pokemon_tower_1f` à `pokemon_tower_7f`.

> **Réponses de Kevin (2026-10-14)** : K-1 à K-20 **acceptés tels que recommandés**. Consolidation :
> `docs/design/dossier-22-tour-pokemon.md`. Correctif : les variantes du rival n° 5 sont données
> au dossier 22 §7.3 (vérifiées dans `parties.asm` : Reptincel avec Noeunoeuf et Léviator,
> Carabaffe avec Caninos et Noeunoeuf, Herbizarre avec Léviator et Caninos).

## 0. Contrat d'entrée (J16 à J18 en parallèle, J20 en aval)

Aucun de ces jalons n'est codé. Le J19 ne les attend pas pour sa conception, mais il **écrit ce qu'il
suppose** :

| Le J19 suppose | Jalon | État réel / source |
|---|---|---|
| Lavanville, son Centre (point de repos) et la maison de M. Fuji (Fuji absent) | J18 | Passe J18, I-19 et I-23 : rien n'est codé. `zones.json` déclare `lavender_town`, avec `maps: []`. |
| Extérieur et rez-de-chaussée de la Tour : visiteurs, tombes, gardien | J18 | Passe J18, I-22 : aucun spectre ni rival, aucune allusion à un enlèvement. |
| **Une Médium en prière bloque l'escalier du rez-de-chaussée** ; elle s'écarte au J19 | J18 | Passe J18, I-21 (K26, absent de RB) → **K-2** et **K-3**. |
| Rival n° 3 : Roucoups 16, Rattata 14, starter évolué 16 (Roucool 15 et Reptincel 15 si le joueur a pris Bulbizarre) | J13 | **Codé** : `data/trainers/rival.json`. |
| Rival n° 4 : Roucoups, **Rattatac**, **Kadabra**, starter évolué, vers 19 / 16 / 18 / 20, recalés par simulation | J16 | Passe J16, G-7 et correctif du 2026-10-13. Ni Kadabra ni Rattatac n'existent dans les données. |
| Le joueur arrive avec une équipe de niveau 22 à 25 environ | J17–J18 | Équipes des J16 à J18 à caler (passe J18, I-12) → **K-6**. |
| Schéma de sauvegarde : v6 (`main`), v7 (`jalon-15`) | — | Le J19 n'ajoute que des drapeaux, sans changer la version (§4). |
| **Le J20 attend** : spectres conditionnés à la **possession de `silph_scope`** et rival n° 5 vaincu | J20 | Passe J20, §2.4 et §4 : accepté tel quel (**K-11**). |

## 1. Les sept décisions verrouillées

Aucune n'est rouverte. Deux demandent une précision : n° 4 et n° 5.

| # | V2 | Avis |
|---|---|---|
| 1 | Tour partiellement explorable, Scope Sylphe au J20 | Oui. C'est exactement RB : sans le Scope, on parcourt les étages 1F à 6F, mais pas l'escalier du 7F. Le tableau de la V2 (§3) colle à RB. Seul écart : au J18, l'escalier est fermé par la Médium, qui n'existe pas dans RB (K-2). |
| 2 | Rival n° 5, victoire obligatoire | Oui. RB : il est au 2F, au bord du seul passage vers l'escalier du 3F, donc **inévitable** (dérivé de la collision de la carte). Défaite → dernier Centre, comme pour les n° 3 et 4. Équipe : K-5 et K-6. |
| 3 | Mystérieuse, émouvante, respectueuse | Oui, conforme à `vision.md` et à la bible. Deux limites techniques (§3) : **aucun système audio** n'existe, et les `Light2D` sont interdites par les tests (rendu mobile). |
| 4 | Fantominus et Spectrum « selon les tables historiques » | **Précision.** Les tables RB contiennent aussi **Osselait** (environ 9 % des rencontres du 3F au 7F). Et surtout, **sans le Scope, toute rencontre sauvage de la Tour est un SPECTRE** : impossible à identifier, à capturer ou à combattre. Au J19, le joueur ne capture donc **rien** dans la Tour. Il découvre Fantominus et Spectrum **par les Exorcistes**, dont les combats montrent l'espèce → K-7 à K-10. |
| 5 | Ossatueur : rencontre au retour avec le Scope | **Précision.** Dans RB, le « spectre non identifié » qui bloque le 6F (§3 de la V2) **est** Ossatueur. Le déclencheur fonctionne aussi sans le Scope : combat où l'on ne peut que fuir, puis le joueur est repoussé d'une case. La V2 demande les deux à la fois : « identité cachée, progression impossible » (§5) et « rencontre après le Scope » (décision 5). Lecture proposée : **au J19, on rencontre « un SPECTRE », jamais « Ossatueur »**. Le nom, le combat réel et la résolution restent au J20 → K-12. |
| 6 | M. Fuji disparu, sauvetage avec le Scope | Oui. Conforme à RB (il est au 7F, retenu par les Rocket). La V2 ajoute que Fuji « s'intéressait à des activités suspectes » (K26). C'est compatible avec la phrase du J18, « il passe ses journées à la Tour », à condition de ne pas nommer la Team Rocket → K-15. |
| 7 | Rocket suggérée, pas de confrontation | Oui. RB : les Rocket ne sont qu'au 7F. En ville, deux PNJ disent que la mère d'Osselait est morte en fuyant la Team Rocket. Le seul indice vers le Scope est **un panneau publicitaire Sylphe** ; **aucun PNJ de RB ne nomme Céladopole** → K-16. |

## 2. Faits Rouge/Bleu vérifiés (base du dossier 22)

### 2.1 Étages et escaliers

Chaque étage fait 20 × 18 cases. Les escaliers alternent droite / gauche, sauf au 6F, où l'escalier
du 7F est au sud.

| Étage | Contenu RB | Sauvages |
|---|---|---|
| 1F | Accueil, 3 visiteurs, une Exorciste qui ne combat pas (« les esprits s'agitent ») | non |
| 2F | **Rival**. Une Exorciste qui ne combat pas : « le Scope Sylphe pourrait démasquer les spectres » | non |
| 3F | 3 Exorcistes (tous facultatifs) ; Corde Sortie | oui, taux 10 |
| 4F | 3 Exorcistes (1 inévitable) ; Élixir, Réveil, PV Plus | oui, taux 10 |
| 5F | 4 Exorcistes (facultatifs), **zone purifiée** ; Pépite et 1 Élixir caché | oui, taux 10 |
| 6F | 3 Exorcistes (2 inévitables) ; Super Bonbon, Précision + ; **Ossatueur spectre** devant l'escalier du 7F | oui, taux 15 |
| 7F | 3 Sbires Rocket (inévitables), M. Fuji | oui, taux 15 |

« Inévitable » est **dérivé** d'une recherche de chemin sur la collision et les lignes de vue. À
recouper en jeu.

### 2.2 Rencontres sauvages

Les rencontres se déclenchent **sur toute case praticable**, ce qui est normal pour un intérieur RB.
Le taux est sur 256 : 10 donne environ 3,9 % par pas, 15 environ 5,9 %.

| Étage | Fantominus | Spectrum | Osselait |
|---|---|---|---|
| 3F | N18–24, ≈ 89 % | N25, ≈ 1 % | N20–22, ≈ 9 % |
| 4F–5F | N18–24, ≈ 86 % | N25, ≈ 5 % | N20–22, ≈ 9 % |
| 6F | N19–24, ≈ 84 % | N26–28, ≈ 6 % | N22–24, ≈ 9 % |
| 7F | N20–24, ≈ 75 % | N28–30, ≈ 15 % | N22–24, ≈ 10 % |

Les pourcentages viennent des emplacements de tirage RB (51, 51, 39, 25, 25, 25, 13, 13, 11 et 3 sur
256). Le détail exact par emplacement sera recopié au dossier.

### 2.3 Combat contre un SPECTRE (sans le Scope)

**Quand ?** Combat sauvage, carte de la Tour, et pas de `SILPH_SCOPE` dans le Sac.

| Aspect | RB |
|---|---|
| Affichage | Silhouette générique, nom « SPECTRE », aucun cri, « Le SPECTRE ne peut être identifié ! ». L'espèce réelle est tirée en coulisse. |
| Tour du joueur | Toute capacité est remplacée par « {pokemon} est trop effrayé pour bouger ! ». Le sommeil et le gel gardent leur propre message. |
| Tour du spectre | Il n'attaque jamais : « SPECTRE : Va-t'en… Va-t'en… ». Pas de dégâts, pas d'XP. |
| Ball | Toujours esquivée : « impossible à capturer ». |
| Sac et changement de Pokémon | Possibles |
| Fuite | **Réussit toujours** |
| Pokédex | **Bizarrerie RB** : l'espèce réelle est notée « vue » alors qu'on ne l'a pas vue → K-9. |
| Avec le Scope | Le contrôle échoue : combat normal (capture, XP). |

### 2.4 Ossatueur spectre (6F)

- **Déclencheur** : la case juste à droite de l'escalier du 7F, tant que l'Ossatueur n'est pas
  apaisé.
- **Sans le Scope** :
  1. message « Va-t'en… Intrus… » ;
  2. combat SPECTRE, avec les règles du §2.3 ;
  3. à la fin, **le joueur est repoussé d'une case** et le déclencheur se réarme.
- **Avec le Scope (J20)** :
  - le spectre se dissipe et laisse voir Ossatueur N30 (Massd'Os, Rugissement, Groz'Yeux,
    Puissance) ;
  - il est impossible à capturer ;
  - une victoire apaise l'âme de la mère d'Osselait.

### 2.5 Rival n° 5 (2F)

- **Équipe** : Roucoups 25, Kadabra 20, starter évolué 25 (Carabaffe, Herbizarre ou Reptincel),
  plus deux Pokémon parmi **Caninos**, **Léviator** et **Noeunoeuf**, selon le starter.
- **Pas de Rattatac** : c'est exactement le « tournant » du dossier 06 §6.
- **Récompense** : 1 625 ₽.
- **Dialogue RB, en résumé** : il se moque (« tes Pokémon n'ont pas l'air morts »). Après sa
  défaite, il dit avoir attrapé un Osselait sans trouver d'Ossatueur adulte.

### 2.6 Zone purifiée (5F)

- **Où** : un carré de 2 × 2 cases.
- **En entrant** : soin complet de l'équipe, fondu blanc et message (« zone purifiée et protégée »).
- **À l'intérieur** : ni rencontre ni Dresseur.
- **En sortant** : la zone se réarme. Le soin est donc **illimité**.

### 2.7 Exorcistes

- **Nom de classe** : « EXORCISTE » en Gen 1 (Poképédia ; à recouper dans une ROM française).
- **Équipes** : Fantominus N22–24 ou Spectrum N22–23, une Exorciste en aligne trois.
- **Récompense** : 30 × niveau du dernier Pokémon.
- **Vision** : 2 à 3 cases.
- Ils sont **possédés** : ils parlent comme des esprits avant le combat.

### 2.8 Lavanville avant la résolution

- **Maison de Fuji** : un homme s'étonne de son absence ; une fille explique qu'il recueille les
  Pokémon orphelins.
- **Maison d'Osselait** : la mère est morte en fuyant la Team Rocket.
- **Centre** : un témoin de sa mort ; un gentleman dit que « la Team Rocket fait tout pour
  l'argent ».
- **En ville** : un PNJ croit que les spectres sont les Pokémon tués par les Rocket. Un **panneau**
  vante le nouveau Scope Sylphe : « rendre visible l'invisible ».

## 3. Ce que l'audit du dépôt apporte (coûts, pas des décisions)

**Rien du « mode spectre » n'existe.** Voici chaque pièce, avec son point d'accroche :

| Pièce | Existe ? | Point d'accroche (`origin/main`) | Coût |
|---|---|---|---|
| Rencontre « spectre » selon la possession d'un objet | non | `EncounterDirector._run` (`encounter_director.gd:181-212`). **Aucune condition** dans les tables (`encounter_library.gd:26-30`). Proposé : un champ de carte ou de table `ghost_unless_item: "silph_scope"` plutôt qu'une table en double. | faible |
| Rencontres sur tout le sol d'un intérieur | non | Terrains `grass` et `rubble` seulement (`encounter_table.gd:26`). Il faut un terrain `floor` (toute case praticable), plus les cases exclues de la zone purifiée. | faible |
| Masquer le nom, le sprite et le niveau | non | `Pokemon.nickname` (`pokemon.gd:36`) couvre le nom. Le sprite (`battle_stage.gd:370-383`), `{species}` (`battle_text.gd:446`) et la carte adverse (`battle_views.gd:84-86`) lisent l'espèce. Il faut un drapeau `disguise` sur le combattant adverse. | moyen |
| « Vu » au Pokédex | à corriger | Enregistré **avant** le combat (`encounter_director.gd:189`). À sauter en mode spectre. | faible |
| Tour « trop effrayé » | non | `_can_act` (`battle.gd:635-672`), qui émet déjà `STATUS_PREVENTED` et `FLINCHED`. | faible |
| Ball refusée avec un message | non sur `main` | Précédent : `BALL_BLOCKED` sur `jalon-14` (`battle.gd:1102-1111`). | faible, **si le J14 est fusionné** |
| Fuite toujours réussie | non | `BattleRules` (`battle_rules.gd:11-27`) : ajouter `flee_always`. | faible |
| Spectre qui « passe son tour » en parlant | non | IA adverse : ajouter une action « message ». | faible |
| **Combat sauvage lancé par une scène** (Ossatueur) | non | L'étape `battle` n'accepte que des Dresseurs (`cutscene_director.gd:500-516`). Le J20 en aura besoin aussi (Ossatueur avec le Scope). | moyen |
| Repousser le joueur après la fuite | **oui** | Modèle `route_3_guard` (`cutscenes/pewter_city.json:12-21`). | nul |
| Soin par case (zone purifiée) | non | Déclencheur, scène, puis dialogue `heal` (`dialogue_runner.gd:339-343`). Il n'existe pas d'étape `heal` dans les scènes : on l'ajoute, ou on passe par un dialogue. | faible |
| Variantes du rival selon le starter | **oui** | `team_by_starter` (`trainer_data.gd:46`) et motif `won` / `lost_once` / `retried` du J13 (`route_24.json:14-55`). | nul |
| Défaite → dernier Centre | **oui** | `DefeatRecovery.recover`. | nul |
| Dégâts égaux au niveau (Ténèbres) | **oui** | `fixed_damage` `mode:"level"` (Frappe Atlas). | nul |
| Objet clé `silph_scope` | non | Catégorie `KEY` (`item_data.gd:18-24`). **Le J20 le crée** ; le J19 n'a besoin que de son identifiant. | nul |
| Lumière d'intérieur | partiel | Profils `lighting.json` et halos additifs (`light_glows.json`). La flamme de bougie est un halo animé ; la brume, un calque. **Pas de `Light2D`** (interdit par les tests). | faible |
| Musique et sons de pas | **non** | Aucun système audio dans le code. | hors J19 → K-18 |
| Fond de combat CB.3 | à créer | Une entrée `decors` et des `places` dans `data/battle/decors.json`. | art |

**Données à créer** :
- **Espèces** : Fantominus (92), Spectrum (93), Osselait (104) si K-7 le retient, plus celles du rival
  n° 5 (K-5). Seuls les artworks officiels existent pour 92 à 94, 104 et 105.
- **Capacités** : Léchouille, Ténèbres et Hypnose. Onde Folie existe déjà. Massd'Os seulement si
  Osselait est retenu.
- **Valeurs** : le projet suit les valeurs **actuelles** (précédent du J16). Léchouille fait donc 30,
  Spectre → Psy est super efficace (pas le bogue RB), et Ténèbres n'atteint pas un type Normal
  (G+ ; RB l'atteignait) [D].

## 4. Sauvegarde et retour au J20 (J19-F, J19-G, J19-H)

- **Aucun changement de version.** Le J19 n'ajoute que des drapeaux :
  - `rival_tower_won`, `rival_tower_lost_once`, `rival_tower_retried` (motif du J13) ;
  - `beaten_<exorciste>` ;
  - les objets ramassés (mécanisme existant) ;
  - `tower_stairs_open` si K-3 = B.
- **Le mode spectre lit le Sac, pas un drapeau.** Le jour où le J20 donne `silph_scope`, toutes les
  rencontres et l'Ossatueur passent en mode normal **sans migration**. C'est exactement ce que la
  passe J20 demande (§4).
- **Le J19 ne pose et ne lit aucun drapeau du J20** : `ghost_marowak_calmed`, `fuji_rescued`,
  `got_poke_flute`, Rocket du 7F. Ces drapeaux sont seulement **nommés** dans le dossier 22, pour
  que les deux jalons parlent la même langue.
- **Le 7F n'est pas construit au J19** (K-13). L'Ossatueur bloque l'escalier, le warp ne mène nulle
  part.
- **Tests de non-régression proposés** :
  1. Une sauvegarde J19 rechargée avec `silph_scope` ajouté au Sac donne des rencontres normales,
     sans autre changement.
  2. Aucune donnée du J19 ne lève un drapeau du J20.
  3. Le rival vaincu ne revient jamais ; une défaite ne pose pas `rival_tower_won`.
  4. Le spectre n'apparaît jamais au Pokédex.

## 5. Arbitrages K-1 à K-20

| # | Question | Options | Recommandation |
|---|---|---|---|
| **K-1** | Numéro du dossier | 22 · autre | **22** (`dossier-22-tour-pokemon.md`), cohérent avec les passes J18 et J20. |
| **K-2** | Nom de la classe des Dresseurs de la Tour | « Exorciste » (V2, RB Gen 1) · « Médium » (passe J18, I-21) · « Mystimana » (G+) | **Exorciste** partout, y compris pour la gardienne de l'escalier du J18 (une Exorciste qui ne combat pas, comme au 1F et au 2F de RB). **À reporter dans le dossier 21.** |
| **K-3** | Comment l'escalier s'ouvre au J19 (verrou K26 du J18) | A : la gardienne n'est **plus là** dans la build J19, sans scène · B : elle s'écarte après un **déclencheur** (ex. : le joueur parle aux gens de la maison de Fuji, ou entre de nouveau dans la Tour) et le dit en une ligne · C : le verrou du J18 est retiré (fidèle à RB) | **B**. Elle reste au rez-de-chaussée et dit une ligne d'inquiétude (« les esprits sont agités… »). C'est le premier signe du J19, et il ne faut qu'un drapeau. |
| **K-4** | Durée de la scène du rival | Dossier 06 §6 (« ...Tu es venu pour quoi ? » / « Laisse tomber. », il reste quelques secondes puis part) · V2 (un discours plus nuancé, qui évoque les spectres et son parcours) | **Le dossier 06 d'abord** (décision verrouillée). On ajoute au plus **une** réplique sur les spectres, sans parler de son Rattatac (« jamais confirmé »). Les textes seront proposés au dossier 22 et validés en lot. |
| **K-5** | Équipe du rival n° 5 | A : RB (Roucoups, Kadabra, starter évolué, plus 2 parmi Caninos, Léviator et Noeunoeuf) · B : RB **réduite à 4** (Roucoups, Kadabra, starter évolué, plus 1 nouveau) · C : on reprend le n° 4 en montant les niveaux, sans espèce nouvelle | **A**, l'équipe RB. Coût : **3 espèces** de dresseur seulement (données, artwork, Pokédex « vu »). Ce ne sont pas des espèces capturables, donc la règle « capturable = évolution disponible » ne s'applique pas. Caninos est déjà prévu au J20 : on le mutualise. Léviator n'impose pas Magicarpe. |
| **K-6** | Niveaux du rival n° 5 | RB 20–25 · recalés par **simulation** contre l'équipe probable au J19 (méthode `simulate_brock.gd`) | **Simulation**, avec RB comme repère. Le n° 4 est vers 16–20 et la passe J20 attend 25–28 à l'arrivée à Céladopole : **22 à 26** devrait tenir. À fixer quand les équipes des J16 à J18 seront connues. |
| **K-7** | Osselait dans les tables de la Tour | A : oui, comme RB · B : non, Fantominus et Spectrum seuls (lecture stricte de la décision 4) | **A** (≈ 9 à 10 % des rencontres). Sans le Scope, il reste un SPECTRE : il ne coûte donc rien de visible au J19. Ses données doivent quand même exister (l'espèce réelle est tirée), mais son art peut arriver au J20. **Prévenir la session J20** : Osselait devient capturable chez elle. |
| **K-8** | Règles du combat SPECTRE | A : **RB complet** (§2.3) · B : RB, mais la Ball n'est **pas consommée** (refus avant le lancer) · C : pas de combat : une apparition, puis fuite automatique | **B**. Toutes les règles RB restent (trop effrayé, fuite toujours réussie, aucun dégât, aucune XP, Sac permis), mais on ne perd pas de Ball contre un ennemi intouchable (K26, plus doux). |
| **K-9** | Pokédex et spectre | RB (espèce réelle « vue », bizarrerie) · **rien d'enregistré** | **Rien.** Fantominus et Spectrum sont « vus » par les combats d'Exorcistes, comme le veut la V2 (« sans espèce Pokédex artificielle »). |
| **K-10** | Taux de rencontres | RB : 10 au 3F–5F, 15 au 6F · réduit (par exemple 6 et 10) | **RB** [D], car la décision 4 dit « tables historiques ». La fuite se fait en un geste. À revoir après la QA S24 si c'est pénible. |
| **K-11** | Déclencheur du mode spectre | **Possession de `silph_scope`** (passe J20) · drapeau | **Possession**, conforme au contrat du J20. |
| **K-12** | Le blocage du 6F (décision 5 lue avec le §5 de la V2) | A : **combat SPECTRE scripté** devant l'escalier du 7F, puis repoussé (RB) · B : **scène sans combat** (silhouette, « Va-t'en… Intrus… », puis repoussé) · C : simple PNJ bloquant | **A**. C'est le même système que les sauvages, sans dette ; l'étape « combat sauvage scripté » servira de toute façon au J20. L'adversaire est « SPECTRE », **jamais nommé Ossatueur** au J19. **B** si tu lis la décision 5 comme « aucun combat avant le Scope ». |
| **K-13** | Le 7F au J19 | A : non construit (le warp n'est jamais atteint) · B : construit et vide, pour avancer le J20 | **A**. La carte, les Rocket et Fuji appartiennent au jalon du retour, sans risque de les déclencher trop tôt. |
| **K-14** | Exorcistes : nombre | RB 13 (3F : 3, 4F : 3, 5F : 4, 6F : 3) · A+ : **9** (2 / 2 / 3 / 2), en gardant les 3 inévitables | **9** [D]. Même logique « A+ » que le Mont Sélénite ; leurs équipes de Fantominus et de Spectrum suivent RB. |
| **K-15** | « Fuji s'intéressait à des activités suspectes » (V2, K26) | A : oui, dit par un PNJ (« il avait vu des gens bizarres monter à la Tour ») · B : RB strict (Fuji absent, personne ne sait où) | **A**, en restant flou : ni « Rocket », ni « enlevé ». Compatible avec la ligne du J18 (« il passe ses journées à la Tour ») : maintenant, **il n'en est pas revenu**. |
| **K-16** | Indices vers Céladopole (V2, étape 6) | A : RB (le panneau du Scope Sylphe, puis l'Exorciste du 2F qui le cite) · B : A plus **une** rumeur qui nomme le **Casino de Céladopole** (des hommes en noir) | **B**. RB ne nomme jamais Céladopole ; la V2 le demande sans marqueur. Une rumeur dans le Centre, une ligne, pas de quête. **Il faut que la sortie ouest (Route 8) soit ouverte au moment du J19** : c'est le contrat du J20 sur le J18. |
| **K-17** | Objets de la Tour | A : RB (Corde Sortie, Élixir, Réveil, PV Plus, Pépite, Super Bonbon, Précision +, Élixir caché) · B : **seulement les objets existants**, remplacés sinon | **B** [D] (règle constante depuis le J12). Existent : Corde Sortie, Réveil, Pépite. Le reste est remplacé (Super Potion si le J15 l'a créée, sinon Potion). L'Élixir caché attend le système d'objets cachés (passe J20, H-14). |
| **K-18** | Son (V2 §6) | A : hors J19 ; on note les intentions (pas, silences, thème intérieur feutré) pour le jalon audio · B : premier système audio au J19 | **A**. Aucun son n'existe dans le jeu : en créer un est une décision de projet, pas un détail du J19. |
| **K-19** | Zone purifiée | A : RB (soin complet, illimité, ni rencontre ni Dresseur) · B : un soin par passage, puis une fois par visite | **A**. Rendu : lumière douce et halo blanc [D]. Aucun point de repos : une défaite ramène au Centre de Lavanville. |
| **K-20** | Découpage S24 (la V2 propose 7 lots) | Lots de la V2 · **3 sous-jalons** | **19.0** : grilles 1F à 6F, vues peintes, données (espèces, capacités, Dresseurs), art. **19A** : **mode spectre** (rencontres, combat, combat scripté, repoussé), Exorcistes et Fantominus / Spectrum, testé par départs de débogage. **19B** : étages 2F à 6F, rival n° 5, zone purifiée, blocage du 6F, variantes de Lavanville et indices, puis QA de bout en bout. Deux validations S24. Aucun système ne touche à la forme de la sauvegarde, donc pas de validation isolée. |

## 6. Défauts verrouillables tout de suite [D]

- **Cartes** :
  - `pokemon_tower_2f` à `pokemon_tower_6f`, de **20 × 18 cases, comme RB**. Le rez-de-chaussée
    garde la taille fixée par le J18.
  - Grilles `tools/plans/pokemon_tower_2f.txt` à `6f.txt`, avec `plan_check`.
  - Les escaliers en zigzag de RB.
- **Lumière** :
  - un profil `tower` dans `lighting.json` (gris violacé, doux, lisible) ;
  - des bougies en halos additifs, animées seulement par un battement léger ;
  - une brume en calque lent, coupée par « Réduire les animations ».
  - Aucun « jumpscare » : le SPECTRE apparaît avec le fondu de combat ordinaire.
- **Fonds de combat CB.3** : un seul décor `tour_pokemon` (dalles, stèles, brume), qui sert à tous
  les étages et au spectre.
- **Silhouette du SPECTRE** : **une** planche peinte (forme spectrale, sans espèce lisible). La même
  sert à l'Ossatueur spectre et au J20, qui la dissipe.
- **Espèces au compagnon** : Fantominus et Spectrum ne sont **pas** éligibles au J19 (on ne peut pas
  les capturer). Leurs planches de marche vont au J20.
- **Défaite** contre un Exorciste : réveil au Centre de Lavanville (règle commune).
- **Scène du rival** : déclenchée en entrant au 2F (case devant le passage), avec le motif de
  victoire obligatoire du J13. Grand moment écrit seulement à la victoire, comme le n° 4.

## 7. À fournir par la consolidation (après tes réponses)

- `docs/design/dossier-22-tour-pokemon.md`, avec la structure du dossier 18 :
  - intention et périmètre ;
  - lieux étage par étage ;
  - règles du mode spectre ;
  - rival n° 5 et Exorcistes ;
  - espèces, capacités, objets et assets ;
  - données et sauvegarde ;
  - cas limites ;
  - **lot complet de textes** (Exorcistes possédés, rival, SPECTRE, zone purifiée, PNJ de
    Lavanville, rumeur, panneau) ;
  - valeurs par défaut et décisions verrouillées.
- Les grilles `tools/plans/pokemon_tower_2f.txt` à `6f.txt`, puis les prompts des vues générales
  peintes.
- La **simulation du rival n° 5** dès que les équipes des J16 à J18 sont connues.
- Les **correctifs à reporter** ailleurs :
  - dossier 21 : « Médium » devient « Exorciste », et la ligne de la gardienne (K-2, K-3) ;
  - passe J20 : prévenir qu'Osselait y devient capturable (K-7) et que l'étape « combat sauvage
    scripté » existe déjà (K-12) ;
  - roadmap : la ligne J19 n'est ajoutée qu'avec ton accord, comme pour le J18 (I-26).
- **Le code commence après la clôture du J18** (C-7 : un jalon à la fois dans le moteur de combat et
  dans la sauvegarde).
