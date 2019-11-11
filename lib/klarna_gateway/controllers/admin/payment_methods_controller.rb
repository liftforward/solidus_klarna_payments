module KlarnaGateway
  module Admin
    module PaymentMethodsController
      def self.included(base)
        base.prepend_before_action(:validate_klarna_credentials, only: [:update])
      end

      private

      def validate_klarna_credentials
        if params[:payment_method][:type] == 'Spree::Gateway::KlarnaCredit'
          if (params[:payment_method][:preferred_api_secret].blank? || params[:payment_method][:preferred_api_key].blank?)
            flash[:error] = Spree.t('klarna.can_not_test_api_connection')
          end

          if params[:payment_method][:preferred_api_secret].present? && params[:payment_method][:preferred_api_key].present?
            Klarna.configure do |config|
              config.environment = !Rails.env.production? ? 'test' : 'production'
              config.country = params[:payment_method][:preferred_country]
              config.api_key =  params[:payment_method][:preferred_api_key]
              config.api_secret = params[:payment_method][:preferred_api_secret]
              config.user_agent = "Klarna Solidus Gateway/#{::KlarnaGateway::VERSION} Solidus/#{::Spree.solidus_version} Rails/#{::Rails.version}"
            end

            klarna_response = Klarna.client(:credit).create_session({})

            if klarna_response.code == 401
              flash[:error] = Spree.t('klarna.invalid_api_credentials')
            else
              flash[:notice] = Spree.t('klarna.valid_api_credentials')
            end
          end
        end
      end
    end
  end
end
