"""Audit Flutter LKey vs es.csv and hardcoded UI strings."""
import csv
import re
from pathlib import Path

APP = Path(r"C:\laragon\www\nexus_krimson\nexus_rs_app")
BACKEND = Path(r"C:\laragon\www\nexus_krimson\nexus_rs")
KEYS_FILE = APP / "lib" / "languages" / "languages_keys.dart"
ES_CSV = BACKEND / "database" / "seeders" / "data" / "es.csv"
FALLBACKS = APP / "lib" / "languages" / "dynamic_translations.dart"
LIB = APP / "lib"

# --- LKey constants ---
src = KEYS_FILE.read_text(encoding="utf-8")
lkeys = {}
for m in re.finditer(
    r'static const String (\w+)\s*=\s*"((?:\\.|[^"\\])*)"', src, re.S
):
    name, val = m.group(1), m.group(2).encode().decode("unicode_escape")
    lkeys[name] = val
# triple-ish concatenations: two string literals
for m in re.finditer(
    r'static const String (\w+)\s*=\s*"((?:\\.|[^"\\])*)"\s*\n\s*"((?:\\.|[^"\\])*)"',
    src,
):
    name = m.group(1)
    val = (m.group(2) + m.group(3)).encode().decode("unicode_escape")
    lkeys[name] = val

print(f"LKey constants: {len(lkeys)}")

# --- es.csv ---
es_map = {}
with ES_CSV.open(encoding="utf-8-sig", newline="") as f:
    reader = csv.reader(f)
    header = next(reader, None)
    for row in reader:
        if len(row) < 2:
            continue
        k, v = row[0], row[1]
        es_map[k] = v
print(f"es.csv rows: {len(es_map)}")


def csv_variants(s: str):
    yield s
    yield s.replace("\n", "")
    yield s.replace("\n", " ")
    yield s.replace("\\n", "")
    yield s.replace("\\n", "\n")


missing_csv = []
for name, val in lkeys.items():
    if any(v in es_map for v in csv_variants(val)):
        continue
    missing_csv.append((name, val))

print(f"LKeys missing in es.csv: {len(missing_csv)}")

# --- fallback maps in dynamic_translations (LKey.xxx as keys) ---
fb = FALLBACKS.read_text(encoding="utf-8")
fb_names = set(re.findall(r"LKey\.(\w+)", fb))
print(f"LKeys referenced in dynamic_translations.dart: {len(fb_names)}")

missing_fallback_es = [n for n, _ in missing_csv if n not in fb_names]
print(f"Missing in BOTH es.csv AND fallbacks: {len(missing_fallback_es)}")

out = BACKEND / "storage" / "app"
out.mkdir(parents=True, exist_ok=True)
rep = Path(r"C:\laragon\www\nexus_krimson\nexus_rs_app\tools")
rep.mkdir(parents=True, exist_ok=True)
report = rep / "missing_translations.txt"
lines = []
lines.append("=== LKeys sin fila en es.csv ===")
for name, val in missing_csv:
    in_fb = "fallback" if name in fb_names else "SIN FALLBACK ES"
    preview = val.replace("\n", "\\n")[:80]
    lines.append(f"{in_fb:18}  LKey.{name} = {preview}")

# --- hardcoded Text('...') without .tr ---
hard = []
pat = re.compile(
    r"""Text\s*\(\s*(?:const\s+)?['"]([^'"]{3,80})['"]""",
)
skip_re = re.compile(
    r"^(https?:|assets/|\$|[0-9%./:]+$|[A-Z0-9_]{2,}$|·|\||•|—|-|\+|Lv\.|SVIP|NEW|LIVE)",
)
for dart in LIB.rglob("*.dart"):
    if "languages" in dart.parts:
        continue
    text = dart.read_text(encoding="utf-8", errors="replace")
    rel = dart.relative_to(APP)
    for i, line in enumerate(text.splitlines(), 1):
        if ".tr" in line or "LKey." in line:
            continue
        if "TextStyle" in line or "fontFamily" in line:
            continue
        for m in pat.finditer(line):
            s = m.group(1).strip()
            if skip_re.match(s):
                continue
            if re.fullmatch(r"[\W\d_]+", s):
                continue
            # likely UI copy if has a letter
            if re.search(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]{3,}", s):
                hard.append((str(rel), i, s))

lines.append("")
lines.append(f"=== Text('...') hardcodeados (sin .tr) : {len(hard)} ===")
# unique strings
seen = {}
for path, ln, s in hard:
    seen.setdefault(s, []).append(f"{path}:{ln}")
for s, locs in sorted(seen.items(), key=lambda x: -len(x[1])):
    lines.append(f"  [{len(locs):3}] {s!r}")
    for loc in locs[:4]:
        lines.append(f"        {loc}")
    if len(locs) > 4:
        lines.append(f"        ... +{len(locs)-4}")

report.write_text("\n".join(lines), encoding="utf-8")
print(f"Wrote {report} ({len(lines)} lines)")
print("--- sample missing LKeys ---")
for name, val in missing_csv[:40]:
    print(f"  {name}: {val[:60]!r}")
print(f"... total missing csv {len(missing_csv)}")
print("--- top hardcoded ---")
for s, locs in sorted(seen.items(), key=lambda x: -len(x[1]))[:25]:
    print(f"  x{len(locs)} {s!r}")
