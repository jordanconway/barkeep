require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'do_sqlite3'
require 'dm-sqlite-adapter'

enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/barkeep.db")

class BoozeBottle
    include DataMapper::Resource
    property :id, Serial
    property :name, Text, :required => true
    property :size, Text, :required => true
    property :ammount, Text, :required => true
    property :saqurl, Text
end

DataMapper.finalize.auto_upgrade!

# Do we need authentication?? Probably not yet, but I'll leave it in.
helpers do

    include Rack::Utils
    alias_method :h, :escape_html

    def protected!
        unless authorized?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n"])
        end
    end

    def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
    end

end

get '/' do
    @title = 'Barkeep! Simple booze inventory management'
    erb :home
end

post '/' do
    a = BoozeBottle.new
    a.name = params[:name]
    a.size= params[:size]
    a.ammount = params[:ammount] 
    a.saqurl= params[:saqurl] 
    a.save
    session[:number] = a.id
    redirect to '/done'
end

get '/done' do
    @boozebtl = BoozeBottle.get(session[:number])
    @title = "done"
    erb :done
end

get '/all' do
    @title = 'all'
    @boozebtl = BoozeBottle.all :order => :id.desc
    erb :all
end

get '/:id' do
    @boozebtl = BoozeBottle.get params[:id]
    @title = "requested"
    erb :show
end
