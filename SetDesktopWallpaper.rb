################################################################################
#
# This script downloads an image from apod.nasa.gov/apod/ap*today*.html and sets
# it as the current background wallpaper.
#
# By Ola Söderström
# This script is not intended for public use.
################################################################################

class SetDesktopWallpaper

  require 'cgi'
  require 'date'
  require 'net/https'
  require 'rbconfig'
  require 'uri'
  require 'Win32API'


#########################################################
# Method to get the response from an address.
#########################################################

  def self.get_response(uri_string)

    # Check if SSL and set the correct default port for requests.
    uri_string[/https(.*?)/] ? default_port = 443 : default_port = 80

    # Create new Net::HTTP object for the specified uri
    uri = URI(uri_string)
    http = Net::HTTP.new(uri.host, default_port)

    # Necessary only if SSL.
    if default_port == 443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # Get the request and return the response.
    req = Net::HTTP::Get.new(uri.request_uri)
    return http.request(req)

  end


#########################################################
# Method to find what OS we are operating under.
#########################################################

  def self.get_os

    @os ||= (
      host_os = RbConfig::CONFIG['host_os']
      case host_os
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          :windows
        when /darwin|mac os/
          :macosx
        when /linux/
          :linux
        when /solaris|bsd/
          :unix
        else
          puts "unknown os: #{host_os.inspect}"
      end
    )

  end



#########################################################
# Download the image and save it as 'nasa_image.jpg'.
# Fallback; use the image saved as 'nasa_image_fallback.jpg'
#########################################################

  def self.download_and_save(uri_string)

    # Get the response from the uri
    @resp = get_response(uri_string)
   
    # Show a message if the source code was not obtained
    puts 'There is no source code!?' if @resp == ''

    # Find image
    @resp.body.each_line { |line|
      @image = line
      break if line[/image(.*?)jpg/, 1]
    }

    if @image != nil && @image[/image(.*?)jpg/, 1] # Image was found.
      # Get the image source
      # The image is always contained within quotation marks on a line in
      # the source code.
      image_address = @uri_domain + '/apod/' + @image[/"(.*?)"/,1]
      resp_image = get_response(image_address)


      # Save the image
      open('nasa_image.jpg', 'wb') { |file| file.write(resp_image.body) }
      return 'nasa_image.jpg'

    else # Image was not found.
      puts '#ERROR!#'
      puts 'No image found at ' + @uri_domain + @uri_path
      puts '--> Using nasa_image_fallback.jpg'
      return 'nasa_image_fallback.jpg'
    end
   
  end


##########################################################
# Find and recreate the image caption in a readable format.
# Then save it to a file on the desktop
##########################################################

  def self.get_caption()
    caption = ''
    line_is_caption = false

    @resp.body.each_line { |line|
      line_is_caption = true if line.include? 'Explanation:'
      break if line.include? 'Tomorrow\'s picture:'
      caption += line if line_is_caption #.gsub(/<(.*?)>/,'')
    }

    caption.each_line { |line|
    }
    puts caption.gsub(/<(.*?)>/,'')

  end


############################################################
# Set the downloaded image as desktop wallpaper.
############################################################
 
  def self.set_desktop_wallpaper(wallpaper_path)
    success = 0
    get_os
   
    if @os == :windows
      # This works for Windows 10, and probably Windows 7.
      system_params_info = Win32API.new('user32', 'SystemParametersInfo', %w(I I P I), 'I')
      #SPI_SETDESKWALLPAPER  = 0x14
      #SPIF_UPDATEINIFILE    = 0x1
      #SPIF_SENDWININICHANGE = 0x2
      full_wallpaper_path = Dir.pwd + '/' + wallpaper_path
      success = system_params_info.call(0x14, 0, full_wallpaper_path, 0x1 | 0x2)
    elsif @os == :macosx
      # Not Implemented
    elsif @os == :linux
      # Not implemented
    elsif @os == :unix
      # Not implemented
    end

  # Return a message which tells if the desktop wallpaper was set successfully.
    puts "The image from #{@uri_string} has successfully been set as the current desktop background!" if success == 1
    puts 'Crap! Something went wrong when trying to set the desktop background...' unless success == 1

  end


#########################################################
# Start of main program
#########################################################

  # Get the correct host and port names of the source file.
  # @uri_path will vary each day since it includes today's date.
  params = { :mode => 'prod',
             :id   => '000000',
             :new  => 'true' }
  @uri_domain = 'https://apod.nasa.gov'
  @uri_path   = '/apod/ap' + Date.today.strftime('%y%m%d') + '.html'

  # Don't think the hash params are actually necessary, but we add them anyway because of reasons...
  uri_params = params.map{|k,v| "#{k}=#{CGI::escape(v.to_s)}"}.join('&')
  @uri_string = @uri_domain + @uri_path + '?' + uri_params

  wallpaper_path = download_and_save(@uri_string)
  get_caption
  set_desktop_wallpaper(wallpaper_path)

end #SetDesktopWallpaper
