# Dossier 08 — Le Menu Dresseur (jalon 6)

> Conçu par Kevin (avec ChatGPT), reçu et consolidé le 2026-10-02, avec les décisions de Kevin du même jour. **Source de vérité** pour le jalon 6 : tableau de bord + 6A Équipe · 6B Sac · 6C Pokédex · 6D Carte · 6E Dresseur · 6F Paramètres.
>
> Les 7 maquettes (§10) donnent **la direction artistique et la composition uniquement**, jamais la vérité fonctionnelle. Si une maquette contredit ce dossier, `vision.md`, la bible UI/UX ou une décision validée, **l'écrit gagne**.
>
> **Pas d'implémentation avant la fin du jalon 5.** Ce dossier sert à supprimer les décisions bloquantes avant d'arriver au J6.

## Philosophie

> « Kanto 2026 n'est pas un remake modernisé de Rouge/Bleu. C'est une réinterprétation : conserver l'ADN qui rend l'expérience Pokémon reconnaissable, supprimer les frictions héritées des anciennes contraintes techniques et repenser chaque interaction comme si elle était conçue aujourd'hui pour une expérience mobile moderne, tactile, fluide, accessible et immersive. » (inscrite dans `vision.md`)

Pour chaque écran, la question n'est pas « comment Pokémon faisait ça ? » mais : **pourquoi Pokémon faisait ça, qu'est-ce qui mérite d'être conservé, et comment le ferait-on mieux aujourd'hui ?**

## Règles transverses du J6

1. **Le Pokémon sélectionné est la vedette** de l'écran. Les menus créent de l'attachement autant qu'ils gèrent des statistiques.
2. **Aucun spoiler, aucun compteur qui révèle du contenu inconnu.** Le jeu se souvient de ce que le joueur a découvert ; il ne dit jamais ce qu'il reste à trouver (pas de « 4/6 », pas de « 8/12 zones », pas de `???` qui signale une espèce manquante dans une zone).
3. **Un système, plusieurs contextes.** Un seul Sac (exploration et combat), une seule Carte (consultation, puis Vol plus tard).
4. **Les six sections communiquent** (liens croisés, §8) : ce ne sont pas six applications séparées.
5. **Une information apparaît là où elle sert à décider.** L'argent : Dresseur, Sac, Boutique. L'heure : jamais avant l'existence réelle du cycle jour/nuit.
6. **Ouverture et fermeture instantanées** : toucher → animation d'environ 200–300 ms → menu ; retour → on retrouve exactement l'exploration. Aucun chargement. Le monde est en pause derrière.
7. **Au pouce.** Le glisser-déposer n'est jamais la seule façon de faire une action ; la couleur n'est jamais la seule information (toujours un texte ou un symbole).
8. **Pas de fonctionnalité annoncée d'avance** : aucun bouton grisé pour un système qui n'existe pas encore (ex. FAIRE SORTIR avant le compagnon).
9. **Rien n'existe « parce que Pokémon l'avait » ni « parce qu'une maquette le montre »** : pas de talents ni de natures chiffrées tant que le jeu ne les utilise pas (dossier 04 §8).
10. **Visuels des Pokémon (V1)** : sprites pixel art fins, agrandis et intégrés proprement à la DA HD. Pas d'illustrations HD des 151 au J6 (à réévaluer pendant la phase DA). Même règle pour le portrait du joueur.
11. **Retours haptiques légers**, jamais agressifs, désactivables (§7).
12. **Format paysage** (2340×1080 sur le S24, référence 1920×1080). Les maquettes en portrait (Dresseur, Paramètres) sont à recomposer.

## 1. Le tableau de bord

- Le bouton Menu ouvre un **tableau de bord plein écran, semi-transparent**, au-dessus du monde flouté et assombri ; le monde est en pause.
- **À gauche, la carte du Dresseur** : nom, « Dresseur Pokémon », portrait, temps de jeu, vus · capturés, badges. En bas, le **Pokémon de tête** (nom, Nv., PV), qui ouvre sa fiche.
- **Six grandes cartes tactiles** : ÉQUIPE · POKÉDEX · SAC · CARTE · DRESSEUR · PARAMÈTRES. Pas davantage au départ.
- **Objectif** : une ligne très discrète (ex. « Objectif : rejoindre Jadielle »). C'est un **rappel narratif** pour le joueur qui reprend sa partie après plusieurs jours, **jamais** un GPS, une flèche permanente ou une checklist. Textes en données, un par étape de l'histoire.
- **Pas de « Sauvegarder »** dans le menu principal : la sauvegarde est automatique et permanente (§7).
- En-tête : fermer (×) et le nom de la zone actuelle. Le retour système Android ferme aussi le menu.

