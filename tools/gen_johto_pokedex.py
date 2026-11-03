#!/usr/bin/env python3
"""Génère data/pokedex/johto.json (JOH0 T6) : taille et poids (PokeAPI) + descriptions françaises originales
écrites ici. Usage : python3 -I tools/gen_johto_pokedex.py <dossier_pokeapi> (contient pokemon/<n>.json)."""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (numéro, identifiant, description)
ENTRIES = [
    (152, "chikorita", "La feuille sur sa tête sent bon l'herbe fraîche. Il s'en sert pour tâter l'air et deviner l'humeur de ceux qu'il croise."),
    (153, "bayleef", "Le collier de bourgeons autour de son cou diffuse un parfum qui apaise. Il aime marcher en tête, le museau levé vers le soleil."),
    (154, "meganium", "Là où il passe, les fleurs s'ouvrent comme au printemps. Son souffle suffit à redonner des couleurs à une plante qui se fane."),
    (155, "cyndaquil", "Frileux et timide, il s'enroule sur lui-même. Quand il a peur, les flammes de son dos jaillissent d'un coup."),
    (156, "quilava", "Les flammes de son dos ondulent au rythme de sa respiration. Il les attise doucement quand il se prépare à bondir."),
    (157, "typhlosion", "Il se tient immobile, puis tout son dos s'embrase dans un grondement. L'air autour de lui tremble comme au-dessus d'un brasier."),
    (158, "totodile", "Ses mâchoires se referment sur tout ce qui bouge, même une branche. Il est tout fier de ses petites dents."),
    (159, "croconaw", "Il perd une dent et la voit repousser aussitôt. Quand il ouvre grand la gueule, mieux vaut garder ses distances."),
    (160, "feraligatr", "Il file dans l'eau en un éclair, la gueule grande ouverte. Tout son corps ne fait qu'une immense mâchoire."),
    (161, "sentret", "Il se dresse sur sa queue pour guetter les alentours. À la moindre alerte, il file se cacher dans son terrier."),
    (162, "furret", "Son corps long et souple se glisse dans les trous les plus étroits. Il garde son nid bien rangé et le défend avec courage."),
    (163, "hoothoot", "Il sait toujours l'heure, même sans horloge. Au moment précis où le soleil se couche, il se met à hululer."),
    (164, "noctowl", "Ses yeux percent la nuit la plus noire. Il tourne la tête dans tous les sens sans jamais quitter sa proie du regard."),
    (169, "crobat", "Quatre ailes lui permettent de voler sans un bruit. Il frôle les arbres de la forêt avant que personne ne l'entende."),
    (175, "togepi", "Sa coquille semble garder la joie de ceux qui l'entourent. Il se blottit contre ceux qui sourient."),
    (176, "togetic", "On le dit porteur de bonheur pour ceux qui sont gentils. Il s'éloigne dès qu'on se dispute près de lui."),
    (179, "mareep", "Sa laine crépite quand l'air est sec. Une caresse à rebrousse-poil, et c'est l'étincelle assurée."),
    (180, "flaaffy", "Sa laine s'est raréfiée là où l'électricité s'accumule, laissant la peau à nu. Le bout de sa queue brille doucement."),
    (181, "ampharos", "La boule au bout de sa queue brille d'une lumière qu'on voit de très loin. Autrefois, elle guidait les bateaux dans la nuit."),
    (183, "marill", "Sa queue ronde flotte comme une bouée et lui permet de rester à la surface. Il l'agite pour appeler ses amis."),
    (184, "azumarill", "Ses grandes oreilles captent le moindre remous. Au fond de la rivière, il entend tout ce qui s'approche."),
    (186, "politoed", "Il pousse un cri sonore et les Têtarte accourent. Chacun veut se placer près de lui."),
    (196, "espeon", "Son poil fin sent la moindre variation de l'air. Il a une longueur d'avance sur ceux qui veulent l'attraper."),
    (197, "umbreon", "Les cercles de son pelage brillent dans l'obscurité. Il se tapit dans l'ombre et attend, les yeux grands ouverts."),
    (198, "murkrow", "On dit qu'il porte malheur à ceux qui le croisent la nuit. Il ramasse tout ce qui brille et le cache dans son nid."),
    (199, "slowking", "Un jour, une idée a traversé sa tête endormie. Depuis, il semble tout comprendre, sans rien dire."),
    (202, "wobbuffet", "Il déteste qu'on l'éclaire et se cache toujours dans l'ombre. Il reste immobile et encaisse, avant de répliquer d'un coup."),
    (208, "steelix", "Il creuse sous les montagnes en faisant grincer tout son corps. Plus il vieillit, plus son métal prend un éclat sombre."),
    (212, "scizor", "Ses pinces d'acier ont la dureté d'une enclume. Il bat des ailes à toute vitesse pour réchauffer son corps de métal."),
    (214, "heracross", "Il plante sa grande corne sous un tronc et le soulève sans effort. Il adore la sève des arbres."),
    (215, "sneasel", "Il se faufile dans l'ombre et frappe de ses griffes acérées. Les plumes qu'il laisse derrière lui sont ses seules traces."),
    (216, "teddiursa", "Il lèche sa patte à la moindre occasion, car elle sent le miel. Son air câlin cache un grand appétit."),
    (217, "ursaring", "Il parcourt les montagnes pour trouver le meilleur miel. Il possède un odorat si fin qu'il retrouve sa route les yeux fermés."),
    (227, "skarmory", "Il vit sur les montagnes et façonne son nid avec des branches. Ses ailes d'acier lui coûtent la plus petite plume."),
    (228, "houndour", "Il communique avec ses compagnons par de petits hurlements. Il s'approche toujours en groupe, par surprise."),
    (229, "houndoom", "Son hurlement résonne longtemps entre les collines. Les anciens disent que ses flammes ne s'éteignent qu'à l'aube."),
    (230, "kingdra", "Il se cache au fond de la mer et ne remonte qu'avec les grands tourbillons. Sa nageoire lui sert de gouvernail."),
    (231, "phanpy", "Il utilise sa trompe pour s'arroser et prendre un bain de boue. Il se roule souvent en boule pour se reposer."),
    (232, "donphan", "Il roule comme une boule de démolition pour détruire des murs. Ses défenses sont si dures que rien n'y laisse de trace."),
    (233, "porygon2", "Un Pokémon artificiel perfectionné. Il apprend très vite, et paraît toujours un peu étonné par le monde."),
    (241, "miltank", "Son lait est réputé pour son goût délicieux. Quand l'un d'eux vient à manquer, on peut en soigner un autre avec."),
    (242, "blissey", "Elle offre un œuf tout chaud à qui a le moral bas. Son attention touche ceux qui l'entourent."),
    (243, "raikou", "Un orage le suit partout où il va. On ne le voit qu'une fraction de seconde, entre deux éclairs."),
    (244, "entei", "Il traverse les plaines en laissant une traînée de chaleur. Les gens de Johto disent que sa course réveille les volcans endormis."),
    (245, "suicune", "Il avance sans bruit au-dessus des lacs. L'eau devient limpide sur son passage, comme si elle se rappelait la source."),
    (246, "larvitar", "Il ne grandit qu'en avalant de la terre et de la roche. Il lui faut des années pour sortir de la montagne."),
    (247, "pupitar", "Enfermé dans sa coque, il attend en silence. Un coup sec ne laisse même pas une marque."),
    (248, "tyranitar", "Son corps cuirassé résiste à presque tout. Un coup de sa queue suffit à fendre un rocher."),
    (249, "lugia", "Il se tient loin des hommes, dans les profondeurs de la mer. Ses ailes déplacent l'air avec une telle puissance que les vagues se lèvent."),
    (250, "ho_oh", "Son plumage change de couleur à chaque battement d'aile. On raconte qu'il ne se montre qu'à ceux qui ont le cœur pur."),
    (251, "celebi", "Il n'apparaît que dans les forêts les plus calmes. On raconte qu'il vient d'un autre temps, et que les arbres savent pourquoi."),
]
WANTED = [
    "chikorita", "bayleef", "meganium", "cyndaquil", "quilava", "typhlosion", "totodile", "croconaw",
    "feraligatr", "sentret", "furret", "hoothoot", "noctowl", "mareep", "flaaffy", "ampharos", "marill",
    "azumarill", "togepi", "togetic", "espeon", "umbreon", "slowking", "steelix", "scizor", "heracross",
    "sneasel", "teddiursa", "ursaring", "phanpy", "donphan", "porygon2", "murkrow", "houndour", "houndoom",
    "wobbuffet", "kingdra", "politoed", "blissey", "crobat", "larvitar", "pupitar", "tyranitar", "skarmory",
    "miltank", "raikou", "entei", "suicune", "lugia", "ho_oh", "celebi",
]


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    folder = sys.argv[1]
    by_id = {sid: (dex, text) for dex, sid, text in ENTRIES}
    lines = []
    for sid in WANTED:
        dex, text = by_id[sid]
        with open(os.path.join(folder, "pokemon", "%d.json" % dex), encoding="utf-8") as handle:
            api = json.load(handle)
        lines.append('\t\t"%s": {"height": %s, "weight": %s, "description": %s, "draft": true}' % (
            sid, repr(api["height"] / 10), repr(api["weight"] / 10), json.dumps(text, ensure_ascii=False)))
    out = '{\n\t"size": %d,\n\t"species": {\n%s\n\t}\n}\n' % (len(WANTED), ",\n".join(lines))
    with open(os.path.join(ROOT, "data", "pokedex", "johto.json"), "w", encoding="utf-8") as handle:
        handle.write(out)
    print(len(WANTED), "fiches écrites")


if __name__ == "__main__":
    main()
