---
name: ui-theme-2026
description: Système visuel de l'interface de Kanto 2026 (UI moderne non pixel art sur un monde 2D HD atmosphérique) — tokens de couleurs, typographie, formes, tailles tactiles, animations, et comment les implémenter en Theme Godot. À charger avant de créer ou modifier tout écran, HUD, menu, bouton ou boîte de dialogue.
---

# Thème UI 2026

Référence : `docs/design/reference/da-2026-planche-v1.webp` et `docs/design/ui-reference.md`. **Toujours regarder l'image** avant de faire un écran.

Principe : **le monde est en 2D HD atmosphérique (texture pixel art légère), l'UI n'est pas pixel art.** Panneaux sombres translucides, coins arrondis, typo sans-serif grasse, accent jaune doré, icônes vectorielles, animations courtes et fluides.

## Tokens

Implémentés dans `game/ui/theme/ui_tokens.gd` (`class_name UiTokens`, constantes) — **aucune couleur ou taille en dur ailleurs**.

| Token | Valeur | Usage |
|---|---|---|
| `PANEL_BG` | `Color(0.10, 0.14, 0.20, 0.82)` | fond des panneaux, cartes, boutons |
| `PANEL_BG_STRONG` | `Color(0.08, 0.11, 0.16, 0.92)` | menus plein écran |
| `PANEL_BORDER` | `Color(1, 1, 1, 0.14)` | bordure 2 px |
| `ACCENT` | `Color("#F5C542")` | sélection, action principale |
| `ACCENT_TEXT` | `Color("#1C1C1C")` | texte sur accent |
| `TEXT` | `Color("#FFFFFF")` | texte principal |
| `TEXT_MUTED` | `Color("#B8C4D6")` | secondaire (ID, région, PP) |
| `NAME_TAG` | `Color("#3E7BD6")` | étiquette de nom des dialogues |
| `DIALOG_BG` | `Color(0.97, 0.97, 0.99, 0.96)` | boîte de dialogue (claire) |
| `DIALOG_TEXT` | `Color("#1E2530")` | texte des dialogues |
| `HP_HIGH` / `HP_MID` / `HP_LOW` | `#4CD964` / `#F5C542` / `#FF5A4F` | barre PV > 50 % / > 20 % / ≤ 20 % |
| `SUCCESS` | `#4CD964` | ✓ sauvegarde |
| `RADIUS` / `RADIUS_SMALL` | 16 / 10 px | coins |
| `PAD` / `GAP` | 24 / 16 px | marges internes / espacement |
| `SAFE_MARGIN` | 48 px | marge de bord d'écran (encoche S24) |

Couleurs de types (badges, cartes de capacités) : Normal `#A8A77A`, Feu `#EE8130`, Eau `#6390F0`, Électrik `#F7D02C`, Plante `#7AC74C`, Glace `#96D9D6`, Combat `#C22E28`, Poison `#A33EA1`, Sol `#E2BF65`, Vol `#A98FF3`, Psy `#F95587`, Insecte `#A6B91A`, Roche `#B6A136`, Spectre `#735797`, Dragon `#6F35FC`.

Tailles en pixels de la **résolution de référence 1080 p de haut** :

| Texte | Taille | Graisse |
|---|---|---|
| Titre d'écran / nom de zone | 44 | Bold, MAJUSCULES |
| Bouton de combat / menu | 36 | Bold, MAJUSCULES |
| Corps / dialogue | 32 | Medium |
| Secondaire / légende | 24 | Medium |

## Typographie

Sans-serif moderne, grasse, légèrement condensée (cf. planche). Candidat : **Barlow / Barlow Semi Condensed** (Google Fonts, licence OFL) dans `assets/fonts/`. Tant que la police n'est pas ajoutée (téléchargement à valider avec Kevin), utiliser la police par défaut de Godot via le Theme — ne pas la référencer en dur. Anti-aliasing activé sur les polices : `ui_theme.tres` règle les polices en `antialiasing = GRAY` ; le filtre par défaut du projet est déjà `linear`.

## Formes et composants

- **Panneau** : `StyleBoxFlat` bg `PANEL_BG`, bordure 2 px `PANEL_BORDER`, coins `RADIUS`, ombre `Color(0,0,0,0.35)` taille 12.
- **Bouton** : état normal = panneau ; `hover/focus/pressed` = fond `ACCENT`, texte `ACCENT_TEXT`, légère mise à l'échelle 0,97 à l'appui. Icône à gauche du libellé.
- **Barre PV** : `ProgressBar` ou nœud dédié, hauteur 14 px, coins ronds, fond `Color(1,1,1,0.15)`, remplissage selon seuil ; valeur « 18 / 18 » en dessous alignée à droite. Variation animée (Tween 400 ms).
- **Bouton rond d'exploration** (menu, courir, parler) : cercle 128 px, fond `PANEL_BG`, icône blanche.
- **Joystick** : anneau 260 px + pastille 110 px, blanc à 35 % d'opacité ; apparaît où le pouce se pose dans la moitié gauche, s'estompe à 0 % au repos (fade 200 ms).
- **Titre de zone** : icône Poké Ball + NOM en 44 Bold + région en 24 `TEXT_MUTED`, en haut à gauche, apparaît en glissant (300 ms), reste 2,5 s, disparaît.

## Tactile

- Zone touchable minimale **128 px** de côté à la référence 1080 p (≈ 48 dp sur S24).
- Rien d'interactif à moins de `SAFE_MARGIN` des bords.
- Retour haptique court (`Input.vibrate_handheld(15)`) sur validation ; plus long sur impact en combat.

## Animations

- Durées : micro 120–180 ms, transitions de panneau 220–300 ms. `Tween` en `TRANS_CUBIC` / `EASE_OUT`.
- Panneaux : glissement 40 px + fondu. Jamais d'apparition sèche.
- Tout reste fluide à 60 fps (pas de shaders lourds plein écran sur l'UI).

## Implémentation Godot

- `game/ui/theme/ui_tokens.gd` — constantes.
- `game/ui/theme/ui_theme.tres` — Theme global (généré ou maintenu par `tools/build_ui_theme.gd` à partir des tokens), assigné dans `project.godot` (`gui/theme/custom`).
- Variations de type de thème (`theme_type_variation`) : `PanelCard`, `AccentButton`, `RoundButton`, `ZoneTitle`, `DialogBox`, `NameTag`.
- L'UI vit dans des `CanvasLayer` (HUD = layer 10, menus = 20, dialogues = 30, transitions = 100), jamais dans l'espace monde.
