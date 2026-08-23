'use strict';

// Sky Go 26.2.3 ships a native keystore built for Electron 22. This adapter
// preserves its AES-256-GCM contract on Electron 41 without changing Sky's
// authentication, player, licensing, or DRM code.
const crypto = require('crypto');
const Module = require('module');

const originalNodeLoader = Module._extensions['.node'];
const builtInKey = Buffer.from('YEpg8O5uHamxnXvlisr8ligxVFOE5HHe', 'utf8');

function keyOrDefault(candidate) {
  return Buffer.isBuffer(candidate) && candidate.length > 0 ? candidate : builtInKey;
}

function encipher(iv, plaintext, key, authData) {
  if (!Buffer.isBuffer(iv)) throw new TypeError('No iv');
  if (!Buffer.isBuffer(plaintext)) throw new TypeError('No plaintext');
  const actualKey = keyOrDefault(key);
  const cipher = crypto.createCipheriv(`aes-${actualKey.length * 8}-gcm`, actualKey, iv);
  if (Buffer.isBuffer(authData) && authData.length > 0) cipher.setAAD(authData);
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return { ciphertext, authTag: cipher.getAuthTag() };
}

function decipher(iv, ciphertext, authTag, key, authData) {
  if (!Buffer.isBuffer(iv)) throw new TypeError('No iv');
  if (!Buffer.isBuffer(ciphertext)) throw new TypeError('No ciphertext');
  if (!Buffer.isBuffer(authTag)) throw new TypeError('No authTag');
  const actualKey = keyOrDefault(key);
  try {
    const decipherer = crypto.createDecipheriv(`aes-${actualKey.length * 8}-gcm`, actualKey, iv);
    if (Buffer.isBuffer(authData) && authData.length > 0) decipherer.setAAD(authData);
    decipherer.setAuthTag(authTag);
    const plaintext = Buffer.concat([decipherer.update(ciphertext), decipherer.final()]);
    return { plaintext, authOk: true };
  } catch (_) {
    return { plaintext: Buffer.alloc(0), authOk: false };
  }
}

Module._extensions['.node'] = function loadNativeOrCompatibility(module, filename) {
  if (filename.endsWith('/@qgo/client-lib-electron-keystore/build/Release/keystore.node')) {
    module.exports = { encipher, decipher };
    return;
  }
  return originalNodeLoader(module, filename);
};
