#!/usr/bin/env python3
"""Build and sideload one uniquely-named APK per sleepRun commit.

Does not commit identity patches. Each APK has its own applicationId so
installs sit side-by-side on the phone.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE_ROOT = Path("/mnt/d/Chadukunta/zeromiles/_zm-stage")
HOT = STAGE_ROOT / "batch2"
OUT = ROOT / "build" / "sleep-apks"
FLUTTER = r"C:\Users\ravim\Downloads\flutter\bin\flutter.bat"
ADB_WIN = r"C:\Users\ravim\AppData\Local\Android\Sdk\platform-tools\adb.exe"
DEVICE = "R3CW50L870R"

# Visual/shoppable commits only (skip docs-only / test-only).
COMMITS = [
    ("00", "a4b8add", "base main"),
    ("01", "c5d8cb9", "theme: candlelit sanctuary palette"),
    ("02", "2cff778", "home: scene line and labeled daily rituals"),
    ("03", "af18caf", "auth: night wash and quieter tagline"),
    ("04", "ca9355b", "pair: six tiles for the join code"),
    ("05", "8c5f690", "feat: thinking-of-you affection"),
    ("06", "127b486", "home: invite-them seat and night sleep glow"),
    ("07", "8c38047", "talk: Okay sits on ink instead of white"),
    ("08", "efe18b5", "ritual: quieter daily-question save copy"),
    ("09", "fcb8b9d", "splash: quieter mark while routing settles"),
    ("10", "8e5d404", "auth: name-setup spinner matches the button ink"),
    ("11", "a040c16", "ritual: photo lock says share yours to see theirs"),
    ("12", "290dfa6", "feel: sent toast and mood caption are quieter"),
    ("13", "cb8ad4e", "home: settings partner copy is quieter"),
    ("14", "e25de06", "talk: tonight option has a caption"),
    ("15", "0c38e3f", "ritual: question header and waiting copy are quieter"),
    ("16", "dcf7c5f", "canvas: titled shared mural"),
    ("17", "0ac9e46", "outfit: rose and ink swatches, save sits on ink"),
    ("18", "1328b2b", "voice: mic sits on ink, gone in a day"),
    ("19", "d3585ac", "home: voice chip says they left a voice"),
    ("20", "dba71da", "ritual: photo titled today, capture sits on ink"),
    ("21", "a37dacd", "pair: join spinner matches the button ink"),
    ("22", "27880cd", "home: tap your seat to change outfit"),
    ("23", "dfaf04d", "ritual: question share sits on ink"),
    ("24", "9cd5284", "talk: sheet titled reach them"),
    ("25", "e6b236e", "ritual: photo cards titled theirs and yours"),
    ("26", "6e3299c", "pair: divider uses hairline"),
    ("27", "1151ddd", "feel: toast sits on a rose wash"),
    ("28", "adff4ae", "home: seat caption fallback is with you"),
    ("29", "a380f09", "auth: quieter create-account toggle"),
    ("30", "b975022", "outfit: they will match, quieter labels"),
    ("31", "ec0f617", "home: rituals labeled wear photo ask"),
    ("32", "c3dde34", "canvas: clear asks about the shared mural"),
    ("33", "e261015", "ritual: photo caption hint is a line for them"),
    ("34", "960606f", "feel: note sheet is a line for them"),
    ("35", "00c7fc5", "home: double-tap their seat to send a kiss"),
    ("36", "f56b165", "feel: thinking action labeled think"),
    ("37", "5c2e8cd", "ritual: waiting badges use candle, not orange"),
    ("38", "c78562f", "talk: not now has a caption"),
    ("39", "5f1d1c2", "home: hairline above the affection row"),
    ("40", "d9f50f8", "home: sleep and wake toast good night or morning"),
    ("41", "095bad5", "theme: rounder cards and sheets"),
    ("42", "71a3bc7", "home: settings sheet titled this room"),
    ("43", "b7901b6", "home: this-room menu hides behind more"),
    ("44", "ccc8983", "home: quieter scene lines"),
    ("45", "2077100", "ritual: both-answered banner uses rose not green"),
]


def win_path(p: Path) -> str:
    s = str(p.resolve())
    if s.startswith("/mnt/") and len(s) > 6 and s[6] == "/":
        drive = s[5].upper()
        return drive + ":\\" + s[7:].replace("/", "\\")
    return s


def run(args: list[str], cwd: Path | None = None, check: bool = True) -> None:
    print("+", " ".join(args), flush=True)
    subprocess.run(args, cwd=cwd, check=check)


def patch_identity(app_dir: Path, num: str, label: str, app_id: str) -> None:
    gradle = app_dir / "android" / "app" / "build.gradle.kts"
    text = gradle.read_text(encoding="utf-8")
    text = text.replace(
        'applicationId = "com.example.zer0mi1es"',
        f'applicationId = "{app_id}"',
        1,
    )
    gradle.write_text(text, encoding="utf-8")

    manifest = app_dir / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    m = manifest.read_text(encoding="utf-8")
    m = m.replace('android:label="zer0mi1es"', f'android:label="{label}"', 1)
    manifest.write_text(m, encoding="utf-8")

    gs = app_dir / "android" / "app" / "google-services.json"
    data = json.loads(gs.read_text(encoding="utf-8"))
    pkgs = {
        c["client_info"]["android_client_info"]["package_name"]
        for c in data["client"]
    }
    if app_id not in pkgs:
        extra = json.loads(json.dumps(data["client"][0]))
        extra["client_info"]["android_client_info"]["package_name"] = app_id
        data["client"].append(extra)
        gs.write_text(json.dumps(data, indent=2), encoding="utf-8")

    lp = app_dir / "android" / "local.properties"
    lp.write_text(
        "sdk.dir=C:\\\\Users\\\\ravim\\\\AppData\\\\Local\\\\Android\\\\Sdk\n"
        "flutter.sdk=C:\\\\Users\\\\ravim\\\\Downloads\\\\flutter\n",
        encoding="utf-8",
    )


SKIP_COPY_DIRS = {"build", ".dart_tool", ".gradle"}


def _unlock(path: Path) -> None:
    if not path.exists():
        return
    try:
        path.chmod(0o666)
    except OSError:
        pass
    subprocess.run(
        ["cmd.exe", "/c", f"attrib -R {win_path(path)}"],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def _copy_sources(src: Path, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d not in SKIP_COPY_DIRS]
        rel = Path(root).relative_to(src)
        target_dir = dest / rel
        target_dir.mkdir(parents=True, exist_ok=True)
        for name in files:
            s = Path(root) / name
            t = target_dir / name
            _unlock(t)
            shutil.copy2(s, t)


def extract_sha(sha: str, dest: Path) -> None:
    incoming = STAGE_ROOT / "_incoming"
    shutil.rmtree(incoming, ignore_errors=True)
    incoming.mkdir(parents=True, exist_ok=True)
    archive = subprocess.Popen(
        ["git", "-C", str(ROOT), "archive", sha],
        stdout=subprocess.PIPE,
    )
    subprocess.run(["tar", "-x", "-C", str(incoming)], stdin=archive.stdout, check=True)
    archive.wait()
    dest.mkdir(parents=True, exist_ok=True)
    gs = dest / "appcode" / "android" / "app" / "google-services.json"
    _unlock(gs)
    _copy_sources(incoming, dest)
    shutil.rmtree(incoming, ignore_errors=True)


def main() -> int:
    start = "00"
    args = sys.argv[1:]
    if len(args) >= 2 and args[0] == "--from":
        start = args[1]

    OUT.mkdir(parents=True, exist_ok=True)
    STAGE_ROOT.mkdir(parents=True, exist_ok=True)
    env_src = ROOT / "appcode" / ".env"

    mapping = []
    for num, sha, title in COMMITS:
        if num < start:
            continue
        label = f"ZM {num}"
        app_id = f"com.example.zer0mi1es.zm{num}"
        print(f"\n=== {label} {sha} {title} ===", flush=True)
        dest = OUT / f"ZM-{num}.apk"
        if not dest.exists():
            extract_sha(sha, HOT)
            app_dir = HOT / "appcode"
            if env_src.exists():
                shutil.copy2(env_src, app_dir / ".env")
            patch_identity(app_dir, num, label, app_id)
            run(
                [
                    "cmd.exe",
                    "/c",
                    f"cd /d {win_path(app_dir)}"
                    f" && {FLUTTER} build apk --debug --target-platform android-arm64"
                    f" --dart-define-from-file=.env",
                ]
            )
            apk = app_dir / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
            shutil.copy2(apk, dest)
        else:
            print(f"reusing {dest}", flush=True)
        run(
            [
                "cmd.exe",
                "/c",
                f"{ADB_WIN} -s {DEVICE} install -r {win_path(dest)}",
            ]
        )
        mapping.append(f"{label}\t{app_id}\t{sha}\t{title}")

    full = []
    for num, sha, title in COMMITS:
        apk = OUT / f"ZM-{num}.apk"
        if apk.exists():
            full.append(
                f"ZM {num}\tcom.example.zer0mi1es.zm{num}\t{sha}\t{title}"
            )
    (OUT / "INDEX.txt").write_text("\n".join(full) + "\n", encoding="utf-8")
    print("\nInstalled:\n" + "\n".join(full), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
