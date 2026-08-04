const path = require('path');
const fs = require('fs');
const E = require('./png-engine.js');
const { createCanvas, px, pxC, fillRect, fillEllipse, ringEllipse, addOutline, combineFrames, encodePNG, C } = E;

const ROOT = 'c:/Users/Administrator/WorkBuddy/2026-08-03-15-51-20/assets/sprites';

function saveSprite(dir, name, frames, fw, fh) {
  const sheet = combineFrames(frames, fw, fh);
  const png = encodePNG(sheet.w, sheet.h, sheet.data);
  const outPath = path.join(ROOT, dir, name + '.png');
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, png);
  console.log('  done: ' + dir + '/' + name + '.png (' + sheet.w + 'x' + sheet.h + ')');
}
function saveSingle(dir, name, canvas) {
  const png = encodePNG(canvas.w, canvas.h, canvas.data);
  const outPath = path.join(ROOT, dir, name + '.png');
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, png);
  console.log('  done: ' + dir + '/' + name + '.png (' + canvas.w + 'x' + canvas.h + ')');
}

// ===================== FIGHTER (32x32) =====================

function drawFighter(c, bob, legL, legR) {
  // Cape
  fillRect(c, 11, 13+bob, 10, 2, C.RED);
  fillRect(c, 10, 15+bob, 12, 3, C.RED);
  fillRect(c, 9, 18+bob, 14, 4, C.RED);
  fillRect(c, 9, 22+bob, 14, 1, C.RED_DK);
  fillRect(c, 9, 18+bob, 1, 4, C.RED_DK);
  fillRect(c, 22, 18+bob, 1, 4, C.RED_DK);
  // Torso
  fillRect(c, 11, 12+bob, 10, 6, C.UI_LITE);
  fillRect(c, 11, 12+bob, 10, 1, C.UI_GRAY);
  fillRect(c, 11, 17+bob, 10, 1, C.UI_GRAY);
  fillRect(c, 11, 15+bob, 10, 1, C.UI_GRAY);
  pxC(c, 15, 15+bob, C.YELLOW); pxC(c, 16, 15+bob, C.YELLOW);
  // Shoulders
  fillRect(c, 10, 12+bob, 2, 2, C.WHITE);
  fillRect(c, 20, 12+bob, 2, 2, C.WHITE);
  pxC(c, 10, 13+bob, C.UI_GRAY); pxC(c, 21, 13+bob, C.UI_GRAY);
  // Arms
  fillRect(c, 9, 13+bob, 2, 4, C.UI_LITE);
  fillRect(c, 21, 13+bob, 2, 4, C.UI_LITE);
  fillRect(c, 9, 17+bob, 2, 1, C.PINK);
  fillRect(c, 21, 17+bob, 2, 1, C.PINK);
  // Helmet
  fillEllipse(c, 16, 6+bob, 4, 3, C.UI_LITE);
  for (let y = 7+bob; y <= 9+bob; y++) for (let x = 12; x <= 19; x++) {
    const dx = (x - 16) / 4, dy = (y - 6 - bob) / 3;
    if (dx*dx + dy*dy <= 1) pxC(c, x, y, C.UI_GRAY);
  }
  fillEllipse(c, 14, 5+bob, 2, 1, C.WHITE);
  fillRect(c, 11, 8+bob, 10, 1, C.UI_LITE);
  pxC(c, 11, 8+bob, C.UI_GRAY); pxC(c, 20, 8+bob, C.UI_GRAY);
  // Face
  fillRect(c, 13, 9+bob, 6, 2, C.PINK);
  pxC(c, 14, 9+bob, C.OUTLINE); pxC(c, 17, 9+bob, C.OUTLINE);
  // Legs
  fillRect(c, 12+legL, 19+bob, 3, 4, C.UI_LITE);
  fillRect(c, 17+legR, 19+bob, 3, 4, C.UI_LITE);
  fillRect(c, 12+legL, 19+bob, 3, 1, C.UI_GRAY);
  fillRect(c, 17+legR, 19+bob, 3, 1, C.UI_GRAY);
  fillRect(c, 12+legL, 23+bob, 3, 1, C.UI_GRAY);
  fillRect(c, 17+legR, 23+bob, 3, 1, C.UI_GRAY);
  addOutline(c, C.OUTLINE);
}

