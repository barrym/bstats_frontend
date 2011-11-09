Install node and npm

brew install node

Follow instructions at http://npmjs.org/

# Production

npm install

cake build

NODE_ENV=production node server.js

or

cake server:start

# Dev

bundle

npm install -g coffee-script

npm install -g node-dev

npm install

foreman start
