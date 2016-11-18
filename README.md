# HydraTempate

This is a template to prepare for a Hydra program. It is intended to be placed next to the Hydra git checkout, but you can edit the `CMakeLists.txt` as needed. The most imporant component is the `cmake/FindHydra.cmake`, which is currently tested on CMake 3.3+ on Mac for TBB, and will soon be tested for other platforms.

For an analysis, you are expected to start from this structure and build on it; this is much better than forking Hydra, building inside, then trying to keep up with merging changes. The only change you might need from updates to the template repository would be to update the `FindHydra.cmake` file.