function genFighterIdle() {
  return [0, -1, 0, 1].map(bob => { const c = createCanvas(32, 32); drawFighter(c, bob, 0, 0); return c; });
}

function genFighterWalk() {
  const d = [{b:0,lL:0,lR:0},{b:-1,lL:1,lR:-1},{b:1,lL:0,lR:0},{b:0,lL:-1,lR:1},{b:-1,lL:0,lR:0},{b:1,lL:1,lR:-1}];
  return d.map(x => { const c = createCanvas(32, 32); drawFighter(c, x.b, x.lL, x.lR); return c; });
}

// ===================== SLIME (24x24) =====================

function drawSlime(c, cx, cy, rx, ry, flash) {
  const body = flash ? C.WHITE : C.GREEN;
  const hi = flash ? C.WHITE : C.GREEN_LT;
  const sh = flash ? [200,200,200,255] : C.GREEN_DK;
  fillEllipse(c, cx, cy, rx, ry, body);
  fillEllipse(c, cx - 1, cy - 1, Math.max(1, rx - 2), Math.max(1, ry - 2), hi);
  for (let x = 0; x < c.w; x++) {
    const dx = (x - cx) / rx;
    if (Math.abs(dx) <= 1) {
      const ey = cy + Math.sqrt(Math.max(0, 1 - dx * dx)) * ry;
      pxC(c, x, Math.round(ey) - 1, sh);
    }
  }
  pxC(c, cx - 2, cy - 1, C.OUTLINE);
  pxC(c, cx + 1, cy - 1, C.OUTLINE);
  pxC(c, cx - 2, cy - 2, [255, 255, 255, 200]);
  pxC(c, cx + 1, cy - 2, [255, 255, 255, 200]);
  pxC(c, cx - 1, cy + 1, C.OUTLINE);
  pxC(c, cx, cy + 1, C.OUTLINE);
  addOutline(c, C.OUTLINE);
}

function genSlimeMove() {
  const c0 = createCanvas(24, 24); drawSlime(c0, 12, 13, 8, 5, false);
  const c1 = createCanvas(24, 24); drawSlime(c1, 12, 12, 6, 7, false);
  return [c0, c1];
}

function genSlimeDeath() {
  const f = [];
  let c = createCanvas(24, 24); drawSlime(c, 12, 13, 8, 5, true); f.push(c);
  c = createCanvas(24, 24);
  fillEllipse(c, 9, 12, 4, 4, C.GREEN); fillEllipse(c, 15, 12, 4, 4, C.GREEN);
  pxC(c, 7, 11, C.OUTLINE); pxC(c, 17, 11, C.OUTLINE); addOutline(c, C.OUTLINE); f.push(c);
  c = createCanvas(24, 24);
  fillEllipse(c, 6, 12, 3, 3, [107,200,107,180]); fillEllipse(c, 18, 12, 3, 3, [107,200,107,180]);
  [[8,9],[16,8],[10,16],[14,15],[7,6]].forEach(([x,y]) => pxC(c, x, y, [107,200,107,150]));
  addOutline(c, [13,13,18,120]); f.push(c);
  c = createCanvas(24, 24);
  [[6,8],[9,12],[12,7],[15,14],[8,16],[18,6],[14,18],[20,12]].forEach(([x,y]) => pxC(c, x, y, [107,200,107,100]));
  f.push(c);
  return f;
}

// ===================== SKELETON (32x32) =====================

