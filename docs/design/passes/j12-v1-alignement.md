# J12 — Route 3 et Mont Sélénite : passe d'alignement de la V1 (ChatGPT)

> Claude, 2026-10-10. Relu contre `vision.md`, `roadmap.md`, dossiers 04, 05, 06, 10, 12, le
> dossier 13 (J11, branche `claude/lancement-j11-4pkt2k`, arbitrages en attente) et le code de
> `main` (`e80f636`, J10 terminé). Aucune ligne de code avant le dossier 14 validé.
> Les arbitrages **B-1 à B-14** complètent les 9 de la V1 ; à répondre par numéro, puis à
> transmettre à ChatGPT avec la V1 pour la consolidation.

## 1. Les 9 arbitrages de la V1

D'accord avec les **9 présélections**. Réserves :

| # | V1 | Avis |
|---|---|---|
| 1 | Route 3 + Mont Sélénite + sortie Route 4 | Oui. |
| 2 | 3 niveaux | Oui ; les grilles (68 × 54, 44 × 36, 56 × 42) seront recalées sur le plan fonctionnel. 1F est la plus grande carte du jeu après la forêt (70 × 90). |
| 3 | Lisible, sans mini-carte | Oui (vision, dossier 08). |
| 4 | Rocket progressive et inquiétante | Oui, mais c'est **la** décision de la roadmap (« non décidé, à demander à Kevin ») : ta réponse la verrouille. Précisions en B-7. |
| 5 | 3 combats Rocket dont un final | Oui (Rouge/Bleu : 4). |
| 6 | Un seul fossile | Oui (Rouge/Bleu). |
| 7 | Combat du chercheur | Oui (Rouge/Bleu : le Super Nerd garde le passage vers la sortie). |
| 8 | Mélofée rare | Oui (« rare mais trouvable », ≈ 5 % dans les galeries profondes). |
| 9 | Sas Route 4, Azuria plus tard | Oui, raccord « AZURIA — À venir » comme les jalons précédents. |

## 2. Ce que la V1 oublie ou contredit

1. **Pierre Lune absente.** Le dossier 13 (A-5, recommandé) reporte les évolutions par pierre au
   J12 « avec la Pierre Lune au Mont Sélénite » ; le Musée d'Argenta l'expose déjà (« Une roche rare
   trouvée près du Mont Sélénite »). Nidorina et Nidorino attendent cette pierre depuis le J9.
   → Il faut sa source, le parcours Sac → pierre → Pokémon, et **les espèces qu'elle fait naître**
   (Mélodelfe, Grodoudou ; Nidoqueen / Nidoking existent déjà).
2. **Rencontres en grotte = mécanique nouvelle.** Aujourd'hui les rencontres n'ont lieu **que dans
   les hautes herbes** (`EncounterDirector`), avec l'intro « bruit dans l'herbe » (dossier 04). La
   V1 veut une fréquence « pas pénible » sans dire où elles ont lieu.
