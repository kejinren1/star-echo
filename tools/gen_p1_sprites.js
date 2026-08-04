const path = require('path');
const fs = require('fs');
const E = require('./png-engine.js');
const { createCanvas, px, pxC, fillRect, fillEllipse, ringEllipse, addOutline, combineFrames, encodePNG, C } = E;

const ROOT = 'c:/Users/Administrator/WorkBuddy/2026-08-03-15-51-20/assets/sprites';

function saveSheet(dir, name, frames, fw, fh) {
  const sheet = combineFrames(frames, fw, fh);
  const png = encodePNG(sheet.w, sheet.h, sheet.data);
  const outPath = path.join(ROOT, dir, name + '.png');
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, png);
  console.log('  done: ' + dir + '/' + name + '.png (' + sheet.w + 'x' + sheet.h + ')');
}
function saveImg(dir, name, canvas) {
  const png = encodePNG(canvas.w, canvas.h, canvas.data);
  const outPath = path.join(ROOT, dir, name + '.png');
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, png);
  console.log('  done: ' + dir + '/' + name + '.png (' + canvas.w + 'x' + canvas.h + ')');
}

// Noise helper for textures
function noiseSeed(seed) { let s = seed; return () => { s = (s * 9301 + 49297) % 233280; return s / 233280; }; }
function scatter(c, x, y, w, h, count, col, seed) {
  const rnd = noiseSeed(seed);
  for (let i = 0; i < count; i++) {
    const px_ = x + Math.floor(rnd() * w);
    const py_ = y + Math.floor(rnd() * h);
    pxC(c, px_, py_, col);
  }
}

// ===================== GROUND TILESET (32x32 x4) =====================

function genGroundTileset() {
  const tiles = [];
  const rnd = noiseSeed(42);

  // Tile 0: Basic stone floor
  let c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [45, 45, 63, 255]); // STONE base
  // Lighter speckles
  for (let i = 0; i < 40; i++) {
    const x = Math.floor(rnd() * 32), y = Math.floor(rnd() * 32);
    pxC(c, x, y, [61, 61, 79, 255]); // COLD
  }
  // Darker speckles
  for (let i = 0; i < 25; i++) {
    const x = Math.floor(rnd() * 32), y = Math.floor(rnd() * 32);
    pxC(c, x, y, [30, 30, 45, 255]);
  }
  // Subtle grid lines
  for (let i = 0; i < 32; i++) { pxC(c, 0, i, [40, 40, 55, 255]); pxC(c, i, 0, [40, 40, 55, 255]); }
  tiles.push(c);

  // Tile 1: Cracked stone
  c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [45, 45, 63, 255]);
  scatter(c, 0, 0, 32, 32, 30, [61, 61, 79, 255], 99);
  scatter(c, 0, 0, 32, 32, 20, [30, 30, 45, 255], 88);
  // Crack lines (dark)
  const cracks = [
    [4, 2, 8, 8], [8, 8, 14, 14], [14, 14, 20, 12], [20, 12, 26, 18],
    [26, 18, 28, 24], [10, 20, 18, 28], [2, 16, 6, 22]
  ];
  for (const [x1, y1, x2, y2] of cracks) {
    const steps = Math.max(Math.abs(x2 - x1), Math.abs(y2 - y1));
    for (let s = 0; s <= steps; s++) {
      const x = Math.round(x1 + (x2 - x1) * s / steps);
      const y = Math.round(y1 + (y2 - y1) * s / steps);
      pxC(c, x, y, [20, 20, 30, 255]);
      pxC(c, x + 1, y, [20, 20, 30, 200]);
    }
  }
  tiles.push(c);

  // Tile 2: Blood-stained stone
  c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [45, 45, 63, 255]);
  scatter(c, 0, 0, 32, 32, 30, [61, 61, 79, 255], 77);
  scatter(c, 0, 0, 32, 32, 20, [30, 30, 45, 255], 66);
  // Blood splatter
  fillEllipse(c, 16, 16, 6, 4, [120, 30, 40, 180]);
  fillEllipse(c, 10, 10, 3, 2, [120, 30, 40, 150]);
  fillEllipse(c, 22, 20, 2, 2, [120, 30, 40, 150]);
  scatter(c, 8, 8, 16, 16, 12, [100, 20, 30, 120], 55);
  tiles.push(c);

  // Tile 3: Mossy stone
  c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [45, 45, 63, 255]);
  scatter(c, 0, 0, 32, 32, 30, [61, 61, 79, 255], 33);
  scatter(c, 0, 0, 32, 32, 20, [30, 30, 45, 255], 22);
  // Moss patches
  fillEllipse(c, 8, 24, 5, 3, [50, 80, 50, 200]);
  fillEllipse(c, 24, 8, 4, 2, [50, 80, 50, 180]);
  fillEllipse(c, 20, 26, 3, 2, [50, 80, 50, 160]);
  scatter(c, 4, 20, 12, 10, 15, [60, 90, 55, 180], 11);
  tiles.push(c);

  return tiles;
}

