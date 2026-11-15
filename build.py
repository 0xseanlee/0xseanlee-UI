"""Build a paste-ready starter without any network dependency."""
from pathlib import Path

root = Path(__file__).resolve().parent
library = (root / "Library.lua").read_text()
example = (root / "Example.lua").read_text()
output = "-- 0xseanlee UI: paste this entire file into your Lua executor.\n"
output += "local Library = (function()\n" + library + "\nend)()\n\n" + example
(root / "Demo.client.lua").write_text(output)
print("Built Demo.client.lua")
