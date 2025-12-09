// scripts/watchStrings.js
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");

const srcDir = path.join(__dirname, "../src");
const input = path.join(srcDir, "Strings.json");

console.log("Watching Strings.json for changes...");

fs.watchFile(input, { interval: 500 }, (curr, prev) => {
    if (curr.mtime !== prev.mtime) {
        console.log("Strings.json changed, regenerating stringkeys.d.ts...");
        exec("node scripts/generateStringKeys.js", (err, stdout, stderr) => {
            if (err) console.error(err);
            else console.log(stdout);
        });
    }
});
