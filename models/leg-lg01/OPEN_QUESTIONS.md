# LG-01-3D-01 open questions

Questions raised while building the leg model. Each records the default chosen
so work could continue; the user can overturn any of them.

| # | Phase | Question | Default chosen |
| --- | --- | --- | --- |
| P2-01 | 2 | How should duplicate CSV part IDs retain distinct physical roles? | Preserve exact CSV `name` as `part_name`; namespace integer instance numbers by that name, or provide a stable explicit suffix such as `lug.03`. Never merge the rows by ID alone. |
| P2-02 | 2 | Should every integral helper be a fabrication-grade union? | Use independent closed shells within one manufactured-module mesh, as in FA-01. Audit closure and outward normals per shell; reserve Boolean unions and fabrication tolerances for a future engineering requirement. |
| P2-03 | 2 | How should subtle wear survive glTF without procedural shader dependencies? | Use 0–6% darker per-corner color on facets, exported as COLOR_0 with the current Mix Color node; keep Principled roughness constant. No normal maps. |
| P2-04 | 2 | Should AgX's lighter red stencils and the exposed test bell's large bronze area change the approved palette? | Keep exact approved sRGB colors and the separate bronze lining. Record the lighting difference; judge the final bell's visible bronze area inside phase 4's calf shroud. Stop after three inspected board renders. |
