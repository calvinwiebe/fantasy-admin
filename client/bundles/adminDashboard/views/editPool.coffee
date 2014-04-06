Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
templates   = rfolder '../templates', extensions: [ '.jade' ]
{GenericView, genericRender, Cleanup, Swapper} = require 'views'
utils = require 'utils'
{PoolModel, UserCollection,
UserModel, CategoriesCollection,
RoundsCollection, SeriesCollection,
TeamsCollection} \
= require 'models'
View = Backbone.View.extend.bind Backbone.View
# Form for editing an existing pool
#
exports.EditPoolFormView = View
    template: templates.editPoolFormTemplate
    id: 'edit-pool-form'

    events:
        'click #save-pool' : 'save'
        'click #start-pool' : 'start'

    initialize: ({@context}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @model = @context.model
        @participantsView = new ParticipantsView { @model }
        @categoryView = new CategoryView { @model }
        @roundsSeriesContainerView = new RoundsSeriesContainer { @model }
        @childViews.push @participantsView
        @childViews.push @categoryView
        @childViews.push @roundsSeriesContainerView

    # retrieve all of our sub collection/models from
    # our childViews, and persist them to the server.
    #
    # participants: if a participant model does not have an id, it is new.
    # In this case we sent it to the server to be created. We should also then
    # resync the pool, as it will have a new user attached to it.
    #
    save: (e, onSaved) ->
        e?.preventDefault()
        participants = @participantsView.collection
        categories = @categoryView.collection
        
        savePool = =>
            pids = participants.map (p) -> p.get('id')
            cids = categories.map (c) -> c.get('id')
            @model.set users: pids, categories: cids
            @model.save {},
                success: -> (onSaved ?= -> alert('pool saved.'))()
                error: -> alert('error saving.')
        asink.each participants.models,
            (model, cb) =>
                model.save {},
                    success: -> cb()
                    error: -> alert('error saving.')
            , (err) -> savePool()
        false

    start: (e) ->
        e?.preventDefault()
        @model.set 'state', 1
        @save e, =>
            @render()

    render: ->
        @undelegateEvents()
        genericRender.call this
        @cleanUp()
        @$('#participants').append @participantsView.render().el
        @$('#categories').append @categoryView.render().el
        @$('#edit-palette').append @roundsSeriesContainerView.render().el
        @delegateEvents()
        this

# Participants
# -----------

ParticipantsView = View

    events:
        'click #users-list'     : 'showEditUsers'
        'click .check-button'   : 'showUserList'

    initialize: (users=[]) ->
        @isEditing = false
        _.extend this, Cleanup.mixin
        @collection = new UserCollection pool: @model.get('id')
        @collection.fetch success: => @render()
        @childViews = []

    showEditUsers: ->
        @isEditing = true
        @render()

    showUserList: (e) ->
        e.preventDefault()
        users = _.chain(@childViews)
            .map((c) -> c.model)
            .filter((m) -> m?.get('email'))
            .value()
        @collection.set users
        @isEditing = false
        @render()
        false

    newUser: (user) ->
        @collection.add user
        @render()

    renderCurrentView: ->
        if !@isEditing
            @childViews.push new ParticipantsListView { @collection }
        else
            if @collection.length
                @childViews = @collection.map (user) =>
                    new ParticipantView model: user
            else
                @collection.reset()
            empty = new ParticipantView model: new UserModel {email:''}
            @childViews.push empty
            @childViews.push new GenericView template: templates.glyphOk
        @childViews.forEach (v) =>
            @listenTo v, 'new', @newUser
            @$el.append v.render().el
        if empty?
            empty.$el.find('input').focus()

    render: ->
        @undelegateEvents()
        @$el.empty()
        @cleanUp()
        @renderCurrentView()
        @delegateEvents()
        this

ParticipantsListView = View
    template: templates.participants_
    render: genericRender

ParticipantView = View
    template: templates.participant_

    events:
        'keypress .user-input'  : 'keyPress'
        'blur .user-input'      : 'blur'

    blur: (e) ->
        email = @$('input').val()
        @model.set { email }

    keyPress: (e) ->
        email = @$('input').val()
        return if e.keyCode isnt 13 or _.isEmpty email
        @model.set { email }
        @trigger 'new', @model
        e.preventDefault()
        false

    render: genericRender

# Categories
# ----------

CategoryView = View

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @categories = []
        @collection = new CategoriesCollection
        @selectionView = null
        @needsData = true
        @categoryList = new CategoriesCollection
        @categoryList.fetch success: =>
            @needsData = false
            @collection.set (@model.get('categories') ? []).map (c) =>
                _.find @categoryList.models, attributes: id: c
            @render()

    addCategory: (model) ->
        @collection.add model
        @render(false, categories: true)

    renderCategories: ->
        @categories.forEach (c) =>
            @stopListening c
            c.remove()
        @categories?.length = 0
        if @collection.length
            @categories = @collection.map (category) =>
                new CategoryItemView model: category
        else
            @collection.reset()
        @categories.forEach (v) =>
            @$el.append v.render().el
        @childView = @childViews.concat @categories
        this

    renderSelection: ->
        return this if @needsData
        @stopListening @selectionView
        @selectionView?.remove()
        @selectionView = new CategorySelectionView collection: @categoryList
        @listenTo @selectionView, 'add', @addCategory
        @$el.append @selectionView.render().el
        @childViews.push @selectionView
        this

    render: (full=true, renders={}) ->
        @undelegateEvents()
        @$el.empty() if full
        @renderSelection() if renders.selection or full
        @renderCategories() if renders.categories or full
        @delegateEvents()
        this

CategorySelectionView = View
    template: templates.categorySelectionSelect
    id: 'category-select'

    events:
        'change select' : 'selectChange'
        'click #add'    : 'add'

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []

    selectChange: (e) ->
        @selection = _.find @collection.models,
            attributes: id: @$('select').val()

    add: (e) ->
        e.preventDefault()
        @trigger 'add', @selection
        false

    render: ->
        @undelegateEvents()
        @$el.empty()
        @cleanUp()
        genericRender.call this
        @$('select').val @$('select').val() or @collection.models[0].get('id')
        @selectChange()
        @delegateEvents()
        this

CategoryItemView = View
    template: templates.categoryItem
    className: 'label label-default'

    render: genericRender

# Rounds And Series
# -----------------

SeriesEditItem = View
    template: templates.seriesEditItem
    className: 'series-edit-item'
    tagName: 'div'

    events:
        'click .back'       : 'dismiss'
        'click .edit'       : 'edit'
        'click .quick-save' : 'quickSave'

    initialize: ({@context}) ->
        # TODO: we should only allow the selection of teams that are not assigned
        # thus far.
        @model = @context.series
        @collection = @context.teams

    quickSave: (e) ->
        e.preventDefault()
        @model.set 'team1', @$('.team1').val()
        @model.set 'team2', @$('.team2').val()
        @model.save {}, success: => @dismiss e
        false

    dismiss: (e) ->
        e.preventDefault()
        @trigger 'action', {
            state: 'seriesList',
            context:
                round: @context.round
        }
        false

    getTemplateData: ->
        conference = @model.get('conference')
        if conference is -1 then teams = @collection.toJSON()
        else teams = _.map(@collection.where(conference: conference ), (model) -> model.toJSON())

        series: @model.toJSON()
        teams: teams

    render: ->
        @undelegateEvents
        @$el.empty()
        @$el.append @template @getTemplateData()
        @afterRender()
        @delegateEvents()
        this

    afterRender: ->
        if @model.get 'team1'
            @$('.team1').val @model.get 'team1'
        if @model.get 'team2'
            @$('.team2').val @model.get 'team2'

SeriesListItem = View
    template: templates.seriesListItem
    className: 'series-list-item'
    tagName: 'div'

    events:
        'click button'  : 'selected'

    selected: (e) ->
        e.preventDefault()
        @trigger 'selected', @model
        false

    render: genericRender

SeriesListView = View
    template: templates.seriesListView
    id: 'series-list-view'
    tagName: 'div'

    events:
        'click .back': 'dismiss'
        'click .lock-matchups': 'lockMatchups'

    initialize: ({@context}) ->
        _.extend this, Cleanup.mixin
        @needsData = true
        @collection = new SeriesCollection round: @context.round.get 'id'
        @collection.fetch success: =>
            @teams = new TeamsCollection league: 'nhl'
            @teams.fetch success: =>
                @needsData = false
                @mapTeamsOntoSeries()
                @render()

    dismiss: (e) ->
        e.preventDefault()
        @trigger 'action', {
            state: 'roundsList',
            context:
                round: @context.round
        }
        false

    lockMatchups: (e) ->
        e.preventDefault()

        ready = true
        @collection.forEach (model) ->
            ready = false if !model.get('team1')? and !model.get('team2')?

        if ready
            @context.round.set 'state', 2
            @context.round.save {},
                success: => @dismiss e
                error: -> alert 'error saving round'
        else
            alert 'finish setting your matchups'

    mapTeamsOntoSeries: ->
        @collection.forEach (model) =>
            team1 = @teams.find 'id': model.get 'team1'
            team2 = @teams.find 'id': model.get 'team2'
            model.set 'team1Name', '(' + team1.get('seed') + ') ' + team1.get('shortName') if team1?
            model.set 'team2Name', '(' + team2.get('seed') + ') ' + team2.get('shortName') if team2?

    renderSeries: ->
        @childViews = _.chain(@collection.models)
            .map((model) =>
                view = new SeriesListItem { model }
                @listenTo view, 'selected', =>
                    if @context.round.get('state') is 1
                        @trigger 'action', {
                            state: 'singleSeries',
                            context:
                                round: @context.round
                                series: model
                                teams: @teams
                        }
                    else
                        alert 'open series results page'
                view
            ).forEach((view) =>
                @$('#series-container').prepend view.render().el
            ).value()
        this

    render: ->
        return this if @needsData
        @undelegateEvents
        @$el.empty()
        @$el.append @template()
        @renderSeries()
        @delegateEvents()
        this

RoundListItem = View
    template: templates.roundListItem
    className: 'round-list-item'
    tagName: 'div'

    events:
        'click .round'          : 'emitSelected'
        'click .round-action'   : 'sendAction'

    emitSelected: (e) ->
        e.preventDefault()
        @trigger 'selected', @model
        false

    sendAction: (e) ->
        e.preventDefault()

        @model.set 'state', @model.get('state') + 1 #configured -> running, running -> finished
        @model.save {},
            success: =>
                @render()
                if @model.get('state') is 4
                    @trigger 'completed'
            error: -> alert('error saving round.')
        false

    setDeadline: (e) ->
        return if @model.get('state') is 1 or not e.date?
        @model.set 'date', e.date.valueOf()

    render: ->
        genericRender.call this
        @afterRender()
        this

    disable: ->
        @$('.input-group.date input').prop 'disabled', 'true'
        @$('.round').prop 'disabled', 'true'
        @$('.round-action').remove()

    afterRender: ->
        return @disable() if @model.get('state') is 0 or @model.get('state') is 4
        @$('.input-group.date')
            .datepicker({})
            .datepicker('setValue', @model.get('date'))
            .on 'changeDate', @setDeadline.bind(this)
        switch @model.get('state')
            when 1 #unconfigured
                @$('.round-action').remove()
            when 2 #configured
                @$('.round-action').html 'START'
             when 3 #running
                @$('.round-action').html 'END'


RoundsView = View
    template: templates.roundsView

    events:
        'click #save-rounds': 'save'

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @needsData = true
        @collection = new RoundsCollection pool: @model.get('id')
        @collection.fetch success: =>
            @needsData = false
            @render()

    save: (e) ->
        e?.preventDefault()
        asink.each @collection.models,
            (model, cb) =>
                model.save {},
                    success: -> cb()
                    error: -> alert('error saving round.')
            , (err) -> alert 'saved rounds'
        false

    renderRounds: ->
        @childViews = _.chain(@collection.models)
            .map((model) =>
                view = new RoundListItem { model }
                @listenTo view, 'selected', =>
                    @trigger 'action', {
                        state: 'seriesList'
                        context:
                            round: model
                    }
                @listenTo view, 'completed', => @roundComplete()
                view
            ).forEach((view) =>
                @$('#rounds-container').append view.render().el
            ).value()
        this

    render: ->
        return this if @needsData
        @undelegateEvents
        @$el.empty()
        @$el.append @template @model
        @cleanUp()
        @renderRounds()
        @delegateEvents()
        this

    roundComplete: ->
        nextRound = @collection.findWhere state: 0

        if nextRound
            nextRound.set 'state', 1
            @render()
            @save()
        else alert 'pool over man'

# This will swap between Rounds, Series and Single Series
# views.
#
RoundsSeriesContainer = Swapper
    template: templates.roundsContainer

    initialize: ->
        @configureSwap
            event: 'action'
            default: 'roundsList'
            map:
                'roundsList':
                    views: [ RoundsView ]
                    template:
                        title: 'Rounds'
                'seriesList':
                    views: [ SeriesListView ]
                    template:
                        title: 'Rounds > Series'
                'singleSeries':
                    views: [ SeriesEditItem ]
                    template:
                        title: 'Rounds > Series > Single Series'

    afterRender: ->
        @$('.title').html @getConfig().map[@state].template.title
