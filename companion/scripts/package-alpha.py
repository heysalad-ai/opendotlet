#!/usr/bin/env python3
"""Build a self-contained alpha from allowlisted inputs. No user state is copied."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import sysconfig
import zipfile

VERSION = '0.6.0-alpha.2'
ROOT = Path(__file__).resolve().parents[1]


def run(*args):
    subprocess.run([str(a) for a in args], cwd=ROOT, check=True)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--identity',help='Developer ID identity for Mac distribution')
    args=p.parse_args(); out=args.output.resolve()
    if out.exists():raise SystemExit('Output already exists; choose a fresh build directory.')
    out.mkdir(parents=True)
    mac=sys.platform=='darwin'; name='opendotlet-host' if mac else 'OpenDotlet'
    command=[sys.executable,'-m','PyInstaller','--noconfirm','--clean','--onedir','--name',name,
             '--distpath',str(out/'runtime'),'--workpath',str(out/'work'),'--specpath',str(out/'spec'),
             '--collect-submodules','serial','--add-data',str(ROOT/'tools/desktop-ui')+os.pathsep+'desktop-ui']
    if mac:
        command+=['--windowed','--osx-bundle-identifier','com.heysalad.opendotlet.host']
        if args.identity:command+=['--codesign-identity',args.identity]
    command+=[str(ROOT/'tools/dotlet_runtime.py')]
    run(*command)
    package=out/'package';package.mkdir()
    if mac:
        run('swift','build','--package-path',ROOT/'macOS','-c','release','-Xswiftc','-debug-prefix-map','-Xswiftc',str(ROOT)+'=.','-Xswiftc','-no-serialize-debugging-options')
        app=package/'OpenDotlet.app'; contents=app/'Contents'
        (contents/'MacOS').mkdir(parents=True); resources=contents/'Resources';resources.mkdir()
        # SwiftPM's --show-bin-path is independent of Xcode's local build layout.
        binary=Path(subprocess.check_output(['swift','build','--package-path',str(ROOT/'macOS'),'-c','release','--show-bin-path'],text=True).strip())/'OpenDotlet'
        shutil.copy2(binary,contents/'MacOS/OpenDotlet')
        helper=contents/'Helpers/OpenDotletHost.app'
        # A nested .app keeps executable code out of the outer Resources tree.
        shutil.copytree(out/'runtime'/(name+'.app'),helper,symlinks=True)
        # PyInstaller's loader uses Frameworks; redundant dylib links in
        # Resources trigger Apple's bundle-structure preflight warnings.
        for link in (helper/'Contents/Resources').glob('*.dylib'):
            if link.is_symlink():link.unlink()
        run('codesign','--force','--options','runtime','--timestamp','--sign',args.identity or '-',helper)
        shutil.copytree(ROOT/'assets/Peel',resources/'Peel')
        shutil.copy2(ROOT/'assets/AppIcon.icns',resources/'AppIcon.icns')
        shutil.copy2(ROOT/'macOS/NICEDECK-LICENSE',resources/'NICEDECK-LICENSE')
        info={'CFBundleName':'OpenDotlet','CFBundleDisplayName':'OpenDotlet','CFBundleIdentifier':'com.heysalad.opendotlet.mac','CFBundleExecutable':'OpenDotlet','CFBundlePackageType':'APPL','CFBundleIconFile':'AppIcon','CFBundleShortVersionString':'0.6.0','CFBundleVersion':'8','LSMinimumSystemVersion':'14.0','NSHighResolutionCapable':True,'NSPrincipalClass':'NSApplication','OpenDotletPortable':True,'OpenDotletSupportSubdirectory':'OpenDotlet/Alpha/Keyboard','NSBluetoothAlwaysUsageDescription':'Optional development device support.'}
        with (contents/'Info.plist').open('wb') as f:plistlib.dump(info,f)
        run('codesign','--force','--options','runtime','--timestamp','--sign',args.identity or '-',app)
        run('codesign','--verify','--deep','--strict','--verbose=2',app)
        archive=out/f'OpenDotlet-{VERSION}-macOS-AppleSilicon.zip'
        run('ditto','-c','-k','--sequesterRsrc','--keepParent',app,archive)
    else:
        shutil.copytree(out/'runtime'/name,package/'OpenDotlet')
        archive=out/f'OpenDotlet-{VERSION}-Windows-x64.zip'
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
            for file in sorted(package.rglob('*')):
                if file.is_file():z.write(file,file.relative_to(package))
    notices=ROOT/'docs/releases/ALPHA-README.md'
    if notices.exists():shutil.copy2(notices,package/'READ-ME-FIRST.md')
    # Rebuild archive to include plain setup instructions and licensing alongside the app.
    for source in ('LICENSE','THIRD_PARTY_NOTICES.md'):
        path=ROOT/source
        if path.exists():shutil.copy2(path,package/source)
    shutil.copytree(ROOT/'docs/releases/licenses',package/'licenses')
    for candidate in (Path(sys.base_prefix)/'LICENSE.txt',Path(sysconfig.get_path('stdlib'))/'LICENSE.txt'):
        if candidate.exists():
            shutil.copy2(candidate,package/'licenses/Python.txt')
            break
    else: raise RuntimeError('Python runtime licence was not found')
    if mac:
        archive.unlink()
        run('ditto','-c','-k','--sequesterRsrc',package,archive)
    else:
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
            for file in sorted(package.rglob('*')):
                if file.is_file():z.write(file,file.relative_to(package))
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    (out/'SHA256SUMS.txt').write_text(digest+'  '+archive.name+'\n')
    (out/'build.json').write_text(json.dumps({'version':VERSION,'platform':sys.platform,'archive':str(archive),'sha256':digest},indent=2)+'\n')
    print('RELEASE_ARCHIVE='+str(archive))


if __name__=='__main__':main()
