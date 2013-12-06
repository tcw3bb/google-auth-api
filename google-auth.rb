#Author:Tom Webb tcw3bb@gmail.com
#Must run on FreeRADIUS box
#Version 1.0
require 'rubygems'
require 'sinatra'
require 'openssl' 
CERT_PATh= './ssl'
APIKEY='321321'


before do
  error 401 unless params[:key]==APIKEY
end

def validate_user(user)
#check if user is already created local account
system("grep -q #{user} /etc/passwd")
  if $?.exitstatus == 0
        puts "User already exists"
		status 400
        else
        create_user(user)
  end
end

def validate_token(user)
#Check to determine if token has been assigned
  system("ls -l /var/google-auth/ |awk '{print $9}'|egrep -qwi #{user}")
  if $?.exitstatus == 0
        puts "Token for user already exists"
        else
		create_token(user)
		puts "Creating token" 
  end
end

def create_user(user)
system("adduser -MNs /sbin/nologin #{user}")

 if $?.exitstatus == 0
        puts "Success creating User"
		else
        puts "Error Creating User"
		status 400
 end

end

def create_token(input2)
 system("/usr/local/bin/google-authenticator  -q -f -t -d -r 3 -R30 -w 2 -s  /var/google-auth/#{input2}_google_auth")
 
  if $?.exitstatus == 0
        puts "Success creating Token"
		else
        puts "Error Creating Token"
		status 400
 end
 
 system("chown root:root /var/google-auth/#{input2}_google_auth")
 system("chmod 400 /var/google-auth/#{input2}_google_auth")
end

configure do
  mime_type :plain, 'text/plain'
  enable :logging, :dump_errors, :raise_errors
 log = File.new("sinatra.log", "a")
  STDOUT.reopen(log)
  STDERR.reopen(log)
end

post '/api/:id' do 
 @userid=params[:id]
 puts @userid
 if @userid.nil? then
  status 404
 else
  validate_user(@userid)
  validate_token(@userid)
   end
end

