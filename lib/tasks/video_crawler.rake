namespace :crawler do
  desc 'Download all videos'
  task :video => :environment do
    Label.where('downloaded = ?', 0).each do |label|
      next if label.downloaded?
      sign = video_downloader(label.video_label, label.id)

      next if sign == 0

      if sign
        label.downloaded = true
        label.save
      else
        label.destroy
      end
    end
  end

  desc "Download test"
  task :video_test do
    download_test("javli4qw7m")
  end

end

# --- Method ---
def video_downloader(identifer, vid)
  video = Video.new; video.id = vid
  baseurl = "#{$JAVLIBRARY_URL}/cn/?v=#{identifer}"
  response = Mechanize.new do |agent|
    agent.read_timeout = 2
    agent.open_timeout = 2
    # agent.user_agent = Mechanize::AGENT_ALIASES.values[rand(21)]
  end

  begin
    response.get baseurl
  # rescue Timeout::Error
  #   retry
  rescue
    return 0
  end

  doc = Nokogiri::HTML(response.page.body.gsub!(/(&nbsp;|\s)+/, " "))

  casts, genres = [], []

  video.video_name = doc.search('div[@id="video_title"]/h3/a').children.text.strip

  video.video_id = doc.search('//div[@id="video_info"]/div[@id="video_id"]/table/tr/td[@class="text"]').children.text.strip

  video.release_date = doc.search('//div[@id="video_info"]/div[@id="video_date"]/table/tr/td[@class="text"]').children.text.strip

  video.length = doc.search('//div[@id="video_info"]/div[@id="video_length"]/table/tr/td[2]/span').children.text.strip

  video.director = doc.search('//div[@id="video_info"]/div[@id="video_director"]/table/tr/td[@class="text"]').children.text.strip

  video.maker = doc.search('//div[@id="video_info"]/div[@id="video_maker"]/table/tr/td[@class="text"]').children.text.strip

  video.label = doc.search('//div[@id="video_info"]/div[@id="video_label"]/table/tr/td[@class="text"]').children.text.strip

  video.rating = doc.search('//div[@id="video_info"]/div[@id="video_review"]/table/tr/td[@class="text"]/span[@class="score"]').children.text.strip.gsub('(', '').gsub(')', '')

  doc.search('//img[@id="video_jacket_img"]').each do |row|
    video.img = 'http:' + row['src']
  end

  doc.search('//span[@class="star"]/a').each do |row|
    casts << row.attributes['href'].value.split('=')[-1]
  end

  doc.search('//div[@id="video_genres"]/table/tr/td[@class="text"]/span[@class="genre"]/a').each do |row|
    genres << row.children.text
  end

  casts.each do |cast|
    begin
      video.actors << Actor.where("actor_label = ?", cast).first
    rescue
      next
    end
  end

  genres.each do |genre|
    begin
      video.genres << Genre.where("name = ?", genre).first
    rescue
      next
    end
  end

  return video.save
end

def download_test(identifer)
  baseurl = "#{$JAVLIBRARY_URL}/cn/?v=#{identifer}"
  response = Mechanize.new do |agent|
    agent.read_timeout = 2
    agent.open_timeout = 2
    # agent.user_agent = Mechanize::AGENT_ALIASES.values[rand(21)]
  end

  begin
    response.get baseurl
  # rescue Timeout::Error
  #   retry
  rescue
    return 0
  end

  doc = Nokogiri::HTML(response.page.body.gsub!(/(&nbsp;|\s)+/, " "))
  casts = []

  doc.search('//span[@class="star"]/a').each do |row|
    casts << row
    pp row.attributes['href'].value.split('=')[-1]
  end

end
