import json, re
p = r"C:\Users\Asus\.cursor\browser-logs\cdp-response-Runtime.evaluate-2026-08-04T20-55-23-129Z.json"
with open(p, encoding="utf-8") as f:
    data = json.load(f)
s = json.dumps(data)
for m in re.finditer(r"(sdkKey|licenseKey|appKey|apiKey|\"key\")\s*:\s*\"([^\"]{16,})\"", s, re.I):
    print(m.group(1), "=>", m.group(2)[:120])
for pat in ["com.nexus", "com.krimson", "ios", "android", "bundle"]:
    i = s.lower().find(pat)
    if i >= 0:
        print("CTX", pat, ":", s[max(0, i - 60) : i + 180].replace("\n", " ")[:260])
print("total", len(s))
