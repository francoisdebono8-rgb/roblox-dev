import sys, os, json, hashlib, xml.etree.ElementTree as ET
def blob(s):
    b=s.encode('utf-8'); return hashlib.sha1(b'blob %d\0'%len(b)+b).hexdigest()
out=[]
for path in sys.argv[1:]:
    rec={'path':path,'size':os.path.getsize(path),'mtime':os.path.getmtime(path)}
    h=hashlib.sha1()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1<<20),b''): h.update(chunk)
    rec['sha1']=h.hexdigest()
    try:
        root=ET.parse(path).getroot()
    except Exception as e:
        rec['error']=str(e); out.append(rec); continue
    scripts=[];fp=None;tops=[]
    def walk(node,chain):
        global fp
        for it in node.findall('Item'):
            props=it.find('Properties')
            name=None;src=None;val=None
            if props is not None:
                for p in props:
                    n=p.get('name')
                    if n=='Name': name=p.text
                    elif n=='Source': src=p.text or ''
                    elif n=='Value' and p.tag=='string': val=p.text
            c=chain+[name or '?']
            cls=it.get('class')
            if cls in ('Script','LocalScript','ModuleScript'):
                scripts.append({'path':'.'.join(c),'class':cls,'blob':blob(src or ''),'len':len(src or '')})
            if name=='BuildFingerprint': rec['fingerprint']=val
            walk(it,c)
    for it in root.findall('Item'):
        props=it.find('Properties'); nm=None
        if props is not None:
            for p in props:
                if p.get('name')=='Name': nm=p.text
        tops.append((it.get('class'),nm))
    walk(root,[])
    rec['scripts']=scripts; rec['services']=[c for c,_ in tops]
    out.append(rec)
json.dump(out,sys.stdout)
