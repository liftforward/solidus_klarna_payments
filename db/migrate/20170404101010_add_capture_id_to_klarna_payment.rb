class AddCaptureIdToKlarnaPayment < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_klarna_credit_payments, :capture_id, :string
  end
end
