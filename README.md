[![CircleCI](https://circleci.com/gh/niteoweb/salarycalc.svg?style=svg)](https://circleci.com/gh/niteoweb/salarycalc)
[![Netlify Status](https://api.netlify.com/api/v1/badges/cccd17ab-57b5-48f2-8f5d-203432b99502/deploy-status)](https://app.netlify.com/sites/salarycalculator/deploys)

# Niteo Salary Calculator

A web app to calculate a salary of a [Niteo](https://niteo.co/) employee. Written in [Elm programming language](https://elm-lang.org/) it runs entirely on the client side.

## Installation

```shell
npm install salary-calculator
```

## Usage

There are several scenarios. Pick the one that suits you the best.

### Serve from a sub-directory

Assuming you have a website at `https://example.com/` with content served from the `public/` directory and want the calculator to be available at `https://example.com/salary-calculator/`, the easiest way is to copy (or link) the `dist` directory, like this: 

```shell
cp -r node_modules/salary-calculator/dist/ public/salary-calculator
```

### Embedding in custom HTML document

If you want to customize the stylesheet or want to embed it in your own HTML page, the easiest way is again to copy the `dist/` directory and then use a `<script>` tag to import the `dist/salary-calculator.js` script. It exposes a global variable `SalaryCalculator` referencing the object with `init` method. This method takes a single argument - an HTML node where the app should be mounted. You also have to provide a Bootstrap compatible stylesheet. The complete HTML can look like this:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width">
    <title>Salary Calculator custom integration</title>
    <link 
      href="https://stackpath.bootstrapcdn.com/bootswatch/4.3.1/darkly/bootstrap.min.css"
      rel="stylesheet"
      integrity="sha384-w+8Gqjk9Cuo6XH9HKHG5t5I1VR4YBNdPt/29vwgfZR485eoEJZ8rJRbm3TR32P6k"
      crossorigin="anonymous"
    >
    <script src="salary-calculator/salary-calculator.js" charset="utf-8">
    </script>
  </head>
  <body>
    <div id="salary-calculator-container">
    </div> 
    <script charset="utf-8">
      SalaryCalculator.init(
        document.getElementById("salary-calculator-container")
      )
    </script>
  </body>
</html>
```

### Using CommonJS or ES6 modules

You can also use it as a CommonJS module:

```js
const SalaryCalculator = require("salary-calculator");
```

or ES6:


```js
import * as SalaryCalculator from "salary-calculator"
```

This way it won't set any globals. The variable will be scoped to the module. Also you don't need to copy anything - just install and import. Otherwise it works the same as the HTML `script` tag.

## What is the purpose of this project?

At Niteo we believe in [open and fair way of doing business](https://niteo.co/about). That's why the salary system is completely transparent. Using this app you can see who earns how much and why. We hope other companies can use it for the same purpose.

## Hacking

Contributions are welcome.

### Prerequisites

- Git
- GNU Make, 
- Node.js (preferabely v. 11)

### Local development

1.  `git clone git@github.com:niteoweb/salarycalc.git && cd salarycalc`

1.  To start development server with hot reloading run `make run`

    This command should also install all the requirements. 

1.  When you are happy with your code, run `make` to compile a production-optimized code in `dist/` directory.

    It will also run tests (with coverage analysis) and linters.

### Contributing

Thanks for your interest in our project. We are open to learn about any issues and for your pull requests.

