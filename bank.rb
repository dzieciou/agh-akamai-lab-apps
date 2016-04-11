require 'sinatra'
require 'sqlite3'

set :port, 8090

Db = SQLite3::Database.new(':memory:')



def setup_db(db)
  setup_credit_card_table(db)
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
  stmt.close
end



setup_db(Db)

post '/bank/pay' do
  cc_number = params[:cc_number]
  cc_csc = params[:cc_csc]
  cc_owner = params[:cc_owner]
  amount = params[:amount]
  target_account_iban = params[:target_account_iban]

  if is_card_valid(cc_number, cc_csc, cc_owner)
    # transfer money
    status 200
  else
    status 401
  end

end

def is_card_valid(cc_number, cc_csc, cc_owner)
  sql = "select count(*) from credit_card where card_number = '#{cc_number}' and csc = '#{cc_csc}' and owner = '#{cc_owner}'"
  count = Db.get_first_value(sql)
  is_valid = (count == 1)
end





