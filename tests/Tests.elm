module Tests exposing
    ( tenureImpact
    , testCommitmentBonus
    , testHandleKeyDown
    , testHumanizeCommitmentBonus
    , testHumanizeTenure
    , testInitHappyPath
    , testInitInvalidConfig
    , testInitInvalidQueryString
    , testInitMissingCareers
    , testInitMissingCountries
    , testInitMissingRoles
    , testInitQueryString
    , testKeyboardNavigation
    , testLookupByName
    , testSalary
    , testViewPluralizedYears
    , testViewSalary
    , testViewWarnings
    )

import Bootstrap.Accordion as Accordion
import Bootstrap.Dropdown as Dropdown
import Career exposing (Career, Role)
import Config exposing (Config)
import Country exposing (Country)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import List.Extra as List
import Main
    exposing
        ( Field(..)
        , Flags
        , Msg(..)
        , Warning
        , handleKeyDown
        , humanizeCommitmentBonus
        , humanizeTenure
        , init
        , lookupByName
        , update
        , viewPluralizedYears
        , viewSalary
        , viewWarnings
        )
import Salary
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (classes, tag, text)
import Url exposing (Protocol(..), Url)


testInitHappyPath : Test
testInitHappyPath =
    let
        json =
            """
              {
                "careers_updated": "1999-01-01",
                "countries_updated": "2000-01-01",
                "countries": [
                  {
                    "name": "Netherlands",
                    "compressed_cost_of_living": 1.3
                  },
                  {
                    "name": "Germany",
                    "compressed_cost_of_living": 1.2
                  }
                ],
                "careers": [
                  {
                    "name": "Technical",
                    "roles": [
                      {
                        "name": "Software Developer",
                        "baseSalary": 3500
                      },
                      {
                        "name": "Junior Software Developer",
                        "baseSalary": 2500
                      }
                    ]
                  }
                ]
              }
            """
    in
    test "Init returns a correct model with default values"
        (\_ ->
            case Decode.decodeString Decode.value json of
                Err error ->
                    error
                        |> Decode.errorToString
                        |> (++) "The JSON string provided in your test is invalid. Here is the message from decoder:\n\n"
                        |> Expect.fail

                Ok config ->
                    { location = "https://example.com/salary-calculator/"
                    , config = config
                    }
                        |> init
                        |> Tuple.first
                        |> Expect.equal
                            { error = Nothing
                            , warnings = []
                            , countries =
                                [ Country "Netherlands" 1.3
                                , Country "Germany" 1.2
                                ]
                            , careers =
                                [ Career "Technical"
                                    [ Role "Software Developer" 3500
                                    , Role "Junior Software Developer" 2500
                                    ]
                                ]
                            , role = Just (Role "Software Developer" 3500)
                            , country = Just (Country "Netherlands" 1.3)
                            , tenure = 2
                            , accordionState = Accordion.initialState
                            , roleDropdown = Dropdown.initialState
                            , countryDropdown = Dropdown.initialState
                            , tenureDropdown = Dropdown.initialState
                            , careers_updated = "1999-01-01"
                            , countries_updated = "2000-01-01"
                            , countrySearchTerm = ""
                            , roleSearchTerm = ""
                            , tenureSearchTerm = ""
                            , roleSelectedIndex = 0
                            , countrySelectedIndex = 0
                            , tenureSelectedIndex = 0
                            }
        )


