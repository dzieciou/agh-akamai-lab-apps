# payment.rb
require 'sinatra'
require 'rest-client'
require 'sqlite3'

set :bind, '0.0.0.0'
set :port, 8070
Db = SQLite3::Database.new(':memory:')

def setup_db(db)
  set_product_tables(db)
end

def set_product_tables(db)

  db.execute <<SQL
  CREATE TABLE product (
    id VARCHAR(255),
    name VARCHAR(255),
    price INTEGER,
    PRIMARY KEY (id)
  );
SQL

  stmt = db.prepare "INSERT INTO product(id,name,price) VALUES (:id, :name, :price)"
  stmt.execute :id => "002", :name => "Nikon D60", :price => 600
  stmt.execute :id => "001", :name => "Canon EOS 5000D", :price => 500
  stmt.close


end

setup_db(Db)

get '/shop/summary' do
  products = Db.execute "SELECT id, name FROM product"
  erb :order, :layout => :layout, :locals => {:products => products}
end

post '/shop/order' do
  product_id = params[:product_id]
  p product_id
  sql = "SELECT price FROM product WHERE id = '#{product_id}'"
  p sql
  price = Db.get_first_value sql

  begin
    response = RestClient.post('http://localhost:8090/bank/pay',
                               {
                                   :cc_number => params[:cc_number],
                                   :cc_csc => params[:cc_csc],
                                   :cc_owner => params[:cc_owner],
                                   :amount => price,
                                   :target_account_iban => params[:target_account_iban]
                               },
                               :content_type => :json,
                               :accept => :json)

    status 200
    erb :success, :layout => :layout

  rescue RestClient::ExceptionWithResponse => err
    status 401
    erb :failure, :layout => :layout
  end
end






