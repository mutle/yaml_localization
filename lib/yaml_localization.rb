require 'yaml'

module YamlLocalization
  mattr_accessor :lang
  
  @@l10s = { :default => {} }
  @@lang = :default
  
  def self._(string_to_localize, *args)
    translated = if !@@l10s[@@lang][string_to_localize]
      if RAILS_ENV != "production"
        data = File.exist?("#{RAILS_ROOT}/lang/add_me.yaml") ? YAML.load(File.read("#{RAILS_ROOT}/lang/add_me.yaml")) || {} : {}
        data[string_to_localize] = {'de' => 'need translation', 'en' => string_to_localize}
        File.open("#{RAILS_ROOT}/lang/add_me.yaml", "w+") do |f|
          f << data.to_yaml
        end
      end
      string_to_localize
    else
      @@l10s[@@lang][string_to_localize]
    end
    return translated.call(*args).to_s  if translated.is_a? Proc
    if translated.is_a? Array
      translated = if translated.size == 3 
        translated[args[0]==0 ? 0 : (args[0]>1 ? 2 : 1)]
      else
        translated[args[0]>1 ? 1 : 0]
      end
    end
    sprintf translated, *args
  end
  
  def self.define(lang = :default)
    @@l10s[lang] ||= {}
    yield @@l10s[lang]
  end
  
  def self.load
    data = []
    Dir.glob("#{RAILS_ROOT}/lang/*.yml").each do |f|
      new_data = YAML.load(File.read(f))
      data.push(*new_data['translations']) if new_data['translations'] && new_data['translations'].is_a?(Array)
    end
    
    langs = %w(de en)
    langs.each do |lang|
      @@l10s[lang] ||= {}
    end
    
    data.each do |translation|
      translation.each do |k,v|
        langs.each { |lang| @@l10s[lang][k] = translation[lang] } if v == nil and !langs.include?(k)
      end
    end
  end
  
end

class Object
  def _(*args)
    YamlLocalization._(*args)
  end
end
