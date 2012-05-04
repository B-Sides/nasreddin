# -*- encoding: UTF-8 -*-
class Weekday
  ENGLISH_DAYS = %w| Monday Tuesday Wednesday Thursday Friday Saturday Sunday |
  TURKSIH_DAYS = %w| Pazartesi Salı Çarsamba Perşembe Cuma Cumartesi Pazar |

  attr_reader :id
  attr_reader :day

  def initialize(opts = {})
    @id = opts[:id].to_i || 1
    @day = ENGLISH_DAYS[@id - 1]
  end

  def self.all
    (1..7).to_a.map { |i| new(id: i) }
  end

  def self.find_by_id(id)
    if !id.kind_of?(Fixnum) || id > 7 || id < 0
      nil
    else
      new(id: id)
    end
  end
end
