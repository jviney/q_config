one "1"

namespace :ns1 do
  username "neil"
  password "armstrong"
end

sale_ends_at :expires_in => 3.seconds do
  10.seconds.from_now
end

namespace :ftp_account do
  namespace :login do
    email "email@email.com"
    password "pa55w0rd"
  end
  
  port 21
  ssl false
end

time Time.now

call_centre_ips [1, 2, 3]
office_ips [1,2, 3]