Ce tableau de bord remplace la §7 de la bible UI/UX (cinq entrées et ⚙ dans un coin) : Paramètres devient une sixième carte, l'objectif est conservé.

## 2. 6A — Équipe

**Composition (maquette `menu-equipe-v1.jpg`)** : l'équipe en liste à gauche, le Pokémon sélectionné en grand au centre (la vedette), sa fiche à droite.

- **Liste** : 6 emplacements maximum. Portrait, nom, ♂/♀, Nv., barre de PV avec valeur, **statut toujours en texte** (K.O., PSN, PAR, SOM, BRÛ, GEL). En moins de deux secondes : qui, quel niveau, combien de PV, quel état. Les emplacements vides restent neutres et **sans action** (pas de « Ajouter un Pokémon » : aucun stockage n'existe encore).
- **Réorganiser** : appui long puis glisser-déposer, **et** un mode accessible DÉPLACER (choisir le Pokémon A, puis l'emplacement B). Courte animation d'échange. Le premier de la liste est le Pokémon de tête, envoyé en combat.
- **Grand sprite** du Pokémon sélectionné (environ 35–40 % de l'écran), avec une petite animation de repos (respiration, queue, clignement) ; changer de Pokémon = transition courte.
- **En-tête de fiche** : nom, sexe, Nv., type(s), PV, XP sous forme de barre discrète : « 320 / 560 XP — 240 XP avant le niveau suivant ».
- **Fiche en trois onglets** :
  - **Aperçu** : type(s), sexe, statistiques du Pokémon (PV, Attaque, Défense, Atq. Spé., Déf. Spé., Vitesse) en jauges et valeurs propres, jamais un tableau. Pas de nature ni de talent (règle 9).
  - **Capacités** : 4 au maximum. Nom, type, catégorie (Physique / Spéciale / Statut), PP x/y, puissance. Toucher une capacité ouvre une courte fiche de son effet. « Réorganiser les capacités » viendra plus tard ; l'apprentissage reste lié aux niveaux et aux CT.
  - **Histoire** : rencontré à (lieu), niveau de rencontre, dresseur d'origine, date. Plus tard : premier combat, etc. Données enregistrées dès le jalon 5 (`jalon-05.md` §16).
- **Évolution, sans spoiler** : tant que l'évolution n'est pas découverte, « Évolution : ??? » ; la chaîne se révèle avec le Pokédex (§4). **Jamais la condition** (« évolue au niveau 16 »), contrairement à la maquette.
- **Actions** : UTILISER UN OBJET (ouvre le Sac filtré sur les objets compatibles) · DÉPLACER. Pas de FAIRE SORTIR avant le jalon du compagnon.

## 3. 6B — Sac

- **Une seule source de vérité** : le Sac (`GameState.bag`) est le même en exploration et en combat.
- **Catégories** : SOINS · CAPTURE · COMBAT · AVENTURE · OBJETS CLÉS, plus **FAVORIS**. La catégorie de chaque objet est une donnée (`data/items/items.json`).
- **Composition (maquette `menu-sac-v1.jpg`)** : catégories à gauche, objets en cartes au centre (illustration, nom, quantité), détail à droite (illustration, nom, quantité, description, action). **Un toucher = un aperçu**, sans changer d'écran.
- **Utiliser** : UTILISER → l'équipe s'affiche avec les PV. Un Pokémon incompatible reste visible avec **la raison** (« PV déjà au maximum »), jamais un bouton désactivé sans explication. Après usage : le résultat (« +20 PV — Salamèche 33/51 ») et **UTILISER À NOUVEAU**, sans refaire tout le parcours. Pas de confirmations en cascade.
- **Contextuel** : en combat sauvage, les Poké Balls et les soins sont mis en avant ; depuis la fiche Équipe, le Sac s'ouvre sur SOINS filtré ; en exploration, sur le dernier état. Un objet de combat se consulte hors combat avec la mention « Utilisable en combat ».
- **Favoris** : appui long → ajouter aux favoris ; rangée d'accès rapide en haut.
- **Tri** : pertinence (par défaut, selon le contexte), nom, quantité, récents. **Recherche** : plus tard, quand l'inventaire le justifiera.
- **Objets clés** : impossible de les jeter ou de les vendre.
- **Interdits** : liste interminable, catégories artificielles, plusieurs inventaires, boutons minuscules, information par la couleur seule, quatre confirmations pour une Potion, animations qui ralentissent une action répétitive, friction conservée parce qu'elle est « authentique ».

## 4. 6C — Pokédex

> **Le Pokédex ne te dit pas où trouver les Pokémon. Il se souvient de ce que toi tu as découvert.** C'est ton carnet de terrain, pas Poképédia.

- **Écran principal** : « POKÉDEX — KANTO », « X vus · Y capturés · 151 espèces », filtres TOUS · VUS · CAPTURÉS · HABITATS, grille numérotée.
- **Trois états** :
  - **inconnu** : numéro et `???`, **sans silhouette** ;
  - **vu** : sprite identifiable, nom, habitats observés ;
  - **capturé** : fiche complète (type(s), taille, poids, description, compteurs).
- **Fiche, quatre onglets** :
  - **Aperçu** : grand sprite vivant, numéro, nom, puis à la capture : types, taille, poids, description ; « vu N fois · capturé N fois ». **Pas de statistiques de base, pas de talents** (contrairement à la maquette).
  - **Habitat** : petite carte avec **seulement** les zones où le joueur a observé l'espèce. Une zone non découverte n'apparaît jamais, même en `???`. Toucher une zone ouvre la Carte sur elle.
  - **Évolution** : « Salamèche → ??? → ??? », puis la chaîne se révèle à mesure que le joueur **voit** les espèces suivantes ou fait évoluer son Pokémon. **Jamais de condition** (niveau, objet).
  - **Observations** : petites notes de comportement débloquées par les rencontres, interactions, PNJ ou événements (« On l'aperçoit souvent près des chemins et des zones boisées. »). Textes en données.
- **Mises à jour discrètes** : un toast (« Pokédex mis à jour — Roucool »), un petit son, une petite vibration. Jamais d'interruption. Même chose pour CAPTURÉ, ÉVOLUTION DÉCOUVERTE, NOUVEL HABITAT OBSERVÉ.
- **Recherche** par nom (espèces connues) et filtres simples : type, habitat, vu/capturé. Pas 25 filtres.
- **Observer dans le monde** : voir un Pokémon dans le décor, sans le combattre, peut compter comme une observation (habitat enregistré). Principe validé ; le moment de l'implémenter est une question ouverte (§12).
- **Trois profils servis** : le collectionneur (151/151), l'explorateur (où vivent-ils), le curieux (compléter leurs fiches).
- Décision du 2026-09-29 : le starter du joueur est **capturé**, le Pokémon du rival est **vu**.

## 5. 6D — Carte

> **La Carte ne montre pas ce qu'il reste à découvrir. Elle raconte ce que tu as déjà découvert.** Un journal, pas un guide stratégique.

- **Géographie** : le vrai Kanto du projet (colonne vertébrale du dossier 06, Bourg Palette du dossier 01, Route 1 du dossier 07). **La Route 1 relie Bourg Palette et Jadielle.** Pas d'Îles Sevii tant que la roadmap ne les prévoit pas. La géographie de la maquette `menu-carte-v1.jpg` est fausse (§10) : seule sa DA compte.
- **Vue régionale** : grande carte illustrée et vivante (villes, routes, forêts, grottes, eau, reliefs). La géographie générale est visible, les informations se révèlent avec l'exploration ; pas de brouillard noir. Très peu d'icônes : la carte respire. Position du joueur : un petit portrait discret, pas une flèche GPS.
- **Toucher une zone** → panneau latéral, sans changer d'écran : nom, connexions (« Bourg Palette ↔ Jadielle »), courte description du paysage, **Pokémon observés** (seulement ceux vus, sans total ni `???`), **objets découverts** (seulement ceux trouvés, sans total), services (Centre, Boutique, Arène) **seulement après les avoir découverts**.
- **Liens** : un Pokémon observé ouvre sa fiche Pokédex ; l'onglet Habitat du Pokédex ouvre la Carte.
- **Bouton** : « Voir sur la carte » / informations. **Aucune téléportation.** Quand Vol sera débloqué, la même carte passera en mode VOLER VERS pour les destinations éligibles.
- **Pas de GPS** (aucune ligne à suivre), **pas de mini-carte permanente** en exploration.
- **Plus tard** : recherche et filtres (villes, routes, lieux) quand il y aura assez de lieux ; jour/nuit et météo par zone ; cartes locales (Forêt de Jade, Mont Sélénite, Sylphe SARL) ; « souvenirs de découverte » (date, premier Pokémon rencontré ou capturé dans la zone), classés en polish.

## 6. 6E — Dresseur

> Le résumé vivant de ton aventure : presque vide à Bourg Palette, de plus en plus riche jusqu'à la Ligue.

- **Identité** : nom, « Dresseur Pokémon », portrait (sprite du joueur agrandi en V1) avec une animation très discrète. À côté, l'essentiel : temps de jeu, argent, vus · capturés, badges.
- **Badges, pièce maîtresse** : 8 emplacements. Un badge inconnu ne montre **ni son nom ni son apparence**. Toucher un badge obtenu : nom, ville, arène, champion (« Badge Roche — Argenta — Pierre »). Plus tard, en polish : l'équipe au moment de la victoire.
- **Grands moments** : un journal automatique, avec date et lieu (départ de Bourg Palette, premier Pokémon, première capture, arrivée à Jadielle, badges…). Aucun texte à rédiger par le joueur. Données enregistrées dès le jalon 5.
- **Statistiques** : une section secondaire, pour ceux qui aiment ça. En V1, seulement ce que le jeu enregistre déjà.
- **Après la Ligue** : « MAÎTRE DE LA LIGUE », date de la victoire, équipe victorieuse ; l'écran parle de lui-même, sans grand « FÉLICITATIONS ».
- **Exclus du J6** (même si la maquette les montre) : niveau et XP de Dresseur, tenues et apparence, titres, pourcentage d'histoire, biographie modifiable. La personnalisation pourra être conçue dans un jalon dédié si elle apporte vraiment quelque chose.

## 7. 6F — Paramètres

Cinq catégories, **d'après ce dossier et non la maquette** :

- **JEU** : vitesse du texte (Lente · Normale · Rapide · Instantanée) ; confirmation de certaines actions (ex. remplacer une capacité) ; **Sauvegarder maintenant** (une sécurité en plus). **La sauvegarde automatique est permanente et ne peut pas être désactivée.**
- **AUDIO** : musique, effets sonores ; son en arrière-plan désactivé par défaut.
- **COMMANDES** : taille et opacité du joystick, taille des boutons, retour haptique, **mode gaucher** (joystick à droite, actions à gauche).
- **ACCESSIBILITÉ** : taille du texte, contraste renforcé, **réduction des animations** (raccourcit les transitions, les animations répétitives de combat et certains effets du menu ; dossier 05 §21, `BattleDirector.speed_scale`), réduction des flashs. L'information n'est jamais transmise par la couleur seule (règle 7).
- **GRAPHISMES** : Auto · Élevée · Économie. Le joueur choisit une intention, le moteur choisit les détails.

**Exclus tant que les systèmes n'existent pas** : difficulté, caméra libre, axe Y, manette, HDR, voix, langue, compte, cloud, sauvegardes multiples (restaurer, supprimer).

## 8. Liens entre les écrans

| Depuis | Toucher | Ouvre |
|---|---|---|
| Tableau de bord | Pokémon de tête | 6A, fiche de ce Pokémon |
| 6A Équipe | UTILISER UN OBJET | 6B Sac, SOINS filtré sur les objets compatibles |
| 6B Sac | UTILISER | choix du Pokémon (équipe et PV) |
| 6C Pokédex | une zone de l'onglet Habitat | 6D Carte, centrée sur la zone |
| 6D Carte | un Pokémon observé | 6C, fiche de l'espèce |
| 6E Dresseur | « vus » / « capturés » | 6C, filtré (vus / capturés) |
| 6E Dresseur | un badge obtenu | détail du badge |
| 6E Dresseur | « premier Pokémon » | 6A s'il est dans l'équipe, sinon 6C |

## 9. Données nécessaires

Règle « données avant interface » (`roadmap.md`) : les faits dont le J6 a besoin sont **enregistrés dès le jalon 5** dans la sauvegarde (`jalon-05.md` §16) ; le J6 n'est qu'une interface sur des données déjà collectées.

| Écran | Données | Enregistrées depuis |
|---|---|---|
| 6A Histoire | lieu, niveau et date de rencontre, dresseur d'origine | J5 (5C.5) |
| 6C Pokédex | vu / capturé, premières observation et capture (lieu, date), lieux vus, compteurs | J5 (vu / capturé : 5B ; le reste : 5C.5) |
| 6C Évolution | se déduit des espèces vues et des évolutions du joueur | rien à stocker en plus |
| 6C Observations | notes débloquées | à ajouter au J6 (le format de sauvegarde le permet) |
| 6D Carte | zones découvertes (date), objets trouvés par zone | J5 (5C.5) |
| 6E Dresseur | temps de jeu, date de départ, grands moments | J5 (5C.5) |
| 6E Dresseur | argent | J7 (économie) |
| 6E Dresseur | badges | J10 (Argenta) |
| Tableau de bord | texte d'objectif selon l'étape de l'histoire | données, J6 |

## 10. Maquettes de référence (direction artistique uniquement)

Fichiers dans `reference/`. Ce qu'on garde : la composition, la lumière, les panneaux sombres translucides sur le monde flouté, les grandes cartes tactiles, la place donnée au Pokémon. Ce qui ne compte pas, écran par écran :

| Fichier | On garde | Ne fait pas foi |
|---|---|---|
| `menu-tableau-de-bord-v1.jpg` | carte du Dresseur à gauche, Pokémon de tête, 6 grandes cartes | argent et heure dans l'en-tête ; il manque la ligne d'objectif (§1) |
| `menu-equipe-v1.jpg` | liste à gauche, Pokémon vedette au centre, fiche à droite, onglets, barre d'XP | « Salamèche N. 16 » dans l'évolution (spoiler) ; « Ajouter un Pokémon » ; « Marquer favori » ; taille, poids et description (relèvent du Pokédex) ; heure et argent |
| `menu-sac-v1.jpg` | catégories, grille de cartes, panneau de détail, « Utiliser sur… » avec PV, Favoris | l'heure ; les objets et quantités montrés sont illustratifs |
| `menu-pokedex-v1.jpg` | grande présentation du Pokémon, onglets, habitat en carte, filtres | statistiques de base, talents, chaîne d'évolution complète avec niveaux, silhouettes d'espèces inconnues, « 27/151 » en tête, heure et argent ; faute « Salaméche » |
| `menu-carte-v1.jpg` | grande carte illustrée, panneau de zone, miniatures des lieux découverts | **géographie fausse** (Route 1 « relie Jadielle à Carmin-sur-Mer », Bourg Palette absent, volcan « Reboutefeu », « Mont Sélénium ») ; onglet Îles Sevii ; « 4 / 6 » et `???` ; « 8 / 12 zones » ; « Se rendre ici » ; heure et argent |
| `menu-dresseur-v1.jpg` | portrait, badges inconnus masqués, frise des grands moments | **format portrait** ; niveau et XP de Dresseur ; tenues ; titres ; « Histoire principale 12 % » ; biographie ; Pikachu, Carapuce et Bulbizarre dans l'équipe (illustratif) |
| `menu-parametres-v1.jpg` | panneaux sombres, interrupteurs et curseurs, catégories à gauche | **format portrait** ; presque tout le contenu (voir §7) : autosave désactivable, caméra, axe Y, manette, HDR, voix, cloud, compte, difficulté, langue, sauvegardes multiples ; il manque le mode gaucher et le réglage du joystick |

## 11. Ordre d'implémentation (au J6, pas avant)

Fondations et navigation → tableau de bord → 6A → 6B → 6C → 6D → 6E → 6F. **Jamais les six écrans en même temps.** Validation S24 par sous-jalon (`CLAUDE.md`, règle 1).

## 12. Questions ouvertes (valeur par défaut appliquée si Kevin ne dit rien)

1. **Observer un Pokémon dans le décor** compte-t-il comme « vu » ? *Défaut* : oui, mis en place avec l'écran Pokédex au J6 (pas au J5).
2. **Textes à produire par Kevin** : les objectifs par étape de l'histoire, les descriptions courtes des zones pour la Carte, les notes d'Observations par espèce. *Défaut* : textes provisoires marqués comme tels.
3. **Nom du joueur** : le jeu n'a pas encore d'écran de nom. *Défaut* : « Kevin », modifiable plus tard.
4. **Argent sur le tableau de bord** : *défaut* : non (Dresseur, Sac et Boutique seulement).
5. **Marquer un Pokémon favori** (maquette Équipe) : *défaut* : absent.

## Décisions verrouillées

Tableau de bord plein écran au-dessus du monde, six cartes, objectif discret · Équipe : liste + Pokémon vedette + fiche Aperçu / Capacités / Histoire, 6 maximum, réorganisation tactile avec alternative · Sac unique et contextuel, cinq catégories + favoris · Pokédex carnet de terrain, trois états, aucun spoiler · Carte = journal du vrai Kanto, aucune checklist, aucun GPS, Vol plus tard sur la même carte · Dresseur = résumé de l'aventure, sans niveau, tenues ni titres · Paramètres simples, autosave permanent, mode gaucher, accessibilité intégrée · Sprites pixel art agrandis en V1 · Les maquettes ne font jamais foi sur le fonctionnel.
