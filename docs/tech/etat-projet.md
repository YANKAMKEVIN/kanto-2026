# État du projet

Mis à jour : 2026-11-07.

> **Ce fichier reste court (quelques Ko).** On y **remplace** ce qui change, on n'empile pas une ligne par tâche : le détail d'une tâche va dans le plan du jalon (`docs/tech/jalon-*.md`) et dans le message de commit.
> Historique complet jusqu'au 2026-11-05 : [`etat-projet-archive.md`](etat-projet-archive.md) (6,5 Mo, à chercher avec `grep`, pas à lire) et [`etat-projet-historique.md`](etat-projet-historique.md).

## Où en est le projet

- **Kanto :** jalons fusionnés dans `main` jusqu'au J34 en cours. RC **0.34.1** (Kanto seul, sauvegarde v9) sur la branche `release/0.34`, qui ne passe pas par `main`.
- **RC 0.35.0 (jeu complet) :** construite (`74d58557`, `~/.pokemake/rc/0.35.0/`), installée sur l'A17 par-dessus la 0.34.1 ; détails dans `docs/tech/rc-0.35.0.md`. APK release de 778,7 Mo.
- **Art de Kanto :** toutes les cartes ont leur décor peint, les 202 espèces ont un dos peint, Sulfura, Électhor et Mewtwo sont peints sur la carte (`reportes.md`, RP-010, RP-132, RP-141, RP-290). Pas dans la RC 0.34.1. Vu sur l'A17 le 2026-11-06 sans blocage, dos peints du joueur compris, à terre et sur l'eau, en tenue d'origine et en costume pour la joueuse et les 16 costumes (`jalon-34-rapport.md` §3, lignes 9 bis et 9 ter).
- **Johto :** JOH0 à JOH9 et l'arc des Pierres (JOHP0 à JOHP3) sont dans `main`, ainsi que les personnages peints. L'arc est jouable de la Tour Radio à l'acte 2, retour de l'équipe compris.
- **Musiques de Johto :** 32 pistes HeartGold / SoulSilver branchées (cartes, Centres et Boutiques, combats par région, légendaires, générique) ; détail dans `docs/tech/johto-musiques.md` §10. Jingles, victoires et « ! » restent ceux de Let's Go.
- **Costumes (2026-11-07, dans `main`) :** huit avantages actifs si le costume est porté, écrits dans l'écran Dresseur et à l'annonce du déblocage ; un thème de combat (sauvages et Dresseurs ordinaires) et un chant d'arrivée en ville de 60 s par costume, 19 pistes validées à l'écoute par Kevin sur l'A17 (`dossier-costumes.md` §2 bis et §2 ter ; Go juridique `jalon-34-34e.md` §16).
- **Personne n'a encore joué Johto d'un bout à l'autre.**
- **CI :** 14 lots équilibrés par durée (`tools/ci_shard.py`, `tools/ci_test_times.json`) et cache de l'import Godot : environ 10 min au lieu de 24. Quand les lots se déséquilibrent, refaire le fichier de durées avec `tools/ci_shard.py --update <dossier des artefacts>`.

## Prochaines étapes

