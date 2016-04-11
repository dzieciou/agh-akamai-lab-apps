require 'sinatra'
require 'sqlite3'
require 'json'

set :port, 8090

Db = SQLite3::Database.new(':memory:')



def setup_db(db)
  setup_credit_card_table(db)
  setup_credit_card_balance_table(db)
  setup_account_balance_table(db)
end


def setup_credit_card_table(db)
  db.execute <<SQL
  CREATE TABLE credit_card (
    card_number varchar(255),
    owner varchar(255),
    csc varchar(3),
    PRIMARY KEY(card_number)
  )
SQL

  stmt = db.prepare <<SQL
  INSERT INTO credit_card(card_number,owner, csc) VALUES(:card_number, :owner, :csc)
SQL

  stmt.execute(:card_number => "4012888888881881", :owner => "MACIEK", :csc => "757")
  stmt.execute(:card_number => "4917610000000000", :owner => "PIOTR", :csc => "324")
  stmt.close
end

def setup_credit_card_balance_table(db)
  db.execute <<SQL
  CREATE TABLE credit_card_balance (
    card_number varchar(255),
    balance integer,
    PRIMARY KEY(card_number)
  )
SQL

  stmt = db.prepare <<SQL
  INSERT INTO credit_card_balance(card_number,balance) VALUES(:card_number, :balance)
SQL

  stmt.execute(:card_number => "4012888888881881", :balance => 2100)
  stmt.execute(:card_number => "4917610000000000", :balance => 4500)
  stmt.close
end

def setup_account_balance_table(db)
  db.execute <<SQL
  CREATE TABLE account_balance (
    account_number varchar(255),
    owner varchar(255),
    balance integer,
    PRIMARY KEY(account_number)
  )
SQL

  stmt = db.prepare <<SQL
  INSERT INTO account_balance(account_number, owner, balance) VALUES(:account_number, :owner,  :balance)
SQL

  stmt.execute(:account_number => "1234", :owner => "Online Shop", :balance => 1300)
  stmt.execute(:account_number => "4567", :owner => "Hacker", :balance => 27000)
  stmt.close
end



setup_db(Db)

def transfer_money(amount, from_card_number, to_account_number)
  stmt = Db.prepare <<SQL
  UPDATE credit_card_balance SET balance = balance - :amount WHERE card_number = :card_number
SQL
  stmt.execute(:card_number => from_card_number, :amount => amount)

  stmt = Db.prepare <<SQL
  UPDATE account_balance SET balance = balance + :amount WHERE account_number = :account_number
SQL
  stmt.execute(:account_number => to_account_number, :amount => amount)

end

post '/bank/pay' do
  cc_number = params[:cc_number]
  cc_csc = params[:cc_csc]
  cc_owner = params[:cc_owner]
  amount = params[:amount]
  target_account_iban = params[:target_account_iban]

  if is_card_valid(cc_number, cc_csc, cc_owner)
    transfer_money(amount, cc_number, target_account_iban)
    status 200
  else
    status 401
  end

end

get '/bank/accounts/:account_number/balance' do
  account_number = params["account_number"]
  sql = "select balance from account_balance where account_number = '#{account_number}'"
  balance = Db.get_first_value(sql)
  content_type :json
  { :account_number => account_number, :balance => balance }.to_json
end

get '/bank/cards/:card_number/balance' do
  card_number = params["card_number"]
  sql = "select balance from credit_card_balance where card_number = '#{card_number}'"
  balance = Db.get_first_value(sql)
  content_type :json
  { :card_number => card_number, :balance => balance }.to_json
end


def is_card_valid(cc_number, cc_csc, cc_owner)
  sql = "select count(*) from credit_card where card_number = '#{cc_number}' and csc = '#{cc_csc}' and owner = '#{cc_owner}'"
  count = Db.get_first_value(sql)
  is_valid = (count == 1)
end





