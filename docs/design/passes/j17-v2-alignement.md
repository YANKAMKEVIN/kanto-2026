# J17 — Les chemins retrouvés : passe d'alignement de la V2 (ChatGPT)

> Claude, 2026-10-14. Relu contre `vision.md`, `roadmap.md`, la bible UI/UX, les dossiers 06, 11, 12,
> 14 (J11), 15 (J12), 18 (J15, branche `jalon-15`), la passe du J16 (`j16-v2-alignement.md`, branche
> `ccr-fa255d49-wvvacc`) et le code de `main` (`267fcf1`, J11 terminé), `jalon-12`, `jalon-14` et
> `jalon-15`. Faits Rouge/Bleu vérifiés sur le désassemblage `pret/pokered` (objets des cartes,
> raccords, équipes des Dresseurs, script de l'assistant) et les CSV de PokeAPI (rencontres `red` /
> `blue`). Conception seulement : aucune ligne de code.
> Les 6 décisions de la V2 sont reprises ; les miennes sont numérotées **H-1 à H-17** (B à G et V
> sont prises). À répondre par numéro, puis à transmettre à ChatGPT pour la consolidation.
> **Numéro de dossier** : 16 (J13), 17 (J14) et 18 (J15) sont pris ; le **19** est réservé au J16
> (passe du J15). Le J17 prend le **20** (`dossier-20-chemins-retrouves.md`, branche
> `docs/dossier-20-j17`) [D, à confirmer au moment du push].

## 0. Hypothèses d'entrée (J12 à J16 en parallèle)

Le J17 reçoit, sans les attendre pour concevoir :

| Reçu de | Attendu | État vérifié le 2026-10-14 |
|---|---|---|
| J15 | Carmin, bord est « ROUTE 11 — À venir » (63, 11..13), arrivée `from_route_11` réservée | Conforme (`tools/plans/vermilion_city.txt:10, 95-96`, branche `jalon-15`) |
| J16 | CS01, Coupe dans le monde (modèle hybride G-2), arbustes **définitifs** (G-4), fonction pure du type `FieldMoves.can_cut`, cases **rendues franchissables par un drapeau** | Conçu, pas codé. **Aujourd'hui, aucune case bloquée ne peut être libérée par un drapeau** (grille statique, `map.gd:283-290`) : c'est le J16 qui crée ce mécanisme ; le J17 le réutilise tel quel |
| J12 | Kit de grotte : terrain `rubble`, profils `cave_*`, voile de pénombre précalculé, `LightGlow` | Fait (branche `jalon-12`), pas encore dans `main` |
| J10 / J11 | `badge_boulder` ; CT réutilisables (`TmTeach`) | Dans `main` |

Résidu à signaler à la session du J15 (pas une décision du J17) : `vermilion_city.txt:17` dit encore
« futur J17 : Coupe » pour l'arbre de l'Arène ; depuis G-1 / G-5, c'est le **J16** qui le coupe.

## 1. Les 6 décisions de la V2

| # | V2 | Avis |
|---|---|---|
| 1 | Route 11 + Cave Taupiqueur + Route 2 revisitée | Oui. Mais la Route 2 « revisitée » demande **une carte neuve** (H-3) : la géographie existante s'arrête aux trois accès fermés. |
| 2 | Cave courte et naturelle | Oui. Rouge/Bleu : grotte en diagonale, sans Dresseur ni objet visible. Le kit de grotte du J12 suffit (pas de Flash). |
| 3 | Raccourcis et découvertes par Coupe | Oui, avec une **réserve sur la place de Coupe** (H-2). |
| 4 | CS05 après 10 espèces possédées | Oui. Rouge/Bleu à l'identique. Le compteur existe déjà (H-8). |
| 5 | Route 11 complète, Ronflex à l'est | Oui. Rouge/Bleu : Ronflex dort sur la Route 12, **exactement au débouché de la Route 11**. Le placer au bout de la Route 11 est fidèle dans les faits (H-10). |
| 6 | Grotte Sombre au J18 | Oui. **Nom** : dans Kanto, c'est le **Tunnel Roche** ; « Grotte Sombre » est la grotte de Johto. À trancher par la session du J18 ; le J17 n'emploie que « grottes obscures ». |

## 2. Faits Rouge/Bleu utiles

