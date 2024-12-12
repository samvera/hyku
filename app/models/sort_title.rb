# frozen_string_literal: true

class SortTitle
  def initialize(title)
    @title = title
  end

  def alphabetical
    return if @title.blank?

    title = @title.downcase
    title = title.gsub(/^an(?:[[:space:]])/, '')
                 .gsub(/^a(?:[[:space:]])/, '')
                 .gsub(/^the(?:[[:space:]])/, '')
                 .gsub(/"|'/, '')
    title_elements = title.split(' ')
    new_title = []
    title_elements.each do |element|
      numbers = element.gsub(/[^\d]/, '')
      unless numbers.empty?
        zero_num = numbers.rjust(6, '0')
        element = element.gsub(numbers, zero_num)
      end
      new_title.push(element)
    end
    title = new_title.join(' ')
    title.strip
  end
end
