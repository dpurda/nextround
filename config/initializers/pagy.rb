# Pagy 43.x uses a single Pagy::Method mixin (included in ApplicationController)
# rather than the older Pagy::Backend/Pagy::Frontend split. See DESIGN.md's
# note on this if extending pagination elsewhere.
Pagy::OPTIONS[:limit] = 15
Pagy::OPTIONS.freeze
