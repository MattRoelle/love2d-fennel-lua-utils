(local spine (require :spine-love.spine))

(local Spine {})
(set Spine.__index Spine)

(fn Spine.update [self dt]
  (self.state:update dt)
  (self.state:apply self.skeleton)
  (self.skeleton:updateWorldTransform))

(fn Spine.draw [self]
  (self.skeleton-renderer:draw self.skeleton))

(fn spineasset [name initial-anim]
 (let [atlas (spine.TextureAtlas.new (spine.utils.readFile (.. "assets/" name ".atlas"))
              #(love.graphics.newImage (.. "assets/" $1)))
       json (spine.SkeletonJson.new (spine.AtlasAttachmentLoader.new atlas))
       skeletonData (json:readSkeletonDataFile (.. "assets/" name ".json"))]
  (fn []
    (let [skeleton (spine.Skeleton.new skeletonData)
          skeleton-renderer (spine.SkeletonRenderer.new true)
          self (setmetatable {: atlas
                              : json
                              : skeletonData
                              : skeleton
                              : skeleton-renderer} Spine)]
      (set skeleton.scaleY -1)
     (set self.stateData (spine.AnimationStateData.new self.skeletonData))
     (set self.state (spine.AnimationState.new self.stateData))
     (self.state:setAnimationByName 0 initial-anim true)
     (self.skeleton:setToSetupPose)
     self))))

{: spineasset}
