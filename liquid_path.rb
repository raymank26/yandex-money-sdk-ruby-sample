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

