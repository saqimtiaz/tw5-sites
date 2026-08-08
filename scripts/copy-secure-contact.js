import fs from 'node:fs';
import path from 'node:path';
import { staticAssetsDir } from 'secure-contact/static-assets';

const [, , destDir] = process.argv;
fs.mkdirSync(destDir, { recursive: true });
fs.cpSync(staticAssetsDir, destDir, { recursive: true });

console.log(`Copied secure-contact assets from ${staticAssetsDir} to ${destDir}`);