function drawSkeleton(c, bob, legL, legR) {
  fillRect(c, 12, 10+bob, 8, 7, C.UI_LITE);
  fillRect(c, 12, 11+bob, 8, 1, C.OUTLINE);
  fillRect(c, 12, 13+bob, 8, 1, C.OUTLINE);
  fillRect(c, 12, 15+bob, 8, 1, C.OUTLINE);
  fillRect(c, 15, 10+bob, 2, 7, C.UI_GRAY);
  fillRect(c, 10, 11+bob, 2, 5, C.UI_LITE);
  fillRect(c, 20, 11+bob, 2, 5, C.UI_LITE);
  fillRect(c, 10, 12+bob, 2, 1, C.OUTLINE);
  fillRect(c, 20, 12+bob, 2, 1, C.OUTLINE);
  fillRect(c, 10, 14+bob, 2, 1, C.OUTLINE);
  fillRect(c, 20, 14+bob, 2, 1, C.OUTLINE);
  fillEllipse(c, 16, 6+bob, 4, 3, C.UI_LITE);
  fillEllipse(c, 14, 5+bob, 2, 1, C.WHITE);
  fillRect(c, 13, 6+bob, 2, 2, C.OUTLINE);
  fillRect(c, 17, 6+bob, 2, 2, C.OUTLINE);
  pxC(c, 14, 7+bob, C.LASER_R); pxC(c, 17, 7+bob, C.LASER_R);
  fillRect(c, 14, 8+bob, 4, 1, C.OUTLINE);
  pxC(c, 15, 8+bob, C.UI_LITE); pxC(c, 17, 8+bob, C.UI_LITE);
  fillRect(c, 12+legL, 17+bob, 3, 5, C.UI_LITE);
  fillRect(c, 17+legR, 17+bob, 3, 5, C.UI_LITE);
  fillRect(c, 12+legL, 19+bob, 3, 1, C.OUTLINE);
  fillRect(c, 17+legR, 19+bob, 3, 1, C.OUTLINE);
  fillRect(c, 12+legL, 22+bob, 3, 1, C.UI_GRAY);
  fillRect(c, 17+legR, 22+bob, 3, 1, C.UI_GRAY);
  addOutline(c, C.OUTLINE);
}

function genSkeletonMove() {
  const d = [{b:0,lL:1,lR:-1},{b:-1,lL:0,lR:0},{b:0,lL:-1,lR:1},{b:-1,lL:0,lR:0}];
  return d.map(x => { const c = createCanvas(32, 32); drawSkeleton(c, x.b, x.lL, x.lR); return c; });
}

function genSkeletonDeath() {
  const f = [];
  let c = createCanvas(32, 32); drawSkeleton(c, 0, 0, 0);
  for (let i = 0; i < c.data.length; i += 4) { if (c.data[i+3] > 0) { c.data[i] = 255; c.data[i+1] = 255; c.data[i+2] = 255; } }
  f.push(c);
  c = createCanvas(32, 32);
  fillEllipse(c, 16, 3, 4, 3, C.UI_LITE);
  pxC(c, 14, 3, C.OUTLINE); pxC(c, 17, 3, C.OUTLINE);
  fillRect(c, 8, 12, 6, 4, C.UI_LITE); fillRect(c, 18, 12, 6, 4, C.UI_LITE);
  fillRect(c, 8, 13, 6, 1, C.OUTLINE); fillRect(c, 18, 13, 6, 1, C.OUTLINE);
  addOutline(c, C.OUTLINE); f.push(c);
  c = createCanvas(32, 32);
  [[6,8],[10,14],[20,10],[24,16],[14,20],[18,22]].forEach(([x,y]) => { fillRect(c, x, y, 3, 2, [204,204,204,180]); pxC(c, x, y, C.UI_GRAY); });
  fillEllipse(c, 16, 4, 3, 2, [204,204,204,180]);
  pxC(c, 15, 4, [13,13,18,150]); pxC(c, 17, 4, [13,13,18,150]);
  f.push(c);
  c = createCanvas(32, 32);
  [[8,6],[12,12],[16,8],[20,14],[10,18],[22,20],[14,22],[18,16]].forEach(([x,y]) => pxC(c, x, y, [204,204,204,100]));
  f.push(c);
  return f;
}

// ===================== EFFECTS =====================

