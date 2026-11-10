# Pokemake 0.36.1 — notes de version

Version **0.36.1** (code Android 3601), le 2026-11-10. Elle s'installe **par-dessus la 0.36.0** et
garde la partie en cours.

> Ne désinstalle pas le jeu pour faire la mise à jour : la sauvegarde partirait avec lui.

## Ce qui change pour toi

### Capacités de terrain (CS)

- **Coupe, Flash, Surf, Force et Vol demandent maintenant un Pokémon qui connaît vraiment
  l'attaque.** Avant, il suffisait qu'un Pokémon de l'équipe puisse l'apprendre. Si un arbuste, un
  rocher ou l'eau ne te laissent plus passer, apprends la CS à un Pokémon depuis le Sac.

### Combats

- **Toutes les attaques Électrik, Feu, Eau, Psy et Plante ont de nouveaux effets peints** : foudre,
  flammes, eau, ondes psy et végétal, plus lisibles et avec plus d'impact.
  - Gardent leur ancien effet : Bulles d'O ; Yoga, Dévorêve et Amnésie ; les trois poudres.
- **Paralysie** : un Pokémon paralysé perd un tour sur trois au lieu d'un sur quatre. Sa Vitesse
  est toujours divisée par deux.
- **Corrigé** : un Pokémon pouvait rester à moitié transparent après un petit coup, ou s'il était
  touché pendant son entrée.

### Sac

- **Corrigé** : si tu touches un autre objet pendant que le choix du Pokémon est ouvert, ce choix se
  referme. L'objet d'avant (CT, potion…) n'est plus utilisé à la place du nouveau.

### Costumes

- **Explorateur (Link / Zelda)** : les Pokémon rares apparaissent 1,5 fois plus souvent dans
  toutes les rencontres en marchant (hautes herbes, grottes, surf), et plus seulement dans les
  hautes herbes. La pêche ne change pas.

### Décors

- Les petites cartes en extérieur n'ont plus de bandes noires sur les côtés : la forêt, la ville ou
  le paysage continuent au-delà du bord (Route 2 est, Route 22…).
- Intérieurs mieux calés sur leurs peintures : on ne marche plus dans les meubles ni sous les
  comptoirs à Céladopole (hôtel, restaurant), au Labo de Cramois'Île, à Safrania, au poste de la
  Route 2 est, dans les Centres Pokémon et les Boutiques.
- Plus de faux paillasson sans sortie dans la chambre du Copieur et au Centre d'Oliville.

## Pour Kevin (technique)

| | |
|---|---|
| Depuis | RC 0.36.0, `88baadf8` |
| Construite depuis | `main` (le commit et la CI sont dans `manifest.json`) |
| Sauvegarde | aucun changement de format |
| Pas encore vu sur téléphone | effets refaits des attaques Électrik, Feu, Eau, Psy et Plante ; décor hors limites et intérieurs calés |

Paquet : `~/.pokemake/rc/0.36.1/` (APK, `manifest.json`, `SHA256SUMS`). Installation :
`docs/tech/release.md` §4.
