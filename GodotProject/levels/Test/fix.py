import re

input_file = "MazeRunner.tscn"
output_file = "your_scene_fixed_new.tscn"

node_pattern = re.compile(
    r'^\[node\s+name="(FoundationPlanter_Long_\d+)"\s+type="Node3D"\s+(parent="[^"]+")\]$'
)

with open(input_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

fixed_lines = []

for line in lines:
    stripped = line.strip()

    # Remove the exact script line
    if stripped == 'script = ExtResource("8_gvlbj")':
        continue

    # Match only FoundationPlanter_Long_* Node3D nodes
    match = node_pattern.match(stripped)
    if match:
        name = match.group(1)
        parent = match.group(2)
        fixed_lines.append(
            f'[node name="{name}" {parent} instance=ExtResource("15_spdj6")]\n'
        )
    else:
        fixed_lines.append(line)

with open(output_file, "w", encoding="utf-8") as f:
    f.writelines(fixed_lines)

print(f"File processed and saved as {output_file}")
