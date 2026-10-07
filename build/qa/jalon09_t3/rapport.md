# J9 T3 — validation de la sauvegarde v4 sur le S24 (base j9-t3-qa = jalon-09 5f25495 + main J8/MM, sans poison)

**Verdict global : ✅ fusionnable** (sous réserve du constat « APK de référence » ci-dessous). Tests GUT 3046/3046 · import OK (0 erreur) · APK J9 75 Mo (sha 38189ed22729) · lancements sans crash (les lignes `AndroidRuntime` du logcat ne sont que l'outil `monkey`).

Partie de Kevin : relevée avant toute installation (v3, JSON valide), **restaurée à la fin**, reprise sur l'APK du J9. Jamais d'uninstall / pm clear.

## Étape 0 — APK v3 de référence : ⚠️ écart assumé
L'APK installé était le build « J8 T6 » (sha1 feb097451387…, = `worktrees/j8`), pas `main` ; il écrit la v3 (`VERSION = 3`). Il sert de référence : `kanto2026-v3.apk` (tiré du téléphone). Pas de reconstruction de `main`.

## Étape 1 — relevé + répétition Mac : ✅
- 1er relevé (route_22, 5048 o) conservé : `save_v3_kevin_avant_premier_releve.json`. Kevin a joué depuis : 2e relevé avant installation = **référence** `save_v3_kevin_avant.json` (version 3, route_2 (24,10), Rattata N4 / Salamèche N8 / Roucool N3, 3000 ₽, 5713 o). Copies scratchpad : `save_v3_kevin_avant_2.json`, `save_v4_kevin.json`, `save_v4_avant_v3.json`.
- Répétition Mac (1er relevé) : `Sauvegarde chargée…` puis **une** ligne `[qa] sauvegarde v3 → v4`, 0 erreur, comparaison IDENTIQUE (`mac_repetition.log`).
- Fixture ajoutée `tests/fixtures/save/v3_kevin_s24.json` (= 2e relevé) + test `test_the_s24_v3_save_of_kevin_is_migrated_to_v4_and_loads_with_no_status` (3046 verts).

## Étape 2 — migration sur le S24 : ✅
`tools/deploy_s24.sh --no-build` : `Sauvegarde chargée : route_2 (24, 10) (temps de jeu 80079 s)`, **exactement une** ligne `[qa] sauvegarde v3 → v4`, puis autosave OK. Capture `s2_reprise.png` : route_2, même case, joueur de dos/droite, entrée de la grotte et panneau, boutons menu et course présents. `save_v4_kevin_apres.json` : version 4, 3 Pokémon `status ""`, **IDENTIQUE** au script de la procédure. Fermeture forcée + relance : **aucune** ligne `[qa] sauvegarde` (`logcat_etape2b.txt`).

## Étape 3 — statut persistant : ✅
- `--debug-start save_v4_qa` : `Départ de débogage (…) : viridian_city/from_center, charmander N9 (poison), pidgey N7 (remplace la sauvegarde)` puis `Sauvegarde automatique (changement de carte) : viridian_city (21, 21), OK`. `save_qa_1.json` : party[0] poison (PV 27), party[1] "".
- Entrée / sortie du Centre sans parler à l'infirmière (`s3_dans_centre.png`, `s3_sorti.png`) : deux autosaves OK ; `save_qa_1b.json` : poison, PV 27.
- `deploy_s24.sh --no-build` (départ retiré) : `Sauvegarde chargée : viridian_city (21, 21)` + `[qa] statut relu : Salamèche (équipe 1) poison`. Fermeture forcée + relance : même ligne. `save_qa_2.json` : poison, PV 27 inchangés.
- Facultatif (soin au Centre) : non fait.

## Étape 4 — restauration : ✅
`save_v4_kevin.json` réécrit (cmp OK), relance : `Sauvegarde chargée : route_2 (24, 10) (temps de jeu 80079 s)`, aucune ligne `[qa]` ; capture identique à l'étape 2 (`s4_restauree.png`) ; fichier IDENTIQUE à la référence v3 par le script.

## Étape 5 — refus par la build v3 : ✅
`adb install -r -d kanto2026-v3.apk` puis lancement : `WARNING: SaveSystem : sauvegarde d'une version plus récente (4 > 3) : mise à jour du jeu requise` et `Boot : … Nouvelle partie SANS sauvegarde automatique : la sauvegarde existante …` (`extraits_etape5.txt`). Nouvelle partie dans la chambre ; menu ouvert (`s5_menu.png`), pas, changement de pièce (`player_house_1f`), mise en arrière-plan : aucun `Sauvegarde automatique`. `save_v4_apres_v3.json` : **identique octet pour octet** (`cmp`), aucun `.corrupt` (`ls files` : save.json, settings.json, shader_cache, vulkan). Écart de forme : le texte exact « Nouvelle partie SANS sauvegarde automatique » est dans le WARNING de Boot, pas dans une ligne `print`.

## Étape 6 — retour au J9 : ✅
`deploy_s24.sh --no-build` : `Sauvegarde chargée : route_2 (24, 10)`, aucune ligne `[qa]` ; capture `s6_retour_j9.png` identique à l'étape 2 ; `save_final.json` IDENTIQUE à la référence v3 (hors version/statuts/play_time). APK installé = APK J9 (sha 38189ed22729). Aucun `debug_start.json`.

## FPS (route_2, 10 s)
fps 58–59 stables, `min` 39–56 hors 1ère fenêtre (min=7 au chargement : 1ère fenêtre de 2 s seulement), draw ≈ 201, tex 72,4 Mo (> budget 64 Mo cité par le skill, constat J8, pas du J9).

## À vérifier par Kevin au doigt
Reprise de sa partie sur l'APK du J9 (route_2, équipe, Sac, Pokédex dans le menu).
