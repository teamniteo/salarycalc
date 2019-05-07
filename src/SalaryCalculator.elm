module SalaryCalculator exposing
    ( Career
    , City
    , Config
    , Field(..)
    , Flags
    , Model
    , Msg(..)
    , Query
    , Role
    , Warning
    , careerDecoder
    , careersDecoder
    , citiesDecoder
    , cityDecoder
    , clearWarnings
    , commitmentBonus
    , configDecoder
    , humanizeCommitmentBonus
    , humanizeTenure
    , init
    , lookupByName
    , main
    , roleDecoder
    , rolesDecoder
    , salary
    , subscriptions
    , update
    , view
    , viewBreakdown
    , viewBreakdownToggle
    , viewCityDropdown
    , viewCityItem
    , viewForm
    , viewPluralizedYears
    , viewRoleDropdown
    , viewRoleItem
    , viewSalary
    , viewTenureDropdown
    , viewTenureItem
    , viewWarnings
    )

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Result.Extra as Result
import Url exposing (fromString)
import Url.Parser as UrlParser exposing ((<?>), parse)
import Url.Parser.Query as QueryParser exposing (int, map3, string)



-- MODEL


{-| Given a list of records with a name field returns first item with a
matching name. If no item has a matching name then returns Nothing.

    lookupByName "Amsterdam"
        [ { name = "Amsterdam", locationFactor = 1.4 }
        , { name = "Ljubljana", locationFactor = 1.0 }
        ]
    --> Just { name = "Amsterdam", locationFactor = 1.4 }

    lookupByName "Warsaw"
        [ { name = "Amsterdam", locationFactor = 1.4 }
        , { name = "Ljubljana", locationFactor = 1.0 }
        ]
    --> Nothing

-}
lookupByName : String -> List { a | name : String } -> Maybe { a | name : String }
lookupByName name rolesOrCities =
    rolesOrCities
        |> List.filter (\record -> record.name == name)
        |> List.head


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            case Decode.decodeValue configDecoder flags.config of
                Err error ->
                    { error = Just (Decode.errorToString error)
                    , warnings = []
                    , cities = []
                    , careers = []
                    , role = Nothing
                    , city = Nothing
                    , tenure = 0
                    , breakdownVisible = False
                    , activeField = Nothing
                    }

                Ok config ->
                    let
                        maybeUrl =
                            Url.fromString flags.location

                        queryParser =
                            QueryParser.map3 Query
                                (QueryParser.string "role")
                                (QueryParser.string "city")
                                (QueryParser.int "years")

                        parser =
                            UrlParser.top <?> queryParser

                        query : Query
                        query =
                            case maybeUrl of
                                Just url ->
                                    { url | path = "/" }
                                        |> UrlParser.parse parser
                                        |> Maybe.withDefault
                                            { role = Nothing
                                            , city = Nothing
                                            , years = Nothing
                                            }

                                Nothing ->
                                    { role = Nothing, city = Nothing, years = Nothing }

                        roles =
                            config.careers
                                |> List.map .roles
                                |> List.concat

                        role : Result Warning (Maybe Role)
                        role =
                            case query.role of
                                Just roleName ->
                                    lookupByName roleName roles
                                        |> Result.fromMaybe
                                            (Warning
                                                RoleField
                                                ("Invalid role provided via URL: "
                                                    ++ roleName
                                                    ++ ". Please choose one from the dropdown below."
                                                )
                                            )
                                        |> Result.map Just

                                Nothing ->
                                    Ok (List.head roles)

                        city : Result Warning (Maybe City)
                        city =
                            case query.city of
                                Just cityName ->
                                    lookupByName cityName config.cities
                                        |> Result.fromMaybe
                                            (Warning
                                                CityField
                                                ("Invalid city provided via URL: "
                                                    ++ cityName
                                                    ++ ". Please choose one from the dropdown below."
                                                )
                                            )
                                        |> Result.map Just

                                Nothing ->
                                    Ok (List.head config.cities)

                        warnings =
                            [ case role of
                                Ok _ ->
                                    Nothing

                                Err warning ->
                                    Just warning
                            , case city of
                                Ok _ ->
                                    Nothing

                                Err warning ->
                                    Just warning
                            ]
                                |> Maybe.values
                    in
                    { error = Nothing
                    , warnings = warnings
                    , cities = config.cities
                    , careers = config.careers
                    , role = role |> Result.extract (\_ -> Nothing)
                    , city = city |> Result.extract (\_ -> Nothing)
                    , tenure = Maybe.withDefault 2 query.years
                    , breakdownVisible = False
                    , activeField = Nothing
                    }
    in
    ( model
    , Cmd.none
    )


