require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'do_sqlite3'
require 'dm-sqlite-adapter'
require 'nokogiri'
require 'open-uri'
enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/barkeep.db")

class BoozeBottle
    include DataMapper::Resource
    property :id, Serial
    property :name, Text
    property :size, Text
    property :type, Text
    property :ammount, Text, :required => true
    property :saqurl, Text, :required => true
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
    #a.name = params[:name]
    #a.size= params[:size]
    a.ammount = params[:ammount] 
    a.saqurl= params[:saqurl] 
    page = Nokogiri::HTML(open(a.saqurl))
    first,second =  page.css('div #content div div div div div.product-page-left div.product-description div.product-description-row1 div.product-description-title-type').text.strip.split(',')
    title  =  page.css('div #content div div div div div.product-page-left div.product-description div.product-description-row1 h1.product-description-title').text.strip
    a.name = title
    a.type = first
    a.size = second
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
    @boozebtl = BoozeBottle.get!(params[:id].to_i)
    @title = "requested"
    erb :show
end
