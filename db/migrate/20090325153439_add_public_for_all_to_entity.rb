class AddPublicForAllToEntity < ActiveRecord::Migration
  def self.up
    add_column :entities, :public_to_all, :boolean
    ActiveRecord::Base.connection.execute("update entities set public_to_all='f'")
  end

  def self.down
    remove_column :entities, :public_to_all
  end
end
