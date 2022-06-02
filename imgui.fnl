(local lume (require :lib.lume))
(local {: vec : polar-vec2} (require :vector))
(local aabb (require :aabb))

(var layout-stack [])

(λ peek-layout-stack [] (. layout-stack 1))
(λ push-layout-stack [item] (table.insert layout-stack 1 item))
(λ pop-layout-stack [] (table.remove layout-stack 1))

(λ get-layout-rect [context]
  (aabb context.position context.size))

(λ expand-props [?tbl]
  (lume.merge
     {:display :absolute
      :direction :left
      :padding (vec 0 0)
      :flex 1
      :flex-direction :row}
     (or ?tbl {})))

(fn clean-children [?children]
  (if (or (not ?children) (= ?children :nil)) [] ?children))

(λ render-display-absolute [render-f props ?children]
  (let [context (peek-layout-stack)]
    (each [_ itm (ipairs (clean-children ?children))]
      (when itm
        (let [[cf ?cp ?cc] itm]
          (push-layout-stack
            {:size context.size
             :position (+ context.position
                          (or
                           (when (?. ?cp :position)
                             (if (= :string (type ?cp.position))
                                 (. (get-layout-rect context) ?cp.position)
                                 ?cp.position))
                           (vec 0 0)))})
          (render-f cf ?cp ?cc)
          (pop-layout-stack))))))

(λ render-display-flex [render-f props ?children]
  (let [root-context (peek-layout-stack)
        nchildren (length (or ?children []))
        width (/ root-context.size.x nchildren)
        height (/ root-context.size.y nchildren)
        offset (match props.flex-direction
                 :row (vec (- width) 0)
                 :column (vec 0 (- height)))]
    (var position (+ root-context.position offset))
    (each [_ itm (ipairs (if (or (not ?children) (not= :table (type ?children)))
                             [] ?children))]
      (when itm
        (let [[cf ?cp ?cc] itm
              context (peek-layout-stack)
              rect (get-layout-rect context)]
          (set position
             (+ position
                (match props.flex-direction
                    :row (vec width 0)
                    :column (vec 0 height)
                    _ (error "Invalid flex-direction"))))
          (push-layout-stack
            {:size
             (match props.flex-direction
                 :row (vec width context.size.y)
                 :column (vec context.size.x height)
                 _ (error "Invalid flex-direction"))
             : position})
          (render-f cf ?cp ?cc))))))

(λ render-display-stack [render-f props ?children]
  (let [root-context (peek-layout-stack)
        offset (match props.content-start
                 :top-right (* root-context.size (vec 1 0))
                 _ (vec 0 0))]
    (each [_ itm (ipairs (or ?children []))]
      (when itm
        (let [[cf ?cp ?cc] itm
              context (peek-layout-stack)
              rect (get-layout-rect context)
              {:size child-size} (render-f cf ?cp ?cc)]
          (push-layout-stack
            {:size context.size
             :position
             (+ context.position
                (match props.direction
                  :left (vec (- child-size.x) 0)
                  :right (vec child-size.x 0)
                  :up (vec 0 (- child-size.y))
                  :down (vec 0 child-size.y)))}))))))

(λ render-layout-node [f ?props ?children]
  (let [props (expand-props ?props)
        context (peek-layout-stack)]
    (let [new-context
          {:position (+ context.position props.padding)
           :size (- (or props.size context.size) (* props.padding 2))}]
      (f new-context props)
      (push-layout-stack new-context)
      (let [draw-f
            (match props
              {:display :absolute} render-display-absolute
              {:display :stack} render-display-stack
              {:display :flex} render-display-flex)]
        (draw-f render-layout-node props ?children)
        (for [i 1 (length (or ?children []))]
          (pop-layout-stack)))
      (pop-layout-stack))))

(λ layout [f ?props ?children]
  (when (not (peek-layout-stack))
    (let [(px py) (love.graphics.transformPoint 0 0)]
      ;; Screen is always the root of the layout stack
      (push-layout-stack {:position (vec px py)
                          :size (or (?. ?props :size)
                                    (vec (love.graphics.getWidth 
                                           (love.graphics.getHeight))))})))
  (render-layout-node f ?props ?children))


{: layout
 : get-layout-rect
 : peek-layout-stack
 : push-layout-stack
 : pop-layout-stack}
