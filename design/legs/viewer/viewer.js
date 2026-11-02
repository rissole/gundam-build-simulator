import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';

const $ = (id) => document.getElementById(id);
const ui = Object.fromEntries(['stage', 'viewport', 'timeline', 'play', 'previous', 'next', 'speed', 'follow', 'pending', 'spread', 'armor', 'exploded', 'tooltip'].map(id => [id, $(id)]));
const state = window.__viewerState = { ready: false, error: null };
const scene = new THREE.Scene();
scene.background = new THREE.Color('#f3f2ef');
const camera = new THREE.PerspectiveCamera(33, 1, .05, 300);
const renderer = new THREE.WebGLRenderer({ canvas: ui.viewport, antialias: true, alpha: false });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.55;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.VSMShadowMap;
renderer.shadowMap.autoUpdate = false;
const pmrem = new THREE.PMREMGenerator(renderer);
const room = new RoomEnvironment();
const environment = pmrem.fromScene(room, .04);
scene.environment = environment.texture;
scene.environmentIntensity = .28;
room.dispose();
pmrem.dispose();
const key = new THREE.DirectionalLight('#fff7ee', 3.2);
key.position.set(7, 14, -9);
key.target.position.set(0, 3, 0);
key.castShadow = true;
key.shadow.mapSize.set(1024, 1024);
Object.assign(key.shadow.camera, { left: -12, right: 12, top: 14, bottom: -14, near: .1, far: 45 });
key.shadow.bias = -.0002;
key.shadow.normalBias = .025;
key.shadow.radius = 8;
key.shadow.blurSamples = 10;
scene.add(key, key.target);
const fill = new THREE.DirectionalLight('#edf1ff', .8);
fill.position.set(-8, 7, -4);
scene.add(fill);
const ground = new THREE.Mesh(new THREE.PlaneGeometry(200, 200), new THREE.ShadowMaterial({ opacity: .075 }));
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);
const controls = new OrbitControls(camera, ui.viewport);
controls.enableDamping = true;
controls.dampingFactor = .09;
controls.minDistance = .3;
controls.maxDistance = 100;
const presets = {
  // Blender front +Y becomes glTF -Z; outer side of the left leg is -X.
  front: new THREE.Vector3(0, .04, -1).normalize(),
  side: new THREE.Vector3(-1, .04, 0).normalize(),
  back: new THREE.Vector3(0, .04, 1).normalize(),
  'three-quarter': new THREE.Vector3(-1.15, .42, -1.65).normalize(),
};
let steps = [], parts = [], partMap = new Map(), stepParts = [];
let time = 0, displayTime = -1, activeStep = -1, playing = false, exploded = false;
let armorMode = 'shown', pendingMode = true, spread = 1.6, pulseParts = [];
const fadingParts = new Map();
let pulseStart = -Infinity, stepArrived = -Infinity;
let cameraTween = false, selectedView = 'three-quarter';
let manualOrbit = false, followPausedUntil = 0, followDirty = false;
const cameraGoal = new THREE.Vector3(), targetGoal = new THREE.Vector3();
const direction = new THREE.Vector3();
const box = new THREE.Box3(), scratchBox = new THREE.Box3(), delta = new THREE.Vector3();
const assembledBox = new THREE.Box3();
const cameraRight = new THREE.Vector3(), cameraUp = new THREE.Vector3(), corner = new THREE.Vector3();
const raycaster = new THREE.Raycaster(), pointer = new THREE.Vector2();
const rayHits = [];
let lastHover = 0;

function resize() {
  const { width, height } = ui.stage.getBoundingClientRect();
  renderer.setSize(width, height, false);
  camera.aspect = width / height;
  camera.updateProjectionMatrix();
  if (state.ready) frameCurrent();
}
new ResizeObserver(resize).observe(ui.stage);
resize();

function bounds(items, includeSeats = false) {
  box.makeEmpty();
  for (const part of items) {
    if (!part.node.visible) continue;
    delta.copy(part.worldOffset).multiplyScalar(1 - part.progress);
    scratchBox.copy(part.bounds).translate(delta);
    box.union(scratchBox);
    if (includeSeats) box.union(part.bounds);
  }
  if (box.isEmpty()) box.copy(assembledBox);
  return box;
}

