// Hide the AMD loader from the blacklight_range_limit UMD bundle.
//
// almond-rails makes `define.amd` truthy, so the gem's UMD wrapper takes the
// AMD branch and its anonymous `define` throws, leaving no global and no
// slider. Hyku requires this file first; range_limit_shared restores `define`
// after the bundle has loaded.

window.hyku_stashed_amd_define = null;

if (typeof define === 'function' && define.amd) {
  window.hyku_stashed_amd_define = define;
  window.define = undefined;
}
