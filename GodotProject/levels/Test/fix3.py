import re

input_file = "your_scene_pass1.tscn"  # output from Category A pass
output_file = "your_scene_passB.tscn"

category_b_node = re.compile(
    r'^\[node\s+name="(Wall_x\d+)"\s+(.*)\]$'
)

foundation_node = re.compile(
    r'^\[node\s+name="FoundationPlanter_Long_\d+"\s+parent="([^"]+)"'
)

with open(input_file, "r", encoding="utf-8") as f:
    lines = f.readlines()

# Keep track of used indices for each M
unique_indices = {}

i = 0
while i < len(lines):
    stripped = lines[i].strip()
    node_match = category_b_node.match(stripped)
    if node_match:
        wall_name = node_match.group(1)
        rest = node_match.group(2)

        # Check that this is truly Category B (no second underscore)
        if '_' not in wall_name.split('x')[1]:  # only one underscore overall
            # Count following FoundationPlanter blocks and record their indices
            count = 0
            j = i + 1
            remove_indices = []  # store line numbers to remove
            while j < len(lines):
                line = lines[j].strip()
                fp_match = foundation_node.match(line)
                if fp_match and f"/{wall_name}" in fp_match.group(1):
                    count += 1
                    remove_indices.append(j)  # [node ...]
                    # transform line
                    if j + 1 < len(lines) and lines[j + 1].lstrip().startswith("transform"):
                        remove_indices.append(j + 1)
                        j += 1
                    # blank lines after
                    k = j + 1
                    while k < len(lines) and lines[k].strip() == "":
                        remove_indices.append(k)
                        k += 1
                    j = k - 1
                elif line.startswith("[node"):
                    break
                j += 1

            if count > 0:
                M = count // 2
                # Assign unique index for this M
                idx = unique_indices.get(M, 0) + 1
                unique_indices[M] = idx

                # Rewrite the node line in-place with RESOURCE_REF
                lines[i] = f'[node name="Wall_x{M}_{idx}" {rest}]\n'

                # Remove FoundationPlanter lines in reverse order
                for remove_i in sorted(remove_indices, reverse=True):
                    lines.pop(remove_i)

                # Ensure exactly one blank line after the transform
                transform_index = i + 1
                if transform_index < len(lines) and lines[transform_index].lstrip().startswith("transform"):
                    after_transform = transform_index + 1
                    if after_transform >= len(lines) or lines[after_transform].strip() != "":
                        lines.insert(after_transform, "\n")

    i += 1

with open(output_file, "w", encoding="utf-8") as f:
    f.writelines(lines)

print(f"Category B pass complete: {output_file}")
