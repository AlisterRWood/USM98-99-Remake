"""Bundle the supplied CD speech, retaining source paths and exact audio bytes."""
from pathlib import Path
import json,shutil,unicodedata,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
def key(s):return ''.join(c for c in unicodedata.normalize('NFKD',s.lower()) if c.isascii() and c.isalpha())
def main():
 out=ROOT/'Sources/USMApp/Resources/Commentary';out.mkdir(exist_ok=True)
 groups={};names={};manifest=[]
 for source,category in [(ROOT/'.work/original-cd/Executable-English/speech','events'),(ROOT/'OriginalCD/speech/players','names')]:
  if not source.exists():raise SystemExit(f'Missing extracted CD source: {source}')
  for f in sorted(source.rglob('*')):
   if f.suffix.lower()!='.wav' or f.stat().st_size<44:continue
   rel=f'{category}/{f.relative_to(source).as_posix().lower()}';dest=out/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,dest)
   if category=='events':groups.setdefault(f.parent.name.lower(),[]).append(rel)
   else:
    mode=f.relative_to(source).parts[0];names.setdefault(mode,{})[key(re.sub(r'^\d+','',f.stem))]=rel
   manifest.append(dict(source=str(f.relative_to(ROOT)),path=rel,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
 (out/'index.json').write_text(json.dumps(dict(groups=groups,names=names)))
 (ROOT/'docs/commentary-manifest.json').write_text(json.dumps(manifest,indent=2))
 print(f'Bundled {len(manifest)} original CD speech clips in {len(groups)} event groups')
if __name__=='__main__':main()
