module Main exposing
    ( Field(..)
    , Flags
    , Model
    , Msg(..)
    , Query
    , Warning
    , humanizeCommitmentBonus
    , humanizeTenure
    , init
    , lookupByName
    , main
    , subscriptions
    , update
    , view
    , viewBreakdown
    , viewHeader
    , viewPluralizedYears
    , viewSalary
    , viewWarnings
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Dropdown as Dropdown
import Bootstrap.ListGroup as ListGroup
import Browser
import Career exposing (Career, Role)
import City exposing (City)
import Config
import Html exposing (Html, div, mark, p, span, table, td, text, tr)
import Html.Attributes exposing (class, id, rowspan)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Result.Extra as Result
import Salary
import Url exposing (fromString)
import Url.Parser as UrlParser exposing ((<?>), parse)
import Url.Parser.Query as QueryParser exposing (int, map3, string)



-- MODEL


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            case Decode.decodeValue Config.configDecoder flags.config of
                Err error ->
                    { error = Just (Decode.errorToString error)
                    , warnings = []
                    , cities = []
                    , careers = []
                    , role = Nothing
                    , city = Nothing
                    , tenure = 0
                    , accordionState = Accordion.initialState
                    , roleDropdown = Dropdown.initialState
                    , cityDropdown = Dropdown.initialState
                    , tenureDropdown = Dropdown.initialState
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
                                                ("Invalid role provided via URL: "
                                                    ++ roleName
                                                    ++ ". Please choose one from the dropdown below."
                                                )
                                                RoleField
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
                                                ("Invalid city provided via URL: "
                                                    ++ cityName
                                                    ++ ". Please choose one from the dropdown below."
                                                )
                                                CityField
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
                    , tenure =
                        query.years
                            |> Maybe.withDefault 2
                    , accordionState = Accordion.initialState
                    , roleDropdown = Dropdown.initialState
                    , cityDropdown = Dropdown.initialState
                    , tenureDropdown = Dropdown.initialState
                    }
    in
    ( model
    , Cmd.none
    )


type alias Flags =
    { location : String
    , config : Decode.Value
    }


type alias Query =
    { role : Maybe String
    , city : Maybe String
    , years : Maybe Int
    }


type Msg
    = RoleDropdownChanged Dropdown.State
    | CityDropdownChanged Dropdown.State
    | TenureDropdownChanged Dropdown.State
    | RoleSelected Role
    | CitySelected City
    | TenureSelected Int
    | AccordionMsg Accordion.State


type Field
    = RoleField
    | CityField


type alias Warning =
    { msg : String
    , field : Field
    }


type alias Model =
    { error : Maybe String
    , warnings : List Warning
    , careers : List Career
    , cities : List City
    , role : Maybe Role
    , city : Maybe City
    , tenure : Int
    , accordionState : Accordion.State
    , roleDropdown : Dropdown.State
    , cityDropdown : Dropdown.State
    , tenureDropdown : Dropdown.State
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        RoleDropdownChanged state ->
            ( { model | roleDropdown = state }
            , Cmd.none
            )

        CityDropdownChanged state ->
            ( { model | cityDropdown = state }
            , Cmd.none
            )

        TenureDropdownChanged state ->
            ( { model | tenureDropdown = state }
            , Cmd.none
            )

        RoleSelected role ->
            ( { model
                | role = Just role
                , warnings =
                    model.warnings
                        |> List.filter (\warning -> warning.field /= RoleField)
              }
            , Cmd.none
            )

        CitySelected city ->
            ( { model
                | city = Just city
                , warnings =
                    model.warnings
                        |> List.filter (\warning -> warning.field /= CityField)
              }
            , Cmd.none
            )

        TenureSelected years ->
            ( { model | tenure = years }, Cmd.none )

        AccordionMsg state ->
            ( { model | accordionState = state }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Dropdown.subscriptions model.roleDropdown RoleDropdownChanged
        , Dropdown.subscriptions model.cityDropdown CityDropdownChanged
        , Dropdown.subscriptions model.tenureDropdown TenureDropdownChanged
        , Accordion.subscriptions model.accordionState AccordionMsg
        ]



-- VIEW


view : Model -> Html Msg
view model =
    case model.error of
        Just error ->
            error
                |> (++) "App initialization failed: "
                |> text

        Nothing ->
            div []
                [ viewWarnings model.warnings
                , Accordion.config AccordionMsg
                    |> Accordion.withAnimation
                    |> Accordion.cards
                        [ Accordion.card
                            { id = "card1"
                            , options = [ Card.outlineLight ]
                            , header =
                                Accordion.header []
                                    (Accordion.toggle [ class "p-0" ]
                                        [ span []
                                            [ if
                                                model.role
                                                    /= Nothing
                                                    && model.city
                                                    /= Nothing
                                              then
                                                text "Okay, let's break that down ..."

                                              else
                                                Html.text ""
                                            ]
                                        ]
                                    )
                                    |> Accordion.prependHeader
                                        (viewHeader model)
                            , blocks =
                                case ( model.role, model.city ) of
                                    ( Nothing, Nothing ) ->
                                        []

                                    ( Nothing, _ ) ->
                                        []

                                    ( _, Nothing ) ->
                                        []

                                    ( Just role, Just city ) ->
                                        [ Accordion.block []
                                            [ Block.text []
                                                [ viewBreakdown role city model.tenure ]
                                            ]
                                        ]
                            }
                        ]
                    |> Accordion.view model.accordionState
                ]


viewWarnings : List Warning -> Html Msg
viewWarnings warnings =
    warnings
        |> List.map .msg
        |> List.map text
        |> List.map List.singleton
        |> List.map (Alert.simpleWarning [])
        |> div []


viewHeader : Model -> List (Html Msg)
viewHeader model =
    let
        roleItem role =
            Dropdown.buttonItem [ onClick (RoleSelected role) ] [ text role.name ]

        cityItem city =
            Dropdown.buttonItem [ onClick (CitySelected city) ] [ text city.name ]

        tenureItem years =
            Dropdown.buttonItem [ onClick (TenureSelected years) ]
                [ humanizeTenure years |> text ]
    in
    [ p [ class "lead" ]
        [ text "I'm a "
        , Dropdown.dropdown model.roleDropdown
            { options = []
            , toggleMsg = RoleDropdownChanged
            , toggleButton =
                Dropdown.toggle [ Button.outlinePrimary ]
                    [ model.role
                        |> Maybe.map .name
                        |> Maybe.withDefault "select a role"
                        |> text
                    ]
            , items =
                model.careers
                    |> List.map
                        (\{ name, roles } ->
                            Dropdown.header [ text (name ++ " Career") ]
                                :: List.map roleItem roles
                        )
                    |> List.concat
            }
        , text " living in "
        , Dropdown.dropdown model.cityDropdown
            { options = []
            , toggleMsg = CityDropdownChanged
            , toggleButton =
                Dropdown.toggle [ Button.outlinePrimary ]
                    [ model.city
                        |> Maybe.map .name
                        |> Maybe.withDefault "select a city"
                        |> text
                    ]
            , items =
                model.cities
                    |> List.map cityItem
            }
        , text " with a tenure at Niteo of "
        , Dropdown.dropdown model.tenureDropdown
            { options = []
            , toggleMsg = TenureDropdownChanged
            , toggleButton =
                Dropdown.toggle [ Button.outlinePrimary ]
                    [ model.tenure
                        |> String.fromInt
                        |> text
                    ]
            , items =
                [ tenureItem 0
                , tenureItem 1
                , tenureItem 2
                , tenureItem 3
                , tenureItem 4
                , tenureItem 5
                , tenureItem 6
                , tenureItem 7
                , tenureItem 8
                , tenureItem 9
                , tenureItem 10
                , tenureItem 15
                ]
            }
        , viewPluralizedYears model.tenure
        ]
    , p [ class "lead" ]
        [ viewSalary model.role model.city model.tenure
        ]
    ]


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
    import City exposing (City)
    import Career exposing (Role)

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
                , span [ class "font-weight-bold", id "total-salary" ]
                    [ (Salary.calculate role city tenure
                        |> String.fromInt
                      )
                        ++ " €"
                        |> text
                    ]
                , text "."
                ]


viewBreakdown : Role -> City -> Int -> Html Msg
viewBreakdown role city tenure =
    div []
        [ table [ class "table" ]
            [ tr []
                [ td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text "(" ]
                , td
                    [ class "border-0 p-0 text-center lead"
                    ]
                    [ role.baseSalary
                        |> String.fromFloat
                        |> text
                    ]
                , td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text "x" ]
                , td
                    [ class "border-0 p-0 text-center lead"
                    ]
                    [ city.locationFactor
                        |> String.fromFloat
                        |> text
                    ]
                , td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text ")" ]
                , td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text "+" ]
                , td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text "(" ]
                , td
                    [ class "border-0 p-0 text-center lead"
                    ]
                    [ role.baseSalary
                        |> String.fromFloat
                        |> text
                    ]
                , td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text "x" ]
                , td
                    [ class "border-0 p-0 text-center lead"
                    ]
                    [ tenure
                        |> Salary.commitmentBonus
                        |> humanizeCommitmentBonus
                        |> text
                    ]
                , td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text ")" ]
                ]
            , tr []
                [ td
                    [ class "border-0 p-0 text-center text-muted" ]
                    [ text "(base salary)" ]
                , td
                    [ class "border-0 p-0 text-center text-muted" ]
                    [ text "(location factor)" ]
                , td
                    [ class "border-0 p-0 text-center text-muted" ]
                    [ text "(base salary)" ]
                , td
                    [ class "border-0 p-0 text-center text-muted" ]
                    [ text "(commitment bonus)" ]
                ]
            ]
        , ListGroup.ul
            [ ListGroup.li []
                [ span
                    [ class "font-weight-bold"
                    ]
                    [ text "Base Salary: " ]
                , text "San Francisco 50th percentile for "
                , mark [] [ text role.name ]
                , text " on Glassdoor, discounted by our Affordability Ratio of 0.53."
                ]
            , ListGroup.li []
                [ span
                    [ class "font-weight-bold"
                    ]
                    [ text "Location Factor: " ]
                , text "Numbeo Cost of Living in "
                , mark [] [ text city.name ]
                , text " compared to San Francisco, compressed and normalized against our Affordability Ratio of 0.53."
                ]
            , ListGroup.li []
                [ span
                    [ class "font-weight-bold"
                    ]
                    [ text "Commitment Bonus: " ]
                , text "Natural logarithm of "
                , mark []
                    [ tenure
                        |> String.fromInt
                        |> text
                    ]
                , text " years of your tenure, divided by 10."
                ]
            , ListGroup.li []
                [ span
                    [ class "font-weight-bold"
                    ]
                    [ text "Affordability Ratio: " ]
                , text "Average Cost of Living index compared to San Francisco, for four major European tech hubs: Amsterdam, Berlin, Barcelona, Lisbon."
                ]
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



-- HELPERS


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
