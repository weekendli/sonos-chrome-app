#!/usr/bin/env node
// Chrome's PWA commands require a local debugging pipe. No TCP port is opened.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {fileURLToPath} from 'node:url';
import {spawn, execFileSync} from 'node:child_process';

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const home = os.homedir();
const profile = path.join(home, 'Library/Application Support/Sonos Chrome App');
const webApp = path.join(home, 'Applications/Chrome Apps.localized/Sonos.app');
const chromeBin = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const url = 'https://play.sonos.com/en-us/web-app';
const manifestId = 'https://play.sonos.com/';
const iconTool = path.join(project, 'build/tools/set-icon');
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
function log(message) {
  const dir = path.join(home, 'Library/Logs/Sonos Chrome App');
  fs.mkdirSync(dir, {recursive: true});
  fs.appendFileSync(path.join(dir, 'install.log'), `${new Date().toISOString()} ${message}\n`);
}
function dedicatedPids() {
  return execFileSync('/bin/ps', ['-ax', '-o', 'pid=,command='], {encoding: 'utf8'})
    .split('\n').flatMap(line => {
      const m = line.trim().match(/^(\d+)\s+(.*)$/);
      if (!m || !m[2].startsWith(`${chromeBin} `)) return [];
      const flag = `--user-data-dir=${profile}`;
      return m[2].includes(`${flag} `) || m[2].endsWith(flag) ? [Number(m[1])] : [];
    });
}
async function setup() {
  if (process.platform !== 'darwin') throw new Error('macOS is required.');
  if (!fs.existsSync(chromeBin)) throw new Error('Install Google Chrome in /Applications first.');
  if (!fs.existsSync(iconTool)) throw new Error('Run bash scripts/build.sh first.');
  // Refuse to redirect an existing Sonos shim belonging to a different Chrome profile.
  if (fs.existsSync(webApp)) {
    const installedProfile = execFileSync('/usr/bin/plutil', ['-extract', 'CrAppModeUserDataDir', 'raw', '-o', '-', path.join(webApp, 'Contents/Info.plist')], {encoding: 'utf8'}).trim();
    if (!installedProfile.startsWith(profile + path.sep))
      throw new Error('An existing Sonos web app belongs to another Chrome profile. Move that app aside before continuing.');
  }
  const pids = dedicatedPids();
  if (pids.length && !process.argv.includes('--restart'))
    throw new Error('Dedicated Sonos Chrome is running. Close it, or rerun with --restart.');
  for (const pid of pids) process.kill(pid, 'SIGTERM');
  for (let n = 0; n < 40 && dedicatedPids().length; n++) await wait(250);
  if (dedicatedPids().length) throw new Error('Sonos Chrome did not exit; it was not force-killed.');
  const chrome = spawn(chromeBin, ['--user-data-dir=' + profile, '--remote-debugging-pipe', '--no-first-run', '--no-default-browser-check', url], {stdio: ['ignore', 'ignore', 'ignore', 'pipe', 'pipe']});
  let seq = 0, buffer = '', chromeClosed = false;
  const pending = new Map();
  const failPending = error => { for (const p of pending.values()) { clearTimeout(p.timer); p.reject(error); } pending.clear(); };
  chrome.on('error', error => { chromeClosed = true; failPending(error); });
  chrome.stdio[3].on('error', failPending);
  chrome.stdio[4].on('error', failPending);
  chrome.on('exit', () => { chromeClosed = true; failPending(new Error('Temporary Chrome closed.')); });
  chrome.stdio[4].on('data', chunk => {
    buffer += chunk.toString();
    let i;
    while ((i = buffer.indexOf('\0')) >= 0) {
      const raw = buffer.slice(0, i); buffer = buffer.slice(i + 1);
      if (!raw) continue;
      const msg = JSON.parse(raw), p = pending.get(msg.id);
      if (!p) continue;
      pending.delete(msg.id); clearTimeout(p.timer);
      msg.error ? p.reject(new Error(msg.error.message)) : p.resolve(msg.result);
    }
  });
  const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
    if (chromeClosed) { reject(new Error('Temporary Chrome is closed.')); return; }
    const id = ++seq;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`${method} timed out.`)); }, 30000);
    pending.set(id, {resolve, reject, timer});
    chrome.stdio[3].write(JSON.stringify({id, method, params, ...(sessionId ? {sessionId} : {})}) + '\0');
  });
  let success = false;
  try {
    log('Started temporary dedicated Chrome debugging pipe for PWA setup; no TCP listener.');
    await send('Browser.getVersion');
    let manifest;
    for (let n = 0; n < 60; n++) {
      const page = (await send('Target.getTargets')).targetInfos.find(t => t.type === 'page' && t.url.startsWith('https://play.sonos.com/'));
      if (page) {
        const {sessionId} = await send('Target.attachToTarget', {targetId: page.targetId, flatten: true});
        try { manifest = await send('Page.getAppManifest', {}, sessionId); }
        finally { await send('Target.detachFromTarget', {sessionId}); }
        if (manifest?.data) break;
      }
      await wait(1000);
    }
    if (!manifest?.data) throw new Error('Sonos manifest was unavailable. Check your connection and retry.');
    const data = JSON.parse(manifest.data);
    const start = new URL(data.start_url, manifest.url).href;
    if (new URL(data.id || start, start).href !== manifestId) throw new Error('Sonos changed its manifest ID; review setup before installing.');
    let installed = false;
    if (fs.existsSync(webApp)) {
      try { await send('PWA.getOsAppState', {manifestId}); installed = true; } catch {}
    }
    if (!installed) await send('PWA.install', {manifestId, installUrlOrBundleUrl: url});
    await send('PWA.changeAppUserSettings', {manifestId, displayMode: 'standalone'});
    await send('PWA.getOsAppState', {manifestId});
    if (!fs.existsSync(webApp)) throw new Error('Chrome did not create the expected Sonos app shim.');
    execFileSync(iconTool, [webApp, path.join(project, 'assets/Sonos.icns')]);
    log('Installed or updated Sonos PWA, set standalone display mode and existing custom Sonos icon.');
    success = true;
  } finally {
    try { await send('Browser.close'); } catch {}
    if (!chromeClosed) {
      chrome.kill('SIGTERM');
      for (let n = 0; n < 40 && !chromeClosed; n++) await wait(250);
    }
    chrome.stdio[3].destroy(); chrome.stdio[4].destroy();
    if (!chromeClosed) throw new Error('Temporary Chrome has not exited. Close it before normal startup.');
    if (success) {
      const launcher = path.join(home, 'Applications/Sonos.app');
      execFileSync('/usr/bin/open', ['-a', fs.existsSync(launcher) ? launcher : webApp]);
    } else {
      execFileSync('/usr/bin/open', ['-n', '-a', '/Applications/Google Chrome.app', '--args', '--user-data-dir=' + profile, '--app=' + url, '--no-first-run', '--no-default-browser-check']);
    }
    log('Closed temporary debugging pipe; restored normal Sonos startup.');
  }
  console.log('Sonos is ready. Sign in on the Sonos page if prompted.');
}
setup().catch(error => { console.error(error.message); process.exitCode = 1; });
