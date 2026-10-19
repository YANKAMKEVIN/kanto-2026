# J23 — Les secrets du Parc Safari : V2 (ChatGPT), telle que transmise par Kevin le 2026-10-16

> Reproduction de la V2 (décisions et prompt de transmission), pour mémoire. La passe d'alignement et
> le dossier sont dans `docs/design/dossier-26-parc-safari-koga.md`. Mise en forme seulement : le
> fond n'est pas modifié. Les images de référence jointes à la V2 (organisation historique du Parc)
> ne sont pas reprises.

## 1. Décisions verrouillées (7 arbitrages validés)

| Sujet | Décision |
|---|---|
| Périmètre | Parc Safari complet, CS03 Surf, CS04 Force, Arène de Koga |
| Captures Safari | Safari Balls, appâts et cailloux, sans combat classique |
| Exploration | Compteur de pas et nombre limité de Safari Balls |
| Dents d'Or | Objet à récupérer et remettre au Gardien |
| CS | Modèle hybride, avec conditions de badges historiques |
| Arène | Murs invisibles historiques, lisibles sur mobile |
| Fin | Badge Âme et exploration libre, sans séquence forcée |

Principe : le joueur peut visiter le Parc Safari **avant** d'affronter Koga. Il peut donc récupérer
Surf et Force sans être encore autorisé à utiliser Surf dans le monde.

## 2. Parc Safari

- Plusieurs zones connectées : herbes hautes, points d'eau, objets, passages à explorer.
- Budget historique : **500 pas, 30 Safari Balls, 500 ₽ par entrée** (à vérifier dans RB).
- Chaque tentative commence à l'entrée avec son propre compteur. Les objets uniques ramassés restent
  acquis.
- Quatre actions : SAFARI BALL, APPÂT, CAILLOU, PARTIR. Effets des appâts et cailloux **selon RB, y
  compris ses particularités**, pas de probabilités inventées.
- Aucun Pokémon de l'équipe ne combat : ni expérience ni argent.

## 3. CS03 Surf et CS04 Force

- **CS03 Surf** : Maison Secrète du Parc, une seule fois ; usage dans le monde avec le **Badge Âme**
  et un Pokémon compatible.
- **CS04 Force** : remise par le Gardien de Parmanie contre les Dents d'Or ; usage dans le monde avec
  le **Badge Prisme** et un Pokémon compatible.
- Modèle hybride de Coupe : la possession débloque l'usage dans le monde sans emplacement de combat ;
  apprentissage facultatif en combat comme une CT réutilisable, oubliable.
- Vigilance : le Badge Prisme doit exister (J20).

## 4. Arène de Koga

- Murs invisibles : obstacles physiques, perceptibles par de très légers indices visuels cohérents
  avec le rendu peint, sans couloir balisé.
- Thème Poison, Badge Âme. Pas de mécanique de combat nouvelle juste pour l'équipe historique :
  audit des capacités et remplacements explicites (comme Major Bob).
- Récompense RB : **CT06 Toxik**.

## 5. Dépendances J20 → J23 (V2)

Parmanie et ses bâtiments (J22) ; deux itinéraires vers Parmanie (J22) ; moteur de rencontres ;
capture et stockage ; Badge Prisme (J20) ; Badge Âme (J23) ; compatibilités des CS (J16+) ; statuts
Poison (J11) ; sauvegardes (duplication des CS ou des Dents d'Or).

## 6. Règles à retenir (V2)

- Fin de visite quand les pas ou les Balls sont épuisés ; appât = moins de fuite, capture plus
  difficile ; caillou = l'inverse.
- Les Safari Balls restantes disparaissent à la fin de la visite, sans rejoindre le Sac.
- Dents d'Or et CS03 restent acquises entre deux visites.
- Le compteur diminue seulement lors des déplacements effectifs, pas en pivotant.
- Sortie volontaire possible sans perdre les objets obtenus.
- Une sauvegarde interrompue ne doit ni dupliquer les récompenses ni rendre gratuitement les
  ressources de la visite.
- Risque de blocage si le joueur ne peut plus payer l'entrée avant Surf et Force : à documenter, avec
  un moyen de gagner de l'argent **sans règle arbitraire propre au Safari**.

## 7. Découpage proposé

23.0 audit · 23A quatre zones, raccords, objets, compteur · 23B rencontres et captures Safari ·
23C Maison Secrète, CS03, Dents d'Or, Gardien · 23D Surf et Force (monde et combat) · 23E Arène de
Koga, Badge Âme, CT06 · 23F sauvegardes, non-régression, QA S24.

Critère de fin : explorer le Parc, capturer ses Pokémon rares, obtenir Surf et Force, vaincre Koga
et repartir librement explorer les zones rendues accessibles par les badges.

## 8. Prompt de transmission (résumé)

Contrat d'entrée à vérifier (J22 : Parmanie, deux accès depuis les Routes 12–18, rencontres et
stockage) ; audit historique et technique (topologie, budget, probabilités, équipe et stockage
pleins, compteur, objets, remises uniques, badges, espèces, Pokédex et art, Arène, Koga et CT06,
blocage d'argent, sauvegardes) ; dossier en 16 sections ; pour chaque mécanique : RB, génération
ultérieure ou adaptation K26. **Ne rien coder**, branche documentaire indépendante, attendre la
validation.
