module Main exposing
    ( Field(..)
    , Flags
    , Model
    , Msg(..)
    , Query
    , Warning
    , handleKeyDown
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
import Browser.Dom as Dom
import Career exposing (Career, Role)
import Config
import Country exposing (Country)
import Html exposing (Html, div, input, mark, p, span, table, td, text, tr)
import Html.Attributes exposing (class, id, placeholder, rowspan, value)
import Html.Events exposing (on, onClick, onInput, stopPropagationOn)
import Json.Decode as Decode
import Maybe.Extra as Maybe
import Result.Extra as Result
import Salary
import String
import Task
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
                    , careers_updated = "1970-01-01"
                    , countries_updated = "1970-01-01"
                    , countrySearchTerm = ""
                    , roleSearchTerm = ""
                    , tenureSearchTerm = ""
                    , roleSelectedIndex = 0
                    , countrySelectedIndex = 0
                    , tenureSelectedIndex = 0
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
                    , careers_updated = config.careers_updated
                    , countries_updated = config.countries_updated
                    , countrySearchTerm = ""
                    , roleSearchTerm = ""
                    , tenureSearchTerm = ""
                    , roleSelectedIndex = 0
                    , countrySelectedIndex = 0
                    , tenureSelectedIndex = 0
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
    | CountrySearchTermChanged String
    | RoleSearchTermChanged String
    | TenureSearchTermChanged String
    | RoleKeyDown String
    | CountryKeyDown String
    | TenureKeyDown String
    | NoOp


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
    , careers_updated : String
    , countries_updated : String
    , countrySearchTerm : String
    , roleSearchTerm : String
    , tenureSearchTerm : String
    , roleSelectedIndex : Int
    , countrySelectedIndex : Int
    , tenureSelectedIndex : Int
    }



-- UPDATE


onKeyDown : (String -> msg) -> Html.Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyDecoder)


keyDecoder : Decode.Decoder String
keyDecoder =
    Decode.field "key" Decode.string


