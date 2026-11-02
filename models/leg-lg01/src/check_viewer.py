"""Static contract check; optional real Chrome scrub/interaction test and captures.

python3 models/leg-lg01/src/check_viewer.py
models/leg-lg01/work/viewer-venv/bin/python models/leg-lg01/src/check_viewer.py --browser

Browser mode needs `pip install playwright`; uses installed Chrome, or Playwright
Chromium if --chrome is not present. Serves locally on an OS-allocated free port.
This model-only check is independent of the game regression/diagnostic inventory.
"""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import threading
import time

from verify_export import ROOT, VIEWER, audit


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_args):
        pass


SCRUB = r"""() => {
  const api = window.__viewerState, slider = document.getElementById('timeline');
  const set = t => { slider.value = t; slider.dispatchEvent(new Event('input', {bubbles:true})); };
  set(0);
  const initial = api.snapshot();
  if (!initial.follow || !initial.pending || initial.spread !== 1.6) throw new Error('Default follow / pending / spread');
  const titles = new Set(), seenSteps = new Set(), moving = new Set();
  let samples = 0, maximumError = 0;
  for (let i = 0; i <= initial.total * 8; i++) {
    const t = i / 8;
    set(t);
    const current = api.snapshot();
    if (current.step !== Math.ceil(t)) throw new Error(`Panel step mismatch at ${t}`);
    if (document.getElementById('step-title').textContent !== current.title) throw new Error('Panel text is stale');
    titles.add(current.title); seenSteps.add(current.step);
    for (const p of current.parts) {
      const pending = t > 0 && p.step !== null && p.step > Math.ceil(t) + 1;
      if (p.pending !== pending || Math.abs(p.opacity - (pending ? .2 : 1)) > 1e-6) throw new Error(`Pending mode mismatch ${p.id} at ${t}`);
      const fraction = p.step === null ? 1 : Math.max(0, Math.min(1, t - p.step + 1));
      // Known interpolation landmarks test the observable motion, including
      // rollback and stationary earlier/later steps, without importing viewer code.
      const landmarks = {0:0, .125:.0078125, .25:.0625, .375:.2109375, .5:.5,
                          .625:.7890625, .75:.9375, .875:.9921875, 1:1};
      const progress = landmarks[fraction];
      for (let axis = 0; axis < 3; axis++) {
        const expected = p.start[axis] + (p.assembled[axis] - p.start[axis]) * progress;
        const error = Math.abs(p.position[axis] - expected);
        maximumError = Math.max(maximumError, error);
        if (error > 1e-5) throw new Error(`Position mismatch ${p.id} at ${t}: ${error}`);
      }
      if (fraction > 0 && fraction < 1 && p.start.some((v, a) => Math.abs(v-p.assembled[a]) > 1e-5)) moving.add(p.id);
    }
    samples++;
  }
  if (seenSteps.size !== initial.total + 1 || titles.size < 2 || !moving.size) throw new Error('Timeline did not change steps/text/positions');
  const savedTime = Math.max(.5, initial.total / 2 - .25);
  set(savedTime);
  const saved = api.snapshot();
  api.setExploded(true);
  const exploded = api.snapshot();
  if (exploded.time !== savedTime || exploded.displayTime !== 0 || exploded.step !== 0) throw new Error('Exploded preview lost slider position');
  api.setExploded(false);
  const restored = api.snapshot();
  if (restored.time !== savedTime || restored.parts.some((p,i) => p.position.some((v,a) => Math.abs(v-saved.parts[i].position[a]) > 1e-5))) throw new Error('Exploded preview failed to restore positions');
  set(0);
  const reset = api.snapshot();
  if (reset.parts.some((p,i) => p.position.some((v,a) => Math.abs(v-initial.parts[i].position[a]) > 1e-5))) throw new Error('Backward scrub failed');
  for (const mode of ['ghost','hidden','shown']) {
    api.setArmor(mode);
    const snap = api.snapshot();
    for (const p of snap.parts) {
      if (!p.armor) { if (!p.visible) throw new Error('Armor toggle hid a structural part'); continue; }
      if (p.visible !== (mode !== 'hidden')) throw new Error('Armor visibility mismatch');
      if (mode === 'ghost' && Math.abs(p.opacity - .15) > 1e-6) throw new Error('Armor opacity mismatch');
    }
  }
  // Cross the foot/leg boundary and scrub both ways with every display mode;
  // changing visibility/follow/spread must never change the travel line or time.
  let modeSamples = 0;
  for (const spread of [1, 1.6, 3]) {
    api.setSpread(spread);
    for (const pending of [false, true]) for (const follow of [false, true]) for (const armor of ['shown', 'ghost', 'hidden']) {
      api.setPending(pending); api.setFollow(follow); api.setArmor(armor);
      for (const t of [0, .5, initial.total / 2, 43.5, initial.total, .5, 0]) {
        set(t);
        const snap = api.snapshot();
        if (snap.time !== t || snap.follow !== follow || snap.pending !== pending) throw new Error('Display modes changed timeline/follow');
        for (let i = 0; i < snap.parts.length; i++) {
          const p = snap.parts[i], base = initial.parts[i];
          const progress = p.step === null || p.step <= t ? 1 : p.step >= t + 1 ? 0 : .5;
          for (let a = 0; a < 3; a++) {
            const offset = (base.start[a] - base.assembled[a]) / 1.6 * spread;
            if (Math.abs(p.position[a] - p.assembled[a] - offset * (1-progress)) > 1e-5) throw new Error(`Spread/mode scrub ${p.id}`);
          }
          const ghost = pending && t > 0 && p.step !== null && p.step > Math.ceil(t) + 1;
          const opacity = p.armor && armor === 'ghost' ? .15 : ghost ? .2 : 1;
          if (Math.abs(p.opacity - opacity) > 1e-6 || p.visible !== !(p.armor && armor === 'hidden')) throw new Error('Composed ghost/armor mode');
        }
        modeSamples++;
      }
    }
  }
  api.setSpread(1.6); api.setPending(true); api.setArmor('shown'); api.setFollow(true); set(0);
  return {samples, unique_steps:seenSteps.size, unique_titles:titles.size, moving_parts:moving.size,
          maximum_position_error:maximumError, armor_parts:initial.parts.filter(p=>p.armor).length,
          mode_samples:modeSamples, spreads:[1,1.6,3], pending:true, follow:true,
          exploded_restore:true, reverse_scrub:true};
}"""


