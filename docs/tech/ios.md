# Portage iOS

Kanto 2026 vise Android (S24) ; iOS est une **seconde cible** pour le cercle restreint de proches
(décision de diffusion du 2026-10-24). Le projet étant en pur GDScript, sans extension native ni
plugin Android, le portage tient à l'export, à la signature et à la zone sûre de l'écran.

## 1. Chaîne de production

| Étape | Outil | Résultat |
|---|---|---|
| Export | preset `iOS` de `export_presets.cfg` | `build/ios/kanto2026.xcodeproj` (+ `.pck`, xcframeworks) |
| Compilation simulateur | `tools/build_ios.sh` | `build/ios/derived/Build/Products/Debug-iphonesimulator/kanto2026.app` (x86_64, sans signature) |
| Lancement simulateur | `tools/build_ios.sh --run` | installe et lance sur `KANTO_IOS_SIM` (défaut « iPhone 16 Pro », runtime iOS 18) |
| Compilation iPhone | `KANTO_IOS_TEAM=XXXXXXXXXX tools/build_ios.sh --device` | `.../Debug-iphoneos/kanto2026.app` signée (provisioning automatique) |

Préalables sur le Mac : Xcode (26.6 au 2026-11-03), les modèles d'export Godot 4.7.2 (`ios.zip`,
déjà installés), Rosetta pour le simulateur.

### Pourquoi x86_64 et un runtime iOS 18 dans le simulateur

Les modèles d'export officiels de Godot 4.7 ne livrent qu'une tranche **x86_64** pour le
simulateur (pas d'arm64-simulator). L'app simulateur tourne donc sous Rosetta, ce que seuls les
runtimes **iOS 18.x** acceptent (les runtimes iOS 26 l'ont abandonné). Dans le simulateur Godot
bascule sur **OpenGL ES 3** (« Setting up an OpenGL ES 3.0 context ») : rendu lent, premier
lancement long (≈ 1 min 30 avant l'écran titre). Le simulateur sert à vérifier le fonctionnel et la
zone sûre, jamais les performances ; sur un vrai iPhone, le moteur de rendu `mobile` tourne sur Metal.

### Identifiant d'équipe

Le preset garde un identifiant d'équipe factice (`XXXXXXXXXX`) parce que Godot refuse d'exporter
sans. Le vrai identifiant (10 caractères, page « Membership » du compte développeur Apple) est
passé par `KANTO_IOS_TEAM` au moment de la compilation pour iPhone ; il n'est jamais commité.

## 2. Zone sûre (encoche, Dynamic Island, barre d'accueil)

En paysage, l'encoche prend ≈ 59 pt d'un bord court et la barre d'accueil ≈ 21 pt en bas (× 3 en
pixels, puis × rapport canevas ≈ 0,9) : ≈ 160 px de canevas d'un côté, ≈ 56 px en bas. Le S24 n'a
qu'une perforation centrée, d'où des retraits nuls jusqu'ici.

- `game/ui/components/safe_area.gd` (`SafeArea`) : conversion des retraits en unités de canevas
  (`insets_for`, pure et testée dans `tests/unit/test_safe_area.gd`), lecture du moteur (`current`),
  application à un Control plein écran avec compensation des enfants qui doivent couvrir toute la
  fenêtre (`apply`).
- Appliqué au **HUD d'exploration** (`exploration_hud.gd`) : racine rentrée, éclair plein écran
  compensé, recalcul au changement de taille de fenêtre et au retour au premier plan.
- **À faire sur un vrai iPhone** (reportés) : combat (`BATTLE_EDGE = SAFE_MARGIN = 48 px`, cartes de
  PV aux coins), Menu Dresseur, boîtes de dialogue (`DIALOG_BOTTOM_MARGIN = 48 px`, sous la barre
  d'accueil), écran titre. Même recette : `SafeArea.apply` sur la racine de l'écran.

## 3. Distribution aux proches

| Option | Coût | Limites |
|---|---|---|
| Apple ID gratuit + câble | 0 | l'iPhone de Kevin seul, l'app expire au bout de 7 jours |
| Programme développeur + **TestFlight interne** | 99 €/an | jusqu'à 100 testeurs ajoutés à l'équipe App Store Connect, **sans relecture Apple**, build valable 90 jours |
| Programme développeur + Ad Hoc | 99 €/an | 100 appareils par an (UDID), fichier `.ipa` |

Recommandation : TestFlight en testeurs **internes** (invitation par e-mail, app TestFlight). Pas de
testeurs externes : ils passent par la Beta App Review, qu'un fan game Pokémon ne franchirait pas.
Le jeu reste hors App Store (diffusion restreinte).

## 4. État au 2026-11-03

- Preset, icône 1024 px (`assets/ui/icon/icon_ios_1024.png`, composée des calques de l'icône
  adaptative Android), script, zone sûre du HUD : faits.
- Vérifié dans le simulateur iPhone 16 Pro (iOS 18.6) : écran titre en paysage, toucher pris en
  compte (fondu vers la nouvelle partie).
- Non vérifié : vrai iPhone (signature, Metal, performances, haptique), écrans autres que le HUD
  face à l'encoche, durée de chargement du `.pck` (625 Mo : il embarque `addons/gut` et `tests/`
  comme l'APK, voir les reportés).
