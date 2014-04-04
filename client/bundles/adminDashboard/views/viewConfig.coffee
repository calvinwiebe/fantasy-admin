module.exports =
    defaults:
        view: 'RoundsView'
        title: 'Rounds'
    events:
        'editSeries'         : 'SeriesListView'
        'editSingleSeries'   : 'SeriesEditItem'
        'clearSingleSeries'  : 'SeriesListView'
        'clearSeries'        : 'RoundsView'
    titles:
        'RoundsView': 'Rounds'
        'SeriesListView': 'Rounds > Series'
        'SeriesEditItem': 'Rounds > Series > Single Series'