function fit(items, viewDirection, immediate = false, includeSeats = false) {
  bounds(items, includeSeats).getCenter(targetGoal);
  if (viewDirection) direction.copy(viewDirection);
  else direction.copy(camera.position).sub(controls.target).normalize();
  cameraRight.crossVectors(camera.up, direction).normalize();
  cameraUp.crossVectors(direction, cameraRight).normalize();
  const tangent = Math.tan(THREE.MathUtils.degToRad(camera.fov / 2));
  // Project individual part corners instead of the much larger union AABB.
  // Follow includes both ends of the remaining travel and at least 1.2 m of context.
  let distance = includeSeats ? .6 / (tangent * .78) : 1.2;
  const occupancy = includeSeats ? .78 : .88;
  const fitBox = b => {
    for (let i = 0; i < 8; i++) {
      corner.set(i & 1 ? b.max.x : b.min.x, i & 2 ? b.max.y : b.min.y, i & 4 ? b.max.z : b.min.z).sub(targetGoal);
      const depth = corner.dot(direction);
      distance = Math.max(distance, depth + Math.abs(corner.dot(cameraUp)) / (tangent * occupancy),
        depth + Math.abs(corner.dot(cameraRight)) / (tangent * camera.aspect * occupancy));
    }
  };
  for (const part of items) {
    if (!part.node.visible) continue;
    delta.copy(part.worldOffset).multiplyScalar(1 - part.progress);
    fitBox(scratchBox.copy(part.bounds).translate(delta));
    if (includeSeats) fitBox(part.bounds);
  }
  // Leave the top toolbar clear while keeping the subject near the visual centre.
  targetGoal.addScaledVector(cameraUp, distance * tangent * .025);
  cameraGoal.copy(targetGoal).addScaledVector(direction, distance);
  if (immediate) {
    controls.target.copy(targetGoal);
    camera.position.copy(cameraGoal);
    controls.update();
    cameraTween = false;
  } else cameraTween = true;
}

function following() { return ui.follow.checked && pulseParts.length && !exploded && time < steps.length; }
function frameCurrent(viewDirection, immediate = false) {
  const follow = following();
  fit(follow ? pulseParts : parts, viewDirection, immediate, Boolean(follow));
}
function setFollow(value) {
  ui.follow.checked = Boolean(value);
  followPausedUntil = 0;
  followDirty = false;
  frameCurrent();
}
function fitAll(immediate = false) {
  ui.follow.checked = false;
  followDirty = false;
  fit(parts, null, immediate);
}

function ensureMaterials(part) {
  if (part.materials) return part.materials;
  const cloned = new Map();
  part.node.traverse(child => {
    if (!child.isMesh) return;
    const clone = material => {
      if (!cloned.has(material)) cloned.set(material, material.clone());
      return cloned.get(material);
    };
    child.material = Array.isArray(child.material) ? child.material.map(clone) : clone(child.material);
  });
  part.materials = [...cloned.values()].map(material => ({
    material, opacity: material.opacity, transparent: material.transparent,
    depthWrite: material.depthWrite, emissive: material.emissive?.clone(),
    ghostEmissive: material.emissive ? desaturate(material.emissive.clone()) : null,
    intensity: material.emissiveIntensity, color: material.color?.clone(),
  }));
  return part.materials;
}

function desaturate(color) {
  const grey = color.r * .2126 + color.g * .7152 + color.b * .0722;
  return color.lerp(new THREE.Color().setRGB(grey, grey, grey), .9);
}

const glow = new THREE.Color('#d99228');
function pulse(items, amount) {
  for (const part of items) {
    const strength = part.pending ? 0 : amount;
    for (const record of ensureMaterials(part)) {
      if (!record.emissive) continue;
      record.material.emissive.copy(part.pending ? record.ghostEmissive : record.emissive).lerp(glow, strength);
      record.material.emissiveIntensity = record.intensity + strength * 1.25;
    }
  }
}

