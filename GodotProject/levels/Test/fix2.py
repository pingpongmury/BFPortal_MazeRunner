import re

input_file = "your_scene_passB.tscn"
output_file = "your_scene_passC.tscn"

category_a_node = re.compile(
    r'^\[node\s+name="(Wall_x(\d)_[^"]*)"\s+(.*)\]$'
)

foundation_node = re.compile(
    r'^\[node\s+name="FoundationPlanter_Long_\d+"\s+parent="([^"]+)"'
)

with open(input_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

output = []
i = 0

while i < len(lines):
    stripped = lines[i].strip()

    wall_match = category_a_node.match(stripped)
    if wall_match:
        wall_name = wall_match.group(1)     # e.g. Wall_x1_4
        wall_index = wall_match.group(2)    # e.g. 1
        rest = wall_match.group(3)

        resource_ref = f"WALL_X{wall_index}_RESOURCE_REF"

        # Write modified wall node
        output.append(
            f'[node name="{wall_name}" {rest} {resource_ref}]\n'
        )
        i += 1

        # Write wall transform
        if i < len(lines):
            output.append(lines[i])
            i += 1
        
        # Ensure a blank line after each Category A wall block
        output.append("\n")

        # NEW: skip blank lines before planters
        while i < len(lines) and lines[i].strip() == "":
            i += 1

        # Skip all FoundationPlanter blocks for this wall
        while i < len(lines):
            fp_match = foundation_node.match(lines[i].strip())
            if fp_match and f"/{wall_name}" in fp_match.group(1):
                # Skip [node ...]
                i += 1

                # Skip transform line
                if i < len(lines) and lines[i].lstrip().startswith("transform"):
                    i += 1

                # Skip trailing blank lines
                while i < len(lines) and lines[i].strip() == "":
                    i += 1
            else:
                break

        continue

    # Default: copy unchanged
    output.append(lines[i])
    i += 1

with open(output_file, "w", encoding="utf-8") as f:
    f.writelines(output)

print(f"Category A pass complete: {output_file}")
