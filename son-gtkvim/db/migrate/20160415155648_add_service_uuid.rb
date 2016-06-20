class AddServiceUuid < ActiveRecord::Migration
  def change
    add_column :vimsqueries, :query_uuid, :uuid
  end
end
