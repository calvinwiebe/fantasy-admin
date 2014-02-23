# Shim bundle to add whatever custom version of jquery we want
# to the window. Bootstrap and Backbone need $ as a global.
#
$ = require 'jquery'
console.log 'setting up jquery'
window.$ = $
window.jQuery = $