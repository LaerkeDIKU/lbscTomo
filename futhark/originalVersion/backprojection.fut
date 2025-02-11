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

import "projection_lib"
open Projection

let main  [p][a](angles : [a]f32)
          (rhozero : f32)
          (deltarho : f32)
          (size : i32)
          (projections: [p]f32): []f32 =
          back_projection angles rhozero deltarho size projections
