// Build-time only. Rasterize the canonical SVG without modifying its geometry.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '../../..');
const source = path.join(root, 'docs/forge/forge-studio-ui/brand/assets/forge-f.svg');
const view = path.join(__dirname, '../SchemaForge/Modules/View.luau');
const output = path.join(__dirname, 'brand-review');

async function main() {
  const width = 32, height = 42;
  const svg = fs.readFileSync(source);
  const alpha = await sharp(svg).resize(width, height).ensureAlpha().extractChannel(3).raw().toBuffer();
  const rows = [];
  for (let y = 0; y < height; y++) {
    const pixels = Array.from(alpha.subarray(y * width, (y + 1) * width), a => Math.round(a / 17) * 17);
    const runs = [];
    for (let x = 0; x < width;) {
      let end = x + 1;
      while (end < width && pixels[end] === pixels[x]) end++;
      if (pixels[x]) runs.push(`${x},${end - x},${pixels[x]}`);
      x = end;
    }
    rows.push(runs.join(';'));
  }
  const block = `local forgeMarkRaster = [[\n${rows.join('\n')}\n]]`;
  const text = fs.readFileSync(view, 'utf8');
  const expression = /local forgeMarkRaster = \[\[[\s\S]*?\]\]/g;
  const matches = text.match(expression);
  if (!matches || matches.length !== 1) throw new Error('Expected one generated raster block');
  if (process.argv.includes('--write')) {
    fs.mkdirSync(output, { recursive: true });
    fs.writeFileSync(view, text.replace(expression, block));
    await sharp(svg).png().toFile(path.join(output, 'canonical-f.png'));
    await sharp(svg).resize(width, height).png().toFile(path.join(output, 'canonical-f-ui.png'));
  } else if (matches[0] !== block) {
    throw new Error('View raster differs from canonical SVG');
  }
  console.log('PASS: canonical SVG raster matches View; source SHA256 ' + crypto.createHash('sha256').update(svg).digest('hex'));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