handleKeyDown : String -> List a -> Int -> ( Int, Maybe a )
handleKeyDown key items currentIndex =
    let
        itemCount =
            List.length items

        getItemAt index =
            items
                |> List.drop index
                |> List.head
    in
    case key of
        "ArrowDown" ->
            let
                newIndex =
                    if currentIndex < itemCount - 1 then
                        currentIndex + 1

                    else
                        currentIndex
            in
            ( newIndex, Nothing )

        "ArrowUp" ->
            let
                newIndex =
                    if currentIndex > 0 then
                        currentIndex - 1

                    else
                        currentIndex
            in
            ( newIndex, Nothing )

        "Enter" ->
            ( currentIndex, getItemAt currentIndex )

        _ ->
            ( currentIndex, Nothing )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RoleDropdownChanged state ->
            ( { model | roleDropdown = state, roleSelectedIndex = 0 }
            , Task.attempt (\_ -> NoOp) (Dom.focus "role-search-input")
            )

        CountryDropdownChanged state ->
            ( { model | countryDropdown = state, countrySelectedIndex = 0 }
            , Task.attempt (\_ -> NoOp) (Dom.focus "country-search-input")
            )

        TenureDropdownChanged state ->
            ( { model | tenureDropdown = state, tenureSelectedIndex = 0 }
            , Task.attempt (\_ -> NoOp) (Dom.focus "tenure-search-input")
            )

        RoleSelected role ->
            ( { model
                | role = Just role
                , warnings =
                    model.warnings
                        |> List.filter (\warning -> warning.field /= RoleField)
                , roleSearchTerm = ""
                , roleDropdown = Dropdown.initialState
                , countryDropdown = Dropdown.initialState
              }
            , Task.attempt (\_ -> NoOp) (Dom.focus "country-search-input")
            )

        CountrySelected country ->
            ( { model
                | country = Just country
                , warnings =
                    model.warnings
                        |> List.filter (\warning -> warning.field /= CountryField)
                , countrySearchTerm = ""
                , countryDropdown = Dropdown.initialState
                , tenureDropdown = Dropdown.initialState
              }
            , Task.attempt (\_ -> NoOp) (Dom.focus "tenure-search-input")
            )

        TenureSelected years ->
            ( { model | tenure = years, tenureSearchTerm = "" }, Cmd.none )

        AccordionMsg state ->
            ( { model | accordionState = state }, Cmd.none )

        CountrySearchTermChanged searchTerm ->
            ( { model | countrySearchTerm = searchTerm, countrySelectedIndex = 0 }, Cmd.none )

        RoleSearchTermChanged searchTerm ->
            ( { model | roleSearchTerm = searchTerm, roleSelectedIndex = 0 }, Cmd.none )

        TenureSearchTermChanged searchTerm ->
            ( { model | tenureSearchTerm = searchTerm, tenureSelectedIndex = 0 }, Cmd.none )

        RoleKeyDown key ->
            let
                allRoles =
                    model.careers
                        |> List.map .roles
                        |> List.concat

                filteredRoles =
                    if String.isEmpty model.roleSearchTerm then
                        allRoles

                    else
                        allRoles
                            |> List.filter
                                (\role ->
                                    String.toLower role.name
                                        |> String.contains (String.toLower model.roleSearchTerm)
                                )
            in
            handleKeyDown key filteredRoles model.roleSelectedIndex
                |> (\( newIndex, maybeRole ) ->
                        case maybeRole of
                            Just role ->
                                ( { model
                                    | role = Just role
                                    , warnings = model.warnings |> List.filter (\warning -> warning.field /= RoleField)
                                    , roleSearchTerm = ""
                                    , roleSelectedIndex = 0
                                    , roleDropdown = Dropdown.initialState
                                    , countryDropdown = Dropdown.initialState
                                  }
                                , Task.attempt (\_ -> NoOp) (Dom.focus "country-search-input")
                                )

                            Nothing ->
                                ( { model | roleSelectedIndex = newIndex }, Cmd.none )
                   )

        CountryKeyDown key ->
            let
                filteredCountries =
                    if String.isEmpty model.countrySearchTerm then
                        model.countries

                    else
                        model.countries
                            |> List.filter
                                (\country ->
                                    String.toLower country.name
                                        |> String.contains (String.toLower model.countrySearchTerm)
                                )
            in
            handleKeyDown key filteredCountries model.countrySelectedIndex
                |> (\( newIndex, maybeCountry ) ->
                        case maybeCountry of
                            Just country ->
                                ( { model
                                    | country = Just country
                                    , warnings = model.warnings |> List.filter (\warning -> warning.field /= CountryField)
                                    , countrySearchTerm = ""
                                    , countrySelectedIndex = 0
                                    , countryDropdown = Dropdown.initialState
                                    , tenureDropdown = Dropdown.initialState
                                  }
                                , Task.attempt (\_ -> NoOp) (Dom.focus "tenure-search-input")
                                )

                            Nothing ->
                                ( { model | countrySelectedIndex = newIndex }, Cmd.none )
                   )

        TenureKeyDown key ->
            let
                allYears =
                    [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 20 ]

                filteredYears =
                    if String.isEmpty model.tenureSearchTerm then
                        allYears

                    else
                        allYears
                            |> List.filter
                                (\years ->
                                    String.fromInt years
                                        |> String.contains model.tenureSearchTerm
                                )
            in
            handleKeyDown key filteredYears model.tenureSelectedIndex
                |> (\( newIndex, maybeYears ) ->
                        case maybeYears of
                            Just years ->
                                ( { model
                                    | tenure = years
                                    , tenureSearchTerm = ""
                                    , tenureSelectedIndex = 0
                                    , tenureDropdown = Dropdown.initialState
                                  }
                                , Cmd.none
                                )

                            Nothing ->
                                ( { model | tenureSelectedIndex = newIndex }, Cmd.none )
                   )

        NoOp ->
            ( model, Cmd.none )


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
                                                [ viewBreakdown role country model.tenure model.careers_updated model.countries_updated ]
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
        roleItem index role =
            let
                attributes =
                    if index == model.roleSelectedIndex then
                        [ onClick (RoleSelected role), class "active" ]

                    else
                        [ onClick (RoleSelected role) ]
            in
            Dropdown.buttonItem attributes [ text role.name ]

        countryItem index country =
            let
                attributes =
                    if index == model.countrySelectedIndex then
                        [ onClick (CountrySelected country), class "active" ]

                    else
                        [ onClick (CountrySelected country) ]
            in
            Dropdown.buttonItem attributes [ text country.name ]

        tenureItem index years =
            let
                attributes =
                    if index == model.tenureSelectedIndex then
                        [ onClick (TenureSelected years), class "active" ]

                    else
                        [ onClick (TenureSelected years) ]
            in
            Dropdown.buttonItem attributes [ humanizeTenure years |> text ]
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
                let
                    searchInput =
                        Dropdown.customItem
                            (div
                                [ class "px-3 py-2"
                                , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
                                ]
                                [ input
                                    [ id "role-search-input"
                                    , placeholder "Search roles..."
                                    , value model.roleSearchTerm
                                    , onInput RoleSearchTermChanged
                                    , onKeyDown RoleKeyDown
                                    , class "form-control form-control-sm"
                                    ]
                                    []
                                ]
                            )

                    roleItems =
                        if String.isEmpty model.roleSearchTerm then
                            let
                                allRoles =
                                    model.careers
                                        |> List.map .roles
                                        |> List.concat

                                indexedRoles =
                                    allRoles
                                        |> List.indexedMap Tuple.pair

                                buildItems currentIndex careerList =
                                    case careerList of
                                        [] ->
                                            []

                                        { name, roles } :: rest ->
                                            let
                                                roleCount =
                                                    List.length roles

                                                careerRoles =
                                                    indexedRoles
                                                        |> List.drop currentIndex
                                                        |> List.take roleCount
                                                        |> List.map (\( idx, role ) -> roleItem idx role)
                                            in
                                            Dropdown.header [ text (name ++ " Career") ]
                                                :: careerRoles
                                                ++ buildItems (currentIndex + roleCount) rest
                            in
                            buildItems 0 model.careers

                        else
                            let
                                allRoles =
                                    model.careers
                                        |> List.map .roles
                                        |> List.concat

                                filteredRoles =
                                    allRoles
                                        |> List.filter
                                            (\role ->
                                                String.toLower role.name
                                                    |> String.contains (String.toLower model.roleSearchTerm)
                                            )
                            in
                            filteredRoles
                                |> List.indexedMap roleItem
                in
                searchInput :: Dropdown.divider :: roleItems
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
                let
                    filteredCountries =
                        if String.isEmpty model.countrySearchTerm then
                            model.countries

                        else
                            model.countries
                                |> List.filter
                                    (\country ->
                                        String.toLower country.name
                                            |> String.contains (String.toLower model.countrySearchTerm)
                                    )

                    searchInput =
                        Dropdown.customItem
                            (div
                                [ class "px-3 py-2"
                                , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
                                ]
                                [ input
                                    [ id "country-search-input"
                                    , placeholder "Search countries..."
                                    , value model.countrySearchTerm
                                    , onInput CountrySearchTermChanged
                                    , onKeyDown CountryKeyDown
                                    , class "form-control form-control-sm"
                                    ]
                                    []
                                ]
                            )

                    countryItems =
                        filteredCountries
                            |> List.indexedMap countryItem
                in
                searchInput :: Dropdown.divider :: countryItems
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
                let
                    allYears =
                        [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15, 20 ]

                    searchInput =
                        Dropdown.customItem
                            (div
                                [ class "px-3 py-2"
                                , stopPropagationOn "click" (Decode.succeed ( NoOp, True ))
                                ]
                                [ input
                                    [ id "tenure-search-input"
                                    , placeholder "Search years..."
                                    , value model.tenureSearchTerm
                                    , onInput TenureSearchTermChanged
                                    , onKeyDown TenureKeyDown
                                    , class "form-control form-control-sm"
                                    ]
                                    []
                                ]
                            )

                    filteredYears =
                        if String.isEmpty model.tenureSearchTerm then
                            allYears

                        else
                            allYears
                                |> List.filter
                                    (\years ->
                                        String.fromInt years
                                            |> String.contains model.tenureSearchTerm
                                    )

                    tenureItems =
                        filteredYears
                            |> List.indexedMap tenureItem
                in
                searchInput :: Dropdown.divider :: tenureItems
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


