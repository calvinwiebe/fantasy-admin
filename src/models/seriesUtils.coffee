exports.create = (conn, r, numberOfGames, conference, cb) ->
    doc =
        numberOfGames: numberOfGames
        conference: conference

    r.table('series').insert(doc).run conn, (err, results) ->
        cb results.generated_keys[0]