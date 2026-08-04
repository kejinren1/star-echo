const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

// ===================== PNG ENCODER =====================

const crcTable = (() => {
  const t = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    t[i] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) crc = crcTable[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function makeChunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crcBuf = Buffer.alloc(4); crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crcBuf]);
}

function encodePNG(w, h, rgba) {
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  const raw = Buffer.alloc((1 + w * 4) * h);
  let pos = 0;
  for (let y = 0; y < h; y++) {
    raw[pos++] = 0;
    for (let x = 0; x < w; x++) {
      const si = (y * w + x) * 4;
      raw[pos++] = rgba[si]; raw[pos++] = rgba[si+1]; raw[pos++] = rgba[si+2]; raw[pos++] = rgba[si+3];
    }
  }
  const compressed = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([sig, makeChunk('IHDR', ihdr), makeChunk('IDAT', compressed), makeChunk('IEND', Buffer.alloc(0))]);
}

// ===================== CANVAS =====================

function createCanvas(w, h) {
  return { w, h, data: new Uint8Array(w * h * 4) };
}

function px(c, x, y, r, g, b, a) { if (a === undefined) a = 255; if (x < 0 || y < 0 || x >= c.w || y >= c.h) return; const i = (y * c.w + x) * 4; c.data[i] = r; c.data[i+1] = g; c.data[i+2] = b; c.data[i+3] = a; }
function pxC(c, x, y, col) { px(c, x, y, col[0], col[1], col[2], col[3] !== undefined ? col[3] : 255); }
function fillRect(c, x, y, w, h, col) { for (let dy = 0; dy < h; dy++) for (let dx = 0; dx < w; dx++) pxC(c, x + dx, y + dy, col); }
function fillEllipse(c, cx, cy, rx, ry, col) {
  for (let y = Math.max(0, Math.floor(cy - ry)); y <= Math.min(c.h - 1, Math.ceil(cy + ry)); y++)
    for (let x = Math.max(0, Math.floor(cx - rx)); x <= Math.min(c.w - 1, Math.ceil(cx + rx)); x++) {
      const dx = (x - cx) / rx, dy = (y - cy) / ry;
      if (dx * dx + dy * dy <= 1) pxC(c, x, y, col);
    }
}
function ringEllipse(c, cx, cy, rx, ry, col, ir) {
  for (let y = 0; y < c.h; y++) for (let x = 0; x < c.w; x++) {
    const dx = (x - cx) / rx, dy = (y - cy) / ry, d2 = dx * dx + dy * dy;
    if (d2 <= 1 && d2 >= ir) pxC(c, x, y, col);
  }
}
function addOutline(c, col) {
  const marks = [];
  for (let y = 0; y < c.h; y++) for (let x = 0; x < c.w; x++) {
    if (c.data[(y * c.w + x) * 4 + 3] > 0) continue;
    const dirs = [[-1,0],[1,0],[0,-1],[0,1],[-1,-1],[1,-1],[-1,1],[1,1]];
    for (const [dx, dy] of dirs) {
      const nx = x + dx, ny = y + dy;
      if (nx >= 0 && ny >= 0 && nx < c.w && ny < c.h && c.data[(ny * c.w + nx) * 4 + 3] > 0) { marks.push([x, y]); break; }
    }
  }
  for (const [x, y] of marks) pxC(c, x, y, col);
}
function combineFrames(frames, fw, fh) {
  const sheet = createCanvas(fw * frames.length, fh);
  for (let i = 0; i < frames.length; i++) {
    const f = frames[i];
    for (let y = 0; y < fh; y++) for (let x = 0; x < fw; x++) {
      const si = (y * f.w + x) * 4, di = (y * sheet.w + (i * fw + x)) * 4;
      sheet.data[di] = f.data[si]; sheet.data[di+1] = f.data[si+1]; sheet.data[di+2] = f.data[si+2]; sheet.data[di+3] = f.data[si+3];
    }
  }
  return sheet;
}
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

// ===================== COLORS =====================

const C = {
  OUTLINE: [13, 13, 18, 255], RED: [233, 69, 96, 255], RED_DK: [180, 50, 75, 255],
  PINK: [243, 129, 129, 255], YELLOW: [246, 201, 14, 255], GREEN: [107, 200, 107, 255],
  GREEN_LT: [140, 220, 140, 255], GREEN_DK: [70, 150, 70, 255], WHITE: [255, 255, 255, 255],
  UI_LITE: [204, 204, 204, 255], UI_GRAY: [122, 122, 143, 255], UI_DK: [58, 58, 79, 255],
  UI_BD: [42, 42, 63, 255], E_YEL: [255, 253, 0, 255], LASER_R: [255, 7, 58, 255],
};

module.exports = {
  createCanvas, px, pxC, fillRect, fillEllipse, ringEllipse, addOutline,
  combineFrames, saveSprite, saveSingle, encodePNG, C
};
