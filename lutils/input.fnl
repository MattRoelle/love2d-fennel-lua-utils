(var last-state {})
(var state {})

(fn copy-state []
  (each [k v (pairs state)]
    (tset last-state k v)))

(fn update []
  (copy-state)
  (set state.mouse (love.mouse.isDown 1)))

(λ mouse-down? []
  state.mouse)

(fn mouse-pressed? []
  (and (not last-state.mouse) state.mouse))

(fn mouse-released? []
  (and last-state.mouse (not state.mouse)))

{: mouse-pressed? 
 : mouse-released?
 : mouse-down?
 : update}
