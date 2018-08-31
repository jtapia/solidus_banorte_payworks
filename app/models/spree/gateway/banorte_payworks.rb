module Spree
  class Gateway::BanortePayworks < Spree::Gateway
    CARD_TYPE_MAPPING = { 'American Express' => 'american_express',
                          'Diners Club' => 'diners_club',
                          'Visa' => 'visa' }

    if SolidusSupport.solidus_gem_version < Gem::Version.new('2.3.x')
      def method_type
        'banorte_payworks'
      end
    else
      def partial_name
        'banorte_payworks'
      end
    end

    def provider_class
      ::BanortePayworks::SimpleTPV
      # ::PayPal::SDK::Merchant::API
    end

    def provider
      provider_class.new(username: 'tienda19',
                         password: '2006',
                         client_id: '19',
                         mode: BanortePayworks::MODE[:accept])
    end

    def purchase(amount, source, gateway_options = {})
      response = do_purchase(gateway_options[:order_id],
                             gateway_options[:card_number],
                             gateway_options[:exp_date],
                             gateway_options[:cvv],
                             amount)

      response
    end

    # amount :: float
    # express_checkout :: Spree::PaypalExpressCheckout
    # gateway_options :: hash
    def authorize(amount, express_checkout, gateway_options={})
      response = do_authorize(gateway_options[:order_id],
                              gateway_options[:card_number],
                              gateway_options[:exp_date],
                              gateway_options[:cvv],
                              amount)
      response
    end

    # def authorize(money, creditcard, gateway_options)
    #   client.authorize(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    # end

    # def capture(money, response_code, gateway_options)
    #   client.capture(money, response_code, gateway_options)
    # end

    # def credit(money, creditcard, response_code, gateway_options)
    #   client.refund(money, response_code, {})
    # end

    def void(transaction, gateway_options)
      client.void(transaction)
    end

    # def cancel(response_code)
    #   client.void(response_code, {})
    # end

    private

    def build_response(response)
      binding.pry
      ActiveMerchant::Billing::Response.new(
        response.success?,
        JSON.pretty_generate(response.to_hash),
        response.to_hash,
        authorization: transaction_id,
        test: sandbox?)
    end

    def do_purchase(amount, gateway_options = {})
      response = provider.do_payment(gateway_options[:order_id],
                                     gateway_options[:card_number],
                                     gateway_options[:exp_date],
                                     gateway_options[:cvv],
                                     amount)
      binding.pry
      build_response(response)
    end

    def do_authorize(amount, gateway_options = {})
      response = provider.do_payment([:order_id],
                                     gateway_options[:card_number],
                                     gateway_options[:exp_date],
                                     gateway_options[:cvv],
                                     amount)
      binding.pry
      build_response(response)
    end

    def address_for(payment)
      {}.tap do |options|
        if address = payment.order.bill_address
          options.merge!(address: {
            address1: address.address1,
            address2: address.address2,
            city: address.city,
            zip: address.zipcode
          })

          if country = address.country
            options[:address].merge!(country: country.name)
          end

          if state = address.state
            options[:address].merge!(state: state.name)
          end
        end
      end
    end

    def update_source!(source)
      source.cc_type = CARD_TYPE_MAPPING[source.cc_type] if CARD_TYPE_MAPPING.include?(source.cc_type)
      source
    end
  end
end




# require 'paypal-sdk-merchant'
# module Spree
#   class Gateway::PayPalExpress < Gateway
#     preference :use_new_layout, :boolean, default: true
#     preference :login, :string
#     preference :password, :string
#     preference :signature, :string
#     preference :server, :string, default: 'sandbox'
#     preference :solution, :string, default: 'Mark'
#     preference :landing_page, :string, default: 'Billing'
#     preference :logourl, :string, default: ''

#     def supports?(source)
#       true
#     end

#     def provider_class
#       ::PayPal::SDK::Merchant::API
#     end

#     def provider
#       ::PayPal::SDK.configure(
#         mode: preferred_server.present? ? preferred_server : "sandbox",
#         username: preferred_login,
#         password: preferred_password,
#         signature: preferred_signature)
#       provider_class.new
#     end

#     def auto_capture?
#       false
#     end

#     def method_type
#       'paypal'
#     end

