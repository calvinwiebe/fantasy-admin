# Compile the data for a `New Pick` email
#
async       = require 'async'
config      = require '../../../config'
poolUtils   = require '../../../models/poolUtils'
{rethink}   = require '../../../lib'
_           = require 'lodash'

uuidRegex = '^[0-9a-f]{22}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

# Maps of category names, whose values will be a rethink id, to the table the
# id should query on
#
idMap =
    'Series Winner': 'teams'

# Get the categories for the table headings
#
getCategories = ({conn, r, pool}, done) ->
    r.table('categories')
    .filter((category) ->
        r.table('pools').get(pool.id)('categories').contains(category('id'))
    )
    .orderBy('name')
    .coerceTo('array')
    .run conn, (err, categories) ->
        done err, categories

# Get all the picks for the user in the current round
#
getPicks = ({conn, r, pool, round, user}, done) ->
    r.table("picks").filter(
        round: round
        user: user
    ).eqJoin("category", r.table("categories"))
    .map((doc) ->
        category: doc('right')('name')
        series: doc('left')('series')
        round: doc('left')('round')
        id: doc('left')('id')
        value: doc('left')('value')
        user: doc('left')('user')
    )
    .eqJoin("series", r.table("series"))
    .without(
        right:
            conference: true
            id: true
            numberOfGames: true
            state: true
    ).zip().eqJoin("team1", r.table("teams"))
    .map((doc) ->
        category: doc('left')('category')
        series: doc('left')('series')
        round: doc('left')('round')
        id: doc('left')('id')
        value: doc('left')('value')
        user: doc('left')('user')
        team1: doc('right')('name')
        team2: doc('left')('team2')
    )
    .eqJoin("team2", r.table("teams"))
    .map((doc) ->
        category: doc('left')('category')
        series: doc('left')('series')
        round: doc('left')('round')
        id: doc('left')('id')
        value: doc('left')('value')
        user: doc('left')('user')
        team1: doc('left')('team1')
        team2: doc('right')('name')
    )
    .eqJoin("user", r.table("users"))
    .map((doc) ->
        category: doc('left')('category')
        series: doc('left')('series')
        round: doc('left')('round')
        id: doc('left')('id')
        value: doc('left')('value')
        team1: doc('left')('team1')
        team2: doc('left')('team2')
        user: doc('right')('email')
    )
    .eqJoin("round", r.table("rounds"))
    .map((doc) ->
        category: doc('left')('category')
        series: doc('left')('series')
        id: doc('left')('id')
        value: doc('left')('value')
        team1: doc('left')('team1')
        team2: doc('left')('team2')
        user: doc('left')('user')
        round: doc('right')('name')
        seriesName: doc('left')('team1').coerceTo('string').add(' vs ').add(doc('left')('team2').coerceTo('string'))
    )
    # if the `value` field is a `uuid`, then attempt to join it
    .map((doc) ->
        r.branch \
            doc('value').coerceTo('string').match(uuidRegex), {
                category: doc('category')
                series: doc('series')
                id: doc('id')
                team1: doc('team1')
                team2: doc('team2')
                user: doc('user')
                round: doc('round')
                seriesName: doc('seriesName')
                value: r.table(r.expr(idMap)(doc('category'))).get(doc('value'))('name')
            }, {
                category: doc('category')
                series: doc('series')
                id: doc('id')
                team1: doc('team1')
                team2: doc('team2')
                user: doc('user')
                round: doc('round')
                seriesName: doc('seriesName')
                value: doc('value')
            }
    )
    .coerceTo('array')
    .run conn, (err, results) ->
        return done err, results

# Take an array of populated picks, and group them by series
#
compilePicks = ({picks, user}) ->
    picks = _.chain(picks)
        .groupBy('seriesName')
        .forEach((seriesPicks, key, object) ->
            object[key] = _.sortBy seriesPicks, 'category'
        ).value()
    picks

# The main handling export
#
module.exports = (data, done) ->
    async.waterfall [
        # get a rethink connection
        (cb) -> rethink.getConnection cb
        # get the pool
        ({conn, r}, cb) -> poolUtils.filter
            context: {conn, r}
            filter: (doc) ->
                doc('rounds').contains(data.round)
            cb: (err, [pool]) ->
                cb err, {conn, r, pool}
        # get the categories for the table headings
        ({conn, r, pool}, cb) -> getCategories {conn, r, pool}, (err, categories) ->
            cb err, {conn, r, pool, categories}
        # TODO: get all the admin users
        # get the picks for the user in this round
        ({conn, r, pool, categories}, cb) -> getPicks {conn, r, pool, round: data.round, user: data.user}, (err, picks) ->
            cb err, {conn, r, picks, user: picks?[0]?.user, categories}
        ({conn, r, picks, user, categories}, cb) ->
            picks = compilePicks {picks, user}
            cb null, {picks, user, categories}
    ], (err, results={}) ->
        return done err, results if err
        {picks, user, categories} = results
        done null,
            recipients: config.email.subscriptions.newPicks
            locals: { picks, categories, user, round: _.values(picks)[0][0].round }
            subject: "A new set of picks have been made!"
