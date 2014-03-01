# Config cson to list the particular views should be
# added to the DashboardView.

module.exports =
    sidebar: [
        'PoolListView'
    ]

    actionArea:
        default: 'DefaultView'
        events:
            'newPool': 'CreatePoolFormView'
            'viewPool': 'ViewPoolView'
            'editPool': 'EditPoolFormView'
