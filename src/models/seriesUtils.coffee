exports.create = (conn, r, numberOfGames, cb) ->
    doc =
        teams: []
        numberOfGames: numberOfGames

    r.table('series').insert(doc).run conn, (err, results) ->
        cb results.generated_keys[0]