| Sujet | Rouge/Bleu |
|---|---|
| Route 11, herbes | Abo (R) / Sabelette (B) 40 % Nv. 12–15 · Piafabec 35 % Nv. 13–17 · Soporifik 25 % Nv. 9–15 |
| Cave Taupiqueur | Taupiqueur 95 % Nv. 15–22 · **Triopikeur 5 % Nv. 29–31** |
| Route 11, Dresseurs | **10** : 4 Joueurs (Ptitard + Hypotrempe 18 ; Chétiflor + Mystherbe 18 ; Voltorbe + Magnéti 18 ; Caninos + Goupix 18), 4 Gamins (Abo 21 ; Sabelette + Nosferapti 19 ; Rattata ×2 + Rattatac 17 ; Nidoran ♂ + Nidorino 18), 2 Ingénieurs (Magnéti 21 ; Magnéti ×2 + Magnéton 18) |
| Route 11, objets | aucun visible ; 1 caché |
| Route 11, est | un poste traversé ; à l'étage, un autre assistant de Chen : **Cherch'Objet contre 30 espèces** |
| Cave, accès | un petit bâtiment à chaque bout (un Joueur côté Route 11, un vieux pêcheur côté Route 2) |
| Route 2, couloir est | parallèle à la forêt. Du nord au sud : sortie de la Cave (près d'Argenta), maison d'échange (Abra → M. Mime), **poste de l'assistant** (CS05), puis, derrière des arbustes, **Pierre Lune** et **PV Plus** |
| Accès à la CS05 | **sans Coupe** : on entre par la Cave et on atteint le poste par le nord. Coupe ne sert qu'aux objets du sud |
| Flash | hors combat, éclaire le Tunnel Roche (praticable sans, à l'aveugle). Condition hors combat : Badge Roche. En combat : Précision de l'adversaire −1, **précision 70 %** en 1re génération |
| Ordre | Route 11 et Cave ouvertes **dès l'arrivée à Carmin**, avant le S.S. Anne |

## 3. Ce que la V2 contredit ou oublie

1. **« Les arbustes peuvent repousser après un changement de carte »** contredit **G-4** (validé le
   2026-10-11 : arbuste coupé **définitif**, un drapeau par arbuste). → H-5, on garde G-4.
2. **« Coupe conduit à la maison de l'assistant »** : en Rouge/Bleu, l'assistant est atteignable
   **sans Coupe** par la Cave. Le mettre derrière un arbuste crée une dépendance inutile au J16 et un
   point de blocage (Pokémon compatible au stockage). → H-2.
3. **« Réutiliser la géographie de la Route 2, ne pas en reconstruire une deuxième »** : c'est
   impossible tel quel. La Route 2 a **trois** accès fermés, et un seul relève de Coupe :
   - **FUTUR A** (ouest, ligne 19) : arbre dense, texte « Les branches sont trop épaisses » → **arbuste
     coupable** naturel ; derrière, un sentier peint de 4 cases qui sort de la carte (rien de conçu) ;
   - **FUTUR B** (est, lignes 43-44) : **barrière entretenue** + panneau « ACCÈS FERMÉ / Travaux sur le
     sentier », réservé au « secteur de la Grotte Taupiqueur » (dossier 11 §6) → **pas** un arbuste ;
   - **éboulis** de la Route 2 nord (24, 16..17), « ne promettent ni Coupe, ni Force » (dossier 12,
     arbitrage 9).
   Le couloir est de Rouge/Bleu (Cave, assistant, objets) n'existe sur aucune carte. → H-3, H-4.
4. **Ordre de jeu non dit.** La Route 11 s'ouvre-t-elle dès Carmin (Rouge/Bleu) ou après le S.S.
   Anne ? Tout le reste en dépend : niveaux de Triopikeur, Coupe obligatoire ou non. → H-1.
5. **Flash sans modèle.** La V2 ne dit ni si la CS05 occupe un emplacement, ni si elle a une
   condition de badge, ni comment elle s'utilise hors combat. Le modèle hybride de Coupe (G-2) et
   l'absence de condition (G-3) s'appliquent naturellement. → H-6, H-7.
6. **Cherch'Objet oublié** (Rouge/Bleu : poste de la Route 11, 30 espèces). Il introduirait un
   système (détection d'objets cachés). → H-11.
7. **Maison d'échange** (Abra → M. Mime) : les échanges sont exclus (dossier 18). → H-12, absente.
8. **Nom** : la V2 dit « Cave Taupiqueur » (nom officiel français), les dossiers 11 et 18 « Grotte
   Taupiqueur ». → H-16.
9. **Risque J17-H (compagnon dans les passages étroits) : sans objet.** Le compagnon prend la case
   que le joueur vient de quitter et n'occupe aucune case (`companion_trail.gd`) : il ne peut ni
   bloquer ni être bloqué. Il se cache déjà dans les intérieurs et n'est jamais posé sur une case de
   passage (J12 T20).
10. **Risque J17-D (compteur Pokédex) : déjà couvert.** `Pokedex.caught_count()` compte les espèces
    distinctes capturées ; l'évolution marque la nouvelle espèce comme possédée ; relâcher ou déposer
    ne touche jamais le Pokédex (`storage_rules.gd`). Seul manque une **condition de dialogue sur ce
    compteur** : aujourd'hui, les conditions n'acceptent que des drapeaux (coût caché n° 2).

## 4. Coûts techniques cachés

1. **Cases libérées par un drapeau** : n'existe pas (grille statique). Créé par le J16 pour les
   arbustes ; le J17 l'emploie pour l'arbuste de FUTUR A, ceux du couloir et la barrière de FUTUR B.
   Si le J16 le livre autrement, le J17 s'aligne.
2. **Condition « au moins N espèces possédées »** dans les variantes de dialogue (`cutscene_variant.gd`
   ne connaît que `if` / `unless` sur des drapeaux). Petit ajout, testable sans scène.
3. **Données des CS** : `tm_compatibility.json` n'a pas de section CS ; `flash` (et `cut`) absents
   des capacités. Le J16 ouvre la section avec la CS01 ; le J17 ajoute la CS05 (compatibilités
   `red-blue` de PokeAPI, comme `tools/gen_tm_compatibility.py`).
4. **Éclairage de Flash** : le projet n'utilise **aucune** `Light2D` ni `CanvasModulate` (rendu
   `mobile`). La pénombre du Mont Sélénite est **précalculée** dans des images ; elle ne sait pas
   suivre le joueur. Un halo autour du joueur dans une carte obscure est une **technique neuve**, à
   mesurer sur S24. → H-8.
5. **Espèces neuves** : Taupiqueur, Triopikeur, Soporifik, Hypno (évolution au Nv. 26, atteignable)
   n'existent sur aucune branche (ni données, ni dos, ni sprite du monde ; l'artwork officiel 001–151
   est partout). Ronflex : seulement un sprite du monde (grand, endormi), pas de données au J17.
   Dresseurs : selon H-13, jusqu'à 4 espèces « côté adversaire » (données + Pokédex, pas d'art).
