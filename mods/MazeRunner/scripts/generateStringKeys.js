// scripts/generateStringKeys.js
const fs = require("fs");
const path = require("path");

// Paths
const srcDir = path.join(__dirname, "../src");
const input = path.join(srcDir, "Strings.json");
const outputDir = path.join(__dirname, "../types");
const output = path.join(outputDir, "stringkeys.d.ts");

// Ensure types folder exists
if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
}

// Read Strings.json
const json = JSON.parse(fs.readFileSync(input, "utf8"));

// Build TypeScript declaration for mod.stringkeys
let dts =
`// AUTO-GENERATED. DO NOT EDIT.
// Generated from Strings.json

declare namespace mod {
    const stringkeys: {
`;

for (const key of Object.keys(json)) {
    dts += `        ${key}: string;\n`;
}

dts +=
`    };
}
`;

fs.writeFileSync(output, dts, "utf8");

console.log(`Generated: ${output}`);
