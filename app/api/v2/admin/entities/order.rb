# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Admin
      module Entities
        class Order < Base
          expose(
            :id,
            documentation:{
              type: Integer,
              desc: 'Unique order id.'
            }
          )

          expose(
            :side,
            documentation: {
              type: String,
              desc: "Either 'sell' or 'buy'."
            }
          )

          expose(
            :ord_type,
            documentation: {
              type: String,
              desc: "Type of order, either 'limit' or 'market'."
            }
          )

          expose(
            :price,
            documentation: {
              type: BigDecimal,
              desc: "Price for each unit. e.g."\
                    "If you want to sell/buy 1 btc at 3000 usd, the price is '3000.0'."
            }
          )

          expose(
            :avg_price,
            documentation: {
              type: BigDecimal,
              desc: 'Average execution price, average of price in trades.'
            }
          )

          expose(
            :state,
            documentation: {
              type: String,
              desc: "One of 'wait', 'done', 'pending', 'reject' or 'cancel'."\
                    "An order in 'wait' is an active order, waiting fulfillment;"\
                    "a 'done' order is an order fulfilled;"\
                    "'cancel' means the order has been canceled."
            }
          )

          expose(
            :market_id,
            as: :market,
            documentation: {
              type: String,
              desc: "The market in which the order is placed, e.g. 'btcusd'."\
                    "All available markets can be found at /api/v2/admin/markets"
            }
          )


          expose(
            :created_at,
            format_with: :iso8601,
            documentation: {
              type: String,
              desc: 'Order create time in iso8601 format.'
            }
          )

          expose(
            :updated_at,
            format_with: :iso8601,
            documentation: {
              type: String,
              desc: 'Order updated time in iso8601 format.'
            }
          )

          expose(
            :origin_volume,
            documentation: {
              type: BigDecimal,
              desc: "The amount user want to sell/buy."\
                    "An order could be partially executed,"\
                    "e.g. an order sell 5 btc can be matched with a buy 3 btc order,"\
                    "left 2 btc to be sold; in this case the order's volume would be '5.0',"\
                    "its remaining_volume would be '2.0', its executed volume is '3.0'."
            }
          )

          expose(
            :volume,
            as: :remaining_volume,
            documentation: {
              type: BigDecimal,
              desc: "The remaining volume, see 'volume'."
            }
          )

          expose(
            :executed_volume,
            documentation: {
              type: BigDecimal,
              desc: "The executed volume, see 'volume'."
            }
          ) do |order, _options|
              order.origin_volume - order.volume
            end

          expose(
            :trades_count,
            documentation: {
              type: Integer,
              desc: 'Count of trades.'
            }
          )

          expose(
            :trades,
            documentation: {
              type: 'API::V2::Entities::Trade',
              is_array: true,
              desc: 'Trades with this order.'
            },
            if: { type: :full }
          ) do |order, _options|
              API::V2::Entities::Trade.represent order.trades, side: order.type == 'OrderAsk' ? 'sell' : 'buy'
            end

          expose(
            :email,
            documentation: {
              type: String,
              desc: 'The shared user email.'
            }
          ) { |w| w.member.email }

          expose(
            :uid,
            documentation: {
              type: String,
              desc: 'The shared user ID.'
            }
          ) { |w| w.member.uid }
        end
      end
    end
  end
end
