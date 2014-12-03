# encoding: utf-8

require 'date'
require 'rexml/document'
require 'era_ja/date'
require 'era_ja/time'

class Date
  require 'holiday_jp'
  def is_holiday?
    return self.wday == 0 || self.wday == 6 || HolidayJp.holiday?(self)
  end
end

class String
  def mb_ljust(width, padding=' ')
    output_width = each_char.map{|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
    padding_size = [0, width - output_width].max
    self + padding * padding_size
  end
end

class AirConditionerApplication
  attr_accessor :belong
  attr_accessor :applicant
  attr_accessor :tel
  attr_accessor :mail

  attr_accessor :building_name
  attr_accessor :room_name
  attr_accessor :room_number

  attr_accessor :reason
  attr_accessor :date

  attr_accessor :result

  def initialize(xml = './document.xml', date=Date.today)
    self.date = date
    @wdays = ["日", "月", "火", "水", "木", "金", "土"]
    @date_arr = []
    14.times do |i|
      @date_arr[i] = self.date + ((i%2==0)?(i/2):(i/2+7))
    end

    @doc = REXML::Document.new(File.open(xml))
    self.result = @doc.xml_decl.to_s
  end

  def run(element = @doc.root)
    self.result << ("<#{element.expanded_name}")
    element.attributes.each do |key, value|
      self.result << (" #{key}=\"#{value}\"")
    end

    if (element.has_elements?)
      self.result << (">")
      element.each_element { |child| self.run(child) }
      self.result << ("</#{element.expanded_name}>")
      
    elsif (element.has_text?)
      text = set_values(element.text)
      self.result << (">#{text}</#{element.expanded_name}>")
    else
      self.result << (" />")
    end
  end

  def set_values(text)
    if text.include? 'building'
      text = self.building_name
    elsif text.include? 'room_name'
      text = self.room_name
    elsif text.include? 'room_number'
      text = self.room_number
    elsif text.include? 'reason'
      text = self.reason
    elsif text == '所属　　　　　　　　　　　　　　　'
      text = "所属　　　　　　" + self.belong.mb_ljust(18)
    elsif text == '申請者　　　　　　　　　　　　　印'
      text = "申請者　　　　　" + self.applicant.mb_ljust(14) + "　印"
    elsif text == 'ＴＥＬ（内線）　　　　　　　　　　'
      text = "ＴＥＬ（内線）　" + self.tel.mb_ljust(18)
    elsif text == 'e-mail'
      text = "e-mail　　　　　 " + self.mail.mb_ljust(18)
    elsif  text.include? '平成　　年　　月　　日'
      text = text.sub(/平成　　年　　月　　日/, self.date.to_era("平成 %E年 %m月 %d日") )
    elsif text.include? '　　　月　　　日（　　）'
      text = text.sub(/　　　月　　　日（　　）/, "　　%d月　　%d日（ %s ）" % [@date_arr[0].month, @date_arr[0].day, @wdays[@date_arr[0].wday]])
    elsif text.include? '午前　　　時　　分～　　時　　分'
      time = [0, 0, 8, 0]
      time = [0, 0, 12, 0] if @date_arr[0].is_holiday?
      text = text.sub(/午前　　　時　　分～　　時　　分/, "午前　　%2d時　%02d分～　%2d時　%02d分" % time)
    elsif text.include? '午後　　　時　　分～　　時　　分'
      time = [9, 0, 12, 0]
      time = [0, 0, 12, 0] if @date_arr[0].is_holiday?
      text = text.sub(/午後　　　時　　分～　　時　　分/, "午後　　%2d時　%02d分～　%2d時　%02d分" % time)
      @date_arr.shift
    end

    return text
  end
end
