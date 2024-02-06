module Config exposing
    ( Config
    , careerDecoder
    , careersDecoder
    , configDecoder
    , countriesDecoder
    , countryDecoder
    , roleDecoder
    , rolesDecoder
    )

import Career exposing (Career, Role)
import Country exposing (Country)
import Json.Decode as Decode


type alias Config =
    { countries : List Country
    , careers : List Career
    , careers_updated : String
    , countries_updated : String
    }


{-| Used in `init` function to decode config passed in `Flags`

    import Json.Decode as Decode
    import Country exposing (Country)
    import Career exposing (Role, Career)

    Decode.decodeString configDecoder """
      {
        "careers_updated" : "1999-01-01",
        "countries_updated" : "2000-01-01",
        "countries" : [
          {
            "name": "Spain",
            "compressed_cost_of_living": 1.87
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
    -->     {
    -->     careers_updated = "1999-01-01"
    -->     , countries_updated = "2000-01-01"
    -->     , countries = [ Country "Spain" 1.87 ]
    -->     , careers =
    -->         [ Career "Design"
    -->             [ Role "Junior Designer" 2345 ]
    -->         ]
    -->     }

-}
configDecoder : Decode.Decoder Config
configDecoder =
    Decode.map4
        Config
        (Decode.field "countries" countriesDecoder)
        (Decode.field "careers" careersDecoder)
        (Decode.field "careers_updated" Decode.string)
        (Decode.field "countries_updated" Decode.string)


{-| A helper for configDecoder

    import Country exposing (Country)
    import Json.Decode as Decode

    Decode.decodeString countriesDecoder """
      [
        {
          "name": "Spain",
          "compressed_cost_of_living": 1.87
        }
      ]
    """
    --> Ok [ Country "Spain" 1.87 ]

-}
countriesDecoder : Decode.Decoder (List Country)
countriesDecoder =
    Decode.list countryDecoder
        |> Decode.andThen
            (\cities ->
                if List.length cities == 0 then
                    Decode.fail "There must be at least one country in your config."

                else
                    Decode.succeed cities
            )


{-| A helper for configDecoder

    import Country exposing (Country)
    import Json.Decode as Decode

    Decode.decodeString countryDecoder """
      {
        "name": "Spain",
        "compressed_cost_of_living": 1.87
      }
    """
    --> Ok (Country "Spain" 1.87)

-}
countryDecoder : Decode.Decoder Country
countryDecoder =
    Decode.map2 Country
        (Decode.field "name" Decode.string)
        (Decode.field "compressed_cost_of_living" Decode.float)


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
