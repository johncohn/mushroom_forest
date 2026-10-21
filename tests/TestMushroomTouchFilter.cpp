// Compile with a C++14-or-newer compiler, e.g. g++ -std=c++14 -fsyntax-only
// tests/TestMushroomTouchFilter.cpp. Assertions exercise the production filter
// at compile time; no board, USB, lighting, or audio is involved.
#include "../mush_touch_v1/TouchFilter.h"

constexpr bool bootHeld() {
  TouchFilter f;
  return !f.update(true, 0) && !f.update(true, 5000) &&
      !f.update(false, 5001) && !f.update(false, 5500) &&
      !f.update(false, 5501) && !f.update(true, 5502) &&
      !f.update(true, 5621) && f.update(true, 5622) &&
      !f.update(true, 9000);
}
static_assert(bootHeld(), "Boot-held sensor must release before selecting once");

constexpr bool glitches() {
  TouchFilter f;
  if (f.update(false, 0) || f.update(false, 500)) return false;
  for (uint32_t t = 600; t < 10000; t += 100) {
    if (f.update(true, t) || f.update(true, t + 10) ||
        f.update(false, t + 20)) return false;
  }
  return true;
}
static_assert(glitches(), "Repeated brief touch glitches must never select");

constexpr bool releaseChatter() {
  TouchFilter f;
  return !f.update(false, 0) && !f.update(false, 500) &&
      !f.update(true, 600) && f.update(true, 720) &&
      !f.update(false, 800) && !f.update(true, 1000) &&
      !f.update(true, 1200) && !f.update(false, 1300) &&
      !f.update(false, 1549) && !f.update(false, 1550) &&
      !f.update(true, 1560) && f.update(true, 1680);
}
static_assert(releaseChatter(), "Short releases must not rearm a held touch");

constexpr bool rollover() {
  TouchFilter f;
  return !f.update(false, 0xfffff000u) &&
      !f.update(false, 0xfffff1f4u) && !f.update(true, 0xfffffff0u) &&
      !f.update(true, 0x67u) && f.update(true, 0x68u);
}
static_assert(rollover(), "Touch timing must survive millis rollover");

constexpr bool independentSensors() {
  TouchFilter a, b;
  return !a.update(false, 0) && !b.update(false, 0) &&
      !a.update(false, 500) && !b.update(false, 500) &&
      !a.update(true, 600) && !b.update(true, 600) &&
      a.update(true, 720) && b.update(true, 720) &&
      !a.update(true, 2000) && !b.update(true, 2000);
}
static_assert(independentSensors(), "Each sensor must filter independently");

constexpr bool startupChatter() {
  TouchFilter f;
  return !f.update(true, 0) && !f.update(false, 100) &&
      !f.update(false, 599) && !f.update(true, 600) &&
      !f.update(true, 1000) && !f.update(false, 1100) &&
      !f.update(false, 1600) && !f.update(true, 1700) &&
      f.update(true, 1820);
}
static_assert(startupChatter(), "Startup needs a continuous released interval");
