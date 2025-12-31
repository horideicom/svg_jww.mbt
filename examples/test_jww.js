const { parse } = require('jww-parser-mbt');
const fs = require('fs');

const files = fs.readdirSync('../../jwwfile').filter(f => f.endsWith('.jww') || f.endsWith('.JWW'));
if (files.length === 0) {
  console.log('No JWW files found');
  process.exit(0);
}

const file = files[0];
console.log('Parsing:', file);
const buffer = fs.readFileSync('../../jwwfile/' + file);
const data = parse(new Uint8Array(buffer));

console.log('Total entities:', data.entities?.length);

// Find Text entities - check for content field
const textEntities = data.entities?.filter(e => {
  for (const k of Object.keys(e)) {
    if (k.startsWith('_')) {
      const v = e[k];
      return v.content !== undefined;
    }
  }
  return false;
}) || [];

console.log('Text entities found:', textEntities.length);

if (textEntities.length > 0) {
  console.log('\nFirst text entity structure:');
  console.log(JSON.stringify(textEntities[0], null, 2));
}

// Show first 5 entity types
console.log('\nFirst 5 entity structures:');
data.entities?.slice(0, 5).forEach((e, i) => {
  for (const k of Object.keys(e)) {
    if (k.startsWith('_')) {
      const v = e[k];
      console.log(i, '-', 'keys:', Object.keys(v).slice(0, 15).join(', '));
      break;
    }
  }
});
