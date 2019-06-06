-- ==
-- input@../../data/bpinputf32rad64
-- input@../../data/bpinputf32rad128
-- input@../../data/bpinputf32rad256
-- input@../../data/bpinputf32rad512
-- input@../../data/bpinputf32rad1024
-- input@../../data/bpinputf32rad1500
-- input@../../data/bpinputf32rad2000
-- input@../../data/bpinputf32rad2048
-- input@../../data/bpinputf32rad2500
-- input@../../data/bpinputf32rad3000
-- input@../../data/bpinputf32rad3500
-- input@../../data/bpinputf32rad4000
-- input@../../data/bpinputf32rad4096


import "testlib"
open testlib

let main  [p][a](angles : [a]f32)
          (rhozero : f32)
          (deltarho : f32)
          (size : i32)
          (projections: [p]f32): []f32 =
          let rhosprpixel = t32(f32.ceil(f32.sqrt(2)/deltarho))
          let halfsize = size/2
          let lines = preprocess angles
          let steep = bp_steep lines.2 0 rhozero deltarho rhosprpixel r halfsize projections
          let flat = bp_flat lines.1 (length lines.2) rhozero deltarho rhosprpixel r halfsize projections
          in map2 (+) steep flat
