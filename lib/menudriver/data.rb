require 'aws-sdk-comprehend'

module MenuDriver

  class Data

    attr_accessor :location_data, :category

    def initialize params = {}
      params.each { |key, value| send "#{key}=", value }
      process
    end

    # Transform the menus, to change or add anything necessary.
    def process
      detectCategories
      detectLanguage
    end

    # Basic data access functions.

    def location_name
      location_data.location.name.gsub(/\s*test\s*location\s*/i,'')
    end

    def location_description
      location_data.location.description
    end

    def menus
      menus = location_data.menus
      menus.select{|menu| menu[:category].eql? category } if category
      menus
    end

    def categories
      categories = menus.map{|menu| menu[:category] || 'Other'}.uniq
      categories = [category] if category
      categories
    end

    # Utility functions.

    def detectCategories
      menus.each do |menu|
        if(match = /(^[^\-]+)\s+\-\s+(.+$)/.match(menu.name))
          menu.category = match[1]
          menu.name = match[2]
        end
      end
    end

    def detectLanguage
      client = Aws::Comprehend::Client.new()

      self.location_data.menus =
        menus.map do |menu|

          # Detect the language.
          menu_text =
            [
              menu.name,
              menu.description,
              menu.sections.map do |section|
                [
                  section.name,
                  section.description,
                  section.items.map do |item|
                    [
                      item.name,
                      item.description
                    ].join(' ')
                  end
                ].join(' ')
              end.join(' ')
            ].join(' ')
          resp = client.detect_dominant_language({text: menu_text[0..2500]})

          menu.merge({
            'language' => resp.languages.first.language_code
          })
        end
    end

  end

end