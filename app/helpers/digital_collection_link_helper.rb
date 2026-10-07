# frozen_string_literal: true

# Makes links to other sites open in a new tab, with the external-link icon at the end of the link.
module DigitalCollectionLinkHelper
  def dc_external_links_in_new_tab(html)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html.to_s)
    fragment.css('a[href]').each do |link|
      host = URI.parse(link['href']).host
      next if host.blank? || host == request.host

      link['target'] = '_blank'
      link['rel'] = (link['rel'].to_s.split + %w[noopener noreferrer]).uniq.join(' ')
      dc_move_external_icon_to_end(link)
    rescue URI::InvalidURIError
      next
    end
    fragment.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def dc_move_external_icon_to_end(link)
    return if link.at_css('.dc-external-icon')

    dc_remove_leading_icon_before(link)
    dc_remove_leading_icon_inside(link)
    icon = link.document.create_element('span', class: 'fa fa-external-link dc-external-icon', 'aria-hidden': 'true')
    dc_last_word_with(link, icon)
    link.add_child(link.document.create_element('span', t('digital_collection.show.new_tab'), class: 'sr-only'))
  end

  def dc_last_word_with(link, icon)
    text = link.xpath('.//text()[normalize-space()]').last
    return link.add_child(icon) unless text

    before, last_word = text.content.match(/\A(.*?)(\S+)\s*\z/m)&.captures
    keep = link.document.create_element('span', class: 'dc-external-end')
    keep.add_child(Nokogiri::XML::Text.new(last_word.to_s, link.document))
    keep.add_child(icon)
    text.content = before.to_s
    text.add_next_sibling(keep)
  end

  def dc_remove_leading_icon_before(link)
    node = link.previous_sibling
    node = node.previous_sibling while dc_blank_text?(node)
    return unless dc_external_icon?(node)

    node.next_sibling.remove while node.next_sibling != link
    node.remove
  end

  def dc_remove_leading_icon_inside(link)
    node = link.children.first
    node = node.next_sibling while dc_blank_text?(node)
    return unless dc_external_icon?(node)

    node.previous_sibling.remove while node.previous_sibling
    following = node.next_sibling
    node.remove
    following.content = following.content.sub(/\A[\s\u00A0]+/, '') if following&.text?
  end

  def dc_blank_text?(node)
    node&.text? && node.content.delete("\u00A0").strip.empty?
  end

  def dc_external_icon?(node)
    node&.element? && node['class'].to_s.split.include?('fa-external-link')
  end
end
