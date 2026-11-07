"""Rangement non destructif Ninja Duel (issue #45). Déplacements (renommages) à
l'intérieur de ~/Documents uniquement, liens de compatibilité aux anciens
chemins de dossiers, journal moves.tsv et script restaurer.sh. Aucune suppression.
usage: python3 reorg.py [--go]"""
import os,sys,time,glob,stat
GO='--go' in sys.argv
D=os.path.expanduser('~/mnt/Documents')
ND='NinjaDuel'
ts=time.strftime('%Y-%m-%d %H:%M:%S')
dirs=[ND,f'{ND}/PLACES',f'{ND}/LAB',f'{ND}/ARCHIVES',f'{ND}/ARCHIVES/places',f'{ND}/ARCHIVES/places/jeu-release',
      f'{ND}/ARCHIVES/places/labo-qa',f'{ND}/ARCHIVES/places/test-debug',f'{ND}/ARCHIVES/places/clips',
      f'{ND}/ARCHIVES/media',f'{ND}/ARCHIVES/git',f'{ND}/ARCHIVES/telechargements',f'{ND}/_maintenance',
      f'{ND}/_maintenance/verrous-studio-perimes',f'{ND}/_outils']
# (source, destination, lien de compatibilité à l'ancien chemin ?)
plan=[('NinjaDuelMedia',f'{ND}/MEDIA',True),('NinjaDuelBlender',f'{ND}/BLENDER',True),
      ('NDLooks',f'{ND}/BLENDER/NDLooks',True),('NinjaDuelVFX',f'{ND}/LAB/VFX',True),
      ('Roblox/repro',f'{ND}/LAB/repro',True)]
fam={'ND-Jeu':'jeu-release','ND-Labo':'labo-qa','ND-Test':'test-debug'}
for p in sorted(glob.glob(os.path.join(D,'Roblox','ND-*.rbxlx'))):
    n=os.path.basename(p)
    if n=='ND-Test-Sharingan.rbxlx': continue        # fichier actif d'une autre discussion
    f=next(v for k,v in fam.items() if n==k+'.rbxlx' or n.startswith(k+'-'))
    plan.append((f'Roblox/{n}',f'{ND}/ARCHIVES/places/{f}/{n}',False))
for n in ('ND-Jeu-v30.rbxlx.lock','ND-Labo.rbxlx.lock'):
    plan.append((f'Roblox/{n}',f'{ND}/_maintenance/verrous-studio-perimes/{n}',False))
plan+=[(f'{ND}/MEDIA/JUTSU_PASS',f'{ND}/ARCHIVES/places/jutsu-pass',False)]
for n in ('ND-Clips-v32.rbxlx','ND-Clips-v39.rbxlx','ND-Clips2.rbxlx'):
    plan.append((f'{ND}/MEDIA/{n}',f'{ND}/ARCHIVES/places/clips/{n}',False))
plan+=[(f'{ND}/LAB/VFX/ND-VFX-Lab.rbxlx.lock',f'{ND}/_maintenance/verrous-studio-perimes/ND-VFX-Lab.rbxlx.lock',False),
       ('Roblox/showcase itachi.MP4',f'{ND}/ARCHIVES/media/showcase itachi.MP4',False),
       ('Roblox/ninja-duel-roster.bundle',f'{ND}/ARCHIVES/git/ninja-duel-roster.bundle',False),
       ('.nd_probe',f'{ND}/_maintenance/sondes-2026-11-07',False)]
def A(r): return os.path.join(D,r)
problems=[]
for s,d,_ in plan:
    # the source may live under a folder moved earlier in the plan
    if not os.path.lexists(A(s)) and not any(s.startswith(x[1]+'/') for x in plan): problems.append('absent: '+s)
    if os.path.lexists(A(d)): problems.append('existe déjà: '+d)
print(len(plan),'déplacements;',len(problems),'problèmes'); [print('  !',p) for p in problems]
if not GO:
    for s,d,l in plan: print(f'  {s}  ->  {d}'+('   [+lien]' if l else ''))
    sys.exit(0)
if problems: sys.exit('arrêt: problèmes')
for x in dirs: os.makedirs(A(x),exist_ok=True)
log=open(A(f'{ND}/_maintenance/moves.tsv'),'a',encoding='utf-8')
undo=[]
for s,d,link in plan:
    os.rename(A(s),A(d))
    log.write(f'{ts}\tMOVE\t{s}\t{d}\n'); undo.append(f'mv "$D/{d}" "$D/{s}"')
    if link:
        rel=os.path.relpath(A(d),os.path.dirname(A(s)))
        os.symlink(rel,A(s)); log.write(f'{ts}\tLINK\t{s}\t-> {rel}\n'); undo.append(f'rm "$D/{s}"   # lien de compatibilité')
    print('ok',s,'->',d)
log.close()
with open(A(f'{ND}/_maintenance/restaurer.sh'),'w',encoding='utf-8') as f:
    f.write('#!/bin/bash\n# Remet chaque élément à son ancien chemin (ordre inverse du rangement du '+ts+' UTC).\n')
    f.write('# Dans un Terminal macOS : bash ~/Documents/NinjaDuel/_maintenance/restaurer.sh\nset -e\nD="$HOME/Documents"; [ -d "$HOME/mnt/Documents" ] && D="$HOME/mnt/Documents"\n')
    for u in reversed(undo):
        if u.startswith('rm'): f.write(u+'\n')
        else: f.write(u+'\n')
    f.write('echo "Restauration terminée (les copies, PLACES/ et ce dossier _maintenance ne sont pas retirés)."\n')
print('fait')
