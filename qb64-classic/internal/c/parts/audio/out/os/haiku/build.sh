#!/bin/sh
# On Haiku, OpenAL is provided by the HaikuPorts 'openal' package, which adds a
# native Media Kit backend upstream OpenAL Soft does not have. The bundled copy
# in parts/audio/out/src is therefore not compiled here; the final link uses
# -lopenal (see internal/c/makeline_haiku.txt).
rm -f src.a
ar rcs src.a
