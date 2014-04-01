exports.create = (conn, r, numberOfGames, cb) ->
    doc =
        teams: []
        numberOfGames: numberOfGames

    (index, done) ->
        r.table('series').insert(doc).run conn, (err, results) ->
            cb results.generated_keys[0]
            done()