function updateAppearance() {
  for (const part of parts) {
    // Step 0 shows the whole kit solid; ghosting starts once the build begins.
    const pending = pendingMode && displayTime > 0 && part.step !== null && part.step > Math.ceil(displayTime) + 1;
    const ghostArmor = part.meta.armor && armorMode === 'ghost';
    const hidden = part.meta.armor && armorMode === 'hidden';
    const mode = `${pending}/${ghostArmor}/${hidden}`;
    if (mode === part.appearance) continue;
    part.appearance = mode;
    part.pending = pending;
    part.node.visible = !hidden;
    const opacity = ghostArmor ? .15 : pending ? .2 : null;
    for (const record of ensureMaterials(part)) {
      const material = record.material;
      const transparent = opacity !== null || record.transparent;
      if (material.transparent !== transparent) material.needsUpdate = true;
      material.opacity = opacity ?? record.opacity;
      material.transparent = transparent;
      material.depthWrite = opacity === null && record.depthWrite;
      material.forceSinglePass = true;
      if (record.color) {
        material.color.copy(record.color);
        if (pending) desaturate(material.color);
      }
      if (record.emissive) material.emissive.copy(pending ? record.ghostEmissive : record.emissive);
    }
    part.node.traverse(child => { if (child.isMesh) child.castShadow = !hidden && opacity === null; });
    renderer.shadowMap.needsUpdate = true;
  }
}
function setArmor(mode) {
  armorMode = ['shown', 'ghost', 'hidden'].includes(mode) ? mode : 'shown';
  ui.armor.value = armorMode;
  updateAppearance();
  followDirty = true;
}
function setPending(value) {
  pendingMode = Boolean(value);
  ui.pending.checked = pendingMode;
  updateAppearance();
}
function setSpread(value) {
  if (!Number.isFinite(Number(value))) return;
  spread = THREE.MathUtils.clamp(Number(value), 1, 3);
  ui.spread.value = spread;
  $('spread-value').textContent = `${Number(spread.toFixed(1))}×`;
  for (const part of parts) {
    part.worldOffset.copy(part.baseOffset).multiplyScalar(spread);
    part.start.copy(part.worldAssembled).add(part.worldOffset);
    part.node.parent.worldToLocal(part.start);
    if (part.step !== null) part.progress = -1;
  }
  displayTime = -1;
  setTime(time);
  frameCurrent();
}

const ease = x => x < .5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
function moveParts(nextTime) {
  if (nextTime === displayTime) return;
  const first = displayTime < 0 ? 0 : Math.floor(Math.min(nextTime, displayTime));
  const end = displayTime < 0 ? steps.length : Math.ceil(Math.max(nextTime, displayTime));
  for (let i = first; i < end; i++) {
    const progress = ease(THREE.MathUtils.clamp(nextTime - i, 0, 1));
    for (const part of stepParts[i]) {
      if (part.progress === progress) continue;
      part.node.position.lerpVectors(part.start, part.assembled, progress);
      part.node.updateMatrix();
      part.progress = progress;
    }
  }
  displayTime = nextTime;
  ground.position.y = Math.min(assembledBox.min.y, bounds(parts).min.y) - .04;
  renderer.shadowMap.needsUpdate = true;
}

