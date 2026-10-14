# Prompt ChatGPT — dossier 16 : S.S. Anne et Badge Foudre (jalon 16), consolidation

> Préparé par Claude le 2026-10-11, à coller dans ChatGPT **après** les réponses de Kevin aux
> arbitrages G-1 à G-10 de `docs/design/passes/j16-v2-alignement.md`. Joindre la V2 de ChatGPT et la
> passe d'alignement. Le texte entre les deux lignes est le prompt ; **remplacer le bloc
> « Réponses de Kevin »** avant de l'envoyer. Numéro de dossier : le premier libre au moment du push
> (passe, §2 n° 17) : 16 et 17 sont déjà pris par le J13 et le J14.

---

Tu m'aides à **consolider le dossier 16** de *Kanto 2026* (S.S. Anne + Arène de Major Bob), à partir
de ta V2 et de la passe d'alignement de Claude, que je te joins. Claude implémente à partir de ton
dossier : tout ce que tu ne tranches pas, il devra me le redemander. Ne rouvre **aucune** décision
listée ci-dessous.

## Décisions verrouillées (V2, passe d'alignement, projet)

- **Périmètre** : S.S. Anne (pont principal, pont inférieur, restaurant, pont extérieur, cabines,
  cabine du capitaine) **et** Arène de Major Bob. Pas de Team Rocket au J16.
- **Rival n° 4** : dans le couloir de la cabine du capitaine ; victoire obligatoire ; défaite →
  dernier Centre, **aucune perte d'argent**, il reste en place avec une réplique de reprise courte
  (pas de réintroduction) ; après sa défaite il part. IA `smart`, **aucun changement de Pokémon**.
- **Capitaine** : mal de mer, scène courte et chaleureuse, sans mini-jeu ; CS01 remise une seule fois.
- **Départ** : le navire part seulement après la CS01 **et** une confirmation explicite à la passerelle
  (cartes de choix, jamais « Oui / Non ») ; avant la CS01 on sort librement ; après le départ, le
  navire n'existe plus. Seul élément indispensable : la CS01.
- **Major Bob** : carte de Champion et Grand moment « badge » génériques (J10), légende « BADGE
  FOUDRE », vibration, **aucun bonus caché** (ni Vitesse, ni obéissance), CT24 Tonnerre réutilisable,
  IA `smart`, capacités choisies à la main.
- **Valeurs des capacités = valeurs actuelles** (convention du projet) : Coupe 50 / 95 % / 30 PP,
  Tonnerre 90 / 100 % / 15 PP / paralysie 10 %, Sonicboom 20 dégâts fixes / 90 % / 20 PP.
- **Mécaniques absentes, à ne pas utiliser** : Destruction / Explosion, Entrave, Téléport en combat de
  Dresseur, Mur Lumière, Protection, Reflet, changement de Pokémon par l'IA. Si une équipe en a
  besoin, choisis d'autres capacités et dis-le.
- **Défauts de Claude** : Grand moment du rival n° 4 à la victoire seulement ; arbuste sans Pokémon
  compatible = une réplique sans choix ; « Utiliser Coupe ? » → **COUPER** / **LAISSER** ; Passe Bateau
  gardé dans le Sac après le départ.
