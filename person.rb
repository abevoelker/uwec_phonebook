require 'active_model'
require 'net/http'
require 'nokogiri'
require 'v8'
require File.join(File.dirname(__FILE__), 'errors.rb')

module UWECPhonebook
  class Person

    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml

    attr_accessor :username
    attr_accessor :name_f
    attr_accessor :name_l
    attr_accessor :phone_local
    attr_accessor :phone_perm
    attr_accessor :addr_local
    attr_accessor :city_local
    attr_accessor :state_local
    attr_accessor :zip_local
    attr_accessor :title
    attr_accessor :office
    attr_accessor :dept
    attr_accessor :description
    attr_accessor :last_mod
    attr_accessor :created

    PHONEBOOK = URI('http://phonebook.uwec.edu/lookup.asp').freeze
    # Map of our model's attributes -> UWEC form attributes
    ATTR_MAP = {:name_f => :first, :name_l => :last, :phone_local => :localPhone,
                :phone_perm => :permPhone, :addr_local => :localAdd,
                :city_local => :localCity, :state_local => :localState,
                :zip_local => :localZip, :description => :descrip,
                :last_mod => :lastmodified}.freeze

    def attributes
      {'username'    => username,
       'name_f'      => name_f,
       'name_l'      => name_l,
       'phone_local' => phone_local,
       'phone_perm'  => phone_perm,
       'addr_local'  => addr_local,
       'city_local'  => city_local,
       'state_local' => state_local,
       'zip_local'   => zip_local,
       'title'       => title,
       'office'      => office,
       'dept'        => dept,
       'description' => description,
       'last_mod'    => last_mod,
       'created'     => created
      }
    end

    def initialize(attributes)
      attributes.each{|k,v| send(k.to_s + '=', v)}
    end

    def name
      "#{name_l}, #{name_f}"
    end

    def to_s
      "#{username} [#{name}]"
    end

    # Returns an array of People that match the criteria
    def self.lookup(args)
      nargs = {}
      args.each{|k,v| nargs[translate_arg(k).to_s] = v} # Nokogiri doesn't like symbolized keys
      res = Net::HTTP.post_form(PHONEBOOK, nargs)
      raise UWECPhonebook::TooManyResults if res.is_a? Net::HTTPInternalServerError
      doc = Nokogiri::HTML(res.body)
      scripts = doc.xpath('//script')
      if scripts.any?
        too_many = scripts.children.select{|n| n.to_s.match("Please refine your search")}.any?
        raise UWECPhonebook::TooManyResults if too_many
      end

      rows = doc.xpath("//table/tr/td/table/tr[position()>1]")
      rows.map do |row|
        # Only use the first column (JS popup), as it has all the info we need
        js = row.children[0].xpath('.//a').first.attribute('href').content
        js.slice!(0..23) # remove JavaScript:openNewWindow
        jsvm = V8::Context.new
        jsvm['p'] = Person
        begin
          jsvm.eval('p.js_init' + js) # Hopefully UWEC doesn't exploit this :-)
        rescue V8::JSError
          warn "Error eval'ing JS on this data: #{js}"
        end
      end
    end

    private

    # Returns a new Person from JavaScript arguments
    def self.js_init(*args)
      # According to lookup.asp code, order is:
      # username,first,last,localPhone,permPhone,localAdd,
      # localCity,localState,localZip,title,office,dept,
      # descrip,lastmodified,created
      Person.new(
        :username => args[0],
        :name_f => args[1],
        :name_l => args[2],
        :phone_local => args[3],
        :phone_perm => args[4],
        :addr_local => args[5],
        :city_local => args[6],
        :state_local => args[7],
        :zip_local => args[8],
        :title => args[9],
        :office => args[10],
        :dept => args[11],
        :description => args[12],
        :last_mod => args[13],
        :created => args[14]
      )
    end

    # Translate our model's attribute to the UWEC form attribute
    def self.translate_arg(arg)
      ATTR_MAP[arg] || arg
    end

  end
end