function updatePanel(index) {
  if (index === activeStep) return;
  const now = performance.now();
  // Do not restart a completed step's glow when advancing after a long pause.
  for (const part of pulseParts) fadingParts.set(part, stepArrived === -Infinity ? now : stepArrived);
  activeStep = index;
  pulseParts = index ? stepParts[index - 1] : [];
  for (const part of pulseParts) fadingParts.delete(part);
  pulseStart = now;
  stepArrived = -Infinity;
  const step = steps[index - 1];
  $('step-number').textContent = `${String(index).padStart(2, '0')} / ${steps.length}`;
  $('step-title').textContent = step ? step.title.replace(/^Preview · /, '') : 'Exploded layout';
  $('step-context').textContent = step ? `${step.section === 'foot' ? 'Foot' : 'Leg'} / ${step.group.replaceAll('-', ' ')} · ${step.id}` : 'All parts at their start positions. Drag the timeline to bring the leg together.';
  $('section-progress').textContent = ['foot', 'leg'].map(section => {
    const total = steps.filter(s => s.section === section).length;
    const current = steps.slice(0, index).filter(s => s.section === section).length;
    return `${section === 'foot' ? 'Foot' : 'Leg'} ${current}/${total}`;
  }).join(' · ');
  $('parts-label').textContent = step ? 'Parts in this step' : 'Assembly groups';
  $('parts-count').textContent = step ? `${pulseParts.length} pcs` : `${parts.length} pcs`;
  const grouped = new Map();
  for (const part of step ? pulseParts : parts) {
    const id = step ? `${part.meta.part_id}\0${part.meta.part_name}` : part.meta.subassembly;
    const item = grouped.get(id);
    if (item) item.count++;
    else grouped.set(id, { id: step ? part.meta.part_id : '', name: step ? part.meta.part_name : part.meta.subassembly.replaceAll('-', ' '), count: 1 });
  }
  const fragment = document.createDocumentFragment();
  for (const item of grouped.values()) {
    const li = document.createElement('li'), label = document.createElement('span');
    if (item.id) {
      const id = document.createElement('span'); id.className = 'part-id'; id.textContent = item.id; label.append(id);
    }
    label.append(document.createTextNode(item.name));
    const count = document.createElement('span'); count.className = 'quantity'; count.textContent = `×${item.count}`;
    li.append(label, count); fragment.append(li);
  }
  $('parts-list').replaceChildren(fragment);
  $('parts-list').scrollTop = 0;
}

function setTime(value) {
  if (!Number.isFinite(Number(value))) return;
  time = THREE.MathUtils.clamp(Number(value), 0, steps.length);
  ui.timeline.value = time;
  ui.timeline.style.setProperty('--progress', `${time / steps.length * 100}%`);
  ui.timeline.setAttribute('aria-valuetext', `Step ${time.toFixed(2)} of ${steps.length}`);
  $('timeline-value').textContent = `${Number(time.toFixed(2))} / ${steps.length}`;
  const visualTime = exploded ? 0 : time;
  moveParts(visualTime);
  updatePanel(Math.ceil(visualTime));
  if (visualTime > 0 && Number.isInteger(visualTime) && stepArrived === -Infinity) stepArrived = performance.now();
  if (!Number.isInteger(visualTime)) stepArrived = -Infinity;
  updateAppearance();
  $('layout-caption').textContent = exploded ? 'Exploded preview · Timeline position saved' : time === 0 ? 'Exploded layout' : time === steps.length ? 'Fully assembled' : 'Assembly in progress';
  ui.previous.disabled = time <= 0;
  ui.next.disabled = time >= steps.length;
  if (ui.follow.checked) followDirty = true;
}

function setExploded(value) {
  exploded = Boolean(value);
  ui.exploded.checked = exploded;
  setPlaying(false);
  setTime(time);
  frameCurrent();
}

function setPlaying(value) {
  playing = Boolean(value) && state.ready;
  if (playing && exploded) { exploded = false; ui.exploded.checked = false; setTime(time); }
  if (playing && time >= steps.length) setTime(0);
  ui.play.innerHTML = playing ? 'Ⅱ <span>Pause</span>' : '▶ <span>Play</span>';
  ui.play.setAttribute('aria-label', playing ? 'Pause build' : 'Play build');
}

function jump(direction) {
  if (!state.ready) return;
  setPlaying(false);
  if (exploded) { exploded = false; ui.exploded.checked = false; }
  setTime(direction > 0 ? Math.floor(time + 1e-8) + 1 : Math.ceil(time - 1e-8) - 1);
}

