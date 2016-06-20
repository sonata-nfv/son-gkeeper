class AddStatus < ActiveRecord::Migration
  def change
    add_column :vimsqueries, :query_response, :json, :default => 'waiting'
  end
end
