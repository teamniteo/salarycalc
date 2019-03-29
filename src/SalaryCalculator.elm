module SalaryCalculator exposing
    ( City(..)
    , Role(..)
    , cityDetail
    , init
    , main
    , roleDetail
    , salary
    , tenureDetail
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Dropdown as Dropdown
import Bootstrap.ListGroup as ListGroup
import Browser
import Html exposing (Html, div, mark, p, span, table, td, text, tr)
import Html.Attributes exposing (class, rowspan)
import Html.Events exposing (onClick)
import Maybe.Extra as Maybe
import Url exposing (fromString)
import Url.Parser as UrlParser exposing ((<?>), parse)
import Url.Parser.Query as QueryParser exposing (int, map3, string)



-- MODEL


init : String -> ( Model, Cmd Msg )
init locationHref =
    let
        maybeUrl =
            Url.fromString locationHref

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
    in
    ( { roleDropdown = Dropdown.initialState
      , cityDropdown = Dropdown.initialState
      , tenureDropdown = Dropdown.initialState
      , role =
            query.role
                |> Maybe.map roleFromString
                |> Maybe.join
                |> Maybe.withDefault SoftwareEngineer
      , city =
            query.city
                |> Maybe.map cityFromString
                |> Maybe.join
                |> Maybe.withDefault Ljubljana
      , tenure =
            query.years
                |> Maybe.withDefault 2
      , accordionState = Accordion.initialState
      }
    , Cmd.none
    )


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


type alias Model =
    { roleDropdown : Dropdown.State
    , cityDropdown : Dropdown.State
    , tenureDropdown : Dropdown.State
    , role : Role
    , city : City
    , tenure : Int
    , accordionState : Accordion.State
    }


type City
    = SanFrancisco
    | London
    | Amsterdam
    | Berlin
    | Barcelona
    | Lisbon
    | Ljubljana
    | Maribor
    | Bucharest
    | NoviSad
    | Davao
    | Delhi
    | Kharkiv


cityFromString : String -> Maybe City
cityFromString city =
    case city of
        "SanFrancisco" ->
            Just SanFrancisco

        "London" ->
            Just London

        "Amsterdam" ->
            Just Amsterdam

        "Berlin" ->
            Just Berlin

        "Barcelona" ->
            Just Barcelona

        "Lisbon" ->
            Just Lisbon

        "Ljubljana" ->
            Just Ljubljana

        "Maribor" ->
            Just Maribor

        "Bucharest" ->
            Just Bucharest

        "NoviSad" ->
            Just NoviSad

        "Davao" ->
            Just Davao

        "Delhi" ->
            Just Delhi

        "Kharkiv" ->
            Just Kharkiv

        _ ->
            Nothing


type alias CityDetail =
    { name : String
    , locationFactor : Float
    }


cityDetail : City -> CityDetail
cityDetail city =
    case city of
        SanFrancisco ->
            { name = "San Francisco"
            , locationFactor = 1.59
            }

        London ->
            { name = "London"
            , locationFactor = 1.3
            }

        Amsterdam ->
            { name = "Amsterdam"
            , locationFactor = 1.2
            }

        Berlin ->
            { name = "Berlin"
            , locationFactor = 0.99
            }

        Barcelona ->
            { name = "Barcelona"
            , locationFactor = 0.97
            }

        Lisbon ->
            { name = "Lisbon"
            , locationFactor = 0.94
            }

        Ljubljana ->
            { name = "Ljubljana"
            , locationFactor = 0.91
            }

        Maribor ->
            { name = "Maribor"
            , locationFactor = 0.86
            }

        Bucharest ->
            { name = "Bucharest"
            , locationFactor = 0.84
            }

        NoviSad ->
            { name = "Novi Sad"
            , locationFactor = 0.81
            }

        Davao ->
            { name = "Davao"
            , locationFactor = 0.81
            }

        Delhi ->
            { name = "Delhi"
            , locationFactor = 0.79
            }

        Kharkiv ->
            { name = "Kharkiv"
            , locationFactor = 0.79
            }


locationFactor : City -> Float
locationFactor city =
    let
        detail =
            cityDetail city
    in
    detail.locationFactor


type Role
    = PrincipalSoftwareEngineer
    | LeadSoftwareEngineer
    | SoftwareEngineer
    | JuniorSoftwareEngineer
    | JuniorProgrammer
    | SeniorProductMarketingManager
    | ProductMarketingManager
    | SeniorDigitalMarketingSpecialist
    | DigitalMarketingSpecialist
    | MarketingAssociate
    | PrincipalDesigner
    | LeadDesigner
    | SeniorDesigner
    | Designer
    | JuniorDesigner
    | SeniorOperationsManager
    | OperationsManager
    | TechnicalSupportSpecialist
    | CustomerSupportAssociate
    | CustomerSupportSpecialist


roleFromString : String -> Maybe Role
roleFromString role =
    case role of
        "PrincipalSoftwareEngineer" ->
            Just PrincipalSoftwareEngineer

        "LeadSoftwareEngineer" ->
            Just LeadSoftwareEngineer

        "SoftwareEngineer" ->
            Just SoftwareEngineer

        "JuniorSoftwareEngineer" ->
            Just JuniorSoftwareEngineer

        "JuniorProgrammer" ->
            Just JuniorProgrammer

        "SeniorProductMarketingManager" ->
            Just SeniorProductMarketingManager

        "ProductMarketingManager" ->
            Just ProductMarketingManager

        "SeniorDigitalMarketingSpecialist" ->
            Just SeniorDigitalMarketingSpecialist

        "DigitalMarketingSpecialist" ->
            Just DigitalMarketingSpecialist

        "MarketingAssociate" ->
            Just MarketingAssociate

        "PrincipalDesigner" ->
            Just PrincipalDesigner

        "LeadDesigner" ->
            Just LeadDesigner

        "SeniorDesigner" ->
            Just SeniorDesigner

        "Designer" ->
            Just Designer

        "JuniorDesigner" ->
            Just JuniorDesigner

        "SeniorOperationsManager" ->
            Just SeniorOperationsManager

        "OperationsManager" ->
            Just OperationsManager

        "TechnicalSupportSpecialist" ->
            Just TechnicalSupportSpecialist

        "CustomerSupportAssociate" ->
            Just CustomerSupportAssociate

        "CustomerSupportSpecialist" ->
            Just CustomerSupportSpecialist

        _ ->
            Nothing


type alias RoleDetail =
    { name : String
    , baseSalary : Int
    }


roleDetail : Role -> RoleDetail
roleDetail role =
    case role of
        PrincipalSoftwareEngineer ->
            { name = "Principal Software Engineer"
            , baseSalary = 6184
            }

        LeadSoftwareEngineer ->
            { name = "Lead Software Engineer"
            , baseSalary = 5791
            }

        SoftwareEngineer ->
            { name = "Software Engineer"
            , baseSalary = 4919
            }

        JuniorSoftwareEngineer ->
            { name = "Junior Software Engineer"
            , baseSalary = 3795
            }

        JuniorProgrammer ->
            { name = "Junior Programmer"
            , baseSalary = 2506
            }

        SeniorProductMarketingManager ->
            { name = "Senior Product Marketing Manager"
            , baseSalary = 6140
            }

        ProductMarketingManager ->
            { name = "Product Marketing Manager"
            , baseSalary = 5243
            }

        SeniorDigitalMarketingSpecialist ->
            { name = "Senior Digital Marketing Specialist"
            , baseSalary = 3693
            }

        DigitalMarketingSpecialist ->
            { name = "Digital Marketing Specialist"
            , baseSalary = 2955
            }

        MarketingAssociate ->
            { name = "Marketing Associate"
            , baseSalary = 2446
            }

        PrincipalDesigner ->
            { name = "Principal Designer"
            , baseSalary = 5371
            }

        LeadDesigner ->
            { name = "Lead Designer"
            , baseSalary = 4206
            }

        SeniorDesigner ->
            { name = "Senior Designer"
            , baseSalary = 4066
            }

        Designer ->
            { name = "Designer"
            , baseSalary = 3119
            }

        JuniorDesigner ->
            { name = "Junior Designer"
            , baseSalary = 2649
            }

        SeniorOperationsManager ->
            { name = "Senior Operations Manager"
            , baseSalary = 3903
            }

        OperationsManager ->
            { name = "Operations Manager"
            , baseSalary = 2720
            }

        TechnicalSupportSpecialist ->
            { name = "Technical Support Specialist"
            , baseSalary = 1979
            }

        CustomerSupportAssociate ->
            { name = "Customer Support Associate"
            , baseSalary = 1792
            }

        CustomerSupportSpecialist ->
            { name = "Customer Support Specialist"
            , baseSalary = 1711
            }


type alias TenureDetail =
    { name : String
    , commitmentBonus : Float
    }


tenureDetail : Int -> TenureDetail
tenureDetail years =
    let
        commitmentBonus =
            logBase e (toFloat years + 1) / 10
    in
    if years < 1 then
        { name = "Just started"
        , commitmentBonus = 0
        }

    else if years == 1 then
        { name = String.fromInt years ++ " year"
        , commitmentBonus = commitmentBonus
        }

    else
        { name = String.fromInt years ++ " years"
        , commitmentBonus = commitmentBonus
        }


baseSalary : Role -> Int
baseSalary role =
    let
        detail =
            roleDetail role
    in
    detail.baseSalary


salary : Model -> Int
salary model =
    let
        detail =
            tenureDetail model.tenure

        commitmentBonus =
            detail.commitmentBonus
    in
    round (toFloat (baseSalary model.role) * locationFactor model.city + toFloat (baseSalary model.role) * commitmentBonus)



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
            ( { model | role = role }, Cmd.none )

        CitySelected city ->
            ( { model | city = city }, Cmd.none )

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
    Accordion.config AccordionMsg
        |> Accordion.withAnimation
        |> Accordion.cards
            [ Accordion.card
                { id = "card1"
                , options = [ Card.outlineLight ]
                , header =
                    Accordion.header []
                        (Accordion.toggle [ class "p-0" ] [ span [] [ text "Okay, let's break that down ..." ] ])
                        |> Accordion.prependHeader
                            (viewHeader model)
                , blocks =
                    [ Accordion.block []
                        [ Block.text [] [ viewBreakdown model ] ]
                    ]
                }
            ]
        |> Accordion.view model.accordionState


viewHeader : Model -> List (Html Msg)
viewHeader model =
    let
        roleName role =
            let
                detail =
                    roleDetail role
            in
            detail.name

        roleItem role =
            Dropdown.buttonItem [ onClick (RoleSelected role) ] [ text (roleName role) ]

        cityName city =
            let
                detail =
                    cityDetail city
            in
            detail.name

        cityItem city =
            Dropdown.buttonItem [ onClick (CitySelected city) ] [ text (cityName city) ]

        tenureName years =
            let
                detail =
                    tenureDetail years
            in
            detail.name

        tenureItem years =
            Dropdown.buttonItem [ onClick (TenureSelected years) ] [ text (tenureName years) ]
    in
    [ p [ class "lead" ]
        [ text "I'm a "
        , Dropdown.dropdown model.roleDropdown
            { options = []
            , toggleMsg = RoleDropdownChanged
            , toggleButton =
                Dropdown.toggle [ Button.outlinePrimary ] [ viewRole model.role ]
            , items =
                [ Dropdown.header [ text "Design Career" ]
                , roleItem JuniorDesigner
                , roleItem Designer
                , roleItem SeniorDesigner
                , roleItem LeadDesigner
                , roleItem PrincipalDesigner
                , Dropdown.header [ text "Marketing Career" ]
                , roleItem MarketingAssociate
                , roleItem DigitalMarketingSpecialist
                , roleItem SeniorDigitalMarketingSpecialist
                , roleItem ProductMarketingManager
                , roleItem SeniorProductMarketingManager
                , Dropdown.header [ text "Operations Career" ]
                , roleItem CustomerSupportSpecialist
                , roleItem CustomerSupportAssociate
                , roleItem TechnicalSupportSpecialist
                , roleItem OperationsManager
                , roleItem SeniorOperationsManager
                , Dropdown.header [ text "Technical Career" ]
                , roleItem JuniorProgrammer
                , roleItem JuniorSoftwareEngineer
                , roleItem SoftwareEngineer
                , roleItem LeadSoftwareEngineer
                , roleItem PrincipalSoftwareEngineer
                ]
            }
        , text " living in "
        , Dropdown.dropdown model.cityDropdown
            { options = []
            , toggleMsg = CityDropdownChanged
            , toggleButton =
                Dropdown.toggle [ Button.outlinePrimary ] [ viewCity model.city ]
            , items =
                [ cityItem Amsterdam
                , cityItem Barcelona
                , cityItem Berlin
                , cityItem Bucharest
                , cityItem Davao
                , cityItem Delhi
                , cityItem Kharkiv
                , cityItem Lisbon
                , cityItem Ljubljana
                , cityItem London
                , cityItem Maribor
                , cityItem NoviSad
                , cityItem SanFrancisco
                ]
            }
        , text " with a tenure at Niteo of "
        , Dropdown.dropdown model.tenureDropdown
            { options = []
            , toggleMsg = TenureDropdownChanged
            , toggleButton =
                Dropdown.toggle [ Button.outlinePrimary ] [ viewTenure model.tenure ]
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
    span []
        [ text "My monthly gross salary is "
        , span [ class "font-weight-bold" ] [ String.fromInt (salary model) ++ " €." |> text ]
        ]


viewBreakdown : Model -> Html Msg
viewBreakdown model =
    div []
        [ table [ class "table" ]
            [ tr []
                [ td [ class "border-0 p-0 text-center align-middle display-4", rowspan 2 ] [ text "(" ]
                , td [ class "border-0 p-0 text-center lead" ] [ viewBaseSalary model.role ]
                , td [ class "border-0 p-0 text-center align-middle display-4", rowspan 2 ] [ text "x" ]
                , td [ class "border-0 p-0 text-center lead" ] [ viewLocationFactor model.city ]
                , td [ class "border-0 p-0 text-center align-middle display-4", rowspan 2 ] [ text ")" ]
                , td [ class "border-0 p-0 text-center align-middle display-4", rowspan 2 ] [ text "+" ]
                , td [ class "border-0 p-0 text-center align-middle display-4", rowspan 2 ] [ text "(" ]
                , td [ class "border-0 p-0 text-center lead" ] [ viewBaseSalary model.role ]
                , td [ class "border-0 p-0 text-center align-middle display-4", rowspan 2 ] [ text "x" ]
                , td [ class "border-0 p-0 text-center lead" ] [ viewCommitmentBonus model.tenure ]
                , td [ class "border-0 p-0 text-center align-middle display-4", rowspan 2 ] [ text ")" ]
                ]
            , tr []
                [ td [ class "border-0 p-0 text-center text-muted" ] [ text "(base salary)" ]
                , td [ class "border-0 p-0 text-center text-muted" ] [ text "(location factor)" ]
                , td [ class "border-0 p-0 text-center text-muted" ] [ text "(base salary)" ]
                , td [ class "border-0 p-0 text-center text-muted" ] [ text "(commitment bonus)" ]
                ]
            ]
        , ListGroup.ul
            [ ListGroup.li [] [ span [ class "font-weight-bold" ] [ text "Base Salary: " ], text "San Francisco 50th percentile for ", mark [] [ viewRole model.role ], text " on Glassdoor, discounted by our Affordability Ratio of 0.53." ]
            , ListGroup.li [] [ span [ class "font-weight-bold" ] [ text "Location Factor: " ], text "Numbeo Cost of Living in ", mark [] [ viewCity model.city ], text " compared to San Francisco, compressed and normalized against our Affordability Ratio of 0.53." ]
            , ListGroup.li [] [ span [ class "font-weight-bold" ] [ text "Commitment Bonus: " ], text "Natural logarithm of ", mark [] [ viewTenure model.tenure ], text " years of your tenure, divided by 10." ]
            , ListGroup.li [] [ span [ class "font-weight-bold" ] [ text "Affordability Ratio: " ], text "Average Cost of Living index compared to San Francisco, for four major European tech hubs: Amsterdam, Berlin, Barcelona, Lisbon." ]
            ]
        ]


viewRole : Role -> Html Msg
viewRole role =
    let
        detail =
            roleDetail role
    in
    text detail.name


viewCity : City -> Html Msg
viewCity city =
    let
        detail =
            cityDetail city
    in
    text detail.name


viewTenure : Int -> Html Msg
viewTenure years =
    String.fromInt years
        |> text


viewBaseSalary : Role -> Html Msg
viewBaseSalary role =
    String.fromInt (baseSalary role)
        |> text


viewLocationFactor : City -> Html Msg
viewLocationFactor city =
    String.fromFloat (locationFactor city)
        |> text


viewCommitmentBonus : Int -> Html Msg
viewCommitmentBonus years =
    let
        detail =
            tenureDetail years

        percentage =
            toFloat (round (detail.commitmentBonus * 1000)) / 10
    in
    text (String.fromFloat percentage ++ "%")



-- MAIN


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