ui.timeline.addEventListener('input', () => {
  setPlaying(false);
  if (exploded) { exploded = false; ui.exploded.checked = false; }
  setTime(ui.timeline.value);
});
ui.play.addEventListener('click', () => setPlaying(!playing));
ui.previous.addEventListener('click', () => jump(-1));
ui.next.addEventListener('click', () => jump(1));
ui.armor.addEventListener('change', () => setArmor(ui.armor.value));
ui.pending.addEventListener('change', () => setPending(ui.pending.checked));
ui.spread.addEventListener('input', () => setSpread(ui.spread.value));
ui.exploded.addEventListener('change', () => setExploded(ui.exploded.checked));
ui.follow.addEventListener('change', () => setFollow(ui.follow.checked));
$('fit').addEventListener('click', () => fitAll());
for (const button of document.querySelectorAll('[data-view]')) button.addEventListener('click', () => {
  selectedView = button.dataset.view;
  for (const other of document.querySelectorAll('[data-view]')) other.setAttribute('aria-pressed', String(other === button));
  followPausedUntil = 0;
  followDirty = false;
  frameCurrent(presets[selectedView]);
});
controls.addEventListener('start', () => {
  cameraTween = false; manualOrbit = true; followDirty = true; ui.tooltip.hidden = true;
});
controls.addEventListener('end', () => { manualOrbit = false; followPausedUntil = performance.now() + 3000; });
window.addEventListener('keydown', event => {
  if (!state.ready || event.altKey || event.metaKey || event.ctrlKey) return;
  const target = event.target;
  if (target.isContentEditable || target.tagName === 'SELECT' || (target.tagName === 'INPUT' && target !== ui.timeline)) return;
  if (event.code === 'ArrowLeft' || event.code === 'ArrowRight') { event.preventDefault(); jump(event.code === 'ArrowLeft' ? -1 : 1); }
  if (event.code === 'Space') { event.preventDefault(); setPlaying(!playing); }
});

ui.viewport.addEventListener('pointerleave', () => { ui.tooltip.hidden = true; });
ui.viewport.addEventListener('pointermove', event => {
  if (!state.ready || event.buttons || playing) { ui.tooltip.hidden = true; return; }
  const now = performance.now();
  if (now - lastHover < 90) return;
  lastHover = now;
  const rect = ui.viewport.getBoundingClientRect();
  pointer.set((event.clientX - rect.left) / rect.width * 2 - 1, 1 - (event.clientY - rect.top) / rect.height * 2);
  raycaster.setFromCamera(pointer, camera);
  rayHits.length = 0;
  raycaster.intersectObjects(scene.children, true, rayHits);
  let hovered;
  for (const hit of rayHits) {
    let node = hit.object;
    while (node && !node.userData.viewerPart) node = node.parent;
    if (node?.visible) { hovered = node.userData.viewerPart; break; }
  }
  ui.tooltip.hidden = !hovered;
  if (hovered) {
    ui.tooltip.textContent = `${hovered.meta.part_id} · ${hovered.meta.part_name}`;
    ui.tooltip.style.left = `${Math.min(rect.width - 280, Math.max(8, event.clientX - rect.left + 14))}px`;
    ui.tooltip.style.top = `${Math.min(rect.height - 65, event.clientY - rect.top + 16)}px`;
  }
});

function applyHash(immediate = false) {
  const hash = new URLSearchParams(location.hash.slice(1));
  const value = hash.get('t');
  setPlaying(false);
  ui.follow.checked = hash.get('follow') !== 'off';
  followPausedUntil = 0; followDirty = false;
  setArmor(hash.get('armor') || 'shown');
  setPending(hash.get('pending') !== 'off');
  exploded = false; ui.exploded.checked = false;
  setTime(value === 'mid' ? steps.length / 2 : value === 'end' || (!value && hash.has('armor')) ? steps.length : Number(value || 0));
  frameCurrent(presets[selectedView], immediate);
  followDirty = false;
}
window.addEventListener('hashchange', () => { if (state.ready) applyHash(true); });

