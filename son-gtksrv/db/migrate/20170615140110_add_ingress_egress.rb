class AddIngressEgress < ActiveRecord::Migration
  def change
    add_column :requests, :ingress, :string
    add_column :requests, :egress, :string
  end
end
