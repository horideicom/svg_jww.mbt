#!/usr/bin/env node
// CLI tool to parse JWW file and output JSON
import { parse } from 'jww-parser';
import { readFileSync } from 'fs';

const jwwFile = process.argv[2];

if (!jwwFile) {
  console.error('Usage: node cli-parse.js <jww-file>');
  console.error('Example: node cli-parse.js sample.jww');
  process.exit(1);
}

try {
  const buffer = readFileSync(jwwFile);
  const uint8Array = new Uint8Array(buffer.buffer);

  console.error(`Parsing: ${jwwFile}`);
  console.error(`File size: ${buffer.length} bytes`);

  const jwwData = parse(uint8Array);

  console.error(`Entities count: ${jwwData.entities?.length || 0}`);

  // Output JSON
  console.log(JSON.stringify(jwwData, null, 2));
} catch (error) {
  console.error(`Error: ${error.message}`);
  process.exit(1);
}
