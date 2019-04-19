module Tests exposing
    ( testCommitmentBonus
    , testHumanizeCommitmentBonus
    , testHumanizeTenure
    , testInit
    , testLookupByName
    , testSalary
    , testViewPluralizedYears
    , testViewSalary
    , testViewWarnings
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Dropdown as Dropdown
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Html
import Json.Encode as Encode
import List.Extra as List
import SalaryCalculator
    exposing
        ( City
        , Field(..)
        , Flags
        , Msg(..)
        , Role
        , Warning
        , commitmentBonus
        , humanizeCommitmentBonus
        , humanizeTenure
        , init
        , lookupByName
        , salary
        , update
        , viewPluralizedYears
        , viewSalary
        , viewWarnings
        )
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (classes, tag, text)
import Url exposing (Protocol(..), Url)


testInit : Test
testInit =
    let
        flags : Flags
        flags =
            { location = "https://example.com/salary-calculator/"
            , config = config
            }

        config : Encode.Value
        config =
            [ ( "cities"
              , [ ( "Amsterdam", 1.3 )
                ]
                    |> Encode.list encodeCity
              )
            , ( "careers"
              , [ ( "technical"
                  , [ ( "Software Developer", 3500 ) ]
                  )
                ]
                    |> Encode.list encodeCareer
              )
            ]
                |> Encode.object

        encodeCity : ( String, Float ) -> Encode.Value
        encodeCity ( name, locationFactor ) =
            [ ( "name"
              , name |> Encode.string
              )
            , ( "locationFactor"
              , locationFactor |> Encode.float
              )
            ]
                |> Encode.object

        encodeCareer : ( String, List ( String, Int ) ) -> Encode.Value
        encodeCareer ( name, roles ) =
            [ ( "name"
              , name |> Encode.string
              )
            , ( "roles"
              , roles |> Encode.list encodeRole
              )
            ]
                |> Encode.object

        encodeRole : ( String, Int ) -> Encode.Value
        encodeRole ( name, baseSalary ) =
            [ ( "name"
              , name |> Encode.string
              )
            , ( "baseSalary"
              , baseSalary |> Encode.int
              )
            ]
                |> Encode.object
    in
    test "Init returns a correct model"
        (\_ ->
            init flags
                |> Tuple.first
                |> Expect.equal
                    { error = Nothing
                    , warnings = []
                    , cities =
                        [ { locationFactor = 1.3
                          , name = "Amsterdam"
                          }
                        ]
                    , careers =
                        [ { name = "technical"
                          , roles =
                                [ { baseSalary = 3500
                                  , name = "Software Developer"
                                  }
                                ]
                          }
                        ]
                    , role =
                        Just
                            { baseSalary = 3500
                            , name = "Software Developer"
                            }
                    , city = Just { locationFactor = 1.3, name = "Amsterdam" }
                    , tenure = 2
                    , accordionState = Accordion.initialState
                    , roleDropdown = Dropdown.initialState
                    , cityDropdown = Dropdown.initialState
                    , tenureDropdown = Dropdown.initialState
                    }
        )


testSalary : Test
testSalary =
    let
        role =
            { name = "FooRole", baseSalary = 4919 }

        city =
            { name = "FooCity", locationFactor = 0.91 }

        tenure =
            2
    in
    test "Salary for Software Engineer from Ljubljana with a 2 year tenure"
        (\_ ->
            salary role city tenure
                |> Expect.equal 5017
        )


testViewSalary : Test
testViewSalary =
    let
        role =
            Just (Role "foo" 500)

        city =
            Just (City "bar" 1.1)
    in
    describe "Correct handling when role or city is not available"
        [ test "nothing is set" <|
            \_ ->
                viewSalary Nothing Nothing 0
                    |> Query.fromHtml
                    |> Query.has [ text "Please select a role and a city." ]
        , test "only city is set" <|
            \_ ->
                viewSalary Nothing city 0
                    |> Query.fromHtml
                    |> Query.has [ text "Please select a role." ]
        , test "only role is set" <|
            \_ ->
                viewSalary role Nothing 0
                    |> Query.fromHtml
                    |> Query.has [ text "Please select a city." ]
        , test "role and city are set" <|
            \_ ->
                viewSalary role city 2
                    |> Query.fromHtml
                    |> Query.has [ text "605 €" ]
        ]


testCommitmentBonus : Test
testCommitmentBonus =
    describe "Commitment Bonus is calculated correctly"
        [ test "0 years" <|
            \_ ->
                commitmentBonus 0
                    |> Expect.equal 0
        , test "1 year" <|
            \_ ->
                commitmentBonus 1
                    |> String.fromFloat
                    |> Expect.equal "0.06931471805599453"
        , test "2 year" <|
            \_ ->
                commitmentBonus 2
                    |> String.fromFloat
                    |> Expect.equal "0.10986122886681096"
        , test "5 year" <|
            \_ ->
                commitmentBonus 5
                    |> String.fromFloat
                    |> Expect.equal "0.1791759469228055"
        , test "10 year" <|
            \_ ->
                commitmentBonus 10
                    |> String.fromFloat
                    |> Expect.equal "0.23978952727983707"
        , test "15 year" <|
            \_ ->
                commitmentBonus 15
                    |> String.fromFloat
                    |> Expect.equal "0.2772588722239781"
        ]


testHumanizeCommitmentBonus : Test
testHumanizeCommitmentBonus =
    describe "Commitment Bonus is viewed as percentages"
        [ test "0" <|
            \_ ->
                humanizeCommitmentBonus 0
                    |> Expect.equal "0%"
        , test "0.011" <|
            \_ ->
                humanizeCommitmentBonus 0.011
                    |> Expect.equal "1%"
        , test "0.125" <|
            \_ ->
                humanizeCommitmentBonus 0.125
                    |> Expect.equal "13%"
        ]


testLookupByName : Test
testLookupByName =
    describe "Get item in list based on name"
        [ test "item exists" <|
            \_ ->
                lookupByName "foo" [ { name = "foo" }, { name = "bar" } ]
                    |> Expect.equal (Just { name = "foo" })
        , test "item does not exist" <|
            \_ ->
                lookupByName "bla" [ { name = "foo" }, { name = "bar" } ]
                    |> Expect.equal Nothing
        ]


testHumanizeTenure : Test
testHumanizeTenure =
    describe "Tenure has a properly pluralized 'years' suffix"
        [ test "0" <|
            \_ ->
                humanizeTenure 0
                    |> Expect.equal "Just started"
        , test "0.011" <|
            \_ ->
                humanizeTenure 1
                    |> Expect.equal "1 year"
        , test "0.125" <|
            \_ ->
                humanizeTenure 5
                    |> Expect.equal "5 years"
        ]


hideWarnings : Test
hideWarnings =
    describe "Warnings are hidden when role or city is selected"
        [ test "role is selected" <|
            \_ ->
                update (RoleSelected (Role "foo" 5000))
                    { error = Nothing
                    , warnings = [ Warning "foo" RoleField, Warning "bar" CityField ]
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
                    |> Tuple.first
                    |> .warnings
                    |> Expect.equal [ Warning "bar" CityField ]
        , test "city is selected" <|
            \_ ->
                update (CitySelected (City "foo" 1.1))
                    { error = Nothing
                    , warnings = [ Warning "foo" RoleField, Warning "bar" CityField ]
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
                    |> Tuple.first
                    |> .warnings
                    |> Expect.equal [ Warning "foo" RoleField ]
        ]


testViewPluralizedYears : Test
testViewPluralizedYears =
    describe "HTML for tenure dropdown suffix"
        [ test "0" <|
            \_ ->
                viewPluralizedYears 0
                    |> Query.fromHtml
                    |> Query.has [ text " years." ]
        , test "1" <|
            \_ ->
                viewPluralizedYears 1
                    |> Query.fromHtml
                    |> Query.has [ text " year." ]
        , test "5" <|
            \_ ->
                viewPluralizedYears 5
                    |> Query.fromHtml
                    |> Query.has [ text " years." ]
        ]


testViewWarnings : Test
testViewWarnings =
    let
        warnings =
            [ Warning "Invalid role" RoleField ]
    in
    test "Warnings are displayed as Bootstrap alerts"
        (\_ ->
            viewWarnings warnings
                |> Query.fromHtml
                |> Query.has [ tag "div", classes [ "alert" ], text "Invalid role" ]
        )
