#!/usr/bin/env python3
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML not installed: YAML syntax check skipped")
    raise SystemExit(0)

for path in sorted(Path("lutris").glob("*.yml")):
    with path.open("r", encoding="utf-8") as stream:
        yaml.safe_load(stream)
    print(f"validated {path}")
