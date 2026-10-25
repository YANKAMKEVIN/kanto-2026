# Dos en plongée (cadrage B) : planche validée et 8 dos à faire avec ChatGPT

> 2026-10-25, DAF.1. Outil `tools/art/serie_dos_rb.py`, prompts `tools/art/prompts/serie_dos_rb/`.
> Branche `art-dos-rb` : les 62 dos sont intégrés (`assets/sprites/pokemon/dos/dos_rb_NNN.png`) et
> lus par le jeu, tests ciblés verts ; **pas encore dans `main`** (attend la validation de la planche,
> arbitrage DA-6).

## 1. Planche

**Validée par Kevin le 2026-10-25** : « Je valide la planche ; refais Porygon et M. Mime, garde
Ronflex ». Porygon refait en r5 (blocs lisses, sans éclats), M. Mime en r7 (2e révision : r4 à r6
refusés) ; planche mise à jour.

`planche-dos-rb-62.webp` (face officielle | dos en plongée) ; captures en jeu (2340 × 1080) de
Machopeur, Ronflex, Krabby, Léviator, Artikodin et Tentacruel relues : coupe nette au bord bas,
sous la carte adverse, hors des commandes.

Points à juger (proposition entre crochets) :
- **Porygon** : éclats cristallins, peu fidèle [refaire en r4, sujet plus précis] ;
- **M. Mime** : chevelure bleue hérissée trop marquée [refaire] ;
- **Ronflex** : fourrure peinte, style un peu à part des autres [garder ou refaire] ;
- **Staross** : une seule étoile visible, sans joyau [garder : de dos, normal] ;
- **Kangourex** : dos de dinosaure à crête [garder].

## 2. Huit dos refusés par Codex sur les trois essais

Tortank (9), Rondoudou (39), Kadabra (64), Alakazam (65), Ossatueur (105), Lokhlass (131),
Mew (151), Voltali (135). Dans l'app ChatGPT : coller `tools/art/prompts/serie_dos_rb/DOSRB_<IDENT>_r1.txt`
**avec** l'artwork joint (`assets/sprites/pokemon/official/NNN.png`) ; en cas de refus, `_r2.txt`
sans image. Puis :

```bash
tools/art/serie_dos_rb.py --ajouter TORTANK ~/Downloads/image.png
```

(prépare, intègre dans `assets/sprites/pokemon/dos/` et refait la planche ; importer ensuite en
headless). Ces 8 espèces gardent en attendant leur dos actuel (provisoire, recadré en B).

## 3. Suite

Les 81 dos « corps entier » de `main` restent recadrés par le code ; ceux qui rendent mal seront
refaits en plongée au fil des lots (décision de Kevin). Premier candidat vu aux captures :
**Salamèche** (de profil, la flamme de la queue paraît détachée en bas à gauche).
