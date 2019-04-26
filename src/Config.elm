module Config exposing
    ( Config
    , careerDecoder
    , careersDecoder
    , citiesDecoder
    , cityDecoder
    , configDecoder
    , roleDecoder
    , rolesDecoder
    )

import Career exposing (Career, Role)
import City exposing (City)
import Json.Decode as Decode


type alias Config =
    { cities : List City
    , careers : List Career
    }


{-| Used in `init` function to decode config passed in `Flags`

    import Json.Decode as Decode
    import City exposing (City)
    import Career exposing (Role, Career)

    Decode.decodeString configDecoder """
      {
        "cities" : [
          {
            "name": "Keren",
            "locationFactor": 1.87
          }
        ],
        "careers" : [
          {
            "name": "Design",
            "roles": [
              {
                "name": "Junior Designer",
                "baseSalary": 2345
              }
            ]
          }
        ]
      }
    """
    --> Ok
    -->     { cities = [ City "Keren" 1.87 ]
    -->     , careers =
    -->         [ Career "Design"
    -->             [ Role "Junior Designer" 2345 ]
    -->         ]
    -->     }

-}
configDecoder : Decode.Decoder Config
configDecoder =
    Decode.map2
        Config
        (Decode.field "cities" citiesDecoder)
        (Decode.field "careers" careersDecoder)


{-| A helper for configDecoder

    import City exposing (City)
    import Json.Decode as Decode

    Decode.decodeString citiesDecoder """
      [
        {
          "name": "Keren",
          "locationFactor": 1.87
        }
      ]
    """
    --> Ok [ City "Keren" 1.87 ]

-}
citiesDecoder : Decode.Decoder (List City)
citiesDecoder =
    Decode.list cityDecoder
        |> Decode.andThen
            (\cities ->
                if List.length cities == 0 then
                    Decode.fail "There must be at least one city in your config."

                else
                    Decode.succeed cities
            )


{-| A helper for configDecoder

    import City exposing (City)
    import Json.Decode as Decode

    Decode.decodeString cityDecoder """
      {
        "name": "Keren",
        "locationFactor": 1.87
      }
    """
    --> Ok (City "Keren" 1.87)

-}
cityDecoder : Decode.Decoder City
cityDecoder =
    Decode.map2 City
        (Decode.field "name" Decode.string)
        (Decode.field "locationFactor" Decode.float)


{-| A helper for configDecoder

    import Career exposing (Career, Role)
    import Json.Decode as Decode

    Decode.decodeString careersDecoder """
      [
        {
          "name": "Design",
          "roles": [
            {
              "name": "Junior Designer",
              "baseSalary": 2345
            }
          ]
        }
      ]
    """
    --> Ok [ Career "Design" [ Role "Junior Designer" 2345 ] ]

-}
careersDecoder : Decode.Decoder (List Career)
careersDecoder =
    Decode.list careerDecoder
        |> Decode.andThen
            (\careers ->
                if List.length careers == 0 then
                    Decode.fail "There must be at least one career in your config."

                else
                    Decode.succeed careers
            )


{-| A helper for configDecoder

    import Career exposing (Career, Role)
    import Json.Decode as Decode

    Decode.decodeString careerDecoder """
      {
        "name": "Design",
        "roles": [
          {
            "name": "Junior Designer",
            "baseSalary": 2345
          }
        ]
      }
    """
    --> Ok
    -->     (Career "Design"
    -->         [ Role "Junior Designer" 2345 ]
    -->     )

-}
careerDecoder : Decode.Decoder Career
careerDecoder =
    Decode.map2
        Career
        (Decode.field "name" Decode.string)
        (Decode.field "roles" rolesDecoder)


{-| A helper for configDecoder

    import Json.Decode as Decode
    import Career exposing (Role)

    Decode.decodeString rolesDecoder """
      [
        {
          "name": "Junior Designer",
          "baseSalary": 2345
        }
      ]
    """
    --> Ok [ Role "Junior Designer" 2345 ]

-}
rolesDecoder : Decode.Decoder (List Role)
rolesDecoder =
    Decode.list roleDecoder
        |> Decode.andThen
            (\roles ->
                if List.length roles == 0 then
                    Decode.fail "There must be at least one role in your config."

                else
                    Decode.succeed roles
            )


{-| A helper for configDecoder

    import Career exposing (Role)
    import Json.Decode as Decode

    Decode.decodeString roleDecoder """
      {
        "name": "Junior Designer",
        "baseSalary": 2345
      }
    """
    --> Ok (Role "Junior Designer" 2345)

-}
roleDecoder : Decode.Decoder Role
roleDecoder =
    Decode.map2 Role
        (Decode.field "name" Decode.string)
        (Decode.field "baseSalary" Decode.int |> Decode.map toFloat)