1. **RC 0.35.0 (Kevin) :** installer la RC et jouer le jeu entier ; T4 reporté à la version suivante. L'A17 porte pour l'instant la version de test des costumes (APK debug de la branche, 2026-11-07) à la place de la RC.
2. **Peinture :** plus aucune carte en tuiles (Kanto et Johto), maison du Gardien et souvenir de Dante compris. Le numéro RP-292 sert deux fois dans `reportes.md` : le second (bouton SURFER après un chargement au bord de l'eau) reste ouvert.
3. **Johto, vérifié sur l'A17 le 2026-11-06 (`docs/tech/qa-johto-a17-2.md`) :** onze jonctions passées par morceaux, Raikou, Entei, Ho-Oh, rival du sommet, remontée et descente du Mont Argenté. Un blocage trouvé et corrigé : sortie de la chambre du Centre d'Oliville. Reste : une partie complète et l'écoute des musiques par Kevin, relecture de deux objectifs ajoutés (JOH9).
4. **Suite de Kanto :** J35 à J40, plans dans `docs/tech/`.
5. **Bande-annonce :** v7 validée par Kevin le 2026-11-06, dans le jeu sur `main` (`docs/design/storyboard-trailer-v3.md` §10). Reste : la lire sur téléphone. La RC 0.35.0, déjà construite, garde l'ancienne vidéo : la nouvelle arrive avec la RC suivante.

## Questions ouvertes

- Aucune au 2026-11-07.

Remarques de rendu et points reportés : registre unique [`reportes.md`](reportes.md) (identifiants `RP-NNN`).

## Décisions de Kevin en vigueur

- **Écran Dresseur (2026-11-09) :** plus de section Équipe ; Costumes au centre, Grands moments à droite (`dossier-costumes.md` §2 quater). Un Pokémon K.O. n'a plus de FAIRE SORTIR.
- **Dépôt (2026-11-07) :** repassé en privé par Kevin. Le workflow de CI reste tel quel (consigne du 2026-11-04, `jalon-34-34e.md` §14).
- **Costumes (2026-11-07) :** l'avantage n'agit que si le costume est porté, et il est écrit pour le joueur. Musiques : un thème de combat (sauvages et Dresseurs ordinaires) et un jingle d'arrivée en ville par costume.
- **Ordre de l'acte 2 (2026-11-06) :** JOH6 avant JOH7. La mer au sud d'Oliville reste fermée jusqu'au déserteur d'Acajou (`johto_whirl_clue`).
- **Hurlement des légendaires sauvages (2026-11-06) :** Raikou et Entei gardent l'attaque, mais ne la maintiennent qu'une fois sur quatre (`Battle._restrain_force_out`). Après une fuite, on peut toujours les retrouver.
- **Validation déléguée (2026-11-04) :** les sessions Kanto et Johto avancent sans lui. Tests ciblés, CI verte (« Conclusion : success ») et auto-validation sur téléphone suffisent pour fusionner dans `main`, avec un compte rendu. Seules les vraies décisions de game design et les décisions juridiques lui remontent.
- **RC 0.35.1 (2026-11-07) :** Kanto et Johto, bande-annonce v7, costumes et leurs 19 musiques locales, icône céleste et démarrage Android sans coupure observée sur l'A17. **Blocage vu sur le S24 le 2026-11-09** (chargement de Boot en arrière-plan figé sur l'image de démarrage) : corrigé dans `main` (`android_launch.gd`, chargement direct), pas encore dans une RC ; Kevin veut ajouter d'autres choses avant la prochaine.
- **RC 0.35.0 (2026-11-06) :** Go technique de Kevin, qui installe la vraie version pour jouer le jeu entier. Le T4 (première utilisation par un proche) est reporté à la version suivante.
- **Go juridique (2026-11-07) :** reconduit pour la RC 0.35.1, avec les musiques des costumes (§16 et §17). **2026-11-06 :** étendu à la RC 0.35.0 et à Johto, pour le seul cercle de la maison, aux mêmes conditions (`jalon-34-34e.md` §14, §15.5).
- **Diffusion (2026-10-24) :** jeu privé, pour Kevin et un cercle restreint de proches. Jamais de store, de lien ouvert ni de page publique.
- **Retours des testeurs (2026-11-06) :** groupe WhatsApp.
- **RC (2026-11-06) :** jeu complet depuis `main`, en version 0.35.0, après la partie complète de Kevin. Remplace « Kanto seul depuis `release/0.34` » du 2026-11-04. `release/0.34` reste telle quelle.
- **Son (2026-10-24) :** musiques de Let's Go Pikachu / Évoli à Kanto, HeartGold / SoulSilver à Johto ; cris PokeAPI. Arbitrages : `docs/design/passes/son-arbitrages-kevin.md`.
- **Art :** option B de `docs/design/phase-da-cadrage.md`, arbitrages DA-1 à DA-9. Une maquette validée par Kevin se reproduit à l'identique.
- **Entrée des combats de Dresseur (2026-11-02) :** deux niveaux, jamais sautée ; `docs/design/dossier-05-combat.md` §3.
- **Difficulté :** première tentative gagnée à 80 % au plus, grands combats autour de 35 à 60 %. Ne pas adoucir au-delà de 80 % sans Kevin.
- **Démarrage (2026-11-07) :** Android garde la Poké Ball céleste à l'écran jusqu'au démarrage de Godot. La première scène Android affiche l'illustration en grand pendant le chargement du jeu, avant le carton « Les studios Kevin & Co / vous présentent ».
- **Icône (2026-11-07) :** Poké Ball céleste, validée par Kevin pour le lanceur Android et iOS.
- **Nom :** le jeu s'appelle Pokemake ; dépôt, dossier et package gardent « kanto2026 ».

Les décisions propres à un jalon restent dans son dossier et son plan.
