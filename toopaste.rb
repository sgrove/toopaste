#!/usr/local/bin/ruby -rubygems

# TO DO:
# - snippet retention
# - language selection
# - deletion url
# - tags
# - line wrapping?

require 'sinatra'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'syntaxi'
require 'haml'
require 'sass'

set :haml, :format => :html5

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/toopaste.db")

class Snippet
  include DataMapper::Resource

  property :id,         Serial
  property :title,      String, :required => true, :length => 32
  property :body,       Text,   :required => true
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_presence_of :body
  validates_length_of :body, :minimum => 1

  Syntaxi.line_number_method = 'floating'
  Syntaxi.wrap_at_column = 80
  #Syntaxi.wrap_enabled = false

  def formatted_body
    replacer = Time.now.strftime('[code-%d]')
    html = Syntaxi.new("[code lang='ruby']#{self.body.gsub('[/code]',
    replacer)}[/code]").process
    "<div class=\"syntax syntax_ruby\">#{html.gsub(replacer, 
    '[/code]')}</div>"
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!
#File.open('toopaste.pid', 'w') { |f| f.write(Process.pid) }

# stylesheet
get '/stylesheet.css' do
    scss :stylesheet, :style => :compact
end

# list
get '/' do
    @snippets = Snippet.all
    if @snippets
        haml :list
    else
        redirect '/new'
    end
end

# new
get '/new' do
  haml :new
end

# create
post '/' do
  @snippet = Snippet.new(:title => params[:snippet_title],
                         :body  => params[:snippet_body])
  if @snippet.save
    redirect "/#{@snippet.id}"
  else
    redirect '/'
  end
end

# show
get '/:id' do
  @snippet = Snippet.get(params[:id])
  if @snippet
    haml :show
  else
    raise not_found
  end
end

# 404
not_found do
  haml :error404
end

# 403
error 403 do
  haml :error403
end

# other errors
error do
  haml :error500
end
