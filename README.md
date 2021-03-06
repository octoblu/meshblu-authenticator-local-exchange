# meshblu-authenticator-local-exchange

[![Build Status](https://travis-ci.org/octoblu/meshblu-authenticator-local-exchange.svg?branch=master)](https://travis-ci.org/octoblu/meshblu-authenticator-local-exchange)
[![Test Coverage](https://codecov.io/gh/octoblu/meshblu-authenticator-local-exchange/branch/master/graph/badge.svg)](https://codecov.io/gh/octoblu/meshblu-authenticator-local-exchange)
[![Dependency status](http://img.shields.io/david/octoblu/meshblu-authenticator-local-exchange.svg?style=flat)](https://david-dm.org/octoblu/meshblu-authenticator-local-exchange)
[![devDependency Status](http://img.shields.io/david/dev/octoblu/meshblu-authenticator-local-exchange.svg?style=flat)](https://david-dm.org/octoblu/meshblu-authenticator-local-exchange#info=devDependencies)
[![Slack Status](http://community-slack.octoblu.com/badge.svg)](http://community-slack.octoblu.com)

[![NPM](https://nodei.co/npm/meshblu-authenticator-local-exchange.svg?style=flat)](https://npmjs.org/package/meshblu-authenticator-local-exchange)
[![Dependency status](http://img.shields.io/david/octoblu/meshblu-authenticator-local-exchange.svg?style=flat)](https://david-dm.org/octoblu/meshblu-authenticator-local-exchange)


[![Dependency status](http://img.shields.io/david/octoblu/meshblu-authenticator-local-exchange.svg?style=flat)](https://david-dm.org/octoblu/meshblu-authenticator-local-exchange)


# Table of Contents

* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [Install](#install)
* [Usage](#usage)
  * [Default](#default)
  * [Docker](#docker)
    * [Development](#development)
    * [Production](#production)
  * [Debugging](#debugging)
  * [Test](#test)
* [License](#license)

# Introduction

...

# Getting Started

## Install

```bash
git clone https://github.com/octoblu/meshblu-authenticator-local-exchange.git
cd /path/to/meshblu-authenticator-local-exchange
npm install
```

# Usage

## Default

```javascript
node command.js
```

## Docker 

### Development

```bash
docker build -t local/meshblu-authenticator-local-exchange .
docker run --rm -it --name meshblu-authenticator-local-exchange-local -p 8888:80 local/meshblu-authenticator-local-exchange
```

### Production

```bash
docker pull quay.io/octoblu/meshblu-authenticator-local-exchange
docker run --rm -p 8888:80 quay.io/octoblu/meshblu-authenticator-local-exchange
```

## Debugging

```bash
env DEBUG='meshblu-authenticator-local-exchange*' node command.js
```

```bash
env DEBUG='meshblu-authenticator-local-exchange*' node command.js
```

## Test 

```bash
npm test
```

## License

The MIT License (MIT)

Copyright (c) 2016 Octoblu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
