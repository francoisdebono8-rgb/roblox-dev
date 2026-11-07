import sys,os,json,hashlib,xml.etree.ElementTree as ET,subprocess
OUT=os.path.expanduser('~/ndarch')
def blob(s):
    b=s.encode('utf-8'); return hashlib.sha1(b'blob %d\0'%len(b)+b).hexdigest()
want={ # place -> script names to extract (unique: not in git)
 'Documents/NinjaDuelVFX/ND-VFX-Lab.rbxlx':None, # all scripts (sandbox, no fingerprint)
 'Documents/NinjaDuelMedia/ND-Clips2.rbxlx':['PhotoLoad','PhotoMode'],
 'Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug-v3.rbxlx':['Effects','FamilyFX','UltimateFX'],
 'Downloads/NinjaDuel-5.rbxlx':['VelmoraMotionEngine'],
 'Downloads/NinjaDuel-Debug.rbxlx':['VelmoraMotionEngine'],
}
known=set(json.load(open(sys.argv[1]))) if len(sys.argv)>1 else set()
idx=[]
for place,names in want.items():
    root=ET.parse(place).getroot()
    def walk(node,chain):
        for it in node.findall('Item'):
            props=it.find('Properties');name=None;src=None
            if props is not None:
                for p in props:
                    if p.get('name')=='Name': name=p.text
                    elif p.get('name')=='Source': src=p.text or ''
            c=chain+[name or '?']
            if it.get('class') in ('Script','LocalScript','ModuleScript') and (names is None or name in names):
                b=blob(src or '')
                if b not in known:
                    d=os.path.join(OUT,'places-scripts',os.path.basename(place).replace('.rbxlx',''))
                    os.makedirs(d,exist_ok=True)
                    fn='.'.join(c)+'.'+it.get('class')+'.luau'
                    open(os.path.join(d,fn),'w',encoding='utf-8').write(src or '')
                    idx.append({'place':place,'path':'.'.join(c),'class':it.get('class'),'blob':b,'file':os.path.relpath(os.path.join(d,fn),OUT)})
            walk(it,c)
    walk(root,[])
json.dump(idx,open(os.path.join(OUT,'places-scripts','index.json'),'w'),indent=1)
print(len(idx)); [print(' ',x['file']) for x in idx]
