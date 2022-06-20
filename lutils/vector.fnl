(local Vector2D {})
(set Vector2D.__index Vector2D)

;; TODO: Implement Vector3d
(local Vector3D {})
(set Vector3D.__index #(error "TODO: Implement Vector3D"))

;; TODO: Implement Vector4d / Quaternion / Colors
(local Vector4D {})
(set Vector4D.__index #(error "TODO: Implement Vector4D"))

(fn vec [x y z? w?]
  (assert x "Must pass at least x and y")
  (assert y "Must pass at least x and y")
  (setmetatable 
    {:x x 
     :y y 
     :z z? 
     :w w?}
    (if w? Vector4D 
        z? Vector3D 
        Vector2D)))

(fn polar-vec2 [theta magnitude]
  (vec (* (math.cos theta) magnitude)
       (* (math.sin theta) magnitude)))

(fn Vector2D.__unm [v] (vec (- v.x) (- v.y)))

(fn Vector2D.__add [a b] (vec (+ a.x b.x) (+ a.y b.y)))

(fn Vector2D.__sub [a b] (vec (- a.x b.x) (- a.y b.y)))

(fn Vector2D.__mul [a b]
  (if (= (type a) :number) (vec (* a b.x) (* a b.y))
      (= (type b) :number) (vec (* a.x b) (* a.y b))
      (vec (* a.x b.x) (* a.y b.y))))

(fn Vector2D.__div [a b]
  (vec (/ a.x b) (/ a.y b)))

(fn Vector2D.__eq [a b]
  (and (= a.x b.x) (= a.y b.y)))

(fn Vector2D.__tostring [self]
  (.. "(" self.x ", " self.y ")"))

(fn Vector2D.floor [self]
  (vec (math.floor self.x)
       (math.floor self.y)))

(fn Vector2D.clamp [self min max]
  (vec (math.min (math.max self.x min.x) max.x)
       (math.min (math.max self.y min.y) max.y)))

(fn Vector2D.clamp! [self min max]
  (set (self.x self.y)
       (values (math.min (math.max self.x min.x) max.x)
               (math.min (math.max self.y min.y) max.y))))

(fn Vector2D.distance-to [a b]
  (math.sqrt (+ (^ (- a.x b.x) 2) (^ (- a.y b.y) 2))))

(fn Vector2D.angle-from [a b]
  (math.atan2 (- a.y b.y) (- a.x b.x)))

(fn Vector2D.angle-to [a b]
  (math.atan2 (- b.y a.y) (- b.x a.x)))

(fn Vector2D.angle [self]
  (math.atan2 self.y self.x))

(fn Vector2D.set-angle [self angle]
  (let [len (self:length)]
    (vec (* (math.cos angle) len)
         (* (math.sin angle) len))))

(fn Vector2D.set-angle! [self angle]
  (let [len (self:length)]
    (set (self.x self.y)
         (values (* (math.cos angle) len)
                 (* (math.sin angle) len)))))

(fn Vector2D.rotate [self theta]
  (let [s (math.sin theta)
        c (math.cos theta)]
      (vec (+ (* c self.x) (* s self.y)) (+ (- (* s self.x)) (* c self.y)))))

(fn Vector2D.rotate! [self theta]
  (let [s (math.sin theta)
        c (math.cos theta)]
      (vec (+ (* c self.x) (* s self.y)) (+ (- (* s self.x)) (* c self.y)))))

(fn Vector2D.unpack [self]
  (values self.x self.y))

(fn Vector2D.clone [self]
  (vec self.x self.y))

(fn Vector2D.length [self]
  (math.sqrt (+ (^ self.x 2)
                (^ self.y 2))))

(fn Vector2D.set-length [self len]
  (let [theta (self:angle)]
    (vec (* (math.cos theta) len)
         (* (math.sin theta) len))))

(fn Vector2D.clamp-length [self min max]
  (let [l (self:length)]
    (if (< l min)
        (self:set-length min)
        (> l max)
        (self:set-length max)
        self)))

(fn Vector2D.clamp-length! [self min max]
  (let [l (self:length)]
    (if (< l min)
        (self:set-length! min)
        (> l max)
        (self:set-length! max))
    self))

(fn Vector2D.set-length! [self len]
  (let [theta (self:angle)]
    (set (self.x self.y)
         (values (* (math.cos theta) len)
              (* (math.sin theta) len)))))

(fn Vector2D.lengthsq [self]
  (+ (^ self.x 2) (^ self.y 2)))

(fn Vector2D.normalize [self]
  (let [mag (self:length)]
    (if (= mag 0)
      self
      (vec (/ self.x mag) (/ self.y mag)))))

(fn Vector2D.normalize! [self]
  (let [mag (self:length)]
    (when (= mag 0)
      (set (self.x self.y)
           (values (/ self.x mag) (/ self.y mag))))))

(fn Vector2D.dot [self v]
  (+ (* self.x v.x) (* self.y v.y)))

(fn Vector2D.limit [self max]
  (let [magsq (self:lengthsq)
        theta (self:angle)]
    (if (> magsq (^ max 2))
      (polar-vec2 theta max)
      self)))

(fn Vector2D.limit! [self max]
  (let [magsq (self:lengthsq)
        theta (self:angle)]
    (if (> magsq (^ max 2))
      (set (self.x self.y)
           (values (* (math.cos theta) max)
                   (* (math.sin theta) max)))
      self)))

(fn Vector2D.lerp [a b t]
  (vec (+ (* a.x (- 1 t)) (* b.x t))
       (+ (* a.y (- 1 t)) (* b.y t))))

(fn Vector2D.lerp! [a b t]
  (set (a.x a.y)
       (values (+ (* a.x (- 1 t)) (* b.x t))
               (+ (* a.y (- 1 t)) (* b.y t)))))

(fn Vector2D.midpoint [a b]
  (/ (+ a b) 2))

{: vec 
 : Vector2D
 : polar-vec2}