6. **Une carte neuve** pour le couloir est (H-3) et une **retouche** de la Route 2 sud (FUTUR A,
   barrière) ; une retouche de Carmin (le bord est devient un vrai raccord).
7. **Ronflex** : aucun mécanisme neuf. Un PNJ présent `unless: <drapeau>` occupe déjà sa case
   (`npc_spec.gd:153`) ; il est donc infranchissable tant que le drapeau n'est pas posé.
8. **Sauvegarde** : uniquement des drapeaux et des objets ramassés. **Pas de v8 a priori** (v7 vient du
   J15).

## 5. Arbitrages à trancher (H-1 à H-17)

| # | Question | Recommandation |
|---|---|---|
| **H-1** | Quand la Route 11 s'ouvre-t-elle ? | **Dès l'arrivée à Carmin**, sans condition (Rouge/Bleu). Rien du chemin principal du J17 ne demande Coupe (H-2) ; le monde reste semi-ouvert. Le bord « À venir » du J15 devient un raccord normal. |
| **H-2** | Où Coupe est-elle nécessaire ? | **Rouge/Bleu** : l'assistant et la CS05 sont atteignables **sans Coupe** (par la Cave). Coupe ouvre seulement les **bonus** : le sud du couloir (Pierre Lune, PV Plus), le raccourci vers la Route 2 sud (H-3) et FUTUR A (H-4). Aucun blocage possible ; et Route 11, Cave et CS05 se codent sans attendre le J16. *Corrige la V2* (« Coupe conduit à la maison de l'assistant »). |
| **H-3** | Géographie du couloir est | **Nouvelle carte `route_2_east`** (zone `route_2` : une seule « Route 2 » dans la Carte et le Pokédex, comme la Route 2 nord, décision Q-3 du J10), ≈ 16 × 48 cases [D], entre la barrière de FUTUR B (sud) et l'arrière des éboulis (nord). Du nord au sud : **bouche de la Cave** ; **poste de l'assistant** (petit bâtiment, intérieur une pièce) ; **arbuste** ; partie sud avec **Pierre Lune** et **PV Plus** ; **barrière de FUTUR B** qui **s'ouvre de ce côté** (portillon, définitivement : drapeau), ce qui crée le raccourci vers Jadielle. Les **éboulis restent fermés** des deux côtés (dossier 12 inchangé). |
| **H-4** | Que cache FUTUR A ? | **Une petite clairière** derrière l'arbre dense, devenu **arbuste coupable** (deuxième arbuste du jeu, que la passe du J16 réservait au J17 « si un contenu est conçu derrière »). Contenu : **1 objet** et un point de vue sur la forêt, rien d'autre. Clairière taillée **dans la carte existante** (retouche du fond peint de la Route 2 sud, colonnes 0..6, lignes 16..22), pas de carte neuve. |
| **H-5** | Repousse des arbustes | **Non : G-4 s'applique** (coupé = définitif, un drapeau par arbuste). La phrase de la V2 est retirée. |
| **H-6** | Modèle de la CS05 | **Celui de Coupe (G-2, G-3)** : Flash débloqué dans le monde dès qu'un Pokémon compatible est dans l'équipe, **sans emplacement** ; la CS05 s'apprend aussi comme une CT réutilisable pour le combat (Précision de l'adversaire −1, **précision 70 %** comme en 1re génération), oubliable normalement. **Aucune condition de badge** (le Badge Roche n'a « pas de Flash », dossier 12). |
| **H-7** | Flash hors combat : action ou automatique ? | **Automatique** : en entrant dans une carte obscure avec la CS05 et un Pokémon compatible, courte mise en scène (le Pokémon apparaît, éclair, le halo s'ouvre), puis le halo reste pour la carte. Pas de menu, pas de bouton (dossier 06 §11 : « l'équipe les utilise dans le monde » ; bible : pas de bouton en plus). Ce que devient la grotte **sans** Flash relève du J18. |
| **H-8** | Quand construire l'éclairage de Flash ? | **Au J17, comme fondation** (d'accord avec la V2) : obscurité + halo autour du joueur sur une **carte de QA** provisoire (`qa_flash`, retirée à la clôture), mesurée sur S24 (fps, contraste du héros ≥ 3,0 comme au J12). Le **réglage** visuel se fait au J18 avec l'art du Tunnel Roche. Le J17 ne pose **aucune** carte obscure dans le jeu. |
| **H-9** | Condition de l'assistant | **`caught_count() ≥ 10`**, espèces distinctes capturées, y compris évolutions et Pokémon relâchés ou déposés (comportement actuel du Pokédex). Avant le seuil : il dit la condition **et le compte actuel**, à chaque visite. Après : CS05 remise **une seule fois** (drapeau), puis une réplique d'après. |
| **H-10** | Ronflex | **Au bout est de la Route 11**, endormi **sur** la route, devant le bord « ROUTE 12 » (fidèle : Rouge/Bleu le place au débouché exact). PNJ présent tant que le drapeau du réveil n'est pas posé : infranchissable, sans contournement possible (vérifié par `plan_check`). Examen : texte seul. **Pas d'entrée au Pokédex** avant le futur combat. Pas de poste sur la Route 11 (voir H-11). |
| **H-11** | Assistant au Cherch'Objet (30 espèces) | **Reporté**, sans place réservée : c'est un système neuf (détection d'objets cachés). *Écart volontaire et provisoire.* |
| **H-12** | Maison d'échange (Abra → M. Mime) | **Absente** au J17 (échanges exclus). Rien ne la promet. |
| **H-13** | Dresseurs de la Route 11 | **8 Dresseurs** (V2), **équipes Rouge/Bleu**, en retirant les **deux Joueurs** dont les espèces n'existent pas encore (Ptitard + Hypotrempe, Chétiflor + Mystherbe). Espèces **côté adversaire seulement** admises (artwork officiel déjà là ; données + Pokédex, pas de dos ni de sprite du monde) : **Magnéti, Magnéton, Caninos, Goupix**. Au plus **1 inévitable**. Niveaux recalés par simulation selon H-1 (joueur arrivant avant le S.S. Anne). |
| **H-14** | Rencontres de la Route 11 | **Rouge et Bleu réunis** (comme B-5 au J12) : Abo 20, Sabelette 20, Piafabec 35, Soporifik 25 ; niveaux Rouge/Bleu. Hypno créé pour l'évolution de Soporifik (Nv. 26). |
| **H-15** | Triopikeur | **5 %**, mais **Nv. 24–26** au lieu de 29–31 : avec H-1, le joueur peut arriver vers le Nv. 18–22, et la Vitesse de Triopikeur (120) rend la fuite presque impossible. Taupiqueur Nv. 15–22 inchangé. *Écart volontaire* (dangereux sans être un mur). |
| **H-16** | Nom de la grotte | **« Cave Taupiqueur »** (nom officiel français), corrigé dans les dossiers 11 et 18. |
| **H-17** | Découpage et validation S24 | **17A** Route 11, Dresseurs, Ronflex, Cave (après la fusion du J15 et du J12 ; aucune dépendance au J16) · **17B** couloir est, poste, condition Pokédex, CS05, FUTUR A et B (les arbustes après la fusion du J16) · **17C** Flash : données, combat, fondation d'éclairage sur `qa_flash` · **17D** clôture, non-régression. Une session S24 par lot (règle 1). Aucun lot ne touche un système risqué : pas de validation isolée. |

## 6. Valeurs par défaut (règle 4, sans arbitrage)

- Bouches de la Cave **naturelles** (pas les petits bâtiments de Rouge/Bleu), sans PNJ. 2 renfoncements,
  **1 objet visible** dans l'un d'eux.
- Route 11 : **2 objets visibles + 1 caché** (V2), parmi les objets déjà en jeu.
- Route 11 ≈ 76 × 36 (V2), Cave ≈ 34 × 80 (V2), recalées sur la grille fonctionnelle.
- Le poste de l'assistant : un assistant (sprite de scientifique existant ou nouveau modèle), un
  visiteur qui parle de Flash et des grottes obscures, sans nommer le Tunnel Roche.
- Barrière de FUTUR B ouverte : le panneau change de texte (« Sentier rouvert. ») [texte à valider].
- Objectifs du tableau de bord : aucun objectif propre au J17 tant que le joueur n'a pas besoin de
  Flash (le chemin principal reste le S.S. Anne / Major Bob du J16).
- Fonds de combat : Route 11 (prairie côtière) et Cave (roche), suivant la méthode CB.3.

## 7. Ce que la consolidation (dossier 20) doit fournir

- Les grilles fonctionnelles `tools/plans/route_11.txt`, `digletts_cave.txt`, `route_2_east.txt`, la
  retouche de `route_2.txt` (FUTUR A, FUTUR B) et de `vermilion_city.txt` (raccord est).
- La liste des Dresseurs (nom, classe, équipe, capacités, argent, inévitable ou non).
- Les objets (visibles, cachés, ceux du couloir).
- Les drapeaux (arbustes, barrière, CS05, objets, Ronflex).
- Les textes regroupés et numérotés : assistant (avant / pendant / après le seuil), visiteur du poste,
  Ronflex, arbuste de FUTUR A, barrière et panneau (avant / après), Dresseurs, habitants, descriptions
  de zone, CS05 et Flash (Sac, apprentissage, mise en scène).
- Les cas limites : seuil atteint par évolution ; Pokémon compatible déposé ; CS05 reçue sans
  Pokémon compatible ; application tuée pendant la remise ; retour Carmin ↔ Route 2 par la Cave
  dans les deux sens ; barrière ouverte puis sauvegarde côté Route 2 sud ; défaite dans la Cave
  (dernier Centre : Carmin ou Argenta / Jadielle selon le dernier visité).
- Critères de QA S21 / S24 par lot (H-17).
- La liste d'art : vues générales Route 11, Cave et couloir ; sprites du monde Taupiqueur (il sort du
  sol), Soporifik, Ronflex endormi ; dos de combat Taupiqueur, Triopikeur, Soporifik, Hypno (méthode
  Colab) ; bâtiment du poste ; arbuste ; portillon.

## 8. Ce qui est verrouillable tel quel

Pas d'Arène, de rival ni de Team Rocket au J17. Cave sans Flash, lisible avec le kit du J12. CS05
remise une fois, sur la condition « 10 espèces possédées ». Ronflex infranchissable jusqu'au futur
jalon de la Poké Flûte. Retour Carmin ↔ Route 2 possible à tout moment par la Cave. Pas de mini-carte,
d'isométrie ni de pixel art. Données dans des fichiers, logique testable sans scène.
