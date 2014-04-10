exports.create = (conn, r, numberOfGames, conference, cb) ->
    doc =
        numberOfGames: numberOfGames
        conference: conference
        state: 0

    r.table('series').insert(doc).run conn, (err, results) ->
        cb results.generated_keys[0]