#pragma once
#include <stdint.h>

// Emit once for a sustained touch. Require a sustained release before rearming.
// A sensor held at boot must first be released; boot is never a selection.
class TouchFilter {
 public:
  constexpr bool update(bool touched, uint32_t now) {
    if (!initialized_) {
      initialized_ = true;
      candidate_ = touched;
      changedAt_ = now;
      return false;
    }
    if (touched != candidate_) {
      candidate_ = touched;
      changedAt_ = now;
    }
    const uint32_t stableFor = now - changedAt_; // Safe across millis() rollover.
    if (!armed_) {
      if (!touched && stableFor >= STARTUP_RELEASE_MS) armed_ = true;
      return false;
    }
    if (!active_ && touched && stableFor >= TOUCH_MS) {
      active_ = true;
      return true;
    }
    if (active_ && !touched && stableFor >= RELEASE_MS) active_ = false;
    return false;
  }

  static constexpr uint32_t TOUCH_MS = 120;
  static constexpr uint32_t RELEASE_MS = 250;
  static constexpr uint32_t STARTUP_RELEASE_MS = 500;

 private:
  bool initialized_ = false;
  bool candidate_ = false;
  bool armed_ = false;
  bool active_ = false;
  uint32_t changedAt_ = 0;
};
