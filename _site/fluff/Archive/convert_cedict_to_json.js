const fs = require("fs");

const cedictFile = "cedict_ts.u8"; // Path to your downloaded CEDICT file
const outputFile = "cedict.json";
const cedictData = {};

fs.readFileSync(cedictFile, "utf-8")
    .split("\n")
    .forEach(line => {
        if (line.startsWith("#") || !line.trim()) return; // Ignore comments and empty lines

        const match = line.match(/^(.+?) (.+?) \[(.+?)\] \/(.+?)\//);
        if (match) {
            const [, simplified, traditional, pinyin, definition] = match;
            cedictData[simplified] = { pinyin, definition };
        }
    });

fs.writeFileSync(outputFile, JSON.stringify(cedictData, null, 2));
console.log("CEDICT successfully converted to JSON!");
