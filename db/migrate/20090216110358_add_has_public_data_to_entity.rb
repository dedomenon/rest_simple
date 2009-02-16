class AddHasPublicDataToEntity < ActiveRecord::Migration
  def self.up
    add_column :entities, :has_public_data, :boolean
    ActiveRecord::Base.connection.execute("update entities set has_public_data='f'")
  end

  def self.down
    remove_column :entities, :has_public_data
  end
end
