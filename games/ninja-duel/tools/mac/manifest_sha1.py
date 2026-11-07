import os,sys,hashlib,time,json
# usage: manifest.py OUT.tsv root1 root2 ...   (resumable: skips paths already in OUT)
out=sys.argv[1]; roots=sys.argv[2:]
done=set()
if os.path.exists(out):
    for line in open(out,encoding='utf-8'):
        done.add(line.split('\t',1)[0])
t0=time.time(); n=0; b=0
with open(out,'a',encoding='utf-8') as fh:
    for r in roots:
        items=[r] if os.path.isfile(r) or os.path.islink(r) else None
        walk=[(r,[],[])] if items else os.walk(r)
        for dp,dn,fn in (walk if not items else []):
            dn.sort()
            for f in sorted(fn):
                p=os.path.join(dp,f)
                if p in done: continue
                if os.path.islink(p):
                    fh.write(f"{p}\tLINK\t\t{os.readlink(p)}\n"); continue
                st=os.stat(p); h=hashlib.sha1()
                with open(p,'rb') as x:
                    for c in iter(lambda:x.read(1<<22),b''): h.update(c)
                fh.write(f"{p}\t{st.st_size}\t{int(st.st_mtime)}\t{h.hexdigest()}\n"); n+=1; b+=st.st_size
                if time.time()-t0>150: fh.flush(); print('PARTIAL',n,b/1e9); sys.exit(3)
        if items:
            p=r
            if p not in done and not os.path.islink(p):
                st=os.stat(p); h=hashlib.sha1(open(p,'rb').read()); fh.write(f"{p}\t{st.st_size}\t{int(st.st_mtime)}\t{h.hexdigest()}\n"); n+=1; b+=st.st_size
print('DONE',n,b/1e9,round(time.time()-t0,1))
