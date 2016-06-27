class AddQueryResponse < ActiveRecord::Migration
  def change
    add_column :vims_requests, :query_response, :json, :default => 'waiting'
  end
end
