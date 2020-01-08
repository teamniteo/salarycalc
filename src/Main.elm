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
import Country exposing (Country)
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
                    , countries = []
                    , careers = []
                    , role = Nothing
                    , country = Nothing
                    , tenure = 0
                    , accordionState = Accordion.initialState
                    , roleDropdown = Dropdown.initialState
                    , countryDropdown = Dropdown.initialState
                    , tenureDropdown = Dropdown.initialState
                    }

                Ok config ->
                    let
                        maybeUrl =
                            Url.fromString flags.location

                        queryParser =
                            QueryParser.map3 Query
                                (QueryParser.string "role")
                                (QueryParser.string "country")
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
                                            , country = Nothing
                                            , years = Nothing
                                            }

                                Nothing ->
                                    { role = Nothing, country = Nothing, years = Nothing }

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

                        country : Result Warning (Maybe Country)
                        country =
                            case query.country of
                                Just countryName ->
                                    lookupByName countryName config.countries
                                        |> Result.fromMaybe
                                            (Warning
                                                ("Invalid country provided via URL: "
                                                    ++ countryName
                                                    ++ ". Please choose one from the dropdown below."
                                                )
                                                CountryField
                                            )
                                        |> Result.map Just

                                Nothing ->
                                    Ok (List.head config.countries)

                        warnings =
                            [ case role of
                                Ok _ ->
                                    Nothing

                                Err warning ->
                                    Just warning
                            , case country of
                                Ok _ ->
                                    Nothing

                                Err warning ->
                                    Just warning
                            ]
                                |> Maybe.values
                    in
                    { error = Nothing
                    , warnings = warnings
                    , countries = config.countries
                    , careers = config.careers
                    , role = role |> Result.extract (\_ -> Nothing)
                    , country = country |> Result.extract (\_ -> Nothing)
                    , tenure =
                        query.years
                            |> Maybe.withDefault 2
                    , accordionState = Accordion.initialState
                    , roleDropdown = Dropdown.initialState
                    , countryDropdown = Dropdown.initialState
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
    , country : Maybe String
    , years : Maybe Int
    }


type Msg
    = RoleDropdownChanged Dropdown.State
    | CountryDropdownChanged Dropdown.State
    | TenureDropdownChanged Dropdown.State
    | RoleSelected Role
    | CountrySelected Country
    | TenureSelected Int
    | AccordionMsg Accordion.State


type Field
    = RoleField
    | CountryField


type alias Warning =
    { msg : String
    , field : Field
    }


type alias Model =
    { error : Maybe String
    , warnings : List Warning
    , careers : List Career
    , countries : List Country
    , role : Maybe Role
    , country : Maybe Country
    , tenure : Int
    , accordionState : Accordion.State
    , roleDropdown : Dropdown.State
    , countryDropdown : Dropdown.State
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

        CountryDropdownChanged state ->
            ( { model | countryDropdown = state }
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

        CountrySelected country ->
            ( { model
                | country = Just country
                , warnings =
                    model.warnings
                        |> List.filter (\warning -> warning.field /= CountryField)
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
        , Dropdown.subscriptions model.countryDropdown CountryDropdownChanged
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
                                                    && model.country
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
                                case ( model.role, model.country ) of
                                    ( Nothing, Nothing ) ->
                                        []

                                    ( Nothing, _ ) ->
                                        []

                                    ( _, Nothing ) ->
                                        []

                                    ( Just role, Just country ) ->
                                        [ Accordion.block []
                                            [ Block.text []
                                                [ viewBreakdown role country model.tenure ]
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

        countryItem country =
            Dropdown.buttonItem [ onClick (CountrySelected country) ] [ text country.name ]

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
        , Dropdown.dropdown model.countryDropdown
            { options = []
            , toggleMsg = CountryDropdownChanged
            , toggleButton =
                Dropdown.toggle [ Button.outlinePrimary ]
                    [ model.country
                        |> Maybe.map .name
                        |> Maybe.withDefault "select a country"
                        |> text
                    ]
            , items =
                model.countries
                    |> List.map countryItem
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
        [ viewSalary model.role model.country model.tenure
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


{-| Displays monthly salary when provided with role and country. Otherwise
displays a prompt for missing data.

    import Html
    import Country exposing (Country)
    import Career exposing (Role)

    viewSalary Nothing Nothing 3
    --> Html.text "Please select a role and a country."

    viewSalary Nothing (Just (Country "Spain" 1.87)) 3
    --> Html.text "Please select a role."

    viewSalary (Just (Role "Junior Designer" 2345)) Nothing 3
    --> Html.text "Please select a country."

-}
viewSalary : Maybe Role -> Maybe Country -> Int -> Html Msg
viewSalary maybeRole maybeCountry tenure =
    case ( maybeRole, maybeCountry ) of
        ( Nothing, Nothing ) ->
            text "Please select a role and a country."

        ( Nothing, _ ) ->
            text "Please select a role."

        ( _, Nothing ) ->
            text "Please select a country."

        ( Just role, Just country ) ->
            span []
                [ text "My monthly gross salary is "
                , span [ class "font-weight-bold", id "total-salary" ]
                    [ (Salary.calculate role country tenure
                        |> String.fromInt
                      )
                        ++ " €"
                        |> text
                    ]
                , text "."
                ]


viewBreakdown : Role -> Country -> Int -> Html Msg
viewBreakdown role country tenure =
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
                    [ country.compressed_cost_of_living
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
                    [ text "(compressed cost of living)" ]
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
                , mark [] [ text country.name ]
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

    lookupByName "Netherlands"
        [ { name = "Netherlands", compressed_cost_of_living = 1.4 }
        , { name = "Slovenia", compressed_cost_of_living = 1.0 }
        ]
    --> Just { name = "Netherlands", compressed_cost_of_living = 1.4 }

    lookupByName "Warsaw"
        [ { name = "Netherlands", compressed_cost_of_living = 1.4 }
        , { name = "Slovenia", compressed_cost_of_living = 1.0 }
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
