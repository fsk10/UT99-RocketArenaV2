# Builds the release zips in ./release:
#   RocketArenaV2-<version>.zip   V2 files + the original 1.60 RocketArena.u/RocketArenaMedia.u
#   RocketArena-Maps.zip          the RA maps
#
#   python -I tools/make_release.py <version> [maps dir]
#
# The original files come from RocketArenaUTFull160.umod in the project root (not in git).
# The maps dir defaults to the PlayUnreal server repo.
import glob, os, re, subprocess, sys, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UMOD = os.path.join(ROOT, 'RocketArenaUTFull160.umod')
OUT = os.path.join(ROOT, 'release')

if len(sys.argv) < 2 or not re.fullmatch(r'[0-9A-Za-z.\-]+', sys.argv[1]):
    sys.exit('usage: make_release.py <version> [maps dir]')
version = sys.argv[1]
maps_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(ROOT), 'PlayUnreal-CTF-Server-Regular', 'Maps')
if not os.path.isfile(UMOD):
    sys.exit('missing ' + UMOD)

os.makedirs(OUT, exist_ok=True)
tmp = os.path.join(OUT, 'umod')
os.makedirs(tmp, exist_ok=True)
for name in ('RocketArena.u', 'RocketArenaMedia.u'):
    subprocess.run([sys.executable, '-I', os.path.join(ROOT, 'tools', 'umod.py'), UMOD, 'System/' + name, tmp], check=True)


def add(z, src, arc):
    z.write(src, arc)
    print(f'  {arc}')


main = os.path.join(OUT, f'RocketArenaV2-{version}.zip')
print(main)
with zipfile.ZipFile(main, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in ('RocketArenaV2.u', 'RocketArenaV2Media.u', 'RocketArenaV2.int', 'RocketArenaV2.ini'):
        add(z, os.path.join(ROOT, 'dist', f), 'System/' + f)
    for f in ('RocketArena.u', 'RocketArenaMedia.u'):
        add(z, os.path.join(tmp, f), 'System/' + f)
    add(z, os.path.join(ROOT, 'tools', 'INSTALL.txt'), 'INSTALL.txt')
    add(z, os.path.join(ROOT, 'README.md'), 'README.md')
    add(z, os.path.join(ROOT, 'LICENSE'), 'LICENSE.txt')

maps = sorted(glob.glob(glob.escape(maps_dir) + '/RA-*.unr'))
if not maps:
    sys.exit('no RA maps in ' + maps_dir)
mapzip = os.path.join(OUT, 'RocketArena-Maps.zip')
print(mapzip)
with zipfile.ZipFile(mapzip, 'w', zipfile.ZIP_DEFLATED) as z:
    for m in maps:
        add(z, m, 'Maps/' + os.path.basename(m))

for f in glob.glob(os.path.join(tmp, '*')):
    os.remove(f)
os.rmdir(tmp)
