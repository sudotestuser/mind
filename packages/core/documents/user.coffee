class User extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last user app activity (login, password change, authored anything, voted on anything, etc.)
  # username: user's username
  # emails: list of
  #   address: e-mail address
  #   verified: is e-mail address verified
  # services: list of authentication/linked services
  # roles: list of roles names (strings) this user is part of
  # avatar: avatar filename

  @Meta
    name: 'User'
    collection: Meteor.users
    fields: =>
      avatar: @GeneratedField 'self', ['avatar', 'username'], (fields) =>
        # TODO: Allow custom avatars.
        #return [] if fields.avatar

        # "i" suffix for initials.
        avatarFilename = "avatar/#{fields._id}-i.svg"
        Storage.save avatarFilename, @generateAvatar fields.username
        # Attach a query string to force reactive client-side update.
        [fields._id, "#{avatarFilename}?#{Random.id()}"]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['username', 'emails']
      lastActivity: share.LastActivityTrigger ['services']

  @REFERENCE_FIELDS: ->
    _id: 1
    username: 1
    avatar: 1

  @EXTRA_PUBLISH_FIELDS: ->
    _id: 1
    avatar: 1

  # Copied from: https://github.com/RocketChat/Rocket.Chat/blob/master/server/startup/avatar.coffee
  @generateAvatar: (username="") ->
    colors = ['#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39', '#FFC107', '#FF9800', '#FF5722', '#795548', '#9E9E9E', '#607D8B']

    position = username.length % colors.length
    color = colors[position]
    # TODO: Use slugify2.
    username = username.replace(/[^A-Za-z0-9]/g, '.').replace(/\.+/g, '.').replace(/(^\.)|(\.$)/g, '')
    usernameParts = username.split('.')
    if usernameParts.length > 1
      initials = _.first(usernameParts)[0] + _.last(usernameParts)[0]
    else
      initials = username.replace(/[^A-Za-z0-9]/g, '').substr(0, 2)
    initials = initials.toUpperCase()

    initials ||= "?"

    """
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <svg xmlns="http://www.w3.org/2000/svg" pointer-events="none" width="50" height="50" style="width: 50px; height: 50px; background-color: #{color};">
      <text text-anchor="middle" y="50%" x="50%" dy="0.36em" pointer-events="auto" fill="#ffffff" font-family="Helvetica, Arial, Lucida Grande, sans-serif" style="font-weight: 400; font-size: 28px;">
        #{initials}
      </text>
    </svg>
    """

  getReference: ->
    _.pick @, _.keys @constructor.REFERENCE_FIELDS()

Meteor.user = (userId, fields) ->
  if not fields and _.isObject userId
    fields = userId
    userId = null

  # Meteor.userId is reactive
  userId ?= Meteor.userId()
  fields ?= {}

  return null unless userId

  User.documents.findOne
    _id: userId
  ,
    fields: fields

# Forbid users from making any modifications to their user document.
User.Meta.collection.deny
  update: ->
    true

if Meteor.isServer
  User.Meta.collection._ensureIndex
    createdAt: 1

  User.Meta.collection._ensureIndex
    updatedAt: 1

  User.Meta.collection._ensureIndex
    lastActivity: 1

  User.Meta.collection._ensureIndex
    roles: 1
