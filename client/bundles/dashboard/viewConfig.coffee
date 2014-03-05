# Config cson to list the particular views should be
# added to the DashboardView.

messages =
    poolCreated:
        title: 'Success!'
        msg: """
            Your pool has been created. It can be found on the left side bar. By clicking
            on the newly created pool you can edit and add properties to it.
        """

module.exports =
    sidebar:
        views: [
            'PoolListView'
        ]
        events:
            'newPool'   : 'CreatePoolFormView'
            'viewPool'  : 'ViewPoolView'
            'editPool'  : 'EditPoolFormView'
            'default'   : 'DefaultView'

    actionArea:
        default: 'DefaultView'
        events:
            'successPoolCreate':
                view: 'MessageView'
                msg: messages.poolCreated
