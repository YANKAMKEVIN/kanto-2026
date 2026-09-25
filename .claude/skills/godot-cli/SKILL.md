---
name: godot-cli
description: Piloter Godot 4.7 en ligne de commande dans Kanto 2026 — réimporter et détecter les erreurs de scripts, lancer les tests GUT, exécuter un script d'outil, lancer une scène, et faire des captures d'écran sur le Mac via Movie Maker. À charger pour vérifier son travail sans ouvrir l'éditeur.
---

# Godot en ligne de commande

Binaire : `godot` (Homebrew, 4.7.2). Toujours depuis la racine du projet, avec `--path .`.

**Piège** : ne jamais laisser une commande lire stdin (`cat > f` sans heredoc) — la session se bloque.

## 1. Réimporter / détecter les erreurs

```bash
godot --headless --path . --import 2>&1 | grep -E "ERROR|SCRIPT ERROR|Parse Error|WARNING" || echo "import OK"
```
À faire après toute création/modif de script, scène, ressource ou asset. Une erreur de parsing GDScript apparaît ici.

## 2. Tests

```bash
tools/test.sh                      # tout tests/
tools/test.sh res://tests/unit     # un dossier
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_grid.gd -gexit
```
Résultat attendu en fin de sortie : `---- All tests passed! ----`. Code retour ≠ 0 en cas d'échec.

## 3. Script d'outil (génération, vérification)

```gdscript
# tools/mon_outil.gd
extends SceneTree
func _init() -> void:
	# … travail …
	quit()
```
```bash
godot --headless --path . -s res://tools/mon_outil.gd
```
`tools/` contient un `.gdignore` : **les scripts d'outil n'y sont pas importés**, c'est voulu (ils ne partent pas dans l'APK). Ils ne peuvent donc pas utiliser les `class_name` de `game/` via le cache global avant import ; utiliser `load("res://game/…")` explicitement.

Pour sauver une scène construite en code :
```gdscript
var packed := PackedScene.new()
packed.pack(root)          # les enfants doivent avoir owner = root
ResourceSaver.save(packed, "res://game/world/maps/pallet_town.tscn")
```

## 4. Lancer une scène quelques frames (smoke test logique)

```bash
godot --headless --path . --quit-after 120 res://game/world/maps/pallet_town.tscn 2>&1 | grep -E "ERROR|SCRIPT ERROR" || echo "run OK"
```

## 5. Capture d'écran sur le Mac (rendu réel, sans téléphone)

Movie Maker écrit une image PNG par frame :
```bash
rm -rf build/cap && mkdir -p build/cap
godot --path . --resolution 1170x540 --write-movie build/cap/frame.png --fixed-fps 60 --quit-after 30 res://game/boot.tscn
# → build/cap/frame00000029.png = dernière frame
```
- `1170x540` = moitié du S24 (2340×1080), même ratio 19,5:9. Utiliser `2340x1080` pour vérifier la netteté des sprites.
- Pas en `--headless` (il faut un rendu). Une fenêtre s'ouvre brièvement : normal.
- Lire ensuite l'image avec l'outil Read pour la vérifier visuellement.
- Pour simuler des entrées pendant une capture, écrire une petite scène de test qui injecte `Input.action_press(&"move_right")` ou des `InputEventScreenTouch` depuis son `_ready`.

## 6. Export Android

Voir skill `android-deploy` (`tools/build_android.sh`, `tools/deploy_s24.sh`).
