module SalaryCalculator exposing
    ( City
    , Role
    , init
    , main
    , salary
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Dropdown as Dropdown
import Bootstrap.ListGroup as ListGroup
import Browser
import Dict exposing (Dict)
import Html exposing (Html, div, mark, p, span, table, td, text, tr)
import Html.Attributes exposing (class, rowspan)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Result.Extra as Result
import Url exposing (fromString)
import Url.Parser as UrlParser exposing ((<?>), parse)
import Url.Parser.Query as QueryParser exposing (int, map3, string)



-- MODEL


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
                    { error = Just error
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
                                        |> Result.fromMaybe ("Invalid role: " ++ roleName)
                                        |> Result.map Just

                                Nothing ->
                                    Ok (List.head roles)

                        city =
                            case query.city of
                                Just cityName ->
                                    lookupByName cityName config.cities

                                Nothing ->
                                    List.head config.cities

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
                    , city = city
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


configDecoder : Decode.Decoder Config
configDecoder =
    Decode.map2 Config
        (Decode.field "cities" citiesDecoder)
        (Decode.field "careers" careersDecoder)


citiesDecoder : Decode.Decoder (List City)
citiesDecoder =
    Decode.list cityDecoder


cityDecoder : Decode.Decoder City
cityDecoder =
    Decode.map2 City
        (Decode.field "name" Decode.string)
        (Decode.field "locationFactor" Decode.float)


careersDecoder : Decode.Decoder (List Career)
careersDecoder =
    Decode.list careerDecoder


careerDecoder : Decode.Decoder Career
careerDecoder =
    Decode.map2 Career
        (Decode.field "name" Decode.string)
        (Decode.field "roles" rolesDecoder)


rolesDecoder : Decode.Decoder (List Role)
rolesDecoder =
    Decode.list roleDecoder


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
    = RoleDropdownChanged Dropdown.State
    | CityDropdownChanged Dropdown.State
    | TenureDropdownChanged Dropdown.State
    | RoleSelected Role
    | CitySelected City
    | TenureSelected Int
    | AccordionMsg Accordion.State


type alias Warning =
    String


type alias Model =
    { error : Maybe Decode.Error
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


commitmentBonus : Int -> Float
commitmentBonus years =
    logBase e (toFloat years + 1) / 10


tenureDescription : Int -> String
tenureDescription years =
    if years < 1 then
        "Just started"

    else if years == 1 then
        String.fromInt years ++ " year"

    else
        String.fromInt years ++ " years"


salary : Role -> City -> Int -> Int
salary role city tenure =
    round (role.baseSalary * city.locationFactor + role.baseSalary * commitmentBonus tenure)



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
            ( { model | role = Just role, warnings = [] }, Cmd.none )

        CitySelected city ->
            ( { model | city = Just city }, Cmd.none )

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
                |> Decode.errorToString
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
                                            [ if model.role /= Nothing && model.city /= Nothing then
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
                [ text (tenureDescription years)
                ]
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
                        |> Maybe.withDefault "select role"
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
        [ viewSalary model
        ]
    ]


viewPluralizedYears : Int -> Html Msg
viewPluralizedYears years =
    if years == 0 then
        text " years."

    else if years == 1 then
        text " year."

    else
        text " years."


viewSalary : Model -> Html Msg
viewSalary model =
    case ( model.role, model.city ) of
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
                    [ salary role city model.tenure
                        |> String.fromInt
                        |> text
                    , text " €"
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
                        |> commitmentBonus
                        |> toPrecision 2
                        |> String.fromFloat
                        |> text
                    ]
                , td
                    [ class "border-0 p-0 text-center align-middle display-4"
                    , rowspan 2
                    ]
                    [ text ")" ]
                ]
            , tr []
                [ td [ class "border-0 p-0 text-center text-muted" ] [ text "(base salary)" ]
                , td [ class "border-0 p-0 text-center text-muted" ] [ text "(location factor)" ]
                , td [ class "border-0 p-0 text-center text-muted" ] [ text "(base salary)" ]
                , td [ class "border-0 p-0 text-center text-muted" ] [ text "(commitment bonus)" ]
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


toPrecision : Int -> Float -> Float
toPrecision precision number =
    let
        factor =
            precision
                |> toFloat
                |> (^) 10
    in
    number
        * factor
        |> Basics.truncate
        |> toFloat
        |> (\n -> n / factor)



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