// ===================== WALL TILESET (32x32 x4) =====================

function genWallTileset() {
  const tiles = [];
  const rnd = noiseSeed(7);

  // Tile 0: Wall top
  let c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [30, 30, 45, 255]);
  fillRect(c, 0, 0, 32, 4, [40, 40, 55, 255]); // top highlight
  scatter(c, 0, 4, 32, 28, 35, [50, 50, 65, 255], 1);
  scatter(c, 0, 4, 32, 28, 20, [20, 20, 30, 255], 2);
  // Brick lines
  fillRect(c, 0, 11, 32, 1, [25, 25, 38, 255]);
  fillRect(c, 0, 23, 32, 1, [25, 25, 38, 255]);
  fillRect(c, 15, 4, 1, 8, [25, 25, 38, 255]);
  fillRect(c, 8, 12, 1, 12, [25, 25, 38, 255]);
  fillRect(c, 24, 12, 1, 12, [25, 25, 38, 255]);
  fillRect(c, 15, 24, 1, 8, [25, 25, 38, 255]);
  tiles.push(c);

  // Tile 1: Wall left edge
  c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [30, 30, 45, 255]);
  fillRect(c, 0, 0, 4, 32, [20, 20, 30, 255]); // dark edge
  fillRect(c, 4, 0, 2, 32, [35, 35, 50, 255]); // transition
  scatter(c, 6, 0, 26, 32, 30, [50, 50, 65, 255], 3);
  fillRect(c, 6, 11, 26, 1, [25, 25, 38, 255]);
  fillRect(c, 6, 23, 26, 1, [25, 25, 38, 255]);
  tiles.push(c);

  // Tile 2: Wall right edge
  c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [30, 30, 45, 255]);
  fillRect(c, 28, 0, 4, 32, [20, 20, 30, 255]);
  fillRect(c, 26, 0, 2, 32, [35, 35, 50, 255]);
  scatter(c, 0, 0, 26, 32, 30, [50, 50, 65, 255], 4);
  fillRect(c, 0, 11, 26, 1, [25, 25, 38, 255]);
  fillRect(c, 0, 23, 26, 1, [25, 25, 38, 255]);
  tiles.push(c);

  // Tile 3: Wall corner
  c = createCanvas(32, 32);
  fillRect(c, 0, 0, 32, 32, [30, 30, 45, 255]);
  fillRect(c, 0, 0, 4, 32, [20, 20, 30, 255]);
  fillRect(c, 0, 0, 32, 4, [40, 40, 55, 255]);
  fillRect(c, 4, 4, 2, 28, [35, 35, 50, 255]);
  fillRect(c, 4, 4, 28, 2, [35, 35, 50, 255]);
  scatter(c, 6, 6, 26, 26, 30, [50, 50, 65, 255], 5);
  tiles.push(c);

  return tiles;
}

// ===================== WEAPON ICONS (32x32 x4) =====================

