;; -*- Gerbil -*-
(import :gerbil/compiler)

(def gerbil-modules-expander
  '("gerbil/expander/common.ss"
    "gerbil/expander/stx.ss"
    "gerbil/expander/core.ss"
    "gerbil/expander/top.ss"
    "gerbil/expander/module.ss"
    "gerbil/expander/compile.ss"
    "gerbil/expander/root.ss"
    "gerbil/expander/stxcase.ss"
    "gerbil/expander.ss"))

(def gerbil-modules-compiler
  '("gerbil/compiler/base.ss"
    "gerbil/compiler/compile.ss"
    "gerbil/compiler/optimize-base.ss"
    "gerbil/compiler/optimize-xform.ss"
    "gerbil/compiler/optimize-top.ss"
    "gerbil/compiler/optimize-spec.ss"
    "gerbil/compiler/optimize-ann.ss"
    "gerbil/compiler/optimize-call.ss"
    "gerbil/compiler/optimize.ss"
    "gerbil/compiler/driver.ss"
    "gerbil/compiler/ssxi.ss"
    "gerbil/compiler.ss"))

(def gerbil-prelude-core
  '("gerbil/prelude/core.ss"))

(def gerbil-prelude-gambit
  '("gerbil/prelude/gambit/ports.ss"
    "gerbil/prelude/gambit/bytes.ss"
    "gerbil/prelude/gambit/misc.ss"
    "gerbil/prelude/gambit/random.ss"
    "gerbil/prelude/gambit/continuations.ss"
    "gerbil/prelude/gambit/os.ss"
    "gerbil/prelude/gambit/exceptions.ss"
    "gerbil/prelude/gambit/threads.ss"
    "gerbil/prelude/gambit/bits.ss"
    "gerbil/prelude/gambit/hvectors.ss"
    "gerbil/prelude/gambit/system.ss"
    "gerbil/prelude/gambit/foreign.ss"
    "gerbil/prelude/gambit/hash.ss"
    "gerbil/prelude/gambit/readtables.ss"
    "gerbil/prelude/gambit/fixnum.ss"
    "gerbil/prelude/gambit/flonum.ss"
    "gerbil/prelude/gambit/exact.ss"
    "gerbil/prelude/gambit.ss"))

(def gerbil-libdir
  (path-expand "lib" (getenv "GERBIL_TARGET")))

(def (compile1 modf debug optimize? gen-ssxi? static?)
  (displayln "... compile " modf)
  (compile-file modf [output-dir: gerbil-libdir invoke-gsc: #t
                      debug: debug optimize: optimize? generate-ssxi: gen-ssxi? static: static?
                      gsc-options: ["-cc-options" "--param max-gcse-memory=300000000"]]))

(def debug-none #f)  ; no bloat
(def debug-src 'src) ; full introspection -- sadly, it adds bloat and increases load time

(displayln "building gerbil in " gerbil-libdir)
;; initialize optimizer and preload core.ssxi so that we have core visibility
(gxc#optimizer-info-init!)
(gx#import-module "gerbil/prelude/core.ssxi.ss" #t #t)
;; compile expander first so that prelude macros have expander visibility; no static
(for-each (cut compile1 <> debug-none #t #t #f)
          gerbil-modules-expander)
;; compile core prelude; don't clobber core.ssxi
(for-each (cut compile1 <> debug-none #t #f #t)
          gerbil-prelude-core)
;; compile gambit prelude
(for-each (cut compile1 <> debug-none #t #t #t)
          gerbil-prelude-gambit)
;; compile compiler; no static
(for-each (cut compile1 <> debug-none #t #t #f)
          gerbil-modules-compiler)
