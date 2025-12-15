import re

INPUT_FILE = "input.tscn"
OUTPUT_FILE = "output.tscn"

node_re = re.compile(
    r'^\[node\s+name="Wall_x\d{1,2}_\d{0,3}"(?![^\]]*instance=)[^\]]*\]\s*$'
)

transform_re = re.compile(r'^transform\s*=\s*Transform3D\(')

def ensure_type_node3d(line: str) -> str:
    if 'type="Node3D"' in line:
        return line
    return re.sub(
        r'(\[node\s+name="Wall_x\d{1,2}_\d{0,3}")',
        r'\1 type="Node3D"',
        line
    )

with open(INPUT_FILE, "r", encoding="utf-8") as f:
    lines = f.readlines()

out = []
i = 0

while i < len(lines):
    line = lines[i]

    if node_re.match(line):
        line = ensure_type_node3d(line)
        out.append(line)

        if i + 1 < len(lines) and transform_re.match(lines[i + 1]):
            out.append(lines[i + 1])
            out.append('script = ExtResource("8_o7556")\n')
            i += 2
            continue

    out.append(line)
    i += 1

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.writelines(out)
