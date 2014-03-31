Backbone    = require 'backbone'
Backbone.$  = window.$
_           = require 'lodash'
asink       = require 'asink'
templates   = rfolder '../templates', extensions: [ '.jade' ]
{GenericView, genericRender, Cleanup} = require 'views'
utils = require 'utils'
{PoolModel, UserCollection, UserModel, CategoriesCollection, RoundsCollection} \
= require '../models/index.coffee'
View = Backbone.View.extend.bind Backbone.View
# Form for editing an existing pool
#
exports.EditPoolFormView = View
    template: templates.editFormTemplate
    id: 'edit-pool-form'

    events:
        'click #save'    : 'save'

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @participantsView = new ParticipantsView { @model }
        @categoryView = new CategoryView { @model }
        @roundsView = new RoundsView { @model }
        @childViews.push @participantsView
        @childViews.push @categoryView
        @childViews.push @roundsView

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
        rounds = @roundsView.collection
        adjacentModels = _.union(participants.models, rounds.models)
        savePool = =>
            pids = participants.map (p) -> p.get('id')
            cids = categories.map (c) -> c.get('id')
            @model.set users: pids, categories: cids
            @model.save({}, success: -> alert('pool saved.'))
        asink.each adjacentModels,
            (model, cb) =>
                model.save({}, success: -> cb())
            , (err) -> savePool()

        false

    render: ->
        @undelegateEvents()
        genericRender.call this
        @cleanUp()
        @$('#participants').append @participantsView.render().el
        @$('#categories').append @categoryView.render().el
        @$('#rounds').append @roundsView.render().el
        @delegateEvents()
        this

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

RoundsView = View
    template: templates.roundsView

    initialize: ->
        _.extend this, Cleanup.mixin
        @childViews = []
        @needsData = true
        @collection = new RoundsCollection pool: @model.get('id')
        @collection.fetch success: =>
            @needsData = false
            @render()

    renderRounds: ->
        @childViews = _.chain(@collection.models)
            .map((model) =>
                view = new RoundListItem { model }
                @listenTo view, 'edit', @editRound
                view
            ).forEach((view) =>
                @$('#rounds').append view.render().el
            ).value()
        this

    editRound: (model) ->
        console.log 'Go to edit round page'

    render: ->
        return this if @needsData
        @undelegateEvents
        @$el.empty()
        @$el.append @template @model
        @cleanUp()
        @renderRounds()
        @delegateEvents()
        this

RoundListItem = View
    template: templates.roundListItem
    className: '.round-list-item'
    tagName: 'div'

    events:
        'click button' : 'roundSelected'

    roundSelected: (e) ->
        e.preventDefault()
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




