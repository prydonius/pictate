require "selenium-webdriver"
require "selenium/server"

module Pictate
  def pictate(image_path, options = {})
    start_server options[:server]
    puts "I'm thinking..."
    puts do_search image_path
    stop_server
  end

  def start_server(server_path)
    FileUtils.cd "../ext"
    selenium_latest = Selenium::Server.latest
    if server_path
      selenium_path = server_path
    else
      if not File.exists? "selenium-server-standalone-#{selenium_latest}.jar"
        puts "Downloading latest version of selenium server standalone..."
      end
      selenium_path = Selenium::Server.download(selenium_latest)
    end

    puts "Starting selenium standalone server"
    @server = Selenium::Server.new(selenium_path, :background => true)
    @server.start
    caps = Selenium::WebDriver::Remote::Capabilities.htmlunit(
      :javascript_enabled => true)
    @driver = Selenium::WebDriver.for(:remote, :desired_capabilities => caps)
  end

  def stop_server
    puts "Stopping server..."
    @driver.quit
    @server.stop
    puts "Goodbye!"
  end

  def do_search(image_path)
    @driver.navigate.to "http://www.google.co.uk/searchbyimage"
    # show the upload dialog
    @driver.execute_script("google.qb.ti(true)")

    # upload image and search
    upload = @driver.find_element(:name, 'encoded_image')
    upload.send_keys image_path

    # best result
    wait = Selenium::WebDriver::Wait.new(:timeout => 100)
    wait.until { @driver.find_element(:id => 'topstuff') }
    topstuff = @driver.find_element(:id => 'topstuff')
    best = topstuff.text.lines.to_a.last
    if not best.match /Best(.*)/
      result = "Can't figure it out for the life of me, sorry!"
    else
      best.gsub!("Best guess for this image:", "")
      result = "I believe this is a picture of: #{best}."
    end
    result
  end
end