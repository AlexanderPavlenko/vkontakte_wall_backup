require 'vkontakte_wall_backup/version'
require 'date'
require 'yaml'
require 'vkontakte_api'
require 'capybara'
require 'capybara/dsl'
require 'selenium/webdriver'

# known bugs:
# https://vk.com/wall7848621_3143 — original post is hidden

module VkontakteWallBackup
  extend Capybara::DSL

  DEFAULT_FILENAME = 'mozilla.pdf'.freeze
  MAX_RETRIES      = 3
  PRINT_TIMEOUT    = (ENV['PRINT_TIMEOUT'] || 3).to_i
  LOAD_TIMEOUT     = 3

  def self.backup!(config:)
    @cwd    = '.'
    @config = YAML.load_file(config)
    configure_driver!
    traverse_map do |url, filename|
      if ENV['DRY_RUN']
        puts [url, filename].inspect
        next
      end
      try = 1
      begin
        FileUtils.rm_f DEFAULT_FILENAME
        visit url
        sleep LOAD_TIMEOUT
        unfold_content
        cleanup_page
        # sleep 10000 # debug
        `xdotool key ctrl+p`
        sleep 1
        `xdotool getactivewindow mousemove --window %1 95 85 click --repeat 2 1`
        sleep PRINT_TIMEOUT**try # large pages printing is slow
        if File.exists? DEFAULT_FILENAME
          `gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="#{filename}" "#{DEFAULT_FILENAME}"`
          unless File.exists?(filename)
            raise "cannot compress #{filename}"
          end
        else
          raise "cannot print #{filename}"
        end
      rescue => ex
        $stderr.puts ex.message
        page.driver.quit
        if try < MAX_RETRIES
          try += 1
          retry
        else
          handle_skipped [url, filename]
          $stderr.puts "skipping #{[url, filename].inspect}"
        end
      end
    end
  end

  def self.traverse_map(map = @config, dir = @cwd, &block)
    map.each do |k, v|
      nested_dir = File.join(dir, k)
      FileUtils.mkdir_p nested_dir
      case v
      when Hash
        traverse_map(v, nested_dir, &block)
      when Array
        v.each do |item|
          case item
          when Hash
            each_post(**item) do |url, filename|
              block.call url, File.join(nested_dir, filename)
            end
          when Array
            url      = item[0]
            filename =
              if item[1].end_with?('.pdf')
                # assuming filename with path, as in the skipped.yml
                item[1]
              else
                # assuming just a label
                File.join(nested_dir, "#{url.split('/')[-1]} #{item[1]}.pdf")
              end
            block.call url, filename
          when String
            block.call item, File.join(nested_dir, "#{item.split('/')[-1]}.pdf")
          else
            raise ArgumentError, "invalid config: #{item.inspect}"
          end
        end
      else
        raise ArgumentError, "invalid config: #{v.inspect}"
      end
    end
  end

  def self.handle_skipped(skipped)
    (@skipped ||= []) << skipped
    @skipped_filename ||= "skipped_#{Time.now.to_i}.yml"
    @skipped_file     ||= File.open(@skipped_filename, 'w')
    @skipped_file.write(YAML.dump('.' => @skipped))
    @skipped_file.fdatasync
  end

  MAX_COUNT     = 100
  REQUEST_DELAY = 0.35

  def self.each_post(domain:, since_id:, filter: :owner, offset: 0, &block)
    VkontakteApi.configure do |config|
      config.logger      = Logger.new(STDERR)
      config.api_version = '5.27'
    end
    raise ArgumentError unless domain || since_id
    vk           = VkontakteApi::Client.new
    params       = {
      filter:       filter,
      offset:       offset,
      domain:       domain,
      count:        MAX_COUNT,
      access_token: ENV['VK_ACCESS_TOKEN'],
    }
    out_of_scope = false
    loop do
      batch = vk.wall.get(params)
      break if batch.items.empty?
      params[:offset] += MAX_COUNT
      batch.items.each do |item|
        if (out_of_scope = item.id < since_id)
          break
        else
          block.call "https://vk.com/wall#{item.owner_id}_#{item.id}", "wall#{item.owner_id}_#{item.id}.pdf"
        end
      end
      break if out_of_scope
      sleep REQUEST_DELAY
    end
    nil
  end

  def self.unfold_content
    while (moar = first('#fwp_load_more')) && moar.visible?
      execute_script 'Pagination.showMore()'
      sleep 0.5
    end
    execute_script %(each(document.getElementsByClassName('wall_reply_more'), function(i, e){ hide(this, domPS(e)); show(domNS(e)) }))
  end

  def self.cleanup_page
    execute_script %(document.getElementById('page_header_cont').remove()) # header
    execute_script %(document.getElementById('side_bar').remove()) # left menu
    execute_script %(document.getElementById('narrow_column').remove()) # right menu
    execute_script %(document.getElementById('footer_wrap').remove()) # footer
    execute_script %(document.getElementById('stl_left').remove()) # scroll to top
    execute_script %(document.getElementById('page_body').style.margin = 0) # top space
    execute_script %(document.getElementById('page_body').style.float = 'left') # left space
    execute_script %(document.getElementById('page_layout').style.margin = 0) # left space
  end

  def self.configure_driver!
    Capybara.register_driver :selenium do |app|
      profile                                = Selenium::WebDriver::Firefox::Profile.new
      profile['intl.accept_languages']       = 'ru'
      profile['print.print_bgcolor']         = true
      profile['print.print_bgimages']        = true
      profile['print.print_to_file']         = true
      profile['print.print_paper_name']      = 'Custom Size 1'
      profile['print.print_paper_height']    = '120,96'
      profile['print.print_paper_width']     = '  7,56'
      profile['print.print_paper_size_unit'] = 0
      profile['print.print_paper_data']      = 0
      Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile, desired_capabilities: Selenium::WebDriver::Remote::Capabilities.firefox.merge!(marionette: false))
    end
    Capybara.default_driver = :selenium
  end
end
