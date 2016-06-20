class CreateRequests < ActiveRecord::Migration
  def change
    create_table :vimsqueries, id: :uuid  do |t|
      t.timestamps
     end
  end
end
