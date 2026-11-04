import json,sys
d=json.load(open(sys.argv[1]))
p=d["party"]
print("version",d["version"],"| joueur",d.get("player_name"),"| rival",d.get("rival_name"),"| carte",d["map"],d["cell"],"face",d.get("facing"))
print("argent",d["money"],"| temps",round(d["play_time"]),"s | starter",d.get("starter"),"| compagnon",repr(d.get("companion")))
print("équipe",[(m.get("species"),m.get("level"),m.get("hp")) for m in p])
print("sac items",d["bag"]["items"],"acquis",d["bag"]["acquired"],"favoris",d["bag"].get("favorites"))
e=d["pokedex"]["entries"]; print("pokédex",len(e),"entrées, capturés",sum(1 for v in e.values() if v.get("caught")))
print("drapeaux",len(d["flags"]),sorted(d["flags"])[:50])
print("cartes découvertes",len(d["discovered_maps"]),"| moments",len(d["moments"]),"| objets trouvés",len(d["found_items"]),"| stockage",len(d["storage"]))
print("clés",sorted(d.keys()))
