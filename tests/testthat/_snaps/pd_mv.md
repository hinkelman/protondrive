# failed bulk results become errors

    Code
      pd_cp(fake_dribble("a.csv", 1), path = "archive")
    Condition
      Error in `pd_cp()`:
      ! Failed to copy 1 item.
      x a.csv: the CLI did not report a reason (run the CLI directly for details)

