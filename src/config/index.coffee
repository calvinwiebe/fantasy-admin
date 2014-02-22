# Coffee configuration object.
#

module.exports =
    db:
        address: 'localhost'
        port: 28015
        adminDb:
            name: 'admin'
            tables: [
                'users'
            ]
        fantasyDb:
            name: 'fantasy'
