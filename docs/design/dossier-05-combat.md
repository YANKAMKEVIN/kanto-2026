# Dossier 05 — Le système de combat

> Conçu par Kevin (avec ChatGPT), reçu le 2026-09-26. Sert aux jalons 4 et suivants (starter, premier combat, rencontres, capture). Références visuelles : `reference/combat-v1.webp` (écran de combat), `reference/combat-capture-v1.webp` (capture en 9 cases) et la sélection des capacités décrite dans `ui-reference.md` (fichier attendu : `reference/combat-capacites-v1.png`).

**Principe** : conservateur sur les règles, très ambitieux sur la mise en scène. Le combat reste du Pokémon au tour par tour ; ce qui devient 2026, c'est **la sensation de combattre**. *On ne modernise pas Pokémon en changeant ses règles ; on modernise ce que le joueur ressent lorsqu'il les utilise.*

## 1. Ce qu'on ne touche pas
1 Pokémon actif contre 1, jusqu'à 4 capacités, types et faiblesses, précision, coups critiques, altérations de statut, objets, changement de Pokémon, fuite contre les sauvages, K.O., XP, combats de Dresseurs. Quelqu'un qui connaît Pokémon comprend immédiatement.

## 2. Le combat se déroule dans l'endroit où l'on se trouve
Décision préférée de Kevin. Pas de « transition → décor générique d'herbe ». Un Roucool rencontré près d'un petit pont de la Route 1 se combat **près de ce pont** : même végétation, même heure, même météo, même lumière (à 19 h sous la pluie : sol humide, pluie qui continue, lumière du soir). Continuité totale entre exploration et combat.

## 3. La transition (~1 s)
- **Sauvage** : pas de spirale Game Boy de 3 s. L'herbe bouge → cri → le personnage s'arrête → la caméra se rapproche légèrement → le Pokémon apparaît → le partenaire entre dans le cadre → combat.
- **Dresseur** : il te voit → s'approche → quelques mots → sort sa Poké Ball → lancer. Rapide.

## 4. La caméra
Vue générale : ton Pokémon en bas/gauche, l'adversaire en haut/droite. Pendant les attaques : léger zoom, déplacement du cadrage, tremblement extrêmement subtil, flash, particules, puis **retour immédiat** au cadrage normal. Cinématique sans transformer chaque attaque en Final Fantasy.

## 5. HUD minimal
Hors choix d'action : nom, niveau, barre de PV (et PV chiffrés pour ton Pokémon seulement) pour chaque camp. **Pas de gros rectangles opaques** : informations intégrées dans la composition.

## 6. Les quatre actions
ATTAQUER · SAC · ÉQUIPE · FUITE. Très grandes zones tactiles, pouce-friendly. **ATTAQUER est l'action visuellement dominante.**

## 7. Sélection d'une capacité
Les quatre capacités arrivent : **nom, type, PP, éventuellement puissance** — pas 15 statistiques. **Tap = rapide ; pression longue = fiche détaillée** (Puissance 40, Précision 100, « Peut paralyser »).

## 8. Types lisibles
Le type s'affiche clairement (⚡ ÉLECTRIQUE). Si le Pokédex en sait assez sur l'adversaire, on peut afficher discrètement **« Efficace »** ou **« Peu efficace »** — jamais « SUPER EFFECTIVE x2.000000 ». On garde une part d'apprentissage.

## 9. Attaques physiques : les Pokémon bougent vraiment
Charge : Pikachu prend appui → traverse une partie de l'écran → impact → revient. Griffe : Salamèche s'approche → mouvement → impact. Morsure : Rattata bondit.

## 10. Attaques à distance
Éclair : Pikachu se prépare, ses joues s'illuminent, CRACK, l'éclair traverse la scène ; pendant ~2 images **tout l'environnement est éclairé** ; Roucool prend l'impact, plumes/particules, PV qui descendent. **1 à 1,5 s**, rapide et spectaculaire.

## 11. Le monde réagit légèrement
Attaque électrique la nuit → éclaire brièvement les arbres ; feu → lumière orange au sol ; eau → gouttelettes ~0,5 s ; grosse attaque → feuilles des plantes qui bougent. **Aucune destruction du décor**, juste une réaction visuelle.

## 12. Les PV
Code vert → jaune → rouge, animation très fluide. Petit coup → descente normale ; **gros coup → descente plus rapide + impact sonore** ; PV critiques → très légère pulsation du HUD. Pas de gros avertissement permanent.

