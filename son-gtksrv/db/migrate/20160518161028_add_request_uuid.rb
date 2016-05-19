class AddRequestUuid < ActiveRecord::Migration
  def change
    add_column :requests, :request_uuid, :uuid
  end
end
