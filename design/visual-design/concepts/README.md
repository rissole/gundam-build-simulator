# Selected whole-robot concept

2026-11-01 · **Direction B (industrial service), turnaround v1, selected by the user**

The concept that the [approved reference turnaround](../turnaround/README.md)
was developed from. It was generated from the [visual design brief](../README.md)
with Codex's built-in `image_gen` tool by a `gpt-6-astra` (high) agent, with the
[approved silhouette](../../../models/silhouette-mannequin/README.md) turnaround
and low view as references and the brief's prompt verbatim. This folder holds
the [turnaround](b-industrial-service/turnaround-v1.jpg), the
[three-quarter view](b-industrial-service/three-quarter-v1.jpg), the exact
prompts and the agent's review in [notes.md](b-industrial-service/notes.md).
The notes call the agent's own v2 correction preferred; the user chose v1.

![Selected: direction B, turnaround v1](b-industrial-service/turnaround-v1.jpg)

## Round 1, for the record

Four directions were generated on the same silhouette: A heroic flagship
(white, blue and red), B industrial service, C samurai lacquer (navy, crimson
and gold) and D sharp prototype (white, black and orange). The user selected B.
The unused directions and B's v2 correction were removed on approval of the
reference turnaround; they remain in Git history at commit `1d3dce1`.

The user preferred B's v1 to the agent's v2 correction. That correction had
removed v1's paired ochre chest vents and slit-mouth faceplate, which closely
echo the classic RX-78. The reference turnaround keeps v1's character but
redraws both features in this robot's own shapes.

The same four tasks were also run with `gpt-6.1-terra` (high) for comparison;
those images were not kept. Image quality was comparable, because both models
drive the same image tool. Terra was faster and made fewer corrections, but it
kept one design that looked like a classic suit even after its own notes
flagged the resemblance.

These are concept images, not dimensioned drawings. The
[proportions](../../proportions.md) govern sizes.
