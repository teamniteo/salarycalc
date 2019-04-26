module Salary exposing
    ( calculate
    , commitmentBonus
    )

import Career exposing (Role)
import City exposing (City)


{-| Calculate a salary based on a role, city and tenure

    import City exposing (City)
    import Career exposing (Role)

    calculate (Role "Designer" 2500) (City "Warsaw" 1) 0
    --> 2500

    calculate (Role "Designer" 2500) (City "Amsterdam" 1.5) 0
    --> 3750

-}
calculate : Role -> City -> Int -> Int
calculate role city tenure =
    round
        (role.baseSalary
            * city.locationFactor
            + role.baseSalary
            * commitmentBonus tenure
        )


{-| Given a tenure returns a commitmentBonus.

    Ok (commitmentBonus 3)
    --> Ok 0.13862943611198905
    -- Note: the value is tagged with `Ok` (i.e. wrapped in a `Result` type) to
    -- bypass a limitation of Elm Verify Examples.
    -- See https://github.com/stoeffel/elm-verify-examples/issues/83

-}
commitmentBonus : Int -> Float
commitmentBonus tenure =
    logBase e (toFloat tenure + 1) / 10
