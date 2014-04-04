Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
templates   = rfolder '../templates', extensions: [ '.jade' ]
{GenericView, genericRender, Cleanup} = require 'views'
utils = require 'utils'
{PoolModel, UserCollection,
UserModel, CategoriesCollection,
RoundsCollection, SeriesCollection,
TeamsCollection} \
= require '../models/index.coffee'
viewConfig = require './viewConfig.coffee'
View = Backbone.View.extend.bind Backbone.View
# Form for editing an existing pool
#
exports.EditPoolFormView = View
    template: templates.editFormTemplate
    id: 'edit-pool-form'

    events:
        'click #save-pool' : 'save'

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []
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
    save: (e) ->
        e.preventDefault()
        participants = @participantsView.collection
        categories = @categoryView.collection
        savePool = =>
            pids = participants.map (p) -> p.get('id')
            cids = categories.map (c) -> c.get('id')
            @model.set users: pids, categories: cids
            @model.save {},
                success: -> alert('pool saved.')
                error: -> alert('error saving.')
        asink.each participants.models,
            (model, cb) =>
                model.save {},
                    success: -> cb()
                    error: -> alert('error saving.')
            , (err) -> savePool()

        false

    render: ->
        @undelegateEvents()
        genericRender.call this
        @cleanUp()
        @$('#participants').append @participantsView.render().el
        @$('#categories').append @categoryView.render().el
        @$('#edit-palette').append @roundsSeriesContainerView.render().el
        @delegateEvents()
        this

# Particpants
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

views = {}

views.SeriesEditItem = View
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
        @model.save {}, success: => alert 'series saved'
        false

    dismiss: (e) ->
        e.preventDefault()
        @trigger 'action', {
            event: 'clearSingleSeries',
            context:
                round: @context.round
        }
        false

    edit: (e) ->
        e.preventDefault()
        @trigger 'goto', page: 'editSeries'
        false

    getTemplateData: ->
        console.log @model
        series: @model.toJSON()
        teams: _.map(@collection.where(conference: @model.get 'conference' ), (model) -> model.toJSON())

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

views.SeriesListView = View
    template: templates.seriesListView
    id: 'series-list-view'
    tagName: 'div'

    events:
        'click .back': 'dismiss'

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
            event: 'clearSeries',
            context:
                round: @context.round
        }
        false

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
                    @trigger 'action', {
                        event: 'editSingleSeries',
                        context:
                            round: @context.round
                            series: model
                            teams: @teams
                    }
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
        #adminClient.resources.rounds.sendAction()
        false

    setDeadline: (e) ->
        return if @model.get('disabled') or not e.date?
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
        return @disable() if @model.get('disabled')
        @$('.input-group.date')
            .datepicker({})
            .datepicker('setValue', @model.get('date'))
            .on 'changeDate', @setDeadline.bind(this)
        @$('.round-action').html if @model.get('state') is 0 then 'START' else 'END'


views.RoundsView = View
    template: templates.roundsView

    events:
        'click #save-rounds': 'save'

    initialize: ({@pool}) ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @needsData = true
        @collection = new RoundsCollection pool: @pool.get('id')
        @collection.fetch success: =>
            @needsData = false
            @render()

    save: (e) ->
        e.preventDefault()
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
                        event: 'editSeries'
                        context:
                            round: model
                    }
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

# This will swap between Rounds, Series and Single Series
# views.
#
RoundsSeriesContainer = View
    template: templates.roundsContainer

    initialize: ->
        _.extend this, Cleanup.mixin
        @_ = viewConfig
        @childViews = []
        @viewClass = @_.defaults.view
        @title = @_.defaults.title

    renderContent: (context) ->
        options =
            pool: @model
            context: context
        view = new views[@viewClass] options
        @childViews.push view
        @listenTo view, 'action', @handleContentViewAction
        @$el.append view.render().el

    handleContentViewAction: (data) ->
        @viewClass = @_.events[data.event]
        @title = @_.titles[@viewClass]
        @render data.context

    render: (context) ->
        @undelegateEvents
        @cleanUp()
        @$el.empty()
        @$el.append @template { @title }
        @renderContent context
        @delegateEvents()
        this