## 13. Statuts visibles sur le Pokémon
Paralysie → petites décharges occasionnelles ; poison → légère aura/particules ; sommeil → respiration différente ; brûlure → petites braises intermittentes. On voit l'état sans lire l'interface.

## 14. Changer de Pokémon
ÉQUIPE ouvre un **panneau latéral**, le combat reste visible derrière (liste : icône de type, nom, PV, « ACTIF »). Le dresseur rappelle le Pokémon, Poké Ball, le nouveau apparaît. **Pas d'écran noir.**

## 15. Le Sac en combat
Seulement ce qui est pertinent : **Poké Balls, Soins, Combat**, éventuellement favoris. Pas les 85 objets.

## 16. La capture
🎒 → Poké Balls → Poké Ball. Le dresseur apparaît davantage dans le cadrage, lancer, Pokémon absorbé, la Ball tombe **dans le décor actuel**, puis toc + vibration ×3… ✨ clic. **Ces trois secondes doivent être presque sacrées.** (Storyboard : `combat-capture-v1.webp`.)

## 17. Capture réussie
> **Précisé le 2026-10-02 (dossier 09 §6)** : « Nouvelle entrée Pokédex » ne s'affiche **qu'après l'activation du Pokédex** par Chen (J7A). Avant, la ligne est absente ; la capture est tout de même enregistrée.

Pas 8 fenêtres : « **ROUCOOL CAPTURÉ** », puis discrètement « Nouvelle entrée Pokédex ». Si l'équipe < 6 : « Roucool rejoint ton équipe. » Sinon : « Roucool a été confié au système de recherche de Chen. » Et on continue.

## 18. Premier combat contre le rival
Le tutoriel du combat **sans ressembler à un tutoriel**. Le starter n'a que ~2 capacités utiles ; le jeu **montre subtilement ATTAQUER** ; on attaque, le rival répond ; éventuellement **une seule indication contextuelle de Chen**, seulement si nécessaire. Pas d'explication des PV : « on sait lire une barre ».

## 19. IA des Dresseurs, progressive
Habitant/débutant : choix simples · Dresseur expérimenté : types, changements, statuts · Champion : stratégie propre à son identité · Conseil 4 : vrai combat tactique · **Rival** : son IA évolue avec le joueur (erreurs au début ; à la fin, « il te connaît »).

## 20. Champions avec une identité de combat
Chaque Champion est un mini-examen stratégique (voir dossier 06 : Pierre = types, Ondine = composition d'équipe, etc.).

## 21. Vitesse des combats
Un combat contre un sauvage faible : **20 à 40 secondes**, pas 2 minutes. Animations belles mais rapides. Option : **Animations de combat : Complètes / Rapides** (même « Complètes » ne fait pas perdre de temps).

## 22. Boss et légendaires
Mise en scène d'exception, même système : silence, vent, plumes/glace, la musique disparaît, puis l'apparition, et **seulement ensuite** le HUD.

## 23. Défaite
Plus de « KEVIN est hors-jeu ! KEVIN perd 1240 ₽ ». Écran très bref → dernier Centre Pokémon visité → soin. Conséquence financière éventuelle mais raisonnable : ne pas punir l'exploration.

## 24. Gestes facultatifs (pas en V1)
Raccourcis possibles plus tard (swipe depuis Pokémon → Équipe, depuis Sac → dernier objet). **V1 : d'abord une excellente interface tactile classique.**

## Décisions verrouillées
| Sujet | Kanto 2026 |
|---|---|
| Tour par tour | oui |
| 1 contre 1 standard | oui |
| 4 capacités | oui |
| Combat dans l'environnement actuel | oui |
| Caméra / animations dynamiques | oui |
| Attaques réellement animées | oui |
| Décor réactif | légèrement |
| UI tactile à 4 actions | oui |
| Gestes obligatoires | non |
| Haptique | oui |
| Combat sauvage rapide | oui |
| IA progressive | oui |
| Mise en scène spéciale boss/légendaires | oui |

## Point à trancher plus tard (noté par Claude)
§5 demande « pas de gros rectangles opaques », alors que la référence `combat-v1.webp` montre des cartes d'information et des boutons sur fonds sombres ou colorés. À préciser au jalon 4 (probablement : cartes translucides comme la boîte de dialogue).
