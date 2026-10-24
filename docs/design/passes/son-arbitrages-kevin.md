# Jalon « Son » — arbitrages pour Kevin

> **VALIDÉ PAR KEVIN le 2026-10-24 : SON-1 à SON-17, toutes les recommandations.**
>
> Claude, 2026-10-24. **Documentation seule : aucune ligne de code,
> aucun fichier son téléchargé.**
> Prépare le plan `docs/tech/jalon-son.md` (moteur §1, table des morceaux §2, bruitages §3,
> découpage §4). Décisions déjà prises, non rouvertes : **musiques = bande-son de Let's Go
> Pikachu / Évoli** ; jeu privé, cercle restreint, jamais public ; cris via PokeAPI.
>
> Faits : `pret/pokered` `data/maps/songs.asm` (musique de chaque carte RB) ; album officiel Let's
> Go « Super Music Collection » (67 pistes Let's Go, liste MusicBrainz) ; dépôt `PokeAPI/cries`
> (tailles lues sur la liste du dépôt, rien téléchargé). Origine : **RB** Rouge/Bleu · **LG**
> Let's Go · **K26** adaptation · **[D]** défaut (règle 4).
>
> Arbitrages numérotés **SON-1 à SON-17**. Réponds par numéro (« tout ok », ou « 5 : B, 13 : non »).

## 0. Ce que l'audit change à la question

1. **Le jeu est bien muet** : `assets/audio/` ne contient que `.gitkeep`, aucun lecteur audio dans
   `game/`, `game/systems/audio/` vide. Mais les accroches existent (`GameMap.music`,
   `cry_requested`, signaux de combat, `BattleEvent`, cycle Android de la sauvegarde) : le moteur
   peut se coder **sans un seul fichier son**, en parallèle des J23 et J26–J31, sans conflit.
2. **Let's Go couvre presque tout, mais pas tout.** Les 67 pistes de l'album donnent un morceau à
   chaque carte de RB ; il manque le **Vélo** et le **Parc Safari** (absents de Let's Go), la
   **victoire contre un sauvage**, et aucun thème propre aux **légendaires** ou au **rival** avant la
   Ligue (RB n'en avait pas non plus). Le jeu complet en contient peut-être plus que l'album :
   seule l'écoute le dira (tâche T1).
3. **RB partage beaucoup ses thèmes** (Jadielle = Argenta = Safrania ; Azuria = Parmanie ; Centres =
   Boutiques) et a quatre « bizarreries » (une maison de Carmin qui joue le thème d'Azuria…). Il faut
   une règle (SON-4, SON-9).

## 1. Arbitrages

- **SON-1 — Cris : `latest` ou `legacy`.** `latest` = cris modernes (X/Y et après, ceux de Let's
  Go) : 151 fichiers OGG, **2,05 Mo** ; `legacy` = anciens cris : **0,92 Mo**. Et accord pour
  télécharger ces 151 fichiers depuis `raw.githubusercontent.com/PokeAPI/cries` (dossier
  `cries/pokemon/latest/`, fichiers `1.ogg` à `151.ogg`) au moment de SonB ?
  *Recommandation : `latest` (cohérent avec la musique Let's Go), et oui au téléchargement au
  moment de SonB.*

- **SON-2 — Source des bruitages.** A : bibliothèques **CC0** (Kenney pour l'interface, les pas et
  les coups ; Freesound filtré CC0 pour les ambiances) ; B : extraction depuis ton Let's Go (sons
  « Pokémon » reconnaissables), si tu as l'outillage ; C : A, plus une douzaine de sons signature
  extraits de Let's Go (Ball, PC, coup critique, porte) ; D : génération IA.
  *Recommandation : C, ou A seule si l'extraction n'est pas simple pour toi. Chaque lot te sera
  présenté avant téléchargement (fichiers, source, taille).*

- **SON-3 — Obtenir les morceaux.** A : **album numérique officiel** acheté par toi (67 pistes
  Let's Go ; pistes d'album à deux tours avec fondu, qu'on coupe une fois à leur boucle sur le Mac) ;
  B : extraction depuis ta cartouche (boucles exactes, morceaux absents de l'album) ; C : A, puis B
  seulement pour les trous si T1 en trouve dans le jeu.
  *Recommandation : C.* (Je ne peux ni acheter ni extraire : c'est ton action ; je prépare la liste
  exacte des 52 pistes utiles et la procédure de découpe.)
  **Révisé par Kevin le 2026-10-25** : « je prendrai toutes les bandes son de let's go sur
  KHInsider » — Kevin télécharge l'album dans `~/Music/kanto-lets-go/` (FLAC ou meilleur MP3, noms
  d'origine) ; Claude ne télécharge rien (`jalon-son.md` §5 bis).

- **SON-4 — Règle d'attribution.** Chaque carte reçoit **le thème que RB lui donne**, dans son
  arrangement Let's Go (Jadielle, Argenta et Safrania partagent donc un morceau). Ou un morceau
  distinct par ville quand Let's Go en a un ? (Il n'en a pas plus que RB.)
  *Recommandation : la règle RB (table au §2 du plan).*

- **SON-5 — Vélo et Parc Safari, absents de Let's Go.** Vélo : A garder la musique de la route ;
  B « Pokémon Road » si l'écoute montre que c'est la musique de monture de Let's Go ; C le thème
  « Cycling » de Jaune (même album, disque Jaune, son Game Boy). Parc Safari : A « **GO Park** »
  (le lieu qui remplace le Safari dans Let's Go, à Parmanie) ; B le thème de Parmanie ; C le thème
  Safari de Jaune.
  *Recommandation : Vélo B, sinon A ; Safari A.* (Le son Game Boy de Jaune jurerait avec le reste.)

- **SON-6 — Reprise après un combat.** La musique de la zone reprend **là où elle s'était
  arrêtée** (comme après le jingle du Centre), ou repart du début comme RB ?
  *Recommandation : là où elle s'était arrêtée, avec un fondu d'1 s.*

- **SON-7 — Curseurs des Paramètres.** Nouvelle catégorie **SON** : trois curseurs **Musique**,
  **Effets** (interface, déplacement, combat, ambiances), **Cris**, de 0 à 100 par crans de 10,
  défauts **70 / 80 / 80** ; enregistrés dans les réglages de l'appareil (pas dans la partie).
  Ou un seul curseur général ; ou quatre (Ambiance à part) ?
  *Recommandation : trois curseurs, défauts 70 / 80 / 80.*

- **SON-8 — Format et poids.** OGG Vorbis partout ; musique en stéréo **≈ 112 kb/s** (qualité q3),
  normalisée au même volume perçu ; bruitages et cris en mono. Ajout estimé à l'APK : **≈ 70 à
  100 Mo** (il fait ≈ 262 Mo aujourd'hui). Ou qualité plus haute (≈ 160 kb/s, ≈ 100 à 140 Mo) ?
  *Recommandation : 112 kb/s ; on remonte un morceau précis si tu entends une différence sur le S24.*

- **SON-9 — Intérieurs.** Un intérieur prend la musique de **sa ville** (sauf Centres, Boutiques,
  Arènes, Labo de Chen et lieux à thème : Tour, Manoir, Sylphe, Casino, repaire, S.S. Anne). Les
  quatre bizarreries RB (poste ouest de la Route 22 en thème de forêt, maison du pêcheur de Carmin en
  thème d'Azuria, maisons des Routes 12 et 16 en thème de Céladopole) sont ramenées à la règle. Ou
  tout copier de RB, bizarreries comprises ?
  *Recommandation : la règle (une ville = un son, vision principe 6).*

- **SON-10 — Tour Pokémon.** RB joue le même thème du 1F au 7F, même après la délivrance. K26 a
  une **zone purifiée** (J19) et la délivrance par Fuji (J21, « thème de la Tour qui s'éclaircit »
  noté au jalon audio). A : thème de la Tour partout (RB) ; B : thème atténué dans la zone purifiée,
  puis, une fois la Tour délivrée, **Lavender Town Theme** dans la Tour ; C : silence et ambiance
  dans la zone purifiée.
  *Recommandation : B.*

- **SON-11 — Sons d'attaque.** Par **familles** (≈ 20 : type × physique / spécial, plus soin,
  statut, explosion), avec des exceptions possibles par attaque dans les données ; ou un son par
  attaque (≈ 165, beaucoup plus long à produire) ?
  *Recommandation : familles.*

- **SON-12 — Cri au Pokédex.** Bouton « Cri » sur la fiche des espèces **capturées** seulement
  (RB), ou aussi des espèces **vues** ?
  *Recommandation : capturées seulement (RB).*

- **SON-13 — Légendaires et Mewtwo.** RB leur donne la musique des combats sauvages. A : la même
  (**Battle! (Wild Pokémon)**) ; B : un thème plus fort si l'écoute du jeu Let's Go en trouve un
  (T1) ; C : « Battle! (Gym Leader Battle) ».
  *Recommandation : B si T1 trouve un thème, sinon A.*

- **SON-14 — Victoire contre un sauvage.** Absente de l'album Let's Go (RB a un petit jingle).
  A : **Victory! (Trainer Battle)** raccourci (fondu à ~4 s) ; B : pas de jingle, la musique de la
  zone revient directement ; C : un jingle du jeu si T1 en trouve un.
  *Recommandation : C si trouvé, sinon A.*

- **SON-15 — Musique pendant les menus.** Le Menu Dresseur, le Sac, le Pokédex, la Carte et les
  Paramètres gardent la musique de la zone **à plein volume** (RB) ; ou atténuée ; ou un thème de
  menu ?
  *Recommandation : à plein volume, atténuée seulement pendant un cri du Pokédex.*

- **SON-16 — Place dans le calendrier.** Son.0 (moteur sans fichier son) **tout de suite**, en
  parallèle des jalons ouverts ; **SonA (musique) et SonB (cris) dans `main` avant l'ouverture du
  J33** (gel fonctionnel) ; les lots de fichiers (bruitages, ambiances, remplacement d'un morceau)
  continuent comme l'art jusqu'au **gel de l'entrée du J34**. Le Son occupe une des 2 à 3 places de
  jalons en code.
  *Recommandation : oui.*

- **SON-17 — Alarme de PV bas.** RB bipe sans arrêt quand ton Pokémon est dans le rouge. A : comme
  RB ; B : trois bips à l'entrée dans le rouge, puis plus rien ; C : aucune alarme (la barre rouge
  suffit).
  *Recommandation : B.*

## 2. Valeurs par défaut posées sans débat [D]

Fondu enchaîné entre deux morceaux 0,6 s ; musique atténuée de 6 dB pendant un cri de combat ;
même morceau entre deux cartes → aucune coupure ; ambiance 18 dB sous la musique, rien dans les
intérieurs ; arrière-plan Android → son coupé, retour en fondu de 0,5 s ; bandeau d'appel →
musique atténuée de 20 dB ; cri de K.O. ralenti (0,8) ; première capture → « Caught a Pokémon! »
complet, les suivantes → version courte ; Grand moment → pas de morceau propre, musique atténuée ;
écran de démarrage → silence ; un cran du curseur Cris joue le cri de Pikachu.
