Build-only stub of the original RocketArena package.

The RA maps contain actors of RocketArena.ArenaInfo, RocketArena.ArenaPlayerStart and
RocketArena.ArenaViewCam, so RocketArenaV2 must use those classes from the original
package. Compiling against the full RocketArena.u is not possible (every class name
exists in both packages), so build.sh compiles this stub as "RocketArena" with the
three classes exactly as exported from the original. At runtime the references
resolve by name to the real RocketArena.u, which the maps require anyway.

Never ship the stub RocketArena.u.
