import pkg from 'jww-parser-mbt/package.json' with { type: 'json' };
import uiPkg from 'svg-jww-viewer/package.json' with { type: 'json' };

console.log('=== jww-parser-mbt ===');
console.log(JSON.stringify(pkg.exports || pkg, null, 2));

console.log('\n=== svg-jww-viewer ===');
console.log(JSON.stringify(uiPkg.exports || uiPkg, null, 2));