testInitQueryString : Test
testInitQueryString =
    let
        json =
            """
              {
                "careers_updated": "1999-01-01",
                "countries_updated": "2000-01-01",
                "countries": [
                  {
                    "name": "Netherlands",
                    "compressed_cost_of_living": 1.3
                  },
                  {
                    "name": "Germany",
                    "compressed_cost_of_living": 1.2
                  }
                ],
                "careers": [
                  {
                    "name": "Technical",
                    "roles": [
                      {
                        "name": "Software Developer",
                        "baseSalary": 3500
                      },
                      {
                        "name": "Junior Software Developer",
                        "baseSalary": 2500
                      }
                    ]
                  }
                ]
              }
            """
    in
    test "Role and Country are read from querystring "
        (\_ ->
            case Decode.decodeString Decode.value json of
                Err error ->
                    error
                        |> Decode.errorToString
                        |> (++) "The JSON string provided in your test is invalid. Here is the message from decoder:\n\n"
                        |> Expect.fail

                Ok config ->
                    { location = "https://example.com/salary-calculator?role=Junior Software Developer&country=Germany"
                    , config = config
                    }
                        |> init
                        |> Tuple.first
                        |> Expect.equal
                            { error = Nothing
                            , warnings = []
                            , countries =
                                [ Country "Netherlands" 1.3
                                , Country "Germany" 1.2
                                ]
                            , careers =
                                [ Career "Technical"
                                    [ Role "Software Developer" 3500
                                    , Role "Junior Software Developer" 2500
                                    ]
                                ]
                            , role = Just (Role "Junior Software Developer" 2500)
                            , country = Just (Country "Germany" 1.2)
                            , tenure = 2
                            , accordionState = Accordion.initialState
                            , roleDropdown = Dropdown.initialState
                            , countryDropdown = Dropdown.initialState
                            , tenureDropdown = Dropdown.initialState
                            , careers_updated = "1999-01-01"
                            , countries_updated = "2000-01-01"
                            , countrySearchTerm = ""
                            , roleSearchTerm = ""
                            , tenureSearchTerm = ""
                            , roleSelectedIndex = 0
                            , countrySelectedIndex = 0
                            , tenureSelectedIndex = 0
                            }
        )


testInitInvalidQueryString : Test
testInitInvalidQueryString =
    let
        json =
            """
              {
                "careers_updated": "1999-01-01",
                "countries_updated": "2000-01-01",
                "countries": [
                  {
                    "name": "Netherlands",
                    "compressed_cost_of_living": 1.3
                  },
                  {
                    "name": "Germany",
                    "compressed_cost_of_living": 1.2
                  }
                ],
                "careers": [
                  {
                    "name": "Technical",
                    "roles": [
                      {
                        "name": "Software Developer",
                        "baseSalary": 3500
                      },
                      {
                        "name": "Junior Software Developer",
                        "baseSalary": 2500
                      }
                    ]
                  }
                ]
              }
            """
    in
    test "Role and Country are given querystring but the values are bad"
        (\_ ->
            case Decode.decodeString Decode.value json of
                Err error ->
                    error
                        |> Decode.errorToString
                        |> (++) "The JSON string provided in your test is invalid. Here is the message from decoder:\n\n"
                        |> Expect.fail

                Ok config ->
                    { location = "https://example.com/salary-calculator?role=Foo&country=Bar"
                    , config = config
                    }
                        |> init
                        |> Tuple.first
                        |> Expect.equal
                            { error = Nothing
                            , warnings =
                                [ Warning "Invalid role provided via URL: Foo. Please choose one from the dropdown below." RoleField
                                , Warning "Invalid country provided via URL: Bar. Please choose one from the dropdown below." CountryField
                                ]
                            , countries =
                                [ Country "Netherlands" 1.3
                                , Country "Germany" 1.2
                                ]
                            , careers =
                                [ Career "Technical"
                                    [ Role "Software Developer" 3500
                                    , Role "Junior Software Developer" 2500
                                    ]
                                ]
                            , role = Nothing
                            , country = Nothing
                            , tenure = 2
                            , accordionState = Accordion.initialState
                            , roleDropdown = Dropdown.initialState
                            , countryDropdown = Dropdown.initialState
                            , tenureDropdown = Dropdown.initialState
                            , careers_updated = "1999-01-01"
                            , countries_updated = "2000-01-01"
                            , countrySearchTerm = ""
                            , roleSearchTerm = ""
                            , tenureSearchTerm = ""
                            , roleSelectedIndex = 0
                            , countrySelectedIndex = 0
                            , tenureSelectedIndex = 0
                            }
        )


