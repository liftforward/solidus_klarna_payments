module Spree
  class LineItemSerializer
    attr_reader :line_item

    def initialize(line_item)
      @line_item = line_item
    end

    # TODO: clarify what amounts exactly should be used
    def to_hash
      {
        reference: line_item.sku,
        name: line_item.name,
        quantity: line_item.quantity,
        # Minor units. Includes tax, excludes discount.
        unit_price: unit_price,
        # tax rate, e.g. 500 for 5.00%
        tax_rate: line_item_tax_rate,
        # Includes tax and discount. Must match (quantity * unit_price) - total_discount_amount within ±quantity
        total_amount: total_amount,
        # Must be within ±1 of total_amount - total_amount * 10000 / (10000 + tax_rate). Negative when type is discount
        total_tax_amount: total_tax_amount
      }
    end

    private

    def line_item_tax_rate
      # TODO: should we just calculate this?
      tax_rate = line_item.adjustments.tax.inject(0) { |total, tax| total + tax.source.amount }
      (10000 * tax_rate).to_i
    end

    def total_amount
      line_item.display_final_amount.cents
    end

    def total_tax_amount
      total_amount - line_item.display_pre_tax_amount.cents
    end

    def unit_price
      line_item.display_price.cents + (total_tax_amount / line_item.quantity).floor
    end
  end
end
