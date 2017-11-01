require "spec_helper"

describe Spree::Klarna::CallbacksController do

  describe "#notification" do
    let(:order) { create(:order_with_line_items, state: "complete") }
    let(:payment_source) { create(:klarna_credit_payment, order_id: order_id, spree_order_id: order.id, fraud_status: "PENDING") }
    let!(:payment) { create(:klarna_payment, source: payment_source, order: order, payment_method: payment_source.payment_method) }
    let(:order_id) { "MY_ORDER_ID" }
    let(:params) { {order_id: payment_source.order_id, event_type: event_type} }

    context "with FRAUD_RISK_ACCEPTED" do
      let(:event_type) { "FRAUD_RISK_ACCEPTED" }

      it "accepts the payment" do
        expect {
          post :notification, params: params
        }.to change{payment_source.reload.accepted?}.from(false).to(true)
        expect(response.body).to eq("ok")
      end

      it "logs the call" do
        expect {
          post :notification, params: params
        }.to change{payment.log_entries.count}.by(1)
      end
    end

    context "with FRAUD_RISK_REJECTED" do
      let(:event_type) { "FRAUD_RISK_REJECTED" }

      it "rejects the payment" do
        expect {
          post :notification, params: params
        }.to change{payment_source.reload.rejected?}.from(false).to(true)
        expect(response.body).to eq("ok")
      end

      it "logs the call" do
        expect {
          post :notification, params: params
        }.to change{payment.log_entries.count}.by(1)
      end
    end

    context "with FRAUD_RISK_UNKNOWN" do
      let(:event_type) { "FRAUD_RISK_UNKNOWN" }

      it "does not update the payment" do
        expect {
          post :notification, params: params
        }.to_not change{payment_source.reload.fraud_status}
        expect(response.body).to eq("ok")
      end

      it "still logs the call" do
        expect {
          post :notification, params: params
        }.to change{payment.log_entries.count}.by(1)
      end
    end
  end
end