def browser_check(args):
    from playwright.sync_api import sync_playwright
    handler = partial(QuietHandler, directory=str(VIEWER))
    server = ThreadingHTTPServer(('127.0.0.1', 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    url = f'http://127.0.0.1:{server.server_port}/'
    console_errors, page_errors, warnings = [], [], []
    captures = []
    try:
        with sync_playwright() as playwright:
            launch = dict(headless=True)
            if args.chrome.exists():
                launch['executable_path'] = str(args.chrome)
            with playwright.chromium.launch(**launch) as browser:
                page = browser.new_page(viewport={'width': 1280, 'height': 800}, device_scale_factor=1)
                page.on('console', lambda message: console_errors.append(message.text) if message.type == 'error' else warnings.append(message.text) if message.type == 'warning' else None)
                page.on('pageerror', lambda error: page_errors.append(str(error)))
                start = time.monotonic()
                page.goto(url + '#t=0', wait_until='load')
                page.wait_for_function('window.__viewerState?.ready && typeof window.__viewerState.snapshot === "function"', timeout=45000)
                load_seconds = time.monotonic() - start
                scrub = page.evaluate(SCRUB)
                # Validate Blender → glTF approach conversion independently of
                # the browser's reported start/assembled interpolation endpoints.
                installed = {i['instance_id']: i for s in json.loads((VIEWER / 'build-steps.json').read_text())['steps'] for i in s['installs']}
                snap = page.evaluate('window.__viewerState.snapshot()')
                for part in snap['parts']:
                    install = installed[part['id']]
                    x, y, z = install['approach']
                    expected = [x, z, -y]
                    assert all(abs(part['start'][a] - part['assembled'][a] - expected[a] * install['offset'] * snap['spread']) < 1e-5 for a in range(3)), f'Axis conversion: {part["id"]}'
                page.locator('#timeline').focus()
                page.keyboard.press('ArrowRight')
                assert page.evaluate('window.__viewerState.snapshot().time') == 1, 'Right arrow'
                page.keyboard.press('ArrowLeft')
                assert page.evaluate('window.__viewerState.snapshot().time') == 0, 'Left arrow'
                page.keyboard.press('Space')
                page.wait_for_timeout(250)
                assert page.evaluate('window.__viewerState.snapshot().playing'), 'Space did not play'
                page.keyboard.press('Space')
                assert not page.evaluate('window.__viewerState.snapshot().playing'), 'Space did not pause'
                # Playback speeds have a common frame-rate cap; measure active
                # time with wall-clock tolerance instead of assuming 60 FPS.
                speed_positions = {}
                for speed in ('0.5', '1', '2', '4'):
                    page.evaluate('window.__viewerState.setTime(0)')
                    page.select_option('#speed', speed)
                    page.click('#play')
                    page.wait_for_timeout(550)
                    page.click('#play')
                    speed_positions[speed] = page.evaluate('window.__viewerState.snapshot().time')
                assert speed_positions['4'] > speed_positions['1'] > speed_positions['0.5'], speed_positions
                page.select_option('#speed', '1')
                page.evaluate('window.__viewerState.setTime(1)')
                page.click('#next')
                assert page.evaluate('window.__viewerState.snapshot().time') == 2, 'Next button'
                page.click('#previous')
                assert page.evaluate('window.__viewerState.snapshot().time') == 1, 'Previous button'
                page.keyboard.press('Space')
                assert page.evaluate('window.__viewerState.snapshot().playing'), 'Space after clicking a button'
                page.keyboard.press('Space')
                # Follow and presets must actually alter camera/target.
                page.evaluate('window.__viewerState.setTime(0); window.__viewerState.fit()')
                camera_before = page.evaluate('window.__viewerState.snapshot().camera')
                page.check('#follow')
                page.evaluate('window.__viewerState.setTime(.5)')
                page.wait_for_timeout(1200)
                camera_after = page.evaluate('window.__viewerState.snapshot().camera')
                assert camera_before != camera_after, 'Follow did not move camera'
                projected = page.evaluate('window.__viewerState.projectBounds(true)')
                assert all(-1 < v < 1 for v in projected['min'] + projected['max']), 'Follow clipped active current/assembled bounds'
                # Pausing in an installation keeps its ochre pulse alive, even
                # after the old 1.1-second timeout. Arrival fades over a second.
                pulse_active = page.evaluate('window.__viewerState.snapshot().parts.filter(p => p.step === 1).map(p => p.emissive)')
                assert any(max(c) > .03 for c in pulse_active), 'Installing parts stopped glowing'
                page.evaluate('window.__viewerState.setTime(1)')
                page.wait_for_timeout(350)
                assert page.evaluate('window.__viewerState.snapshot().parts.some(p => p.step === 1 && Math.max(...p.emissive) > .03)'), 'Arrival glow ended early'
                page.wait_for_timeout(850)
                assert page.evaluate('window.__viewerState.snapshot().parts.every(p => p.step !== 1 || Math.max(...p.emissive) < .001)'), 'Arrival glow did not fade'
                # Orbit pauses follow without clearing the checkbox, including
                # while held; resuming preserves the manually chosen direction.
                page.mouse.move(460, 350)
                page.mouse.down()
                page.mouse.move(550, 390, steps=12)
                page.evaluate('window.__viewerState.setTime(1.5)')
                assert page.evaluate('window.__viewerState.snapshot().followPaused && window.__viewerState.snapshot().follow'), 'Orbit cancelled follow'
                page.mouse.up()
                page.wait_for_timeout(900)
                orbit_before = page.evaluate('window.__viewerState.snapshot()')
                page.evaluate('window.__viewerState.setTime(2.5)')
                page.wait_for_timeout(500)
                orbit_paused = page.evaluate('window.__viewerState.snapshot()')
                assert orbit_paused['followPaused'], 'Follow resumed before three seconds'
                assert sum((a-b)**2 for a, b in zip(orbit_before['target'], orbit_paused['target'])) < 1e-6, 'Follow fought manual orbit'
                page.wait_for_timeout(2300)
                orbit_resumed = page.evaluate('window.__viewerState.snapshot()')
                assert not orbit_resumed['followPaused'] and orbit_resumed['target'] != orbit_paused['target'], 'Follow did not resume'
                def camera_direction(s):
                    v = [a-b for a, b in zip(s['camera'], s['target'])]
                    length = sum(x*x for x in v)**.5
                    return [x/length for x in v]
                assert sum(a*b for a, b in zip(camera_direction(orbit_paused), camera_direction(orbit_resumed))) > .999, 'Follow reset orbit angle'
                page.uncheck('#follow')
                page.wait_for_timeout(900)
                whole = page.evaluate('window.__viewerState.projectBounds()')
                assert all(-1 < v < 1 for v in whole['min'] + whole['max']), 'Follow off did not fit the whole layout'
                page.check('#follow')
                page.click('#fit')
                assert not page.is_checked('#follow'), 'Fit all was immediately overridden by follow'
                page.evaluate('window.__viewerState.setTime(window.__viewerState.snapshot().total)')
                for view, axis, sign in [('front', 2, -1), ('side', 0, -1), ('back', 2, 1)]:
                    page.click(f'[data-view="{view}"]')
                    page.wait_for_timeout(1200)
                    snap = page.evaluate('window.__viewerState.snapshot()')
                    assert (snap['camera'][axis] - snap['target'][axis]) * sign > 0, f'{view} camera direction'
                page.click('[data-view="three-quarter"]')
                args.shots.mkdir(parents=True, exist_ok=True)
                framing = {}
                for name, hash_value in [('start', 't=0'), ('mid', 't=mid'), ('end', 't=end&follow=off'), ('ghost', 't=end&armor=ghost&follow=off')]:
                    # Reapply even when the URL already has this hash (the earlier
                    # control tests changed the slider independently of the URL).
                    page.evaluate('(hash) => { location.hash = hash; window.dispatchEvent(new HashChangeEvent("hashchange")); }', hash_value)
                    page.wait_for_timeout(1450)  # Settle the camera; mid-step glow stays active.
                    capture_state = page.evaluate('window.__viewerState.snapshot()')
                    expected_time = 0 if name == 'start' else capture_state['total'] / 2 if name == 'mid' else capture_state['total']
                    assert capture_state['time'] == expected_time, f'{name} capture time'
                    assert capture_state['armor'] == ('ghost' if name == 'ghost' else 'shown'), f'{name} capture armor'
                    assert capture_state['follow'] == (name in ('start', 'mid')), f'{name} capture follow'
                    framing[name] = page.evaluate('window.__viewerState.projectBounds(' + ('true' if name == 'mid' else 'false') + ')')
                    if name == 'end':
                        height = (framing[name]['max'][1] - framing[name]['min'][1]) / 2
                        assert .79 < height < .9, f'Whole-leg height {height:.1%}'
                    assert all(-1 < v < 1 for v in framing[name]['min'] + framing[name]['max']), f'{name} capture clipped subject'
                    section_steps = json.loads((VIEWER / 'build-steps.json').read_text())['steps']
                    progress = ' · '.join(f'{section.title()} {sum(s["section"] == section for s in section_steps[:capture_state["step"]])}/{sum(s["section"] == section for s in section_steps)}' for section in ('foot', 'leg'))
                    assert capture_state['sectionProgress'] == progress, f'{name} section progress'
                    assert page.evaluate('document.documentElement.scrollWidth <= innerWidth'), 'Horizontal layout overflow'
                    path = args.shots / f'viewer-{name}.jpg'
                    page.screenshot(path=str(path), type='jpeg', quality=92)
                    captures.append(str(path.relative_to(ROOT)))
                assert not console_errors and not page_errors, f'Browser errors: {console_errors + page_errors}'
                # A deliberately mismatched sequence verifies graceful skipping
                # and assembled retention, without modifying the files on disk.
                mismatched = json.loads((VIEWER / 'build-steps.json').read_text())
                first = mismatched['steps'][0]['installs'][0]
                unassigned = first['instance_id']
                first['instance_id'] = '__unknown_test_instance__'
                page.route('**/build-steps.json', lambda route: route.fulfill(json=mismatched))
                page.reload(wait_until='load')
                page.wait_for_function('window.__viewerState?.ready && window.__viewerState.snapshot', timeout=45000)
                mismatch = page.evaluate('window.__viewerState.mismatches')
                assert mismatch['missing'] == ['__unknown_test_instance__'], mismatch
                assert mismatch['unassigned'] == [unassigned], mismatch
                page.evaluate('window.__viewerState.setTime(0)')
                retained = page.evaluate('(id) => window.__viewerState.snapshot().parts.find(p => p.id === id)', unassigned)
                assert all(abs(a-b) < 1e-6 for a, b in zip(retained['position'], retained['assembled'])), 'Unassigned part moved'
                assert not console_errors and not page_errors, f'Browser errors: {console_errors + page_errors}'
                return dict(ok=True, viewport=[1280, 800], load_seconds=round(load_seconds, 3),
                            scrub=scrub, keyboard=True, playback_positions=speed_positions,
                            camera_presets=True, follow=True, follow_orbit_pause_seconds=3,
                            sustained_glow=True, arrival_fade=True, framing=framing, coordinate_conversion=True,
                            mismatch_fallback=mismatch, console_errors=console_errors, page_errors=page_errors,
                            warnings=warnings, screenshots=captures)
    except Exception as exc:
        raise RuntimeError(f'{exc}; console errors: {console_errors}; page errors: {page_errors}') from exc
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--browser', action='store_true', help='Run Chrome interaction checks and save four JPEGs')
    parser.add_argument('--chrome', type=Path, default=Path('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'))
    parser.add_argument('--shots', type=Path, default=ROOT / 'output/viewer-shots')
    parser.add_argument('--report', type=Path, default=ROOT / 'output/audits/viewer.json')
    args = parser.parse_args()
    report = {}
    try:
        report['contract'] = audit()
        if not report['contract']['ok']:
            raise ValueError('GLB/sequence contract failed: ' + '; '.join(report['contract']['errors']))
        if args.browser:
            report['browser'] = browser_check(args)
        report['ok'] = True
    except Exception as exc:
        report.update(ok=False, error=f'{type(exc).__name__}: {exc}')
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
