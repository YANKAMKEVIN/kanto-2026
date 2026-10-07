import json,sys
a=json.load(open(sys.argv[1]));b=json.load(open(sys.argv[2]))
[m.pop('status') for k in ('party','storage') for m in b[k]]
for d in (a,b):
    for k in ('version','play_time'): d.pop(k)
print('IDENTIQUE' if a==b else 'DIFF')
if a!=b:
    for k in set(a)|set(b):
        if a.get(k)!=b.get(k): print(k,a.get(k),b.get(k))
