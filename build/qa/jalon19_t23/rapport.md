# QA 19B (T23) - S24, 2026-10-19, révision 9fc88208 (jalon-19-integ)
Phone : S24 SM_S921B, sans fil, nom adb-RFCX80Y0FVX-daOvI1. Durée sur téléphone : 21:14 -> 21:44 (30 min). APK debug 194 Mo installé (-r), import headless OK.
Départs utilisés : pokemon_tower_1f, tower_rival_weak, tower_rival (+ variantes « fortes » dans ds/), tower_ghost_qa, tower_5f_zone, tower_6f_block, vraie partie.
Aucun départ `tower_qa` n'existe dans tools/debug_start/ (prévu au §9 du plan) : le 1F a été testé avec pokemon_tower_1f.

| Point | Verdict | Observation |
|---|---|---|
| 1F : scène gardienne, escalier -> 2F | OK (partiel) | log « [qa] scène tower_guardian jouée », puis SceneRouter pokemon_tower_2f. Position de la gardienne en (18,3) et textes non relus sur capture (captures 1F perdues à l'affichage) : NON VÉRIFIÉ visuellement. Titre « TOUR POKÉMON » vu au 2F (v0.png). |
| 2F rival n°5 : défaite -> Centre | OK | tower_rival_weak (Salamèche N5) : scène jouée, combat perdu, réveil à lavender_center (r9.png). |
| 2F rival : reprise puis victoire, un seul Grand moment | NON TESTÉ | reprise après défaite non jouée ; victoire non obtenue (équipe 24/20 perdante, puis équipe forte : voir bug 1). Variante Salamèche N58 : combat enchaîné Noeunoeuf, Kadabra, Carabaffe, victoire sur 3, 4e (Pikachu N20 mal choisi) non terminé ; écran final sans plantage, mais Grand moment non constaté. |
| 2F Exorciste calme §15.4 | NON VÉRIFIÉ | présent sur la carte (w2.png), dialogue non lu. |
| 3F-6F rencontres SPECTRE | OK | « Un SPECTRE apparaît ! », « Nv. ?? », « Impossible d'identifier le SPECTRE... » (f3b, f5d, f5e), FUITE active au 3F/5F. |
| Exorcistes 3F-4F (voix d'esprit, combat, défaite) | NON TESTÉ | hors temps. |
| 5F zone purifiée | OK | entrée par la droite (zone en retrait) : scène tower_purified_zone, « Une lumière douce vous... », « Votre équipe est entièrement soi[gnée] » (z2.png). Soin chiffré non vérifié (équipe déjà pleine). |
| 5F Exorciste calme, objets visibles, cache (4,11) + EXAMINER | NON VÉRIFIÉ | exorcistes visibles sur f5b ; cache non testée ; objet visible (Poké Ball) au 6F. |
| 6F blocage SPECTRE | OK | §15.3.7 « ...Va-t'en... Intrus... », combat SPECTRE, FUITE possible, recul d'une case, « Quelque chose refuse qu'on... » (b1, b5). « Recommencer » non testé. |
| Corde Sortie depuis le 6F | OK | « Tu utilises la Corde Sortie. » -> lavender_town devant la Tour (e4.png). |
| Lavanville Maison des Pokémon | OK | homme (« Pas des visiteurs. Il est allé voir. Depuis... »), enfant (« Papy Fuji est monté à la Tour... »), fillette « Osselait attend sa maman. » ; Osselait non visible (h7.png). |
| Gentleman du Centre | OK (présence) | présent à côté du canapé (r9.png) ; dialogue non lu. |
| Panneau du Scope (42,11) | OK | « SCOPE SYLPHE - Voir ce que l'oeil ne voit pas » (s3.png), affiche lunettes à droite. |
| Reprise vraie partie | OK | « Ouverture : titre (sauvegarde VALID) », « Sauvegarde chargée : route_2 (24,10) », « sauvegarde v4 -> v7 », 0 ERROR, reprise exacte (Route 2, Kevin 22 h 14). |

## fps / température
Lavanville : 60 (min 60) draw 254-343. 1F : 60 (min 55-60) draw 50-74. 2F, 3F, 5F, 6F : 60 (quelques min 35-49 au chargement de carte / combat). Moyenne >= 58 partout. tex 64-84 Mo (Lavanville 84,2 Mo, au-dessus du budget 64 Mo des cartes J7 ; 1F 78-79). Température batterie 39,8 C au début, pic 44,2 C (Lavanville après ~10 min), 39,0 C à la fin.
## Lumière
Tour (2F-6F) lisible, assez sombre mais les murs sont distincts. Dalle purifiée 5F : blanche saturée (le carreau perd son relief), trop claire comme prévu ; contraste net avec l'étage.
## Bugs
1. ERREUR réelle (provoquée par mon départ de test) : avec Charizard (ou Blastoise) en tête, `rival_tower` : « TrainerLibrary : « rival_tower » n'a pas d'équipe contre « charizard » » puis « équipe adverse vide », combat refusé, retour au Centre (log 21:31:20). La table du rival n°5 n'a que les 3 starters (Bulbizarre, Salamèche, Carapuce) ; un Dresseur dont la première espèce est une évolution est donc hors table. Réaliste en vraie partie ? Le rival est choisi d'après le starter : voir si la clé utilise l'espèce de tête (au lieu du starter enregistré) : à confirmer par l'architecte.
2. Ergonomie : en vraie partie le choix du premier Pokémon (écran Équipe) fait toucher « Envoyer » ; RAS.
## Sauvegarde
Avant : save.json sha1 c0753e548be443bbf454f5c57698dc7f56c045e5 (5 765 o, 600), settings.json a1aa1b4c4c474ec52a8a30632095ce57d75d40ff (300 o, 600), pas de debug_start.json. Après la reprise, l'autosave du jeu avait écrit une v7 (sha f100b3eb...) ; restaurés à l'identique : sha1 c0753e54... et a1aa1b4c..., droits 600, debug_start.json supprimé. Copies dans backup/.
## Planche
build/qa/jalon19_t23/planche.png (8 captures : 1F dialogue, 2F rival, 3F SPECTRE, 5F, zone purifiée, 6F blocage, Maison des Pokémon, panneau Scope).