3. **Corde Sortie / Repousse absentes.** Le dossier 12 les liste « plus tard » ; un premier donjon
   est leur place naturelle (règle « l'objet arrive avec la mécanique »).
4. **Le J12 dépend du J11 en dur.** Capacités des nouvelles espèces : Ultrason (confusion),
   Para-Spore, Spore et Berceuse (sommeil), Purédpois (poison) = statuts du J11 ; **Vampirisme**
   (attaque qui draine) et **Ligotage** (piège) n'existent pas dans le moteur ; Spore, Berceuse,
   Écras'Face, Purédpois, Vampirisme, Ligotage ne sont pas dans les données. → Code du J12
   **après la fusion de 11A** (statuts) au minimum.
5. **Coût en espèces sous-estimé.** Règle implicite du projet : une espèce capturable doit avoir
   son évolution disponible dès qu'elle est atteignable (niveau ou objet présent). Le pool de la
   V1 implique **11 espèces nouvelles** : Rondoudou, Grodoudou (Pierre Lune), Nosferapti,
   Nosferalto (N22), Paras, Parasect (N24), Mélofée, Mélodelfe (Pierre Lune) ; Abo, Voltorbe,
   Smogo si limités aux Dresseurs (pas d'évolution à fournir). Chacune = données, Pokédex,
   artwork de face, **dos peint**, et planche de marche si elle vit dans le décor ou sert de
   compagnon (J11).
6. **Route 3 sans découverte.** Roucool, Piafabec, Rattata, Nidoran : tous déjà rencontrés.
   Rouge/Bleu : Piafabec, Rondoudou, **Sabelette** (Rouge) / **Abo** (Bleu). Sabelette existe déjà
   dans les données (seulement chez Pierre, jamais sauvage).
7. **« Passage de sortie débloqué »** : la V1 ne dit pas ce qui le bloque. Dans Rouge/Bleu c'est
   le chercheur qui garde l'échelle de sortie. À écrire noir sur blanc : quels combats sont
   **inévitables** (comme Théo et Milo dans la forêt).
8. **Objets cachés = système nouveau** : rien dans le code.
9. **Compagnon (J11) dans la grotte** : le dossier 13 le fait rentrer dans sa Ball dans toute
   « carte d'intérieur ». Une grotte en est-elle une ?
10. **Rival** : absent de la V1, conforme à Rouge/Bleu (combat n° 3 = Azuria / Pont Pépite). À
    verrouiller pour que la consolidation n'en ajoute pas.
11. **Vendeur de Magicarpe** (Centre du Mont Sélénite, Rouge/Bleu) : non mentionné.
12. **Images de la V1** (Pokéarth, fan art, carte TCG) : ambiance seulement, **à ne pas mettre
    dans le dépôt** (droits). La production suit la filière habituelle : vue générale peinte +
    grille `tools/plans/*.txt` validées par toi, avant toute carte.
13. **Découpage « agents en parallèle »** : compatible, mais la règle 1 (une session S24 par
    sous-jalon, jamais trois systèmes à la fois) impose un ordre de validation (B-14).

## 3. Coûts techniques à connaître (pas des décisions)

- **Lumière de grotte** : rendu `mobile` ; préférer la lumière **peinte** dans le décor + quelques
  sources légères plutôt que beaucoup de `PointLight2D`. Pas de cycle jour/nuit dedans (comme les
  intérieurs).
- **Budgets** : ≤ 3 000 nœuds par carte (forêt : 2 983) ; mémoire = carte + voisines (J10). Trois
  étages + Centre + Route 3 voisins : à mesurer dès la grille.
- **Échelles** : nouveau type de passage entre cartes (fondu, comme une porte) ; peu coûteux.
- **Décors de combat** (CB.3) : 2 à 3 nouveaux décors peints (Route 3, grotte, chambre des fossiles).
- **Personnages peints** : Sbire Rocket (au moins un modèle, idéalement H/F), chercheur, Dresseurs
  de la Route 3 (réutiliser les modèles existants autant que possible).
- **Sauvegarde** : a priori **pas de nouvelle version** (drapeaux, Dresseurs battus, objets clés
  existent) ; à confirmer quand le J11 aura fixé la v5. Les objets cachés ajoutent une liste.

## 4. Arbitrages à trancher (B-1 à B-14)

| # | Question | Recommandation |
|---|---|---|
| **B-1** | Pierre Lune au J12 ? | **Oui** : 1 visible dans la grotte + 1 cachée (Rouge/Bleu en a deux) ; pas en vente. Parcours Sac → pierre → Pokémon compatible (prévu au J11, reporté ici). |
| **B-2** | Grodoudou et Mélodelfe dans le J12 ? | **Oui** (sinon la Pierre Lune est une impasse pour Rondoudou / Mélofée). Données + artwork + dos ; pas de planche de marche tant qu'ils ne vivent pas dans le décor. |
| **B-3** | Où ont lieu les rencontres dans la grotte ? | **Zones de rencontre lisibles** (sol de gravats / galeries plus sombres) et couloirs calmes, plutôt que partout comme Rouge/Bleu. Le joueur choisit son risque comme avec les herbes. Intro : pierres qui roulent / ombre qui passe, ≤ 2 s (dossier 04). *Invention Kanto 2026.* |
| **B-4** | Corde Sortie et Repousse ? | **Corde Sortie oui** (Boutique d'Argenta + 1 dans la grotte ; ramène au **dernier Centre utilisé**, comme Rouge/Bleu — ici celui du pied de la montagne). **Repousse plus tard** (les zones de B-3 suffisent). |
| **B-5** | Espèces sauvages de la Route 3 ? | **Piafabec, Rondoudou, Sabelette, Abo** (+ Rattata en remplissage). Abo sauvage → **Arbok** à fournir (N22). Alternative moins chère : Sabelette seul (déjà fait), Abo réservé aux Rocket. |
| **B-6** | Espèces du chercheur | **Voltorbe, Smogo** (Dresseur seulement, pas d'évolution à fournir). Tadmorv (Rouge/Bleu) écarté : Entrave = mécanique nouvelle. |
| **B-7** | Team Rocket : précisions | Nom « Team Rocket » **prononcé** au Mont Sélénite (oui, comme Rouge/Bleu) ; « R » rouge sur noir, tenue modernisée peinte ; ils cherchent **les fossiles** (lien avec la phrase des collectionneurs du Musée) ; aucun chef nommé ; après le J12, la grotte reste **sans Rocket** une fois l'événement résolu (vaincus = partis, à la place de Rouge/Bleu où ils restent plantés). |
| **B-8** | Combats inévitables | **Rocket final + chercheur** inévitables ; les 2 autres Rocket évitables ou non selon le plan. Route 3 : **2 inévitables** sur 6 (« aucun combat contournable par un bug » de la V1 = règle de grille, vérifiée par `plan_check.py`). |
| **B-9** | Ordre de la fin | **Rocket final, puis le chercheur**, qui te prend d'abord pour un Rocket : sa méfiance est justifiée par la scène qui précède, pas gratuite. |
| **B-10** | Objets cachés | **Oui, version simple** : interagir face à une case discrètement marquée par le décor (éclat, caillou différent), aucun indicateur d'interface. 1 sur la Route 3, 1–2 dans la grotte. *Mécanique nouvelle.* |
| **B-11** | Compagnon (J11) dans la grotte | **Il suit** (la grotte est un extérieur au sens du compagnon) ; il rentre seulement dans le Centre. Profils « massif » : règles du J11. |
| **B-12** | Rival au J12 | **Absent** (Rouge/Bleu ; combat n° 3 à Azuria au J13). Pas d'allusion non plus : Pierre en a déjà fait une après le badge (dossier 12, arbitrage 19), une deuxième affaiblirait la rencontre d'Azuria. |
| **B-13** | Vendeur de Magicarpe | **Pas au J12** : Magicarpe arrive avec la pêche / l'eau (Azuria et après). |
| **B-14** | Ordre de validation sur S24 | **12.0** kit d'art + données (espèces, capacités, drain, piège si retenu) · **12A** Route 3 + Centre · **12B** grotte (3 étages, échelles, rencontres de grotte, lumière) · **12C** Rocket, chercheur, fossiles, Pierre Lune · **12D** sas Route 4, clôture. Code après la fusion de **11A**. |

## 5. Ce qui est verrouillable tel quel

Première apparition de la Team Rocket au Mont Sélénite et aucune avant ; ni Giovanni, ni Mewtwo,
ni chef inventé ; aucun puzzle à capacité d'exploration (pas de Flash) ; pas de mini-carte / GPS /
flèche ; grotte sombre mais lisible ; décor de combat peint par zone (CB.3) ; Centre au pied de la
montagne = point de retour ; fossile = objet clé, résurrection bien plus tard, Amonita et Kabuto
non implémentés ; pas de quête secondaire sur la Route 3 ; niveaux (sauvages 7–13, Dresseurs
9–16) dans l'esprit de Rouge/Bleu.

## 6. À fournir par la consolidation (dossier 14)

Textes définitifs regroupés et numérotés (Rocket, chercheur, Dresseurs, panneaux, objets, Corde
Sortie, Pierre Lune, objectifs du tableau de bord après Argenta → « continuer vers la Route 3. »
déjà en place), équipes exactes et capacités (en signalant toute mécanique absente du moteur),
tables de rencontres, liste des drapeaux, plan fonctionnel ASCII de chaque carte, cas limites
(défaite dans la grotte, Corde Sortie pendant l'événement, partie quittée entre deux combats
Rocket, fossile choisi puis inventaire plein, etc.).
