#!/usr/bin/env node
import { execSync } from 'child_process';
import { readFileSync } from 'fs';
import readline from 'readline';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function ask(question) {
  return new Promise(resolve => {
    rl.question(question, answer => resolve(answer));
  });
}

function runCommand(cmd, description, options = {}) {
  try {
    console.log(`\n▸ ${description}`);
    execSync(cmd, { stdio: 'inherit', ...options });
    return true;
  } catch (error) {
    console.error(`❌ ${description} failed:`, error.message);
    return false;
  }
}

async function main() {
  const packageJson = JSON.parse(readFileSync('package.json', 'utf8'));
  const currentVersion = packageJson.version;

  console.log(`📦 Current version: ${currentVersion}`);
  console.log('');

  const newVersion = await ask('Enter new version (e.g., 0.2.0): ');

  if (!newVersion) {
    console.log('❌ No version provided');
    rl.close();
    return;
  }

  console.log('');
  console.log('Release plan:');
  console.log(`  1. Update package.json to ${newVersion}`);
  console.log(`  2. Sync moon.mod.json & examples/package.json`);
  console.log(`  3. Build (moon build → rolldown → types)`);
  console.log(`  4. Update examples/pnpm-lock.yaml`);
  console.log(`  5. Git commit, tag, and push`);
  console.log(`  6. Create GitHub Release (optional)`);
  console.log('');

  const confirm = await ask('Continue? (y/N): ');

  if (confirm.toLowerCase() !== 'y') {
    console.log('❌ Cancelled');
    rl.close();
    return;
  }

  try {
    // 1. Update package.json
    if (!runCommand(`pnpm version ${newVersion} --no-git-tag-version`, 'Updating package.json')) {
      throw new Error('Failed to update package.json');
    }

    // 2. Sync moon.mod.json & examples/package.json
    if (!runCommand('node scripts/sync-version.js', 'Syncing moon.mod.json & examples/package.json')) {
      throw new Error('Failed to sync versions');
    }

    // 3. Build
    console.log('\n━━━ Build Phase ━━━');

    if (!runCommand('pnpm run build', 'Building package (moon → rolldown → types)')) {
      throw new Error('Build failed');
    }

    // Verify build outputs
    const requiredFiles = ['dist/index.mjs', 'dist/index.cjs', 'dist/index.d.ts'];
    for (const file of requiredFiles) {
      try {
        readFileSync(file);
      } catch {
        throw new Error(`Build verification failed: ${file} not found`);
      }
    }
    console.log('✓ Build outputs verified');

    // 4. Update examples/pnpm-lock.yaml
    console.log('\n━━━ Examples Update Phase ━━━');

    if (!runCommand('pnpm install --filter examples', 'Updating examples/pnpm-lock.yaml')) {
      console.log('⚠ Failed to update examples lock file (continuing anyway)');
    }

    // 5. Git commit, tag, and push
    console.log('\n━━━ Git Phase ━━━');

    if (!runCommand(
      'git add package.json moon.mod.json examples/package.json examples/pnpm-lock.yaml',
      'Staging changes'
    )) {
      throw new Error('Failed to stage changes');
    }

    if (!runCommand(
      `git commit -m "chore(release): bump version to ${newVersion}"`,
      'Creating git commit'
    )) {
      throw new Error('Failed to create git commit');
    }

    if (!runCommand(`git tag v${newVersion}`, `Creating git tag v${newVersion}`)) {
      throw new Error('Failed to create git tag');
    }

    if (!runCommand('git push', 'Pushing commits to GitHub')) {
      throw new Error('Failed to push commits');
    }

    if (!runCommand(`git push origin v${newVersion}`, 'Pushing git tag')) {
      throw new Error('Failed to push git tag');
    }

    // 6. Create GitHub Release (optional)
    console.log('\n━━━ GitHub Release ━━━');

    const createRelease = await ask('Create GitHub Release? (y/N): ');

    if (createRelease.toLowerCase() === 'y') {
      const releaseCreated = runCommand(
        `gh release create v${newVersion} --generate-notes`,
        'Creating GitHub Release'
      );

      if (!releaseCreated) {
        console.log('');
        console.log('⚠️  GitHub Release creation failed');
        console.log(`   Create manually: https://github.com/horideicom/svg_jww.mbt/releases/new?tag=v${newVersion}`);
      }
    } else {
      console.log('Skipping GitHub Release creation');
    }

    // Success summary
    console.log('');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ Release complete!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');
    console.log('Published:');
    console.log(`  🏷️  Tag: v${newVersion}`);
    console.log(`  🔗 Repo: https://github.com/horideicom/svg_jww.mbt`);

  } catch (error) {
    console.error('\n❌ Release failed:', error.message);
    console.log('\nRollback suggestions:');
    console.log(`  git tag -d v${newVersion}           # Delete local tag (if created)`);
    console.log(`  git reset --soft HEAD~1             # Undo last commit (if created)`);
    console.log(`  git checkout package.json moon.mod.json examples/package.json`);
    console.log('');
  }

  rl.close();
}

main();
