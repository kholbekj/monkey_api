require 'sinatra'
require 'JSON'
require 'CSV'

get '/monkeys' do
  monkeys = read_monkeys
  monkeys.to_json
end

get '/monkeys/:id' do
  monkey = find_monkey(params[:id])
  return status 404 if monkey.nil?
  monkey.to_json
end

post '/monkeys' do
  new_monkey = monkey_data(request.body)
  id = read_monkeys.last[:id].to_i + 1
  monkey = { id: id, name: new_monkey['name'], age: new_monkey['age'] }
  write_monkey monkey
  status 201
end

put '/monkeys/:id' do
  monkey = find_monkey(params[:id])
  return 404 if monkey.nil?
  monkey.merge! monkey_data(request.body)
  update_monkey(monkey['id'], monkey)
  status 202
end

delete '/monkeys/:id' do
  monkey = find_monkey(params[:id])
  return status 404 if monkey.nil?
  delete_monkey(monkey)
  status 202
end

private
def storage_path
  'monkeys.csv'
end

def monkey_data(body)
  JSON.parse(body.read)['monkey']
end

def delete_monkey(monkey)
  void_monkey = { id: nil, name: nil, age: nil }
  update_monkey(monkey['id'], void_monkey)
end

def find_monkey(id)
  monkeys = read_monkeys
  monkeys.select! {|m| m['id'] == id }
  monkeys.first
end

def update_monkey(id, monkey)
  CSV.open("#{storage_path}.new", 'wb') do |csv|
    CSV.foreach(storage_path) do |row|
      if row.first == id
        csv << monkey.values
      else
        csv << row
      end
    end
  end
  `mv #{storage_path}.new #{storage_path}`
end

def read_monkeys
  monkeys = []
  CSV.foreach(storage_path) do |row|
    monkeys << { 'id' => row.first, 'name' => row[1], 'age' => row.last } unless row.first.nil?
  end
  monkeys
end

def write_monkey(monkey)
  CSV.open(storage_path, 'ab') do |csv|
    csv << monkey.values
  end
end
