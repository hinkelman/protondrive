# pd_untrash() refuses ambiguous or mismatched names

    Code
      pd_untrash(fake_dribble("a", 1, path = "/trash/a"))
    Condition
      Error in `pd_untrash()`:
      ! '/trash' holds 2 items named "a".
      x The Proton Drive CLI identifies trashed items by name, so protondrive can't tell which one you mean.
      i Restore and rename the others first, or use the Proton Drive web app.

