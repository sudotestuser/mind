class Point.NewComponent extends UIComponent
  @register 'Point.NewComponent'

  onCreated: ->
    super

    @canNew = new ComputedField =>
      User.hasPermission User.PERMISSIONS.POINT_NEW

  currentDiscussionId: ->
    @ancestorComponent(Point.ListComponent)?.currentDiscussionId()

  events: ->
    super.concat
      'submit .point-new': @onSubmit

  onSubmit: (event) ->
    event.preventDefault()

    # TODO: We cannot use required for body input with trix.
    unless @hasBody()
      # TODO: Use flash messages.
      alert "Point is required."
      return

    category = @$('[name="category"]:checked').val()

    unless category
      # TODO: We cannot use required for radio input with Materialize.
      #       See https://github.com/Dogfalo/materialize/issues/2187
      # TODO: Use flash messages.
      alert "Category is required."
      return

    Meteor.call 'Point.new',
      body: @$('[name="body"]').val()
      category: category
      discussion:
        _id: @currentDiscussionId()
    ,
      (error, documentId) =>
        if error
          console.error "New point error", error
          alert "New point error: #{error.reason or error}"
          return

        event.target.reset()

  categories: ->
    for category, value of Point.CATEGORY
      category: value
      # TODO: Make translatable.
      label: _.capitalize category.replace('_', ' ')

  categoryColumns: ->
    "s#{Math.floor(12 / _.size(Point.CATEGORY))}"

  hasBody: ->
    # We require body to have at least some text content or a figure.
    $body = $($.parseHTML(@$('[name="body"]').val()))
    $body.text() or $body.has('figure').length