async function load() {
  const started = performance.now();
  const [sequence, gltf] = await Promise.all([
    fetch('build-steps.json', { cache: 'no-cache' }).then(response => {
      if (!response.ok) throw new Error(`build-steps.json: HTTP ${response.status}`);
      return response.json();
    }),
    new GLTFLoader().loadAsync('leg-lg01.glb', progress => {
      if (progress.total) {
        $('load-progress').value = progress.loaded / progress.total * 90;
        $('loading-detail').textContent = `${(progress.loaded / 1e6).toFixed(1)} / ${(progress.total / 1e6).toFixed(1)} MB`;
      } else $('load-progress').removeAttribute('value');
    }),
  ]);
  if (sequence.schema !== 'leg-lg01-build-steps/1' || sequence.units !== 'm' || !sequence.steps?.length) throw new Error('Unsupported or empty build-steps.json');
  steps = sequence.steps;
  stepParts = steps.map(() => []);
  scene.add(gltf.scene);
  scene.updateMatrixWorld(true);
  // GLTFLoader sanitizes punctuation in Object3D.name. Recover the exact node
  // identity from its JSON association/extras, including dotted instance IDs.
  gltf.scene.traverse(node => {
    const sourceIndex = gltf.parser.associations.get(node)?.nodes;
    if (sourceIndex === undefined) return;
    const source = gltf.parser.json.nodes[sourceIndex];
    const iid = source.extras?.instance_id || source.name;
    if (!iid || source.mesh === undefined) return;
    node.name = iid;
    const meta = sequence.parts?.[iid] || { ...source.extras, armor: false };
    const part = { id: iid, node, meta, assembled: node.position.clone(), start: node.position.clone(),
      worldAssembled: node.getWorldPosition(new THREE.Vector3()), worldOffset: new THREE.Vector3(),
      baseOffset: new THREE.Vector3(),
      bounds: new THREE.Box3().setFromObject(node), progress: 1, step: null, materials: null };
    partMap.set(iid, part); parts.push(part); node.userData.viewerPart = part;
    assembledBox.union(part.bounds);
  });
  const missing = [], duplicate = [];
  steps.forEach((step, index) => {
    for (const install of step.installs) {
      const part = partMap.get(install.instance_id);
      if (!part) { missing.push(install.instance_id); continue; }
      if (part.step !== null) { duplicate.push(part.id); continue; }
      const [x, y, z] = install.approach;
      if (![x, y, z, install.offset].every(Number.isFinite)) { console.warn('Invalid approach; keeping assembled:', part.id); continue; }
      part.baseOffset.set(x, z, -y).multiplyScalar(install.offset);
      part.worldOffset.copy(part.baseOffset).multiplyScalar(spread);
      part.start.copy(part.worldAssembled).add(part.worldOffset);
      // Handles parents correctly too, though our export deliberately flattens them.
      part.node.parent.worldToLocal(part.start);
      part.step = index + 1;
      stepParts[index].push(part);
    }
  });
  const unassigned = parts.filter(p => p.step === null).map(p => p.id);
  if (missing.length) console.warn('Step IDs missing from GLB; skipped:', missing);
  if (duplicate.length) console.warn('Duplicate installs; keeping first:', duplicate);
  if (unassigned.length) console.warn('GLB parts without a step; kept assembled:', unassigned);
  state.mismatches = { missing, duplicate, unassigned };
  $('sequence-kind').textContent = steps.every(s => s.title.startsWith('Preview · ')) ? 'Development sequence · Placeholder' : 'Build sequence';
  $('model-stats').textContent = `${parts.length.toLocaleString()} parts / ${steps.length} steps`;
  ui.timeline.max = steps.length;
  ui.timeline.disabled = false;
  $('timeline-end').textContent = `${steps.length}  Assembled`;
  for (let i = 0; i <= steps.length; i++) {
    const tick = document.createElement('span'); tick.className = `tick${i % 5 === 0 ? ' major' : ''}`;
    tick.style.left = `${i / steps.length * 100}%`; $('ticks').append(tick);
  }
  state.ready = true;
  applyHash(true);
  $('load-progress').value = 95;
  $('loading-detail').textContent = 'Preparing studio lighting…';
  renderer.render(scene, camera);
  $('load-progress').value = 100;
  $('loading').hidden = true;
  state.loadMs = performance.now() - started;
  state.setTime = setTime;
  state.setArmor = setArmor;
  state.setPending = setPending;
  state.setSpread = setSpread;
  state.setFollow = setFollow;
  state.setExploded = setExploded;
  state.fit = () => fitAll(true);
  state.projectBounds = (active = false) => {
    const projected = { min: [Infinity, Infinity], max: [-Infinity, -Infinity] };
    const project = b => {
      for (let i = 0; i < 8; i++) {
        corner.set(i & 1 ? b.max.x : b.min.x, i & 2 ? b.max.y : b.min.y, i & 4 ? b.max.z : b.min.z).project(camera);
        projected.min[0] = Math.min(projected.min[0], corner.x); projected.min[1] = Math.min(projected.min[1], corner.y);
        projected.max[0] = Math.max(projected.max[0], corner.x); projected.max[1] = Math.max(projected.max[1], corner.y);
      }
    };
    for (const part of active ? pulseParts : parts) {
      if (!part.node.visible) continue;
      delta.copy(part.worldOffset).multiplyScalar(1 - part.progress);
      project(scratchBox.copy(part.bounds).translate(delta));
      if (active) project(part.bounds);
    }
    return projected;
  };
  state.snapshot = () => ({
    ready: state.ready, time, displayTime, step: activeStep, total: steps.length,
    title: $('step-title').textContent, playing, exploded, armor: armorMode,
    sectionProgress: $('section-progress').textContent, pending: pendingMode, spread,
    camera: camera.position.toArray(), target: controls.target.toArray(), follow: ui.follow.checked,
    cameraGoal: cameraGoal.toArray(), targetGoal: targetGoal.toArray(),
    followPaused: manualOrbit || performance.now() < followPausedUntil,
    activeBounds: bounds(pulseParts, true).clone(),
    parts: parts.map(p => ({ id: p.id, step: p.step, position: p.node.getWorldPosition(new THREE.Vector3()).toArray(),
      assembled: p.worldAssembled.toArray(), start: p.worldAssembled.clone().add(p.worldOffset).toArray(),
      progress: p.progress, visible: p.node.visible, armor: Boolean(p.meta.armor),
      pending: p.pending, opacity: p.materials ? p.materials[0]?.material.opacity : 1,
      emissive: p.materials?.[0]?.material.emissive?.toArray(),
      bounds: p.bounds,
    })),
    calls: renderer.info.render.calls, triangles: renderer.info.render.triangles,
  });
}

