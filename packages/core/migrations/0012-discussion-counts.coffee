# In fact it is a reverse field, not generated field.
class Migration extends Document.AddGeneratedFieldsMigration
  name: "Adding motions field"
  fields: ['motions', 'comments', 'points', 'motionsCount', 'commentsCount', 'pointsCount']

Discussion.addMigration new Migration()
