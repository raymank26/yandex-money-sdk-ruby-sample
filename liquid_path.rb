require 'liquid'
require 'json'
require 'pry-byebug'


class LocalFileSystem
  attr_accessor :root

  def initialize(root)
    @root = root
  end

  def read_template_file(template_path, context)
    full_path = full_path(template_path)
    raise FileSystemError, "No such template '#{template_path}'" unless File.exists?(full_path)

    File.read(full_path)
  end

  def full_path(template_path)
    #raise FileSystemError, "Illegal template name '#{template_path}'" unless template_path =~ /^[^.\/][a-zA-Z0-9_\/]+$/
    full_path = if template_path.include?('/')
                  File.join(root, File.dirname(template_path), "#{File.basename(template_path)}")
                else
                  File.join(root, "#{template_path}")
                end

    raise FileSystemError, "Illegal template path '#{File.expand_path(full_path)}'" unless File.expand_path(full_path) =~ /^#{File.expand_path(root)}/

    full_path
  end
end

module LiquidFilters
  def plus(a, b)
    (a + b).to_s
  end
end

 Liquid::Template.register_filter(LiquidFilters)

 #class Include < Liquid::Tag
   #def initialize(tag_name, markup, options)
     #super
     #syntax = /(#{QuotedFragment}+)(\s+(?:with|for)\s+(#{QuotedFragment}+))?/o

     #if markup =~ syntax

       #template_name = $1
       #variables = $3
       #puts %Q{templates_name is "#{template_name}"}
       #puts %Q{variables is "#{variables}"}
     #end
   #end

   #def render(context)
     #""
   #end
 #end

 #Liquid::Template.register_tag('include2', Include)
