class AddStatus < ActiveRecord::Migration
  def change
    add_column :vimsqueries, :status, :string, :default => 'waiting'
  end
end