#     # amount :: float
#     # express_checkout :: Spree::PaypalExpressCheckout
#     # gateway_options :: hash
#     def authorize(amount, express_checkout, gateway_options={})
#       response =
#         do_authorize(express_checkout.token, express_checkout.payer_id)

#       # TODO don't do this, use authorization instead
#       # this is a hold over from old code.
#       # I don't think this actually even used by anything?
#       express_checkout.update transaction_id: response.authorization

#       response
#     end

#     # https://developer.paypal.com/docs/classic/api/merchant/DoCapture_API_Operation_NVP/
#     # for more information
#     def capture(amount_cents, authorization, currency:, **_options)
#       do_capture(amount_cents, authorization, currency)
#     end

#     def credit(credit_cents, transaction_id, originator:, **_options)
#       payment = originator.payment
#       amount = credit_cents / 100.0

#       refund_type = payment.amount == amount.to_f ? "Full" : "Partial"

#       refund_transaction = provider.build_refund_transaction(
#         { TransactionID: payment.transaction_id,
#           RefundType: refund_type,
#           Amount: {
#             currencyID: payment.currency,
#             value: amount },
#           RefundSource: "any" })

#       refund_transaction_response = provider.refund_transaction(refund_transaction)

#       if refund_transaction_response.success?
#         payment.source.update_attributes(
#           { refunded_at: Time.now,
#             refund_transaction_id: refund_transaction_response.RefundTransactionID,
#             state: "refunded",
#             refund_type: refund_type
#         })
#       end

#       build_response(
#         refund_transaction_response,
#         refund_transaction_response.refund_transaction_id)
#     end

#     def server_domain
#       self.preferred_server == "live" ?  "" : "sandbox."
#     end

#     def express_checkout_url(pp_response, extra_params={})
#       params = {
#         token: pp_response.Token
#       }.merge(extra_params)

#       if self.preferred_use_new_layout
#         "https://www.#{server_domain}paypal.com/checkoutnow/2?"
#       else
#         "https://www.#{server_domain}paypal.com/cgi-bin/webscr?" +
#           "cmd=_express-checkout&force_sa=true&"
#       end +
#       URI.encode_www_form(params)
#     end

#     def do_authorize(token, payer_id)
#       response =
#         self.
#         provider.
#         do_express_checkout_payment(
#           checkout_payment_params(token, payer_id))

#       build_response(response, authorization_transaction_id(response))
#     end

#     def do_capture(amount_cents, authorization, currency)
#       response = provider.
#         do_capture(
#           provider.build_do_capture(
#             amount: amount_cents / 100.0,
#             authorization_id: authorization,
#             complete_type: "Complete",
#             currencycode: options[:currency]))

#       build_response(response, capture_transaction_id(response))
#     end

#     def capture_transaction_id(response)
#       response.do_capture_response_details.payment_info.transaction_id
#     end

#     # response ::
#     #   PayPal::SDK::Merchant::DataTypes::DoExpressCheckoutPaymentResponseType
#     def authorization_transaction_id(response)
#       response.
#         do_express_checkout_payment_response_details.
#         payment_info.
#         first.
#         transaction_id
#     end

#     def build_response(response, transaction_id)
#       ActiveMerchant::Billing::Response.new(
#         response.success?,
#         JSON.pretty_generate(response.to_hash),
#         response.to_hash,
#         authorization: transaction_id,
#         test: sandbox?)
#     end

#     def payment_details(token)
#       self.
#         provider.
#         get_express_checkout_details(
#           checkout_details_params(token)).
#         get_express_checkout_details_response_details.
#         PaymentDetails
#     end

#     def checkout_payment_params(token, payer_id)
#       self.
#         provider.
#         build_do_express_checkout_payment(
#           build_checkout_payment_params(
#             token,
#             payer_id,
#             payment_details(token)))
#     end

#     def checkout_details_params(token)
#       self.
#         provider.
#         build_get_express_checkout_details(Token: token)
#     end

#     def build_checkout_payment_params(token, payer_id, payment_details)
#       {
#         DoExpressCheckoutPaymentRequestDetails: {
#           PaymentAction: "Authorization",
#           Token: token,
#           PayerID: payer_id,
#           PaymentDetails: payment_details
#         }
#       }
#     end

#     def sandbox?
#       self.preferred_server == "sandbox"
#     end
#   end
# end
