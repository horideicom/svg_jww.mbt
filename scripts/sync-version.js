#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, '..');

// Read package.json
const packagePath = join(rootDir, 'package.json');
const packageJson = JSON.parse(readFileSync(packagePath, 'utf8'));

// Get version from argument or package.json
const argVersion = process.argv[2];
const version = argVersion || packageJson.version;

// Update package.json if version argument provided
if (argVersion) {
  packageJson.version = argVersion;
  writeFileSync(packagePath, JSON.stringify(packageJson, null, 2) + '\n');
}

// Read moon.mod.json
const moonModPath = join(rootDir, 'moon.mod.json');
const moonModJson = JSON.parse(readFileSync(moonModPath, 'utf8'));

// Read examples/package.json
const examplesPackagePath = join(rootDir, 'examples', 'package.json');
const examplesPackageJson = JSON.parse(readFileSync(examplesPackagePath, 'utf8'));

// Update versions
moonModJson.version = version;
examplesPackageJson.dependencies['svg-jww-viewer'] = `^${version}`;

// Write back
writeFileSync(moonModPath, JSON.stringify(moonModJson, null, 2) + '\n');
writeFileSync(examplesPackagePath, JSON.stringify(examplesPackageJson, null, 2) + '\n');

console.log(`Synced version to ${version}`);
console.log(`   - package.json: ${version}`);
console.log(`   - moon.mod.json: ${version}`);
console.log(`   - examples/package.json: ^${version}`);
