# Config cson to list the particular views should be
# added to the DashboardView.

module.exports =
    sidebar:
        views: [
            'PoolListView'
        ]
        events:
            'editSeries'   : 'EditSeriesFormView'
            'newPool'   : 'CreatePoolFormView'
            'editPool'  : 'EditPoolFormView'
            'default'   : 'DefaultView'

    actionArea:
        default: 'DefaultView'
