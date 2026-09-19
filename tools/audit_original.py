#!/usr/bin/env python3
"""Read-only evidence inventory. Candidate binary fields are not runtime imports."""
from pathlib import Path
import collections,hashlib,json,re,struct
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'.work/original-cd/Executable-English'
out=ROOT/'docs/audit';out.mkdir(parents=True,exist_ok=True)
def save(name,value): (out/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
files=[]
for p in sorted(source.rglob('*')):
 if p.is_file():
  b=p.read_bytes();files.append({'path':str(p.relative_to(source)),'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'signature_hex':b[:8].hex()})
save('cd-file-inventory.json',{'source':str(source.relative_to(ROOT)),'files':files})
b=(source/'help.txt').read_bytes();parts=re.split(r'(?m)^#\s*(\d+)[^\n]*\n',b.decode('cp1252'))
save('help-sections.json',{'source':str((source/'help.txt').relative_to(ROOT)),'sha256':hashlib.sha256(b).hexdigest(),'sections':[{'id':int(parts[i]),'title':parts[i+1].strip().splitlines()[0],'text':parts[i+1].strip()} for i in range(1,len(parts),2) if parts[i+1].strip()]})
b=(source/'Usm98-99.exe').read_bytes()
strings=[{'offset':m.start(),'text':m.group().decode('cp1252',errors='replace')} for m in re.finditer(rb'[\x20-\x7e\xa0-\xff]{5,}',b)]
save('executable-strings.json',{'note':'Static printable runs only; no execution or algorithm recovery. Offsets are decimal file offsets.','strings':strings})
b=(source/'GAME.TXT').read_bytes();n=struct.unpack_from('<I',b)[0]//4;offsets=struct.unpack_from('<'+'I'*n,b)
assert offsets[-1]==len(b) and all(x<=y for x,y in zip(offsets,offsets[1:]))
save('game-message-records.json',{'note':'1525 offsets including terminal file-length sentinel; token and control byte semantics not decoded.','records':[{'index':i,'offset':a,'bytes':z-a,'text':b[a:z].decode('cp1252',errors='replace')} for i,(a,z) in enumerate(zip(offsets,offsets[1:]))]})
b=(source/'COACH.DAT').read_bytes();assert len(b)%26==0
save('coach-candidates.json',{'note':'26-byte stride is supported by all names aligned. Byte semantics remain hypotheses: +10 specialty, +11 age, +12 LE32 wage, +19 quality. Do not treat wage units or enum labels as verified.','records':[{'offset':i,'name':b[i:i+10].split(b'\0')[0].decode('cp1252'),'byte10':b[i+10],'byte11':b[i+11],'le32_at12':int.from_bytes(b[i+12:i+16],'little'),'byte19':b[i+19],'raw_hex':b[i:i+26].hex()} for i in range(0,len(b),26)]})
b=(source/'ADVERT.DAT').read_bytes();assert len(b)%150==0
save('advert-candidates.json',{'note':'150-byte candidate records based on name alignment. Repeated names may encode categories, not 100 distinct firms. Terms and prices remain unverified.','records':[{'offset':i,'name':b[i:i+14].split(b'\0')[0].decode('cp1252'),'raw_hex':b[i:i+150].hex()} for i in range(0,len(b),150)]})
print(f'Inventoried {len(files)} files; extracted help, strings, 1524 message records, 195 coach candidates and 100 advertiser candidates.')
