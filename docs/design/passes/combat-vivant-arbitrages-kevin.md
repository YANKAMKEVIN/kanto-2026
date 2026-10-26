# Combat vivant — arbitrages pour Kevin

> Rédigé le 2026-10-26 (session de coordination, documents seuls). Plan : `docs/tech/combat-vivant.md`.
> Source : `docs/design/dossier-05-combat.md` (§4, §9 à §13, §16, §21, §22).
> **En attente de Kevin.** Réponse possible en une ligne : « CV-1 à CV-14 : tes recommandations »,
> ou numéro par numéro.

**Le constat en deux lignes.** Aujourd'hui, toutes les attaques jouent le même retour : un élan de
60 px (physique), une pulsation blanche (spéciale) ou deux petits bonds (statut), puis un
clignotement de la cible. Rien ne part, rien n'arrive, la caméra ne bouge que sur un critique, et
aucune option « Complètes / Rapides » n'existe. Le son de l'attaque sort aussi après l'élan au lieu
d'être en même temps (défaut trouvé dans le code, à confirmer à l'oreille).

| N° | Question | Recommandation |
|---|---|---|
| **CV-1** | Animations **par famille** (17 familles, une par élément ou geste, + 13 attaques phares avec un effet propre), **une par attaque** (165), ou **familles seules** ? | **Familles + 13 phares.** Une par attaque coûte ≈ 10 fois plus pour un gain que peu de joueurs verront ; ajouter une phare plus tard = une ligne de données. Phares : Éclair, Tonnerre, Fatal-Foudre, Lance-Flammes, Déflagration, Hydrocanon, Surf, Ultralaser, Séisme, Psyko (priorité A) ; Blizzard, Lance-Soleil, Explosion / Destruction (B). |
| **CV-2** | **Durée** d'une attaque en Complètes ? | **0,8 à 1,5 s** (phares jusqu'à 1,8 s), Rapides **≤ 0,5 s**. Un sauvage faible reste à ≈ 25–35 s en Complètes (cible 20 à 40 s, §21), chronométré sur S24 à la clôture. |
| **CV-3** | **Intensité de la caméra** : subtile (zoom ≤ 6 %, tremblement ≤ 6 px, seulement sur les attaques offensives, retour en 0,15 s), marquée (zoom 10–15 %, cadrage qui suit l'attaque), ou aucune ? | **Subtile.** Le §4 dit « tremblement extrêmement subtil » et « pas Final Fantasy ». La HUD ne bouge jamais. |
| **CV-4** | **Option « Animations de combat »** : valeur par défaut, et où ? | **Complètes par défaut**, dans la catégorie **JEU** des Paramètres. Aide : « Rapides : combats plus courts, mêmes effets. » |
| **CV-5** | « Réduire les animations » (Accessibilité, existe déjà) : **réglage distinct** de Complètes / Rapides, ou fusionner les deux ? | **Distinct.** Rapides = confort (même spectacle, plus court) ; Réduire = accessibilité (aucun mouvement de caméra, aucune secousse, moins de particules). « Réduire les flashs » reste valable partout : jamais plus de 3 flashs par seconde. |
| **CV-6** | **Le monde réagit** (§11 : lumière orange du feu, scène éclairée par l'Éclair, gouttelettes, feuillage qui bouge) : sur tous les décors, ou seulement les décors peints ? | **Partout**, par une lumière simulée sur le décor (pas de vraies lumières : l'A17 n'a pas la marge). Sur le repli (carte floutée), seulement la lumière. |
| **CV-7** | **Art des particules** : ≈ 20 sprites peints par Codex (flamme, goutte, feuille, plume, éclat de glace, caillou, étoile d'impact…), ou **tout en formes dessinées en code** ? | **Formes en code d'abord** (CV.0, rien n'attend l'art), puis **un atlas de ≈ 20 sprites peints** en CV.1, une planche à valider comme un lot DAF. Rayons, arcs et ondes restent en code. |
| **CV-8** | **Respiration au repos** de tous les Pokémon (souffle de 1 % sur 3 s ; le sommeil respire plus lentement et plus fort) ? | **Oui.** Aujourd'hui rien ne bouge entre deux actions ; le §13 parle d'une respiration *différente* pour le sommeil, ce qui suppose une respiration normale. |
| **CV-9** | **Trace des PV perdus** : un segment clair reste 0,3 s puis rattrape la barre (repère courant des jeux récents) ? | **Oui, discret.** Le gros coup se lit mieux, sans rien ajouter d'autre à l'écran. |
| **CV-10** | **Éclair sur Pikachu** : partir des joues (une petite table de position des joues pour Pikachu et Raichu), ou du centre du sprite pour tout le monde ? | **Joues pour Pikachu et Raichu seulement**, centre ailleurs. C'est l'image du §10 ; l'artwork est fixe, on ne repeint rien. |
| **CV-11** | **Capture** (§16, « trois secondes presque sacrées ») : finition dans ce chantier (Ball peinte au lieu du pixel art, léger zoom sur la Ball pendant les secousses, lumière qui baisse un peu, éclat final) ? | **Oui**, en CV.3 ; la Ball peinte entre dans l'atlas de CV-7. Les durées ne changent pas. |
| **CV-12** | **Évolution et boss / légendaires** (§22 : silence, vent, apparition puis HUD) : dans ce chantier ? | **Non.** L'écran d'évolution a déjà ses particules ; les légendaires ont une entrée ralentie depuis la passe systèmes 2. Les deux vont en DAF.8 (1.0.x) si tu veux plus. |
| **CV-13** | **Calendrier** : dans `main` **avant le début du J33** (sa campagne teste les combats), au plus tard avant le gel du J34 ; CV.0 commence après la fusion du J23 (il touche le même fichier de scène) ? | **Oui.** Le chantier peut tourner en parallèle des fusions J26 à J31 : il ne touche ni au moteur ni aux cartes, son code neuf est dans un dossier à part. Il compte comme un des 2 à 3 jalons actifs. |
| **CV-14** | **Validation** : 3 créneaux S24 (CV.0 socle et Éclair ; CV.1 toutes les familles ; CV.2 + CV.3 phares, monde, statuts) sur une « galerie d'effets » qui enchaîne les attaques, ou un seul à la fin ? | **3 créneaux** (≈ 15 min chacun). Système nouveau et visible : la règle 1 veut une validation par sous-jalon. |

**Effort** (détail au plan, §5.2) : 8 à 12 sessions, ≈ 3 à 5 jours avec deux sessions en parallèle ;
ton temps : ≈ 1 h en tout (3 validations S24 et une planche).

## Réponses de Kevin

*(à remplir)*
