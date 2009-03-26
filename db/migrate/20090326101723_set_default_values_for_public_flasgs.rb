class SetDefaultValuesForPublicFlasgs < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("alter table entities alter column public_to_all set default 'f' ")
    ActiveRecord::Base.connection.execute("alter table entities alter column has_public_data set default 'f' ")
  end

  def self.down
  end
end
