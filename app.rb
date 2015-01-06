#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'sinatra'
require 'sinatra/reloader'
require './lib/air_conditioner_application'
require 'digest/md5'
require 'rexml/document'
require 'fileutils'
require 'pp'

set :bind, '0.0.0.0'
set :port, 3000
set :session_secret, '6e9XESoiNK35jp4l2fHCdIBDmqzQycntF'
set :sessions, true

get '/' do
  puts session[:belong]
  @session = session
  @base_path = request.env['REQUEST_URI']

  @elements = [
      {:jp => "所属", :en => "belong", :key => :belong },
      {:jp => "申請者", :en => "applicant", :key => :applicant },
      {:jp => "内線番号", :en => "tel", :key => :tel },
      {:jp => "メールアドレス", :en => "mail", :key => :mail },
      {:jp => "棟名", :en => "building_name", :key => :building_name },
      {:jp => "室名", :en => "room_name", :key => :room_name },
      {:jp => "室番号", :en => "room_number", :key => :room_number },
      {:jp => "理由", :en => "reason", :key => :reason },
  ]

  erb :"index.html"
end

post '/' do
  session.merge! params

  begin
	params[:date] = Date.parse(params[:date])
  rescue
	params[:date] = Date.today
  end
  tmpdir = './public/files/' + Digest::MD5.hexdigest(params.to_s)

  unless File.exist?(tmpdir + ".docx")
    system("mkdir #{tmpdir}")
    system("/usr/local/bin/unzip -q -o #{settings.root}/ext/2-1-16.docx -d '#{tmpdir}'")
    app = AirConditionerApplication.new(tmpdir + "/word/document.xml", params[:date])
    app.belong        = params[:belong]
    app.applicant     = params[:applicant]
    app.tel           = params[:tel]
    app.mail          = params[:mail]
    app.building_name = params[:building_name]
    app.room_name     = params[:room_name]
    app.room_number   = params[:room_number]
    app.reason        = params[:reason]

    app.run
    File.write(tmpdir + "/word/document.xml", app.result)
    system("cd #{tmpdir}; /usr/local/bin/zip -qr ../#{tmpdir.split('/')[-1]}.docx ./")
    system("rm #{tmpdir}")
  end

  redirect "#{request.env['REQUEST_URI']}files/#{tmpdir.split('/')[-1]}.docx"
end
