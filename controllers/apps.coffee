exports.index = (req, res) ->
    apps = [
        {name:'buzzard'},
        {name:'falcon'}
    ]
    res.send(apps)

exports.new = (req, res) ->
      res.send('new app')

exports.create = (req, res) ->
      res.send('create app')

exports.show = (req, res) ->
      res.send('show app ' + req.params.app)

exports.edit = (req, res) ->
      res.send('edit app ' + req.params.app)

exports.update = (req, res) ->
      res.send('update app ' + req.params.app)

exports.destroy = (req, res) ->
      res.send('destroy app ' + req.params.app)
