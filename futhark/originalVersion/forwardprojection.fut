-- ==
-- input@../../data/fpinputf32rad64
-- input@../../data/fpinputf32rad128
-- input@../../data/fpinputf32rad256
-- input@../../data/fpinputf32rad512
-- input@../../data/fpinputf32rad1024
-- input@../../data/fpinputf32rad1500
-- input@../../data/fpinputf32rad2000
-- input@../../data/fpinputf32rad2048
-- input@../../data/fpinputf32rad2500
-- input@../../data/fpinputf32rad3000
-- input@../../data/fpinputf32rad3500
-- input@../../data/fpinputf32rad4000
-- input@../../data/fpinputf32rad4096

import "projection_lib"
open Projection

let main  [n][a] (angles : *[a]f32)
          (rhozero : f32)
          (deltarho : f32)
          (numrhos : i32)
          (image : *[n]f32) =
          let rhos = map (\i -> rhozero+ r32(i)*deltarho) (iota numrhos)
          let size = t32(f32.sqrt(r32(n)))
          let halfsize = size/2
          in forward_projection angles rhos halfsize image
