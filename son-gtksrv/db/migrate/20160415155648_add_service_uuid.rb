class AddServiceUuid < ActiveRecord::Migration
  def change
    add_column :requests, :service_uuid, :uuid
  end
end