function genFxHit() {
  const f = [], cx = 16, cy = 16;
  let c = createCanvas(32, 32); fillEllipse(c, cx, cy, 3, 3, C.WHITE); f.push(c);
  c = createCanvas(32, 32); ringEllipse(c, cx, cy, 6, 6, [255,255,255,220], 0.5);
  for (let a = 0; a < 8; a++) { const ang = (a/8)*Math.PI*2; pxC(c, Math.round(cx+Math.cos(ang)*7), Math.round(cy+Math.sin(ang)*7), C.WHITE); }
  f.push(c);
  c = createCanvas(32, 32); ringEllipse(c, cx, cy, 10, 10, [255,255,255,150], 0.7);
  for (let a = 0; a < 8; a++) { const ang = (a/8)*Math.PI*2; pxC(c, Math.round(cx+Math.cos(ang)*11), Math.round(cy+Math.sin(ang)*11), [255,255,255,180]); }
  f.push(c);
  c = createCanvas(32, 32); ringEllipse(c, cx, cy, 14, 14, [255,255,255,60], 0.8);
  for (let a = 0; a < 8; a++) { const ang = (a/8)*Math.PI*2; pxC(c, Math.round(cx+Math.cos(ang)*15), Math.round(cy+Math.sin(ang)*15), [255,255,255,80]); }
  f.push(c);
  return f;
}

function genFxCrit() {
  const f = [], cx = 16, cy = 16;
  for (let i = 0; i < 6; i++) {
    const c = createCanvas(32, 32);
    const radius = 3 + i * 2.5, alpha = Math.max(0, 255 - i * 38), col = [255, 253, 0, alpha];
    for (let a = 0; a < 12; a++) { const ang = (a/12)*Math.PI*2; for (let r = 2; r <= radius; r++) pxC(c, Math.round(cx+Math.cos(ang)*r), Math.round(cy+Math.sin(ang)*r), col); }
    if (i < 3) fillEllipse(c, cx, cy, 3-i, 3-i, [255,253,0,alpha]);
    for (let a = 0; a < 8; a++) { const ang = (a/8)*Math.PI*2 + i*0.4; pxC(c, Math.round(cx+Math.cos(ang)*(radius+2)), Math.round(cy+Math.sin(ang)*(radius+2)), col); }
    f.push(c);
  }
  return f;
}

function genFxDeath() {
  const f = [], cx = 16, cy = 16;
  const colors = [C.RED, C.GREEN, C.E_YEL, C.UI_LITE];
  for (let i = 0; i < 4; i++) {
    const c = createCanvas(32, 32);
    const radius = 2 + i * 4, alpha = Math.max(0, 255 - i * 60);
    for (let p = 0; p < 12; p++) {
      const ang = (p/12)*Math.PI*2, r = radius + (p%2)*2, col = colors[p % colors.length];
      pxC(c, Math.round(cx+Math.cos(ang)*r), Math.round(cy+Math.sin(ang)*r), [col[0], col[1], col[2], alpha]);
      if (i > 0) pxC(c, Math.round(cx+Math.cos(ang)*(r-3)), Math.round(cy+Math.sin(ang)*(r-3)), [col[0], col[1], col[2], Math.floor(alpha/2)]);
    }
    f.push(c);
  }
  return f;
}

function genFxLevelUp() {
  const f = [], cx = 16, cy = 16;
  for (let i = 0; i < 6; i++) {
    const c = createCanvas(32, 32);
    const radius = 2 + i * 2.5, alpha = Math.max(0, 255 - i * 35);
    ringEllipse(c, cx, cy, radius, radius, [57, 255, 20, alpha], 0.5);
    if (i < 4) fillEllipse(c, cx, cy, Math.max(1, radius-2), Math.max(1, radius-2), [57, 255, 20, Math.floor(alpha/3)]);
    for (let a = 0; a < 3; a++) {
      const baseAng = -Math.PI/2 + (a-1)*0.35;
      for (let r = 0; r < 4; r++) pxC(c, Math.round(cx+Math.cos(baseAng)*(radius+r)), Math.round(cy+Math.sin(baseAng)*(radius+r)), [57,255,20,Math.max(0,alpha-r*30)]);
    }
    f.push(c);
  }
  return f;
}