viewBreakdown : Role -> Country -> Int -> String -> String -> Html Msg
viewBreakdown role country tenure careers_updated countries_updated =
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
                , text "US median for "
                , mark [] [ text role.name ]
                , text " on Salary.com, divided by 12 (months) and converted to EUR using a 10-year USD -> EUR average. "
                , text "This value was fetched from Salary.com on "
                , mark [] [ text careers_updated ]
                , text "."
                ]
            , ListGroup.li []
                [ span
                    [ class "font-weight-bold"
                    ]
                    [ text "Compressed Cost of Living: " ]
                , text "Numbeo Cost of Living in "
                , mark [] [ text country.name ]
                , text " compared to United States, compressed against our Affordability Ratio of 0.49. "
                , text "This value was fetched from Numbeo on "
                , mark [] [ text countries_updated ]
                , text "."
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
                , text "The value is set somewhat arbitrarily, to match our salaries before the introduction of Salary System v2.0. The value in v1.0 was set to reflect the average cost of living in 4 major European tech hubs. We adjust the Affordability Ratio every January, based on the previous year's performance."
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
    --> "12.34%"

    humanizeCommitmentBonus 0.126
    --> "12.6%"

    humanizeCommitmentBonus 3.0
    --> "300%"

-}
humanizeCommitmentBonus : Float -> String
humanizeCommitmentBonus bonus =
    let
        scaledBonus =
            bonus * 100

        bonusText =
            String.fromFloat scaledBonus

        dotIndex =
            String.indexes "." bonusText

        endIndex =
            case List.head dotIndex of
                -- Keep two decimal places
                Just index ->
                    index + 3

                -- No decimal point found
                Nothing ->
                    String.length bonusText
    in
    String.slice 0 endIndex bonusText ++ "%"