testInitMissingCountries : Test
testInitMissingCountries =
    let
        json =
            """
              {
                "countries": [],
                "careers": []
              }
            """
    in
    test "Countries need to be given"
        (\_ ->
            case Decode.decodeString Decode.value json of
                Err error ->
                    error
                        |> Decode.errorToString
                        |> (++) "The JSON string provided in your test is invalid. Here is the message from decoder:\n\n"
                        |> Expect.fail

                Ok config ->
                    { location = "https://example.com/salary-calculator"
                    , config = config
                    }
                        |> init
                        |> Tuple.first
                        |> Expect.equal
                            { error = Just "Problem with the value at json.countries:\n\n    []\n\nThere must be at least one country in your config."
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
        )


testInitMissingCareers : Test
testInitMissingCareers =
    let
        json =
            """
              {
                "countries": [
                  {
                    "name": "Netherlands",
                    "compressed_cost_of_living": 1.3
                  }
                ],
                "careers": []
              }
            """
    in
    test "Careers need to be given"
        (\_ ->
            case Decode.decodeString Decode.value json of
                Err error ->
                    error
                        |> Decode.errorToString
                        |> (++) "The JSON string provided in your test is invalid. Here is the message from decoder:\n\n"
                        |> Expect.fail

                Ok config ->
                    { location = "https://example.com/salary-calculator"
                    , config = config
                    }
                        |> init
                        |> Tuple.first
                        |> Expect.equal
                            { error = Just "Problem with the value at json.careers:\n\n    []\n\nThere must be at least one career in your config."
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
        )


testInitMissingRoles : Test
testInitMissingRoles =
    let
        json =
            """
              {
                "countries": [
                  {
                    "name": "Netherlands",
                    "compressed_cost_of_living": 1.3
                  }
                ],
                "careers": [
                  {
                    "name": "Technical",
                    "roles": []
                  }
                ]
              }
            """
    in
    test "Roles need to be given"
        (\_ ->
            case Decode.decodeString Decode.value json of
                Err error ->
                    error
                        |> Decode.errorToString
                        |> (++) "The JSON string provided in your test is invalid. Here is the message from decoder:\n\n"
                        |> Expect.fail

                Ok config ->
                    { location = "https://example.com/salary-calculator"
                    , config = config
                    }
                        |> init
                        |> Tuple.first
                        |> Expect.equal
                            { error = Just "Problem with the value at json.careers[0].roles:\n\n    []\n\nThere must be at least one role in your config."
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
        )


testInitInvalidConfig : Test
testInitInvalidConfig =
    let
        json =
            """
              {
                "foo": "bar"
              }
            """
    in
    test "Config is broken"
        (\_ ->
            case Decode.decodeString Decode.value json of
                Err error ->
                    error
                        |> Decode.errorToString
                        |> (++) "The JSON string provided in your test is invalid. Here is the message from decoder:\n\n"
                        |> Expect.fail

                Ok config ->
                    { location = "https://example.com/salary-calculator"
                    , config = config
                    }
                        |> init
                        |> Tuple.first
                        |> Expect.equal
                            { error = Just "Problem with the given value:\n\n{\n        \"foo\": \"bar\"\n    }\n\nExpecting an OBJECT with a field named `countries`"
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
        )


testSalary : Test
testSalary =
    let
        role =
            { name = "FooRole", baseSalary = 4919 }

        country =
            { name = "FooCountry", compressed_cost_of_living = 0.91 }

        tenure =
            2
    in
    test "Salary for Software Engineer from Slovenia with a 2 year tenure"
        (\_ ->
            Salary.calculate role country tenure
                |> Expect.equal 5017
        )


testViewSalary : Test
testViewSalary =
    let
        role =
            Just (Role "foo" 500)

        country =
            Just (Country "bar" 1.1)
    in
    describe "Correct handling when role or country is not available"
        [ test "nothing is set" <|
            \_ ->
                viewSalary Nothing Nothing 0
                    |> Query.fromHtml
                    |> Query.has [ text "Please select a role and a country." ]
        , test "only country is set" <|
            \_ ->
                viewSalary Nothing country 0
                    |> Query.fromHtml
                    |> Query.has [ text "Please select a role." ]
        , test "only role is set" <|
            \_ ->
                viewSalary role Nothing 0
                    |> Query.fromHtml
                    |> Query.has [ text "Please select a country." ]
        , test "role and country are set" <|
            \_ ->
                viewSalary role country 2
                    |> Query.fromHtml
                    |> Query.has [ text "605 €" ]
        ]


testCommitmentBonus : Test
testCommitmentBonus =
    describe "Commitment Bonus is calculated correctly"
        [ test "0 years" <|
            \_ ->
                Salary.commitmentBonus 0
                    |> Expect.equal 0
        , test "1 year" <|
            \_ ->
                Salary.commitmentBonus 1
                    |> String.fromFloat
                    |> Expect.equal "0.06931471805599453"
        , test "2 year" <|
            \_ ->
                Salary.commitmentBonus 2
                    |> String.fromFloat
                    |> Expect.equal "0.10986122886681096"
        , test "5 year" <|
            \_ ->
                Salary.commitmentBonus 5
                    |> String.fromFloat
                    |> Expect.equal "0.1791759469228055"
        , test "10 year" <|
            \_ ->
                Salary.commitmentBonus 10
                    |> String.fromFloat
                    |> Expect.equal "0.23978952727983707"
        , test "15 year" <|
            \_ ->
                Salary.commitmentBonus 15
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
                humanizeCommitmentBonus 0.0101
                    |> Expect.equal "1.01%"
        , test "0.125" <|
            \_ ->
                humanizeCommitmentBonus 0.125
                    |> Expect.equal "12.5%"
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
    describe "Warnings are hidden when role or country is selected"
        [ test "role is selected" <|
            \_ ->
                update (RoleSelected (Role "foo" 5000))
                    { error = Nothing
                    , warnings = [ Warning "foo" RoleField, Warning "bar" CountryField ]
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
                    |> Tuple.first
                    |> .warnings
                    |> Expect.equal [ Warning "bar" CountryField ]
        , test "country is selected" <|
            \_ ->
                update (CountrySelected (Country "foo" 1.1))
                    { error = Nothing
                    , warnings = [ Warning "foo" RoleField, Warning "bar" CountryField ]
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
                    |> Tuple.first
                    |> .warnings
                    |> Expect.equal [ Warning "foo" RoleField ]
        ]


testKeyboardNavigation : Test
testKeyboardNavigation =
    describe "Keyboard navigation works correctly"
        [ test "ArrowDown increases selected index" <|
            \_ ->
                let
                    model =
                        { error = Nothing
                        , warnings = []
                        , countries =
                            [ Country "Slovenia" 0.91
                            , Country "Slovakia" 0.85
                            ]
                        , careers =
                            [ Career "Technical"
                                [ Role "Software Developer" 3500 ]
                            ]
                        , role = Just (Role "Software Developer" 3500)
                        , country = Nothing
                        , tenure = 2
                        , accordionState = Accordion.initialState
                        , roleDropdown = Dropdown.initialState
                        , countryDropdown = Dropdown.initialState
                        , tenureDropdown = Dropdown.initialState
                        , careers_updated = "2022-01-01"
                        , countries_updated = "2022-01-01"
                        , countrySearchTerm = "slov"
                        , roleSearchTerm = ""
                        , tenureSearchTerm = ""
                        , roleSelectedIndex = 0
                        , countrySelectedIndex = 0
                        , tenureSelectedIndex = 0
                        }
                in
                update (CountryKeyDown "ArrowDown") model
                    |> Tuple.first
                    |> .countrySelectedIndex
                    |> Expect.equal 1
        , test "ArrowUp decreases selected index" <|
            \_ ->
                let
                    model =
                        { error = Nothing
                        , warnings = []
                        , countries =
                            [ Country "Slovenia" 0.91
                            , Country "Slovakia" 0.85
                            ]
                        , careers =
                            [ Career "Technical"
                                [ Role "Software Developer" 3500 ]
                            ]
                        , role = Just (Role "Software Developer" 3500)
                        , country = Nothing
                        , tenure = 2
                        , accordionState = Accordion.initialState
                        , roleDropdown = Dropdown.initialState
                        , countryDropdown = Dropdown.initialState
                        , tenureDropdown = Dropdown.initialState
                        , careers_updated = "2022-01-01"
                        , countries_updated = "2022-01-01"
                        , countrySearchTerm = "slov"
                        , roleSearchTerm = ""
                        , tenureSearchTerm = ""
                        , roleSelectedIndex = 0
                        , countrySelectedIndex = 1
                        , tenureSelectedIndex = 0
                        }
                in
                update (CountryKeyDown "ArrowUp") model
                    |> Tuple.first
                    |> .countrySelectedIndex
                    |> Expect.equal 0
        , test "Enter selects the current item and closes dropdown" <|
            \_ ->
                let
                    model =
                        { error = Nothing
                        , warnings = []
                        , countries =
                            [ Country "Slovenia" 0.91
                            , Country "Slovakia" 0.85
                            ]
                        , careers =
                            [ Career "Technical"
                                [ Role "Software Developer" 3500 ]
                            ]
                        , role = Just (Role "Software Developer" 3500)
                        , country = Nothing
                        , tenure = 2
                        , accordionState = Accordion.initialState
                        , roleDropdown = Dropdown.initialState
                        , countryDropdown = Dropdown.initialState
                        , tenureDropdown = Dropdown.initialState
                        , careers_updated = "2022-01-01"
                        , countries_updated = "2022-01-01"
                        , countrySearchTerm = "slov"
                        , roleSearchTerm = ""
                        , tenureSearchTerm = ""
                        , roleSelectedIndex = 0
                        , countrySelectedIndex = 0
                        , tenureSelectedIndex = 0
                        }

                    updatedModel =
                        update (CountryKeyDown "Enter") model
                            |> Tuple.first
                in
                Expect.all
                    [ .country >> Expect.equal (Just (Country "Slovenia" 0.91))
                    , .countrySearchTerm >> Expect.equal ""
                    , .countrySelectedIndex >> Expect.equal 0
                    ]
                    updatedModel
        , test "Search term change resets selected index" <|
            \_ ->
                let
                    model =
                        { error = Nothing
                        , warnings = []
                        , countries =
                            [ Country "Slovenia" 0.91
                            , Country "Slovakia" 0.85
                            ]
                        , careers =
                            [ Career "Technical"
                                [ Role "Software Developer" 3500 ]
                            ]
                        , role = Just (Role "Software Developer" 3500)
                        , country = Nothing
                        , tenure = 2
                        , accordionState = Accordion.initialState
                        , roleDropdown = Dropdown.initialState
                        , countryDropdown = Dropdown.initialState
                        , tenureDropdown = Dropdown.initialState
                        , careers_updated = "2022-01-01"
                        , countries_updated = "2022-01-01"
                        , countrySearchTerm = ""
                        , roleSearchTerm = ""
                        , tenureSearchTerm = ""
                        , roleSelectedIndex = 0
                        , countrySelectedIndex = 5
                        , tenureSelectedIndex = 0
                        }
                in
                update (CountrySearchTermChanged "test") model
                    |> Tuple.first
                    |> .countrySelectedIndex
                    |> Expect.equal 0
        ]


testHandleKeyDown : Test
testHandleKeyDown =
    describe "handleKeyDown function works correctly"
        [ test "ArrowDown increments index" <|
            \_ ->
                handleKeyDown "ArrowDown" [ "A", "B", "C" ] 0
                    |> Expect.equal ( 1, Nothing )
        , test "ArrowDown doesn't go past end" <|
            \_ ->
                handleKeyDown "ArrowDown" [ "A", "B", "C" ] 2
                    |> Expect.equal ( 2, Nothing )
        , test "ArrowUp decrements index" <|
            \_ ->
                handleKeyDown "ArrowUp" [ "A", "B", "C" ] 2
                    |> Expect.equal ( 1, Nothing )
        , test "ArrowUp doesn't go below zero" <|
            \_ ->
                handleKeyDown "ArrowUp" [ "A", "B", "C" ] 0
                    |> Expect.equal ( 0, Nothing )
        , test "Enter returns selected item" <|
            \_ ->
                handleKeyDown "Enter" [ "A", "B", "C" ] 1
                    |> Expect.equal ( 1, Just "B" )
        , test "Other keys do nothing" <|
            \_ ->
                handleKeyDown "Escape" [ "A", "B", "C" ] 1
                    |> Expect.equal ( 1, Nothing )
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



-- Generated tests


countries =
    [ { name = "United States"
      , compressed_cost_of_living = 1.59
      }
    , { name = "Netherlands"
      , compressed_cost_of_living = 1.2
      }
    , { name = "Portugal"
      , compressed_cost_of_living = 0.94
      }
    , { name = "Slovenia"
      , compressed_cost_of_living = 0.91
      }
    , { name = "Serbia"
      , compressed_cost_of_living = 0.81
      }
    , { name = "India"
      , compressed_cost_of_living = 0.81
      }
    ]


roles =
    [ { name = "Principal Software Engineer"
      , baseSalary = 6184
      }
    , { name = "Software Engineer"
      , baseSalary = 4919
      }
    , { name = "Junior Software Engineer"
      , baseSalary = 2506
      }
    , { name = "Junior Programmer"
      , baseSalary = 3000
      }
    , { name = "Senior Product Marketing Manager"
      , baseSalary = 6140
      }
    , { name = "Product Marketing Manager"
      , baseSalary = 5243
      }
    , { name = "Digital Marketing Specialist"
      , baseSalary = 2955
      }
    ]


years =
    List.range 0 24


tenureImpact : Test
tenureImpact =
    let
        tenureTest : Role -> Country -> Int -> Test
        tenureTest role country tenure =
            let
                title =
                    String.join " "
                        [ role.name
                        , "living in"
                        , country.name
                        , "with tenure of"
                        , String.fromInt tenure
                        , "earns more than with tenure of"
                        , String.fromInt (tenure - 1)
                        ]
            in
            test title
                (\_ ->
                    Expect.greaterThan
                        (Salary.calculate role country tenure)
                        (Salary.calculate role country tenure + 1)
                )
    in
    describe "Longer tenure always results in higher salary" <|
        List.lift3 tenureTest roles countries years


countryImpact : Test
countryImpact =
    let
        personaSuit : ( Role, Int ) -> Test
        personaSuit ( role, tenure ) =
            let
                title =
                    [ role.name
                    , "with a tenure of"
                    , String.fromInt tenure
                    , "years..."
                    ]
                        |> String.join " "
            in
            countries
                |> List.sortBy .compressed_cost_of_living
                |> List.reverse
                |> pairs
                |> List.map (countriesTest role tenure)
                |> describe title

        personas : List ( Role, Int )
        personas =
            List.lift2 Tuple.pair roles years

        countriesTest : Role -> Int -> ( Country, Country ) -> Test
        countriesTest role tenure ( a, b ) =
            let
                title =
                    [ "...living in"
                    , a.name
                    , "earns at least as much as if she would live in"
                    , b.name
                    ]
                        |> String.join " "
            in
            test title <|
                \() ->
                    Expect.atLeast
                        (Salary.calculate role a tenure)
                        (Salary.calculate role b tenure)
    in
    describe "Salaries are higher in more expensive countries" <|
        List.map personaSuit personas


{-| Helper that given a list of elements returns a list of tuples with two neighboring elements paired together

    pairs [ SanFrancisco, London, Netherlands, Germany ]
    --> [ ( SanFrancisco, London )
    --> , ( London, Netherlands )
    --> , ( Netherlands, Germany )
    --> ]

Used for comparing salaries in different countries.

-}
pairs : List a -> List ( a, a )
pairs list =
    case list of
        [] ->
            []

        a :: [] ->
            []

        a :: b :: rest ->
            ( a, b ) :: pairs (b :: rest)
