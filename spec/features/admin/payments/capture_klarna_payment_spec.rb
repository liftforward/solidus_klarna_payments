require 'features_helper'

describe 'Managing a Klarna Payment', type: 'feature', bdd: true do
  include_context "ordering with klarna"
  include_context "change driver"
  include WorkflowDriver::Process

  it 'Captures a klarna payment' do
    klarna_order = order_on_state(product_name: 'Ruby on Rails Bag', state: :delivery, quantity: 1)

    on_the_payment_page do |page|
      page.load
      page.update_hosts
    end

    pay_with_klarna(testing_data: @testing_data)

    if KlarnaGateway.is_solidus?
      on_the_confirm_page do |page|
        expect(page.displayed?).to be(true)
      end
    else
      on_the_complete_page do |page|
        expect(page.displayed?).to be(true)
      end
    end

    expect(klarna_order.confirm?).to be(true)
    klarna_order.complete
    expect(klarna_order.complete?).to be(true)

    Capybara.current_session.driver.quit

    change_driver_to(:poltergeist) do
      on_the_admin_login_page do |page|
        page.load
        expect(page.displayed?).to be(true)

        page.login_with(TestData::AdminUser)
      end

      order = Spree::Order.complete.last

      on_the_admin_payments_page do |page|
        page.load(number: order.number)
        expect(page.displayed?).to be(true)

        expect(page.payments.first.is_klarna?).to be(true)
        expect(page.payments.first.is_pending?).to be(true)
        expect(page.payments.first.is_klarna_authorized?).to be(true)

        page.payments.first.capture!
        expect(page.payments.first.is_klarna_captured?).to be(true)
        expect(page.payments.first.is_completed?).to be(true)
        page.payments.first.identifier.find('a').click
      end

      on_the_admin_payment_page do |page|
        expect(page.displayed?).to be(true)
        page.payment_menu.logs.click
      end

      on_the_admin_logs_page do |page|
        expect(page.displayed?).to be(true)
        expect(page.log_entries.count).to eq(2)
        expect(page.log_entries.first.message.text).to have_content('Placed order')
        expect(page.log_entries.second.message.text).to have_content('Captured order')
      end
    end
  end
end
