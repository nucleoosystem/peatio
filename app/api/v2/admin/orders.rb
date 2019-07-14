# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Admin
      class Orders < Grape::API
        helpers API::V2::Admin::OrderParams
        helpers API::V2::Admin::ParamsHelpers

        desc 'Get all orders, result is paginated.',
          is_array: true,
          success: API::V2::Admin::Entities::Order
        params do
          optional :limit,
                   type: { value: Integer, message: 'admin.order.non_integer_limit' },
                   values: { value: 1..1000, message: 'admin.order.invalid_limit' },
                   default: 100,
                   desc: 'Limit the number of returned orders. Default to 100.'
          optional :page,
                   type: { value: Integer, message: 'admin.order.non_integer_page' },
                   allow_blank: false,
                   default: 1,
                   desc: 'Specify the page of paginated results.'
          optional :ordering,
                   type: String,
                   values: { value: %w(asc desc), message: 'admin.order.invalid_ordering' },
                   default: 'asc',
                   desc: 'If set, returned orders will be sorted in specific order, default to \'asc\'.'
          optional :order_by,
                   type: String,
                   default: 'id',
                   desc: 'Name of the field, which will be ordered by'
          use :order_params
        end
        get '/orders' do
          authorize! :read, Order

          ransack_params = {
            price_eq: params[:price],
            origin_volume_eq: params[:origin_volume],
            ord_type_eq: params[:ord_type],
            state_eq: params[:state].present? ? Order::STATES[params[:state].to_sym] : nil,
            market_id_eq: params[:market],
            type_eq: params[:type].present? ? "Order#{params[:type].capitalize}" : nil,
            member_uid_eq: params[:uid],
            member_email_eq: params[:email],
            created_at_gteq: time_param(params[:created_at_from]),
            created_at_lt: time_param(params[:created_at_to]),
            updated_at_gteq: time_param(params[:updated_at_from]),
            updated_at_lt: time_param(params[:updated_at_to])
          }

          search = Order.ransack(ransack_params)
          search.sorts = "#{params[:order_by]} #{params[:ordering]}"
          present paginate(search.result), with: API::V2::Admin::Entities::Order
        end
      end
    end
  end
end