function genWeaponIcons() {
  const icons = [];

  // W01: Short Sword
  let c = createCanvas(32, 32);
  // Blade (diagonal)
  const bladePts = [[20, 4], [22, 6], [14, 22], [12, 20]];
  for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) {
    // Simple polygon check for blade
    const cx = x, cy = y;
    if (cx + cy >= 24 && cx + cy <= 28 && cx - cy >= -4 && cx - cy <= 8) {
      pxC(c, x, y, [204, 204, 204, 255]); // blade
    }
  }
  // Blade highlight
  for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) {
    const cx = x, cy = y;
    if (cx + cy >= 25 && cx + cy <= 26 && cx - cy >= 0 && cx - cy <= 6) {
      pxC(c, x, y, [255, 255, 255, 255]);
    }
  }
  // Crossguard
  fillRect(c, 18, 20, 7, 2, [246, 201, 14, 255]); // yellow guard
  // Handle
  fillRect(c, 21, 22, 3, 6, [120, 80, 40, 255]); // brown handle
  // Pommel
  pxC(c, 23, 28, [246, 201, 14, 255]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  // W02: Pistol
  c = createCanvas(32, 32);
  // Barrel
  fillRect(c, 8, 10, 14, 4, [61, 61, 79, 255]);
  // Slide
  fillRect(c, 8, 8, 12, 8, [74, 74, 95, 255]);
  fillRect(c, 8, 8, 12, 1, [122, 122, 143, 255]); // highlight
  // Grip
  fillRect(c, 18, 14, 4, 10, [61, 61, 79, 255]);
  fillRect(c, 19, 14, 1, 10, [74, 74, 95, 255]);
  // Trigger guard
  fillRect(c, 14, 16, 4, 1, [61, 61, 79, 255]);
  fillRect(c, 14, 19, 1, 3, [61, 61, 79, 255]);
  fillRect(c, 17, 19, 1, 3, [61, 61, 79, 255]);
  fillRect(c, 14, 22, 4, 1, [61, 61, 79, 255]);
  // Muzzle
  fillRect(c, 6, 10, 2, 4, [45, 45, 63, 255]);
  // Trigger
  pxC(c, 15, 19, [122, 122, 143, 255]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  // W03: Bow
  c = createCanvas(32, 32);
  // Bow arc (left side curve)
  for (let y = 0; y < 32; y++) {
    for (let x = 0; x < 32; x++) {
      const dx = x - 20, dy = y - 16;
      const d = Math.sqrt(dx * dx + dy * dy);
      if (d >= 10 && d <= 12 && x <= 22) {
        pxC(c, x, y, [120, 80, 40, 255]); // brown bow
      }
    }
  }
  // Bow highlights
  for (let y = 0; y < 32; y++) {
    for (let x = 0; x < 32; x++) {
      const dx = x - 20, dy = y - 16;
      const d = Math.sqrt(dx * dx + dy * dy);
      if (d >= 10.5 && d <= 11.5 && x <= 21) {
        pxC(c, x, y, [160, 110, 60, 255]);
      }
    }
  }
  // Bowstring
  fillRect(c, 10, 6, 1, 20, [204, 204, 204, 255]);
  // Arrow
  fillRect(c, 11, 15, 14, 1, [204, 204, 204, 255]); // shaft
  // Arrowhead
  pxC(c, 25, 15, [255, 255, 255, 255]);
  pxC(c, 26, 14, [255, 255, 255, 255]);
  pxC(c, 26, 16, [255, 255, 255, 255]);
  // Fletching
  fillRect(c, 10, 14, 1, 1, [233, 69, 96, 255]);
  fillRect(c, 10, 16, 1, 1, [233, 69, 96, 255]);
  fillRect(c, 9, 13, 1, 1, [233, 69, 96, 255]);
  fillRect(c, 9, 17, 1, 1, [233, 69, 96, 255]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  // W04: Staff
  c = createCanvas(32, 32);
  // Staff shaft
  fillRect(c, 15, 10, 2, 20, [120, 80, 40, 255]);
  fillRect(c, 15, 10, 1, 20, [160, 110, 60, 255]); // highlight
  // Orb
  fillEllipse(c, 16, 8, 5, 5, [157, 78, 221, 255]); // purple
  fillEllipse(c, 14, 6, 2, 2, [200, 120, 240, 255]); // highlight
  // Orb glow
  ringEllipse(c, 16, 8, 6, 6, [157, 78, 221, 80], 0.6);
  // Staff decorations
  fillRect(c, 14, 14, 4, 1, [246, 201, 14, 255]); // gold band
  fillRect(c, 14, 20, 4, 1, [246, 201, 14, 255]);
  // Wrapping at top
  fillRect(c, 13, 10, 6, 2, [100, 60, 30, 255]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  return icons;
}

// ===================== ITEM ICONS (32x32 x4) =====================

function genItemIcons() {
  const icons = [];

  // I01: HP Potion
  let c = createCanvas(32, 32);
  // Bottle body
  fillEllipse(c, 16, 20, 6, 7, [45, 45, 63, 255]); // glass outline dark
  fillEllipse(c, 16, 20, 5, 6, [233, 69, 96, 255]); // red liquid
  // Liquid surface
  fillRect(c, 11, 16, 10, 1, [255, 100, 130, 255]);
  // Bottle neck
  fillRect(c, 14, 8, 4, 6, [45, 45, 63, 255]);
  fillRect(c, 15, 8, 2, 6, [60, 60, 80, 200]);
  // Cork
  fillRect(c, 14, 6, 4, 3, [120, 80, 40, 255]);
  // Highlight on glass
  pxC(c, 13, 18, [255, 255, 255, 180]);
  pxC(c, 13, 19, [255, 255, 255, 120]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  // I02: Strength Charm (amulet)
  c = createCanvas(32, 32);
  // Chain
  fillRect(c, 12, 5, 8, 1, [246, 201, 14, 255]);
  fillRect(c, 12, 5, 1, 3, [246, 201, 14, 255]);
  fillRect(c, 19, 5, 1, 3, [246, 201, 14, 255]);
  fillRect(c, 13, 7, 6, 1, [246, 201, 14, 255]);
  // Amulet body
  fillEllipse(c, 16, 18, 7, 7, [246, 201, 14, 255]); // gold
  fillEllipse(c, 16, 18, 5, 5, [255, 253, 0, 255]); // bright center
  // Gem
  fillEllipse(c, 16, 18, 3, 3, [233, 69, 96, 255]); // red gem
  pxC(c, 15, 17, [255, 255, 255, 255]); // shine
  // Decoration
  pxC(c, 16, 24, [246, 201, 14, 255]);
  pxC(c, 14, 22, [246, 201, 14, 255]);
  pxC(c, 18, 22, [246, 201, 14, 255]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  // I03: Speed Boots
  c = createCanvas(32, 32);
  // Boot body
  fillRect(c, 10, 14, 8, 10, [78, 137, 222, 255]); // blue boot
  fillRect(c, 10, 14, 8, 1, [100, 160, 240, 255]); // top highlight
  fillRect(c, 10, 23, 8, 1, [50, 100, 180, 255]); // sole
  // Boot toe (extends right)
  fillRect(c, 18, 20, 8, 3, [78, 137, 222, 255]);
  fillRect(c, 18, 20, 8, 1, [100, 160, 240, 255]);
  fillRect(c, 18, 23, 8, 1, [50, 100, 180, 255]);
  // Cuff
  fillRect(c, 10, 14, 8, 2, [246, 201, 14, 255]); // gold trim
  // Laces
  fillRect(c, 13, 16, 3, 1, [255, 255, 255, 255]);
  fillRect(c, 13, 18, 3, 1, [255, 255, 255, 255]);
  // Speed lines
  pxC(c, 27, 21, [255, 253, 0, 200]);
  pxC(c, 28, 22, [255, 253, 0, 150]);
  pxC(c, 29, 21, [255, 253, 0, 100]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  // I04: Armor (shield)
  c = createCanvas(32, 32);
  // Shield shape
  for (let y = 6; y <= 26; y++) {
    for (let x = 6; x <= 26; x++) {
      const dx = x - 16, dy = y - 16;
      // Shield: wide at top, pointed at bottom
      const hw = 9 - Math.max(0, (y - 18)) * 0.8;
      if (Math.abs(dx) <= hw && y >= 6 && y <= 26) {
        if (y <= 18 || Math.abs(dx) <= hw) {
          pxC(c, x, y, [122, 122, 143, 255]); // gray
        }
      }
    }
  }
  // Shield border
  for (let y = 6; y <= 26; y++) {
    for (let x = 6; x <= 26; x++) {
      const dx = x - 16, dy = y - 16;
      const hw = 9 - Math.max(0, (y - 18)) * 0.8;
      if (Math.abs(dx) <= hw + 1 && Math.abs(dx) >= hw - 0.5 && y <= 22) {
        pxC(c, x, y, [45, 45, 63, 255]);
      }
    }
  }
  // Shield center emblem (cross)
  fillRect(c, 15, 10, 2, 12, [233, 69, 96, 255]);
  fillRect(c, 11, 14, 10, 2, [233, 69, 96, 255]);
  // Highlight
  fillRect(c, 10, 8, 4, 1, [255, 255, 255, 200]);
  pxC(c, 10, 9, [255, 255, 255, 150]);
  addOutline(c, C.OUTLINE);
  icons.push(c);

  return icons;
}

// ===================== SLOT BACKGROUNDS (24x24) =====================

function genWeaponSlot() {
  const c = createCanvas(24, 24);
  fillRect(c, 0, 0, 24, 24, [42, 42, 63, 255]); // UI_BD border
  fillRect(c, 1, 1, 22, 22, [58, 58, 79, 255]); // UI_DK inner
  // Corner accents
  pxC(c, 1, 1, [78, 137, 222, 255]); // blue corner
  pxC(c, 22, 1, [78, 137, 222, 255]);
  pxC(c, 1, 22, [78, 137, 222, 255]);
  pxC(c, 22, 22, [78, 137, 222, 255]);
  // Inner shadow
  fillRect(c, 1, 1, 22, 1, [45, 45, 63, 255]);
  fillRect(c, 1, 22, 22, 1, [45, 45, 63, 255]);
  return c;
}

function genItemSlot() {
  const c = createCanvas(24, 24);
  fillRect(c, 0, 0, 24, 24, [42, 42, 63, 255]);
  fillRect(c, 1, 1, 22, 22, [58, 58, 79, 255]);
  // Green corners for items
  pxC(c, 1, 1, [107, 200, 107, 255]);
  pxC(c, 22, 1, [107, 200, 107, 255]);
  pxC(c, 1, 22, [107, 200, 107, 255]);
  pxC(c, 22, 22, [107, 200, 107, 255]);
  fillRect(c, 1, 1, 22, 1, [45, 45, 63, 255]);
  fillRect(c, 1, 22, 22, 1, [45, 45, 63, 255]);
  return c;
}

// ===================== 9-SLICE PANELS (36x36, 12px corners) =====================

function gen9Slice(fillCol, borderCol, cornerCol) {
  const c = createCanvas(36, 36);
  // Fill
  fillRect(c, 0, 0, 36, 36, borderCol);
  fillRect(c, 1, 1, 34, 34, fillCol);
  // Corner decorations
  // TL
  fillRect(c, 1, 1, 3, 1, cornerCol);
  fillRect(c, 1, 1, 1, 3, cornerCol);
  // TR
  fillRect(c, 32, 1, 3, 1, cornerCol);
  fillRect(c, 34, 1, 1, 3, cornerCol);
  // BL
  fillRect(c, 1, 32, 3, 1, cornerCol);
  fillRect(c, 1, 34, 1, 3, cornerCol);
  // BR
  fillRect(c, 32, 32, 3, 1, cornerCol);
  fillRect(c, 34, 34, 1, 3, cornerCol);
  // Inner highlight
  fillRect(c, 2, 2, 32, 1, [fillCol[0] + 20, fillCol[1] + 20, fillCol[2] + 20, 255]);
  return c;
}

function genShopPanel() {
  return gen9Slice([30, 30, 47, 255], [42, 42, 63, 255], [78, 137, 222, 255]);
}

function genShopCard() {
  return gen9Slice([40, 40, 55, 255], [58, 58, 79, 255], [246, 201, 14, 255]);
}

function genBtnReroll() {
  const c = gen9Slice([45, 45, 63, 255], [58, 58, 79, 255], [122, 122, 143, 255]);
  // Arrow icon in center
  const cx = 18, cy = 18;
  for (let r = 0; r < 5; r++) {
    const a = r * 0.4;
    pxC(c, Math.round(cx + Math.cos(a) * r), Math.round(cy + Math.sin(a) * r), [204, 204, 204, 255]);
  }
  return c;
}

function genBtnConfirm() {
  const c = gen9Slice([50, 80, 55, 255], [42, 42, 63, 255], [107, 200, 107, 255]);
  // Checkmark in center
  const cx = 18, cy = 18;
  const check = [[14, 18], [15, 19], [16, 20], [17, 19], [18, 18], [19, 17], [20, 16], [21, 15]];
  for (const [x, y] of check) pxC(c, x + 4, y, [255, 255, 255, 255]);
  return c;
}

// ===================== MAIN =====================

console.log('=== P1 Sprite Generation (Batch 1) ===\n');

console.log('[Ground Tileset]');
saveSheet('effects', 'tileset_ground', genGroundTileset(), 32, 32);
saveSheet('effects', 'tileset_wall', genWallTileset(), 32, 32);

console.log('\n[Weapon Icons]');
saveSheet('ui', 'weapons', genWeaponIcons(), 32, 32);

console.log('\n[Item Icons]');
saveSheet('ui', 'items', genItemIcons(), 32, 32);

console.log('\n[Slot Backgrounds]');
saveImg('ui', 'slot_weapon', genWeaponSlot());
saveImg('ui', 'slot_item', genItemSlot());

console.log('\n[Shop Panels]');
saveImg('ui', 'panel_shop', genShopPanel());
saveImg('ui', 'panel_card', genShopCard());
saveImg('ui', 'btn_reroll', genBtnReroll());
saveImg('ui', 'btn_confirm', genBtnConfirm());

console.log('\n=== Done! 10 files generated. ===');
