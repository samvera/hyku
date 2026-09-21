// Restore the AMD loader after the blacklight_range_limit UMD bundle has loaded.
//
// range_limit_shared loads the gem's bundle; this file is required last and acts
// as a safety net in case that file did not restore `define` itself.

if (window.hyku_stashed_amd_define) {
  window.define = window.hyku_stashed_amd_define;
  window.hyku_stashed_amd_define = null;
}
