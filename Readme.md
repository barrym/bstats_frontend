npm install -g coffee-script

npm install

coffee -c public/\*/\*.coffee

node server.js

# Dev

npm install coffeescript-growl

npm install node-dev

coffee -r coffeescript-growl -b -c -w public/\*/\*.coffee

node-dev server.js
