#!/usr/bin/env python3
"""Read-only extraction of USM's fixed records; never executes Windows code."""
from pathlib import Path
import datetime
import argparse, hashlib, json, struct, zlib, shutil, subprocess
from collections import Counter
ROOT=Path(__file__).resolve().parents[1]
def birth_date(r):
 try:
  d=datetime.date(1900+r[31],r[30]+1,r[29]+1)
  return dict(birthYear=d.year,birthMonth=d.month,birthDay=d.day) if 1940<=d.year<=1984 else {}
 except ValueError: return dict(birthYear=1900+r[31]) if 40<=r[31]<=84 else dict(birthYear=None)
def text(b): return b.split(b'\0')[0].decode('cp1252',errors='replace').strip()
def png(path,w,h,rgb):
 def chunk(k,v): return struct.pack('>I',len(v))+k+v+struct.pack('>I',zlib.crc32(k+v)&0xffffffff)
 raw=b''.join(b'\0'+rgb[y*w*3:(y+1)*w*3] for y in range(h))
 path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
def main():
 ap=argparse.ArgumentParser()
 ap.add_argument('--source',type=Path,default=ROOT/'OriginalCD',help='Original CD used for the non-database assets.')
 ap.add_argument('--database-source',type=Path,default=ROOT/'MegaUpdate',help='Folder containing the roster TEAM*.DAT and PLAYER*.DAT files.')
 ap.add_argument('--dataset-label',default='Mega Update 1.2 • squads through 31 Jan 2001',help='Human-readable name stored in the generated database.')
 ap.add_argument('--output',type=Path,default=ROOT/'Sources/USMApp/Resources')
 a=ap.parse_args();a.output.mkdir(parents=True,exist_ok=True)
 original_root=a.source
 cab=a.source/'data1.cab'
 if cab.exists():
  unpacked=ROOT/'.work/original-cd'
  if not shutil.which('unshield'): raise SystemExit('Install unshield (brew install unshield) to read the original CD cabinet.')
  subprocess.run(['unshield','-d',str(unpacked),'x',str(cab)],check=True,stdout=subprocess.DEVNULL)
  a.source=unpacked/'Executable-English'
 def locate(root,relative):
  current=root
  for component in relative.split('/'):
   current=next((f for f in current.iterdir() if f.name.lower()==component.lower()),current/component)
  return current
 database_root=a.database_source
 if not database_root.exists(): raise SystemExit(f'Database source does not exist: {database_root}')
 clubs=[];players=[];rejected=Counter()
 for code,country in [('N','England'),('S','Scotland'),('F','France'),('G','Germany'),('I','Italy'),('P','Spain'),('D','Netherlands')]:
  team_path=locate(database_root,f'TEAM{code}.DAT');player_path=locate(database_root,f'PLAYER{code}.DAT')
  tb=team_path.read_bytes();pb=player_path.read_bytes()
  assert len(tb)%671==0 and len(pb)%187==0
  local={}
  for i in range(len(tb)//671):
   r=tb[i*671:(i+1)*671];name=text(r[:26])
   if not name or r[189]>5: rejected['club_empty_or_invalid']+=1;continue
   c=dict(id=f'{code}-{i}',name=name,manager=text(r[26:52]),nickname=text(r[52:78]),stadium=text(r[78:104]),country=country,division=r[189],source=f'MegaUpdate/TEAM{code}.DAT',offset=i*671)
   local[i]=c
  for i in range(len(pb)//187):
   r=pb[i*187:(i+1)*187];first=text(r[:14]);last=text(r[14:29]);club=struct.unpack_from('<H',r,33)[0]
   if not first or not last or club not in local:rejected['player_empty_or_unassigned']+=1;continue
   stats=[r[j] for j in [144,145,146,147,148,150,151,152,153]]
   if max(stats)>100 or max(stats)<10:rejected['player_invalid_skills']+=1;continue
   # Position reconstructed from skill profile; original position flags not yet verified.
   pos='GK' if stats[0]>max(stats[1],stats[2],stats[3]) else ('DEF' if stats[1]>max(stats[2],stats[3]) else ('MID' if stats[2]>=stats[3] else 'FWD'))
   players.append(dict(id=f'{code}-p{i}',name=f'{first} {last}',clubID=local[club]['id'],position=pos,skills=stats,source=f'MegaUpdate/PLAYER{code}.DAT',offset=i*187,**birth_date(r)))
  counts=Counter(p['clubID'] for p in players)
  clubs.extend(c for c in local.values() if counts[c['id']]>=11)
 ids={c['id'] for c in clubs};players=[p for p in players if p['clubID'] in ids]
 db=dict(schemaVersion=1,dataset=a.dataset_label,clubs=clubs,players=players)
 (a.output/'database.json').write_text(json.dumps(db,ensure_ascii=False,separators=(',',':')))
 # Standard IFF/PBM asset. No proprietary PAK2 decoder is guessed.
 if locate(a.source,'usme0000.lbm').exists():
  b=locate(a.source,'usme0000.lbm').read_bytes();assert b[:4]==b'FORM' and b[8:12]==b'PBM ';chunks={};i=12
  while i+8<=len(b):
   n=struct.unpack_from('>I',b,i+4)[0];chunks[b[i:i+4]]=b[i+8:i+8+n];i+=8+n+(n%2)
  w,h=struct.unpack_from('>HH',chunks[b'BMHD']);assert chunks[b'BMHD'][10]==0
  body=chunks[b'BODY'];pal=chunks[b'CMAP'];rgb=b''.join(pal[v*3:v*3+3] for v in body[:w*h]);png(a.output/'original-screen.png',w,h,rgb)
 shutil.copyfile(original_root/'MUSIC/music1.wav',a.output/'original-music.wav')
 subprocess.run(['python3',str(ROOT/'tools/import_commentary.py')],check=True)
 soundout=a.output/'SFX';soundout.mkdir(exist_ok=True)
 sounds=[]
 for f in locate(a.source,'sfx').iterdir():
  if f.suffix.lower()=='.wav' and f.stat().st_size>0:
   shutil.copyfile(f,soundout/f.name.lower());sounds.append(dict(name=f.name,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
 (ROOT/'docs/audio-manifest.json').write_text(json.dumps(dict(source='OriginalCD/data1.cab / Executable-English/sfx',sounds=sounds),indent=2))
 files=[]
 for f in sorted(a.source.rglob('*')):
  if f.is_file():files.append(dict(path=str(f.relative_to(a.source)),bytes=f.stat().st_size,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
 report=dict(source=str(original_root.relative_to(ROOT)),databaseSource=str(database_root.relative_to(ROOT)),cabinetSHA256=hashlib.sha256(cab.read_bytes()).hexdigest() if cab.exists() else None,clubs=len(clubs),players=len(players),countries=dict(Counter(c['country'] for c in clubs)),rejected=dict(rejected),files=files)
 (ROOT/'docs/original-cd-manifest.json').write_text(json.dumps(report,indent=2))
 print(json.dumps({k:v for k,v in report.items() if k!='files'},indent=2))
if __name__=='__main__':main()