function genFxPickup() {
  const f = [], cx = 8, cy = 8;
  for (let i = 0; i < 4; i++) {
    const c = createCanvas(16, 16);
    const sz = 1 + i, alpha = Math.max(0, 255 - i * 50);
    fillRect(c, cx-sz, cy, sz*2+1, 1, [255,253,0,alpha]);
    fillRect(c, cx, cy-sz, 1, sz*2+1, [255,253,0,alpha]);
    if (sz > 1) for (let r = 1; r <= sz; r++) { const a = Math.max(0, alpha-r*20); pxC(c, cx+r, cy+r, [255,253,0,a]); pxC(c, cx-r, cy-r, [255,253,0,a]); pxC(c, cx+r, cy-r, [255,253,0,a]); pxC(c, cx-r, cy+r, [255,253,0,a]); }
    pxC(c, cx, cy, [255,255,255,alpha]);
    f.push(c);
  }
  return f;
}

// ===================== UI =====================

function genBarHpBg() { const c = createCanvas(120, 8); fillRect(c, 0, 0, 120, 8, C.UI_BD); fillRect(c, 1, 1, 118, 6, C.UI_DK); for (let i = 20; i < 120; i += 20) fillRect(c, i, 1, 1, 6, C.UI_BD); return c; }
function genBarHpFill() { const c = createCanvas(120, 8); fillRect(c, 0, 0, 120, 8, C.RED); fillRect(c, 0, 0, 120, 1, [255,100,130,255]); fillRect(c, 0, 7, 120, 1, C.RED_DK); return c; }
function genBarXpBg() { const c = createCanvas(120, 4); fillRect(c, 0, 0, 120, 4, C.UI_BD); fillRect(c, 1, 1, 118, 2, C.UI_DK); return c; }
function genBarXpFill() { const c = createCanvas(120, 4); fillRect(c, 0, 0, 120, 4, C.GREEN); fillRect(c, 0, 0, 120, 1, C.GREEN_LT); return c; }
function genIconCoin() { const c = createCanvas(16, 16); fillEllipse(c, 8, 8, 6, 6, C.YELLOW); fillEllipse(c, 8, 8, 5, 5, C.E_YEL); fillEllipse(c, 7, 7, 2, 2, C.WHITE); fillRect(c, 7, 5, 2, 6, [180,130,0,255]); addOutline(c, C.OUTLINE); return c; }

// ===================== MAIN =====================

console.log('=== P0 Sprite Generation ===\n');

console.log('[Characters]');
saveSprite('characters', 'fighter_idle', genFighterIdle(), 32, 32);
saveSprite('characters', 'fighter_walk', genFighterWalk(), 32, 32);

console.log('\n[Enemies]');
saveSprite('enemies', 'slime_move', genSlimeMove(), 24, 24);
saveSprite('enemies', 'slime_death', genSlimeDeath(), 24, 24);
saveSprite('enemies', 'skeleton_move', genSkeletonMove(), 32, 32);
saveSprite('enemies', 'skeleton_death', genSkeletonDeath(), 32, 32);

console.log('\n[Effects]');
saveSprite('effects', 'fx_hit', genFxHit(), 32, 32);
saveSprite('effects', 'fx_crit', genFxCrit(), 32, 32);
saveSprite('effects', 'fx_death', genFxDeath(), 32, 32);
saveSprite('effects', 'fx_levelup', genFxLevelUp(), 32, 32);
saveSprite('effects', 'fx_pickup', genFxPickup(), 16, 16);

console.log('\n[UI]');
saveSingle('ui', 'bar_hp_bg', genBarHpBg());
saveSingle('ui', 'bar_hp_fill', genBarHpFill());
saveSingle('ui', 'bar_xp_bg', genBarXpBg());
saveSingle('ui', 'bar_xp_fill', genBarXpFill());
saveSingle('ui', 'icon_coin', genIconCoin());

console.log('\n=== Done! 16 files generated. ===');
