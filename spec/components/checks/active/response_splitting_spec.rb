require 'spec_helper'

describe name_from_filename do
    include_examples 'check'

    def self.elements
        [ Element::Form, Element::Link, Element::Cookie, Element::Header,
          Element::LinkTemplate]
    end

    def issue_count_per_element
        {
            Element::Form         => 4,
            Element::Link         => 4,
            Element::Cookie       => 4,
            Element::Header       => 2,
            Element::LinkTemplate => 4
        }
    end

    easy_test
end