{-| Used in `init` function to decode config passed in `Flags`

    import Json.Decode as Decode

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


type alias Flags =
    { location : String
    , config : Decode.Value
    }


type alias Config =
    { cities : List City
    , careers : List Career
    }


type alias City =
    { name : String
    , locationFactor : Float
    }


type alias Role =
    { name : String
    , baseSalary : Float
    }


type alias Career =
    { name : String
    , roles : List Role
    }


type alias Query =
    { role : Maybe String
    , city : Maybe String
    , years : Maybe Int
    }


type Msg
    = DropdownButtonClicked Field
    | RoleItemSelected Role
    | CityItemSelected City
    | TenureItemSelected Int
    | BreakdownToggleClicked


type Field
    = RoleField
    | CityField
    | TenureField


type alias Warning =
    { field : Field
    , msg : String
    }


type alias Model =
    { error : Maybe String
    , warnings : List Warning
    , careers : List Career
    , cities : List City
    , role : Maybe Role
    , city : Maybe City
    , tenure : Int
    , breakdownVisible : Bool
    , activeField : Maybe Field
    }


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


{-| Format tenure given as an integer as a human readable string.

    humanizeTenure 0
    --> "Just started"

    humanizeTenure 1
    --> "1 year"

    humanizeTenure 3
    --> "3 years"

-}
humanizeTenure : Int -> String
humanizeTenure years =
    if years < 1 then
        "Just started"

    else if years == 1 then
        String.fromInt years ++ " year"

    else
        String.fromInt years ++ " years"


{-| Calculate a salary based on a role, city and tenure

    salary (Role "Designer" 2500) (City "Warsaw" 1) 0
    --> 2500

    salary (Role "Designer" 2500) (City "Amsterdam" 1.5) 0
    --> 3750

-}
salary : Role -> City -> Int -> Int
salary role city tenure =
    round
        (role.baseSalary
            * city.locationFactor
            + role.baseSalary
            * commitmentBonus tenure
        )



-- UPDATE


clearWarnings : Field -> List Warning -> List Warning
clearWarnings field warnings =
    List.filter (\warning -> warning.field /= field) warnings


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        DropdownButtonClicked field ->
            if model.activeField == Just field then
                ( { model | activeField = Nothing }
                , Cmd.none
                )

            else
                ( { model | activeField = Just field }
                , Cmd.none
                )

        RoleItemSelected role ->
            ( { model
                | warnings = clearWarnings RoleField model.warnings
                , role = Just role
                , activeField = Nothing
              }
            , Cmd.none
            )

        CityItemSelected city ->
            ( { model
                | warnings = clearWarnings CityField model.warnings
                , city = Just city
                , activeField = Nothing
              }
            , Cmd.none
            )

        TenureItemSelected tenure ->
            ( { model
                | warnings = clearWarnings TenureField model.warnings
                , tenure = tenure
                , activeField = Nothing
              }
            , Cmd.none
            )

        BreakdownToggleClicked ->
            ( { model | breakdownVisible = not model.breakdownVisible }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.error of
        Just error ->
            error
                |> (++) "App initialization failed: "
                |> text

        Nothing ->
            div
                [ class "container-fluid"
                ]
                [ div
                    [ class "warnings"
                    , class "row"
                    ]
                    [ div
                        [ class "col-lg-12" ]
                        [ viewWarnings model.warnings ]
                    ]
                , div
                    [ class "form"
                    , class "row"
                    ]
                    [ div
                        [ class "col-lg-12"
                        , class "bg-light"
                        , class "p-4"
                        , class "border-bottom"
                        ]
                        [ viewForm model ]
                    ]
                , div
                    [ class "breakdown"
                    , class "row"
                    , class "collapse"
                    , classList
                        [ ( "show"
                          , not model.breakdownVisible
                          )
                        ]
                    ]
                    [ div
                        [ class "col-lg-12"
                        , class "p-3"
                        , class "border border-light"
                        ]
                        (case ( model.role, model.city ) of
                            ( Nothing, _ ) ->
                                []

                            ( _, Nothing ) ->
                                []

                            ( Just role, Just city ) ->
                                [ viewBreakdown role city model.tenure ]
                        )
                    ]
                ]


viewBreakdownToggle model =
    if
        model.role
            /= Nothing
            && model.city
            /= Nothing
    then
        button
            [ onClick BreakdownToggleClicked
            , class "btn"
            , class "btn-link"
            ]
            [ text "Okay, let's break that down ..." ]

    else
        text ""


viewWarnings : List Warning -> Html Msg
viewWarnings warnings =
    warnings
        |> List.map .msg
        |> List.map text
        |> List.map List.singleton
        |> List.map
            (div
                [ class "alert"
                , class "alert-warning"
                , attribute "role" "alert"
                ]
            )
        |> div []


viewForm : Model -> Html Msg
viewForm model =
    div []
        [ p [ class "lead" ]
            [ "I'm a " |> text
            , model.role
                |> viewRoleDropdown
                    (model.activeField == Just RoleField)
                    model.careers
            , " living in " |> text
            , model.city
                |> viewCityDropdown
                    (model.activeField == Just CityField)
                    model.cities
            , " with a tenure at Niteo of " |> text
            , model.tenure
                |> viewTenureDropdown
                    (model.activeField == Just TenureField)
            , model.tenure |> viewPluralizedYears
            ]
        , p [ class "lead" ]
            [ viewSalary model.role model.city model.tenure
            ]
        , viewBreakdownToggle model
        ]


viewRoleDropdown : Bool -> List Career -> Maybe Role -> Html Msg
viewRoleDropdown active careers role =
    let
        viewItems : List (Html Msg)
        viewItems =
            careers
                |> List.map viewCareerItemsSection
                |> List.concat

        viewCareerItemsSection : Career -> List (Html Msg)
        viewCareerItemsSection career =
            h6
                [ class "dropdown-header" ]
                [ text (career.name ++ " Career") ]
                :: List.map viewRoleItem career.roles
    in
    div
        [ class "dropdown"
        , class "d-inline-block"
        , classList [ ( "show", active ) ]
        ]
        [ button
            [ class "btn"
            , class "btn-outline-primary"
            , class "dropdown-toggle"
            , onClick (DropdownButtonClicked RoleField)
            ]
            [ role
                |> Maybe.map .name
                |> Maybe.withDefault "select a role"
                |> text
            ]
        , div
            [ class "dropdown-menu"
            , classList [ ( "show", active ) ]
            ]
            viewItems
        ]


viewCityDropdown : Bool -> List City -> Maybe City -> Html Msg
viewCityDropdown active cities city =
    let
        viewItems : List (Html Msg)
        viewItems =
            cities
                |> List.map viewCityItem
    in
    div
        [ class "dropdown"
        , class "d-inline-block"
        , classList [ ( "show", active ) ]
        ]
        [ button
            [ class "btn"
            , class "btn-outline-primary"
            , class "dropdown-toggle"
            , onClick (DropdownButtonClicked CityField)
            ]
            [ city
                |> Maybe.map .name
                |> Maybe.withDefault "select a city"
                |> text
            ]
        , div
            [ class "dropdown-menu"
            , classList [ ( "show", active ) ]
            ]
            viewItems
        ]


viewTenureDropdown : Bool -> Int -> Html Msg
viewTenureDropdown active tenure =
    let
        viewItems =
            List.map
                viewTenureItem
                [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15 ]
    in
    div
        [ class "dropdown"
        , class "d-inline-block"
        , classList [ ( "show", active ) ]
        ]
        [ button
            [ class "btn"
            , class "btn-outline-primary"
            , class "dropdown-toggle"
            , onClick (DropdownButtonClicked TenureField)
            ]
            [ tenure
                |> String.fromInt
                |> text
            ]
        , div
            [ class "dropdown-menu"
            , classList [ ( "show", active ) ]
            ]
            viewItems
        ]


viewRoleItem role =
    button
        [ class "dropdown-item"
        , onClick (RoleItemSelected role)
        ]
        [ text role.name ]


viewCityItem city =
    button
        [ class "dropdown-item"
        , onClick (CityItemSelected city)
        ]
        [ text city.name ]


viewTenureItem tenure =
    button
        [ class "dropdown-item"
        , onClick (TenureItemSelected tenure)
        ]
        [ tenure |> humanizeTenure |> text ]


{-| Displays a plural or singular form of word "year"

    import Html

    viewPluralizedYears 0
    --> Html.text " years."

    viewPluralizedYears 1
    --> Html.text " year."

    viewPluralizedYears 34
    --> Html.text " years."

-}
viewPluralizedYears : Int -> Html Msg
viewPluralizedYears years =
    if years == 0 then
        text " years."

    else if years == 1 then
        text " year."

    else
        text " years."


{-| Displays monthly salary when provided with role and city. Otherwise
displays a prompt for missing data.

    import Html

    viewSalary Nothing Nothing 3
    --> Html.text "Please select a role and a city."

    viewSalary Nothing (Just (City "Keren" 1.87)) 3
    --> Html.text "Please select a role."

    viewSalary (Just (Role "Junior Designer" 2345)) Nothing 3
    --> Html.text "Please select a city."

-}
viewSalary : Maybe Role -> Maybe City -> Int -> Html Msg
viewSalary maybeRole maybeCity tenure =
    case ( maybeRole, maybeCity ) of
        ( Nothing, Nothing ) ->
            text "Please select a role and a city."

        ( Nothing, _ ) ->
            text "Please select a role."

        ( _, Nothing ) ->
            text "Please select a city."

        ( Just role, Just city ) ->
            span []
                [ text "My monthly gross salary is "
                , span [ class "font-weight-bold" ]
                    [ (salary role city tenure
                        |> String.fromInt
                      )
                        ++ " €"
                        |> text
                    ]
                , text "."
                ]


{-| Formats commitment bonus as percentage rounded to a percent.

    humanizeCommitmentBonus 0.3
    --> "30%"

    humanizeCommitmentBonus 0.12345
    --> "12%"

    humanizeCommitmentBonus 0.126
    --> "13%"

    humanizeCommitmentBonus 3.0
    --> "300%"

-}
humanizeCommitmentBonus : Float -> String
humanizeCommitmentBonus bonus =
    (bonus
        |> (*) 100
        |> round
        |> String.fromInt
    )
        ++ "%"


viewBreakdown : Role -> City -> Int -> Html Msg
viewBreakdown role city tenure =
    let
        viewFormula =
            [ [ "(" |> viewOperator
              , role.baseSalary
                    |> String.fromFloat
                    |> viewVariable "base salary"
              , "x" |> viewOperator
              , city.locationFactor
                    |> String.fromFloat
                    |> viewVariable "location factor"
              , ")" |> viewOperator
              ]
                |> div
                    [ class "d-flex"
                    , class "justify-content-around"
                    , class "flex-grow-1"
                    ]
            , "+" |> viewOperator
            , [ "(" |> viewOperator
              , role.baseSalary
                    |> String.fromFloat
                    |> viewVariable "base salary"
              , "x" |> viewOperator
              , tenure
                    |> commitmentBonus
                    |> humanizeCommitmentBonus
                    |> viewVariable "commitment bonus"
              , ")" |> viewOperator
              ]
                |> div
                    [ class "d-flex"
                    , class "justify-content-around"
                    , class "flex-grow-1"
                    ]
            ]
                |> div
                    [ class "d-md-flex"
                    , class "justify-content-around"
                    , class "text-center"
                    ]

        viewLegend =
            ul
                [ class "list-group"
                , class "mt-3"
                ]
                [ viewLegendItem
                    "Base Salary"
                    [ text "San Francisco 50th percentile for "
                    , role.name |> viewHighlighted
                    , text " on Glassdoor, discounted by our Affordability Ratio of 0.53."
                    ]
                , viewLegendItem
                    "Location Factor"
                    [ "Numbeo Cost of Living in " |> text
                    , city.name |> viewHighlighted
                    , " compared to San Francisco, compressed and normalized against our Affordability Ratio of 0.53." |> text
                    ]
                , viewLegendItem
                    "Commitment Bonus"
                    [ text "Natural logarithm of "
                    , tenure
                        |> String.fromInt
                        |> viewHighlighted
                    , text " years of your tenure, divided by 10."
                    ]
                , viewLegendItem
                    "Affordability Ratio"
                    [ "Average Cost of Living index compared to San Francisco, for four major European tech hubs: Amsterdam, Berlin, Barcelona, Lisbon." |> text
                    ]
                ]

        {- For displaying the big things like "(" or "+" -}
        viewOperator : String -> Html Msg
        viewOperator operator =
            div
                [ class "display-4"
                ]
                [ text operator ]

        viewVariable name value =
            div
                [ class "variable"
                , class "d-flex"
                , class "flex-column"
                , class "justify-content-center"
                ]
                [ div
                    [ class "value" ]
                    [ text value ]
                , div
                    [ class "name"
                    , class "text-muted"
                    ]
                    [ text <| String.concat [ "( ", name, " )" ] ]
                ]

        viewHighlighted : String -> Html Msg
        viewHighlighted string =
            mark [] [ text string ]

        viewLegendItem : String -> List (Html Msg) -> Html Msg
        viewLegendItem term definition =
            div
                [ class "list-group-item" ]
                [ strong []
                    [ text term
                    , text ": "
                    ]
                , span [] definition
                ]
    in
    div
        []
        [ div
            [ class "row" ]
            [ div
                [ class "col-lg-12" ]
                [ viewFormula ]
            ]
        , div
            [ class "row" ]
            [ div
                [ class "col-lg-12" ]
                [ viewLegend ]
            ]
        ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
