Push middleware
===============

To make incoming calls possible, you need to setup your own middleware. We use Asterisk servers as our PBX. The asterisk asks the middleware to push a message to the app. The app will ask the library to register an account. The app will then respond to the middleware when that is successful. The Asterisk will then try to connect to the app. More info on the middleware can be found the in the [Vialer Middleware](https://github.com/VoIPGRID/vialer-middleware) repo.
