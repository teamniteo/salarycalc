module Career exposing
    ( Career
    , Role
    )


type alias Role =
    { name : String
    , baseSalary : Float
    }


type alias Career =
    { name : String
    , roles : List Role
    }
