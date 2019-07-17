# encoding: UTF-8
# frozen_string_literal: true
require 'csv'

# Required fields:
# - uid with format (ID1234567890)
# - email
#
# Make sure that you create required currency
# Usage: bundle exec rake import:users['file_name.csv']

namespace :import do
  desc 'Load members from csv file.'
  task :users, [:config_load_path] => [:environment] do |_, args|
    csv_table = File.read(Rails.root.join(args[:config_load_path]))
    errors_users_file = File.open("errors_users_file.txt", "w")
    count = 0
    CSV.parse(csv_table, headers: true).map do |row|
      ActiveRecord::Base.transaction do
        composed_uid = "ID" + (1000000000 + row['AccountId'].to_i).to_s
        uid = composed_uid
        email = row['Email']
        level = row.fetch('level', 0)
        role = row.fetch('role', 'member')
        state = row.fetch('state', 'active')
        Member.create!(uid: uid, email: email, level: level, role: role, state: state)
        count += 1
        # Currency.all.map do |c|
        #   account = member.get_account(c.id)
        #   next unless account

        #   amount = row.fetch("balance_#{c.id}", 0).to_d
        #   if amount < 161
        #     locked_balance = amount
        #   else
        #     balance = amount
        #   end

        #   next if balance.zero? && locked_balance.zero?

        #   main_code, locked_code = c.coin? ? [202, 212] : [201, 211]
        #   asset_code = c.coin? ? 102 : 101 
        #   asset_credit = balance + locked_balance
        #   Operations::Asset.create!(code: asset_code, currency_id: c.id, credit: asset_credit) unless asset_credit.zero?
        #   Operations::Liability.create!(code: main_code, currency_id: c.id, member_id: member.id, credit: balance) unless balance.zero?
        #   Operations::Liability.create!(code: locked_code, currency_id: c.id, member_id: member.id, credit: locked_balance) unless locked_balance.zero?
        #   account.update!(balance: balance, locked: locked_balance)
        # end
      end
    rescue => e
      errors_users_file.write(e.message + row['Email'] + ' ' + row['AccountId'] + "\n")
    end
    errors_users_file.close
    Kernel.puts "Created #{count} members"
  end

  task :accounts, [:config_load_path] => [:environment] do |_, args|
    csv_table = File.read(Rails.root.join(args[:config_load_path]))
    errors_accounts_file = File.open("errors_accounts_file.txt", "w")
    count = 0
    CSV.parse(csv_table, headers: true).map do |row|
      composed_uid = 'ID' + (1_000_000_000 + row['AccountId'].to_i).to_s
      member = Member.find_by_uid(composed_uid)
      currency = Currency.find(row['ProductSymbol'])
      account = Account.find_by(member: member, currency_id: currency)
      next unless account

      amount = row['Amount'].to_d
      asset_code = currency.coin? ? 102 : 101
      liability_code = currency.coin? ? 202 : 201
      ActiveRecord::Base.transaction do
        Operations::Asset.create!(code: asset_code, currency_id: currency.id, credit: amount)
        Operations::Liability.create!(code: liability_code, currency_id: currency.id, member_id: member.id, credit: amount) 
        account&.update!(balance: amount)
      end unless amount.zero?
    rescue => e
      errors_accounts_file.write(e.message + ' ' + composed_uid + "\n")
    end
    errors_accounts_file.close
  end
end
