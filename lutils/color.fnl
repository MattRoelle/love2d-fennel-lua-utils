(local Color {})
(set Color.__index Color)

(λ Color.lighten [])

; (fn Color.rgba-to-hsla [self]
;   (local (max min) (values (math.max self.r self.g self.b)
;                            (math.min self.r self.g self.b)))
;   (var (h s l) nil)
;   (set l (/ (+ max min) 2))
;   (if (= max min) (set-forcibly! (h s) (values 0 0))
;       (let [d (- max min)]
;         (var s nil)
;         (if (> l 0.5) (set s (/ d (- (- 2 max) min)))
;             (set s (/ d (+ max min))))
;         (if (= max r)
;             (do
;               (set h (/ (- g b) d))
;               (when (< g b)
;                 (set h (+ h 6))))
;             (= max g) (set h (+ (/ (- b r) d) 2)) (= max b)
;             (set h (+ (/ (- r g) d) 4)))
;         (set h (/ h 6))))
;   (values h s l self.a))

(λ rgba [r? g? b? a?]
  (setmetatable
    (if
      (= (type r?) :number)
      {:r r? :g g? :b b? :a a?}
      (?. r? :r)
      {:r r?.r :g r?.g :b r?.b :a r?.a}
      (?. r? 1)
      {:r (. r? 1) :g (. r? 2) :b (. r? 3) :a (. r? 4)}
      (error "Invalid color arguments"))
    Color))

(λ parse-hexadecimal-number [str] (tonumber str 16))
(λ hexcolor [str]
  (let [r (parse-hexadecimal-number (string.sub str 1 2))
        g (parse-hexadecimal-number (string.sub str 3 4))
        b (parse-hexadecimal-number (string.sub str 5 6))
        a (parse-hexadecimal-number (string.sub str 7 8))]
    (rgba (/ r 255) (/ g 255) (/ b 255) (/ a 255))))

(λ Color.set-alpha [self a]
  (rgba self.r self.g self.b a))

(λ Color.clone [self]
  (rgba self.r self.g self.b self.a))

(λ Color.serialize [self]
  [self.r self.g self.b self.a])

(λ Color.__tostring [self]
  (string.format "(%d, %d, %d, %d)" self.r self.g self.b self.a))

{: rgba
 :white (rgba 1 1 1 1)
 :black (rgba 0 0 0 1)
 : hexcolor}
