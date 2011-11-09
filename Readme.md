# Installation

## Install Node JS:

    brew install node

## Install npm

Follow instructions at http://npmjs.org/

# All I want to do is run the app

    git clone http://github.com/barrym/bstats_frontend

    npm install

    node server.js

Then go to http://localhost:8888 in your browser.


# I want to run the app in production

    npm install

    NODE_ENV=production cake server:start

# I want to work on the code

    bundle

    npm install -g coffee-script

    npm install -g node-dev

    npm install

    foreman start