- **Forme** : bulles de 2 lignes de ≈ 40 caractères ; pas de fenêtre « OBJECTIF MIS À JOUR » ; pas de
  marqueur ni de flèche (la circulation et l'équipage guident) ; pas de tutoriel.

## Réponses de Kevin aux arbitrages G-1 à G-10

Tranchés le 2026-10-11 (détail : passe d'alignement, §8). À appliquer tels quels :

- **G-1** : contrat d'entrée validé. Écris-le mot pour mot au §2 du dossier.
- **G-2** : **modèle hybride**. La CS01 débloque Coupe dans le monde dès qu'un Pokémon compatible est
  dans l'équipe, **sans occuper d'emplacement**. Elle s'apprend aussi comme une CT réutilisable pour
  servir en combat, et s'oublie normalement. F-2 est sans objet.
- **G-3** (retranché le 2026-10-14) : **Coupe exige le Badge Cascade** (Rouge/Bleu), car le J14 ne garantit pas Ondine avant le Passe Bateau. Sans le badge, le Pokémon compatible refuse de couper : l'arbuste le dit, sans choix. Le navire et la CS01 restent accessibles avant Ondine. Donne le texte exact.
- **G-4** : arbuste coupé **définitif**.
- **G-5** : arbuste devant l'Arène de Carmin (posé au J15, coupé au J16).
- **G-6** : au moins une espèce compatible Coupe capturable avant Carmin quel que soit le starter :
  c'est déjà le cas (Dardargnan, Sabelette, Paras).
- **G-7** : rival n° 4 = **Roucoups, Rattatac, Kadabra, starter évolué** (avantage de type), niveaux
  de référence 19 / 16 / 18 / 20 ; Kadabra sans Entrave. **Pas d'Abra au rival n° 3** (décision D-6 du J13, 2026-10-13) : Kadabra arrive directement au n° 4.
- **G-8** : **puzzle Rouge/Bleu strict**. Premier interrupteur tiré au hasard, second voisin, toute
  erreur remet tout à zéro. Interrupteurs cachés dans des objets à fouiller bien lisibles, sans indice
  qui désigne le bon ; nouveau tirage à chaque entrée tant que ce n'est pas résolu ; résolu = ouvert
  pour toujours.
- **G-9** : au plus **3 espèces nouvelles** (Abra, Kadabra + au plus une de marin) ; **10 Dresseurs**
  sur le navire, au plus 2 inévitables hors rival.
- **G-10** : confirmation à la passerelle après la CS01 : **PARTIR** / **PAS ENCORE** ; avant, sortie
  libre.

## Ce que j'attends : le dossier 16 complet

1. **Intention** en deux phrases.
2. **Contrat d'entrée** (G-1) mot pour mot : ce que J13–J15 doivent livrer (drapeaux, objets,
   cartes, rival n° 3 = Roucoups, Rattata, starter évolué, **sans Abra** (correction du 2026-10-13), donneur du Passe Bateau = **Léo** (nom officiel de Bill ; l'enfant de Bourg Palette s'appelle désormais Nils), Badge Cascade **non garanti** avant le Passe Bateau).
3. **Plans fonctionnels ASCII** de chaque carte : navire (une carte par espace + cabines),
   passerelle et quai de Carmin, Arène. Pour chacune : taille en cases (1 case ≈ 1 m, écran ≈ 24 × 11
   cases), portes et escaliers, cases des Dresseurs et leur regard, objets visibles et cachés,
   place du rival, du capitaine, de l'arbuste, des interrupteurs, des barrières. Angles droits, pas
   d'isométrie.
4. **Dresseurs** (≈ 10, au plus 2 inévitables hors rival) : nom, classe, équipe (espèces **déjà
   présentes ou listées comme nouvelles**, G-9), niveaux, capacités, argent, répliques avant /
   après / défaite.
5. **Rival n° 4** par starter : espèces, niveaux, capacités (Kadabra sans Entrave), répliques avant
   (allusion au mal de mer), après, reprise.
6. **Capitaine et CS01** : scène pas à pas, textes, ce qui se passe si on lui reparle.
7. **Coupe** selon G-2 / G-3 / G-4 : texte de la CS dans le Sac, texte de l'arbuste (avec et sans
   Pokémon compatible), mise en scène (≤ 2 s, le Pokémon qui coupe est visible), liste des arbustes
   posés au J16.
8. **Départ** : textes de la confirmation (G-10), scène vue du quai (≤ 10 s), état de Carmin après.
9. **Arène** selon G-8 : indices du décor, règle exacte, Dresseurs, guide, Major Bob (carte, avant,
   après, défaite), remise de la CT24.
10. **Objectifs du tableau de bord**, de l'arrivée à Carmin jusqu'après le badge.
11. **Liste des drapeaux** (noms en anglais, `snake_case`).
12. **Espèces, capacités et art** : ce qui est nouveau (données, Pokédex, dos peints, personnages
    peints, décors de combat), en distinguant indispensable et souhaitable.
13. **Cas limites** : défaite contre le rival puis Corde Sortie ; application fermée pendant la
    confirmation, pendant la scène de départ, juste après ; CS01 obtenue puis sortie sans confirmer ;
    Pokémon compatible déposé au stockage ; équipe entièrement incompatible devant l'arbuste ;
    interrupteur trouvé puis carte quittée ; défaite contre Major Bob après le puzzle.
14. **Découpage S24** : 16.0 à 16F (le départ, 16D, est validé seul).
15. **Textes à valider**, regroupés et numérotés.
16. **Questions ouvertes** numérotées, chacune avec ta recommandation.
17. **Tableau final « Décisions verrouillées »**.

Pour chaque règle, dis si elle suit **Rouge/Bleu**, une **génération plus récente** ou une
**invention de Kanto 2026**. Signale toute mécanique nouvelle.

---

## Après ChatGPT

Colle sa réponse à Claude. Il fait une dernière relecture : contradictions, mécaniques ajoutées en
douce, coût d'art. Puis il écrit le dossier dans `docs/design/` avec le premier numéro libre.
Viennent ensuite la vue générale peinte du navire et les grilles `tools/plans/*.txt`, à valider
avant toute carte.