let previousFrame = performance.now();
function frame(now) {
  requestAnimationFrame(frame);
  const dt = Math.min((now - previousFrame) / 1000, .1);
  previousFrame = now;
  if (!state.ready) return;
  if (playing) {
    setTime(time + dt * Number(ui.speed.value) / 1.4);
    if (time >= steps.length) setPlaying(false);
  }
  const fade = stepArrived === -Infinity ? 1 : Math.max(0, 1 - (now - stepArrived) / 1000);
  const amount = (.48 + .18 * Math.sin((now - pulseStart) / 1000 * Math.PI * 3)) * fade;
  pulse(pulseParts, amount);
  for (const [part, stopped] of fadingParts) {
    const remaining = Math.max(0, 1 - (now - stopped) / 1000);
    pulse([part], .48 * remaining);
    if (!remaining) fadingParts.delete(part);
  }
  if (followDirty && ui.follow.checked && !manualOrbit && now >= followPausedUntil) {
    frameCurrent();
    followDirty = false;
  }
  if (cameraTween) {
    const blend = 1 - Math.exp(-dt * 8); // 99% of the move in about 0.6 seconds.
    camera.position.lerp(cameraGoal, blend);
    controls.target.lerp(targetGoal, blend);
    if (camera.position.distanceToSquared(cameraGoal) < 1e-6 && controls.target.distanceToSquared(targetGoal) < 1e-6) cameraTween = false;
  }
  controls.update();
  renderer.render(scene, camera);
}
requestAnimationFrame(frame);
load().catch(error => {
  state.ready = false; state.error = error.message;
  console.error(error);
  $('loading-title').textContent = 'Unable to load the build';
  $('loading-detail').textContent = `${error.message}. Open this page with open-viewer.command; the pinned three.js modules require an internet connection.`;
  $('load-progress').hidden = true;
});
